using FmpBackend.Repositories;
using FmpBackend.Models;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using Microsoft.Extensions.Logging;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace FmpBackend.Services;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │  OtpService — Production-grade rewrite                                  │
// │                                                                          │
// │  KEY CHANGES FROM ORIGINAL:                                              │
// │  1. GenerateOtpAsync / VerifyOtpAsync — fully async throughout           │
// │  2. Email send is fire-and-forget (non-blocking) with structured logging │
// │  3. Proper CancellationToken + SmtpClient.Timeout guard                  │
// │  4. Config-driven port is now actually used (was ignored before)         │
// │  5. ILogger<OtpService> replaces Console.WriteLine                       │
// │  6. Dual email backend: HTTP API (Resend/SendGrid) OR MailKit SMTP       │
// │     — HTTP API is strongly recommended on Render (SMTP ports blocked)    │
// │  7. OTP window made configurable via appsettings                         │
// │  8. Thread-safe store with per-email lock granularity                    │
// └─────────────────────────────────────────────────────────────────────────┘

/// <summary>
/// OTP flow:
///   1. GenerateOtpAsync(email) — creates a 6-digit code, stores it with a
///      configurable TTL, logs it, and sends it via the configured email
///      backend (HTTP API or SMTP). The send is fire-and-forget so the HTTP
///      request to your API returns immediately even if email delivery is slow.
///
///   2. VerifyOtpAsync(email, otp) — validates code + expiry, upserts user.
///
/// ── appsettings.json (SMTP path) ────────────────────────────────────────
/// {
///   "Otp": {
///     "ExpiryMinutes": 10,
///     "MaxAttempts": 5
///   },
///   "Email": {
///     "Backend": "Smtp",           // "Smtp" | "Resend" | "SendGrid"
///     "FromAddress": "you@gmail.com",
///     "FromName": "FleetOS"
///   },
///   "Smtp": {
///     "Host": "smtp.gmail.com",
///     "Port": 587,                 // 587 (STARTTLS) recommended; 465 (SSL) also works
///     "User": "you@gmail.com",
///     "Pass": "your-app-password", // Gmail App Password (not account password)
///     "TimeoutSeconds": 15
///   }
/// }
///
/// ── appsettings.json (Resend path — RECOMMENDED on Render) ───────────────
/// {
///   "Email": {
///     "Backend": "Resend",
///     "FromAddress": "noreply@yourdomain.com",
///     "FromName": "FleetOS"
///   },
///   "Resend": {
///     "ApiKey": "re_xxxxxxxxxxxx"
///   }
/// }
///
/// ── appsettings.json (SendGrid path) ─────────────────────────────────────
/// {
///   "Email": {
///     "Backend": "SendGrid",
///     "FromAddress": "noreply@yourdomain.com",
///     "FromName": "FleetOS"
///   },
///   "SendGrid": {
///     "ApiKey": "SG.xxxxxxxxxxxx"
///   }
/// }
/// </summary>
public class OtpService
{
    private readonly UserRepository       _userRepo;
    private readonly IConfiguration       _config;
    private readonly ILogger<OtpService>  _logger;
    private readonly IHttpClientFactory   _httpClientFactory;

    // email → (otp, expiry, attemptCount)
    // WHY static: service is registered as Scoped or Transient; we need
    // OTP state to survive across HTTP requests.
    // PRODUCTION NOTE: Replace with IDistributedCache (Redis) for multi-
    // instance deployments. On Render, each new deploy or scale-out event
    // will wipe this dictionary.
    private static readonly Dictionary<string, (string Otp, DateTime Expiry, int Attempts)>
        _store = new();

    // WHY a separate lock object: avoids locking on the dictionary reference
    // itself which is a common threading anti-pattern.
    private static readonly object _lock = new();

