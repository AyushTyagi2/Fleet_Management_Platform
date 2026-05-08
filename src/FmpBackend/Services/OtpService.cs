using FmpBackend.Repositories;
using FmpBackend.Models;
using Microsoft.Extensions.Logging;
using System.Text;
using System.Text.Json;

namespace FmpBackend.Services;

public class OtpService
{
    private readonly UserRepository      _userRepo;
    private readonly IConfiguration      _config;
    private readonly ILogger<OtpService> _logger;
    private readonly IHttpClientFactory  _httpClientFactory;

    private static readonly Dictionary<string, (string Otp, DateTime Expiry, int Attempts)>
        _store = new();
    private static readonly object _lock = new();

    private int OtpExpiryMinutes => int.TryParse(_config["Otp:ExpiryMinutes"], out var v) ? v : 10;
    private int MaxAttempts      => int.TryParse(_config["Otp:MaxAttempts"],   out var v) ? v : 5;

    public OtpService(
        UserRepository      userRepo,
        IConfiguration      config,
        ILogger<OtpService> logger,
        IHttpClientFactory  httpClientFactory)
    {
        _userRepo          = userRepo;
        _config            = config;
        _logger            = logger;
        _httpClientFactory = httpClientFactory;
    }

    // ── Generate & send ───────────────────────────────────────────────────────

    public async Task GenerateOtpAsync(string email)
    {
        var otp = Random.Shared.Next(100_000, 999_999).ToString();

        lock (_lock)
        {
            _store[email] = (otp, DateTime.UtcNow.AddMinutes(OtpExpiryMinutes), 0);
        }

        _logger.LogInformation(
            "OTP generated | Email={Email} | Code={Otp} | ValidMinutes={Minutes}",
            email, otp, OtpExpiryMinutes);

        // Fire-and-forget — response doesn't wait for email delivery
        _ = SendEmailSafeAsync(email, otp);

        await Task.CompletedTask;
    }

    // ── Email send (Brevo) ────────────────────────────────────────────────────

    private async Task SendEmailSafeAsync(string email, string otp)
    {
        try
        {
            await SendViaBrevoAsync(email, otp);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Brevo email delivery failed | Email={Email}", email);
        }
    }

    private async Task SendViaBrevoAsync(string toEmail, string otp)
    {
        var apiKey      = _config["Brevo:ApiKey"];
        var fromAddress = _config["Email:FromAddress"];
        var fromName    = _config["Email:FromName"] ?? "FleetOS";

        if (string.IsNullOrWhiteSpace(apiKey))
            throw new InvalidOperationException("Brevo:ApiKey is not configured.");

        if (string.IsNullOrWhiteSpace(fromAddress))
            throw new InvalidOperationException("Email:FromAddress is not configured.");

        var payload = new
        {
            sender      = new { email = fromAddress, name = fromName },
            to          = new[] { new { email = toEmail } },
            subject     = $"{otp} is your FleetOS verification code",
            htmlContent = BuildEmailHtml(otp)
        };

        var client = _httpClientFactory.CreateClient("BrevoClient");
        client.DefaultRequestHeaders.Add("api-key", apiKey);

        var json    = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(15));
        var response  = await client.PostAsync(
            "https://api.brevo.com/v3/smtp/email", content, cts.Token);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException(
                $"Brevo API error {(int)response.StatusCode}: {body}");
        }

        _logger.LogInformation("Brevo email sent | To={Email}", toEmail);
    }

    // ── Verify ────────────────────────────────────────────────────────────────

    public async Task<User> VerifyOtpAsync(string email, string otp)
    {
        lock (_lock)
        {
            if (!_store.TryGetValue(email, out var entry))
                throw new InvalidOperationException("No OTP was requested for this email.");

            if (entry.Attempts >= MaxAttempts)
                throw new InvalidOperationException(
                    "Too many failed attempts. Please request a new OTP.");

            if (DateTime.UtcNow > entry.Expiry)
            {
                _store.Remove(email);
                throw new InvalidOperationException(
                    "OTP has expired. Please request a new one.");
            }

            if (entry.Otp != otp)
            {
                _store[email] = entry with { Attempts = entry.Attempts + 1 };
                int remaining = MaxAttempts - (entry.Attempts + 1);
                _logger.LogWarning(
                    "Incorrect OTP | Email={Email} | AttemptsLeft={Remaining}",
                    email, remaining);
                throw new InvalidOperationException(
                    $"Incorrect OTP. {remaining} attempt(s) remaining.");
            }

            _store.Remove(email);
        }

        var user = _userRepo.GetByEmail(email);

        if (user == null)
        {
            var id = Guid.NewGuid();
            user = new User
            {
                Id           = id,
                Email        = email,
                PasswordHash = string.Empty,
                AuthProvider = "email_otp",
                FullName     = $"user_{id.ToString()[..8]}",
                CreatedAt    = DateTime.UtcNow,
            };
            _userRepo.Create(user);
            _logger.LogInformation("New user created | Email={Email} | Id={Id}", email, id);
        }
        else
        {
            _logger.LogInformation("Existing user authenticated | Email={Email} | Id={Id}",
                email, user.Id);
        }

        return user;
    }

    // ── Email HTML template ───────────────────────────────────────────────────

    private string BuildEmailHtml(string otp) => $@"
<!DOCTYPE html>
<html lang=""en"">
<head><meta charset=""UTF-8""><meta name=""viewport"" content=""width=device-width,initial-scale=1""></head>
<body style=""margin:0;padding:0;background:#f4f4f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif"">
  <table width=""100%"" cellpadding=""0"" cellspacing=""0"">
    <tr><td align=""center"" style=""padding:40px 16px"">
      <table width=""480"" cellpadding=""0"" cellspacing=""0""
             style=""background:#ffffff;border-radius:12px;overflow:hidden;
                    box-shadow:0 2px 8px rgba(0,0,0,.08)"">
        <tr>
          <td style=""background:#2563EB;padding:28px 32px"">
            <h1 style=""margin:0;color:#ffffff;font-size:22px;font-weight:700"">
              FleetOS Verification
            </h1>
          </td>
        </tr>
        <tr>
          <td style=""padding:32px"">
            <p style=""margin:0 0 24px;color:#374151;font-size:16px;line-height:1.6"">
              Use the code below to sign in. It expires in {OtpExpiryMinutes} minutes.
            </p>
            <div style=""background:#EFF6FF;border:2px solid #BFDBFE;
                        border-radius:8px;padding:24px;text-align:center"">
              <span style=""font-size:40px;font-weight:700;letter-spacing:12px;
                           color:#1D4ED8"">{otp}</span>
            </div>
            <p style=""margin:24px 0 0;color:#6B7280;font-size:13px"">
              If you didn't request this code, you can safely ignore this email.
            </p>
          </td>
        </tr>
        <tr>
          <td style=""background:#F9FAFB;padding:16px 32px;border-top:1px solid #E5E7EB"">
            <p style=""margin:0;color:#9CA3AF;font-size:12px"">
              © {DateTime.UtcNow.Year} FleetOS. This is an automated message.
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>";
}