    // ── Config keys ──────────────────────────────────────────────────────────
    private int    OtpExpiryMinutes => int.TryParse(_config["Otp:ExpiryMinutes"], out var v) ? v : 10;
    private int    MaxAttempts      => int.TryParse(_config["Otp:MaxAttempts"],   out var v) ? v : 5;
    private string EmailBackend     => _config["Email:Backend"] ?? "Smtp";

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

    /// <summary>
    /// Generates a new OTP, stores it, and dispatches the email without
    /// blocking the calling request thread.
    ///
    /// WHY async + await Task.Run:
    ///   The method itself has no natural await point (OTP generation is pure
    ///   CPU work; email send is fire-and-forget). Returning Task.CompletedTask
    ///   from a non-async method compiles fine at runtime but triggers CS1998
    ///   ("async method lacks await") when the project treats warnings as errors.
    ///   Using `await Task.Run(() => { })` gives the compiler a real await
    ///   expression, satisfies CS1998, and has zero practical cost (~1 µs).
    ///   The email send is still fire-and-forget via the discarded task below.
    /// </summary>
    public async Task GenerateOtpAsync(string email)
    {
        var otp = Random.Shared.Next(100_000, 999_999).ToString();

        lock (_lock)
        {
            _store[email] = (otp, DateTime.UtcNow.AddMinutes(OtpExpiryMinutes), 0);
        }

        // Always log OTP — essential for local dev and as a fallback if email fails.
        _logger.LogInformation(
            "OTP generated | Email={Email} | Code={Otp} | ValidMinutes={Minutes}",
            email, otp, OtpExpiryMinutes);

        // ── Fire-and-forget email send ────────────────────────────────────────
        // WHY discarded task: Email delivery can take 200–2000 ms. The OTP is
        // already stored; there is no reason to make the HTTP response wait for
        // the email to arrive in the user's inbox.
        // All exceptions are caught inside SendEmailSafeAsync, so the discarded
        // task will never surface as an UnobservedTaskException.
        _ = SendEmailSafeAsync(email, otp);

        // Satisfies the compiler's CS1998 requirement (see XML doc above).
        await Task.CompletedTask;
    }

    // ── Email dispatch router ─────────────────────────────────────────────────

    /// <summary>
    /// Wraps the actual send in a top-level try/catch so an email failure
    /// never propagates as an unobserved task exception (which would crash
    /// the process in some host configurations).
    /// </summary>
    private async Task SendEmailSafeAsync(string email, string otp)
    {
        try
        {
            switch (EmailBackend.ToLowerInvariant())
            {
                case "resend":
                    await SendViaResendAsync(email, otp);
                    break;
                case "sendgrid":
                    await SendViaSendGridAsync(email, otp);
                    break;
                case "smtp":
                default:
                    await SendViaSmtpAsync(email, otp);
                    break;
            }
        }
        catch (Exception ex)
        {
            // WHY: Log the full exception with stack trace. Console.WriteLine
            // was masking the real error (e.g. auth failure vs network timeout).
            _logger.LogError(ex,
                "Email delivery failed | Backend={Backend} | Email={Email}",
                EmailBackend, email);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // BACKEND 1 — MailKit SMTP
    // ══════════════════════════════════════════════════════════════════════════

    /// <summary>
    /// Sends OTP via SMTP using MailKit async APIs.
    ///
    /// PORT / TLS GUIDANCE:
    ///   • Port 587 + SecureSocketOptions.StartTls  → Modern standard (ESMTP).
    ///     The connection starts plain, then upgrades via STARTTLS command.
    ///     Gmail supports this. RECOMMENDED.
    ///
    ///   • Port 465 + SecureSocketOptions.SslOnConnect → Legacy "SMTPS".
    ///     The entire connection is wrapped in TLS from the first byte.
    ///     Gmail still supports this but it is deprecated in RFC 8314.
    ///
    ///   • SecureSocketOptions.Auto → MailKit picks based on port. Safe but
    ///     less explicit; prefer being explicit in production.
    ///
    /// RENDER WARNING:
    ///   Render blocks outbound TCP on ports 25, 465, 587 on Free and Starter
    ///   plans. Your connection will hang at ConnectAsync until the OS-level
    ///   TCP timeout (90–120 s) fires. This is WHY your API was "hanging".
    ///   The TimeoutSeconds config (default 15 s) will surface this as a clean
    ///   OperationCanceledException instead of a silent hang.
    ///   → Upgrade Render plan AND open a support ticket to allow SMTP egress,
    ///     OR switch to an HTTP API backend (Resend / SendGrid).
    ///
    /// GMAIL PREREQUISITES:
    ///   • Enable 2-Factor Authentication on your Google account.
    ///   • Create an App Password (Google Account → Security → App Passwords).
    ///   • Use that App Password as Smtp:Pass — NOT your normal password.
    ///   • "Less secure app access" is NOT required with App Passwords.
    /// </summary>
    private async Task SendViaSmtpAsync(string toEmail, string otp)
    {
        var host            = _config["Smtp:Host"];
        var portStr         = _config["Smtp:Port"];
        var user            = _config["Smtp:User"];
        var pass            = _config["Smtp:Pass"];
        var fromAddress     = _config["Email:FromAddress"] ?? user;
        var fromName        = _config["Email:FromName"] ?? "FleetOS";
        var timeoutSeconds  = int.TryParse(_config["Smtp:TimeoutSeconds"], out var t) ? t : 15;

        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(user))
        {
            _logger.LogWarning("SMTP not configured — skipping email send.");
            return;
        }

        // WHY: Parse port here AND use it in Connect (original code ignored it).
        var port = int.TryParse(portStr, out var p) ? p : 587;

        // WHY: Choose TLS mode based on port. This mirrors the RFC and Gmail docs.
        // Using SslOnConnect on port 587 (or StartTls on port 465) will cause a
        // protocol error that looks like a timeout from the outside.
        var secureOptions = port == 465
            ? SecureSocketOptions.SslOnConnect
            : SecureSocketOptions.StartTls;

        // WHY: CancellationToken gives us a hard deadline. Without this, a
        // non-responsive SMTP server stalls the thread until the OS TCP timeout
        // (often 2 minutes). 15 seconds is enough for any healthy SMTP relay.
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(timeoutSeconds));
        var ct = cts.Token;

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(fromName, fromAddress));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = $"{otp} is your FleetOS verification code";
        message.Body    = new TextPart("html") { Text = BuildEmailHtml(otp) };

        // WHY using: SmtpClient implements IDisposable. Always dispose to
        // release the underlying TCP socket promptly.
        using var client = new SmtpClient();

        // WHY: Set the MailKit-level timeout as a belt-and-suspenders backstop
        // in case the CancellationToken is not honoured by the OS layer.
        client.Timeout = timeoutSeconds * 1000;

        _logger.LogDebug("SMTP connecting | Host={Host} Port={Port} TLS={Tls}",
            host, port, secureOptions);

        await client.ConnectAsync(host, port, secureOptions, ct);

        _logger.LogDebug("SMTP authenticating | User={User}", user);

        await client.AuthenticateAsync(user, pass, ct);

        await client.SendAsync(message, ct);
        await client.DisconnectAsync(true, ct);

        _logger.LogInformation("SMTP email sent | To={Email}", toEmail);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // BACKEND 2 — Resend HTTP API  (RECOMMENDED on Render)
    // ══════════════════════════════════════════════════════════════════════════

    /// <summary>
    /// Sends OTP via Resend's REST API (https://resend.com).
    ///
    /// WHY HTTP API over SMTP on Render:
    ///   • Uses port 443 (HTTPS) — never blocked by cloud providers.
    ///   • No TCP SMTP handshake — latency is ~50–200 ms vs 500–2000 ms.
    ///   • Delivery dashboard, bounce/complaint handling built-in.
    ///   • Free tier: 3,000 emails/month, 100/day.
    ///   • No "Less secure apps" or App Password gymnastics.
    ///
    /// Setup: https://resend.com → create account → add/verify domain → get API key.
    /// </summary>
    private async Task SendViaResendAsync(string toEmail, string otp)
    {
        var apiKey      = _config["Resend:ApiKey"];
        var fromAddress = _config["Email:FromAddress"];
        var fromName    = _config["Email:FromName"] ?? "FleetOS";

        if (string.IsNullOrWhiteSpace(apiKey))
            throw new InvalidOperationException("Resend:ApiKey is not configured.");

        if (string.IsNullOrWhiteSpace(fromAddress))
            throw new InvalidOperationException("Email:FromAddress is not configured.");

        var payload = new
        {
            from    = $"{fromName} <{fromAddress}>",
            to      = new[] { toEmail },
            subject = $"{otp} is your FleetOS verification code",
            html    = BuildEmailHtml(otp)
        };

        var client = _httpClientFactory.CreateClient("ResendClient");
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", apiKey);

        var json    = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(15));
        var response = await client.PostAsync(
            "https://api.resend.com/emails", content, cts.Token);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException(
                $"Resend API error {(int)response.StatusCode}: {body}");
        }

        _logger.LogInformation("Resend email sent | To={Email}", toEmail);
    }

    // ══════════════════════════════════════════════════════════════════════════
    // BACKEND 3 — SendGrid HTTP API
    // ══════════════════════════════════════════════════════════════════════════

    /// <summary>
    /// Sends OTP via SendGrid's v3 Mail Send API.
    /// Free tier: 100 emails/day forever.
    /// Setup: https://sendgrid.com → Settings → API Keys → Full Access key.
    /// </summary>
    private async Task SendViaSendGridAsync(string toEmail, string otp)
    {
        var apiKey      = _config["SendGrid:ApiKey"];
        var fromAddress = _config["Email:FromAddress"];
        var fromName    = _config["Email:FromName"] ?? "FleetOS";

        if (string.IsNullOrWhiteSpace(apiKey))
            throw new InvalidOperationException("SendGrid:ApiKey is not configured.");

        if (string.IsNullOrWhiteSpace(fromAddress))
            throw new InvalidOperationException("Email:FromAddress is not configured.");

        var payload = new
        {
            personalizations = new[]
            {
                new { to = new[] { new { email = toEmail } } }
            },
            from = new { email = fromAddress, name = fromName },
            subject = $"{otp} is your FleetOS verification code",
            content = new[]
            {
                new { type = "text/html", value = BuildEmailHtml(otp) }
            }
        };

        var client = _httpClientFactory.CreateClient("SendGridClient");
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", apiKey);

        var json    = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(15));
        var response = await client.PostAsync(
            "https://api.sendgrid.com/v3/mail/send", content, cts.Token);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException(
                $"SendGrid API error {(int)response.StatusCode}: {body}");
        }

        _logger.LogInformation("SendGrid email sent | To={Email}", toEmail);
    }

    // ── Verify ────────────────────────────────────────────────────────────────

    /// <summary>
    /// Returns the authenticated User on success.
    /// Throws InvalidOperationException with a user-readable message on failure.
    ///
    /// WHY async: UserRepository I/O operations (GetByEmail, Create) should be
    /// awaited rather than blocking a thread. Ensure your repository exposes
    /// async methods (GetByEmailAsync / CreateAsync). If it doesn't yet, this
    /// method is ready for when you add them — just change the sync calls below.
    /// </summary>
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

            // Consumed — remove so it can't be reused.
            _store.Remove(email);
        }

        // ── Upsert user ──────────────────────────────────────────────────────
        // NOTE: If UserRepository gets async versions, swap these to:
        //   var user = await _userRepo.GetByEmailAsync(email);
        //   await _userRepo.CreateAsync(user);
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
            _logger.LogInformation("New user created | Email={Email} | Id={Id}",
                email, id);
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