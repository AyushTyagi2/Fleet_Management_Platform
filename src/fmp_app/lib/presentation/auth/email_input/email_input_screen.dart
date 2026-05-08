import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fmp_app/presentation/auth/auth_controller.dart';
import 'package:fmp_app/shared/theme/app_theme.dart';

// lib/presentation/auth/email_input/email_input_screen.dart

class EmailInputScreen extends StatefulWidget {
  const EmailInputScreen({super.key});
  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(BuildContext context) async {
    final auth = context.read<AuthController>();
    if (!_formKey.currentState!.validate()) return;
    auth.setEmail(_emailCtrl.text.trim());
    await auth.sendOtp();
    if (!mounted) return;
    if (auth.stage == AuthStage.otpSent) {
      Navigator.pushNamed(context, '/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.stage == AuthStage.otpSending;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background Gradient ──────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEEF1F8), Color(0xFFF7F9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // ── Top Blue Wave ─────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.38,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(color: const Color(0xFF2233CC)),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _BrandMarkWhite(),
                          const SizedBox(height: 32),
                          _buildCard(auth, isLoading),
                          const SizedBox(height: 24),
                          // ── Footer note ───────────────────────────────────
                          Center(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                                children: [
                                  TextSpan(text: 'By continuing you agree to our\n'),
                                  TextSpan(
                                    text: 'Terms',
                                    style: TextStyle(color: Color(0xFF2233CC), fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(text: ' & '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(color: Color(0xFF2233CC), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AuthController auth, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Less blobby
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Headline ────────────────────────────────────────────────────
          const Text('Welcome back',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                  color: Color(0xFF111827), letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('Enter your email address to continue',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
          const SizedBox(height: 32),

          // ── Form ────────────────────────────────────────────────────────
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Email Address',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _sendOtp(context),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                      color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 15),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(Icons.mail_outline_rounded,
                          color: Color(0xFF6B7280), size: 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E9F0), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E9F0), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2233CC), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE02424), width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE02424), width: 2),
                    ),
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
                    if (s.isEmpty) return 'Please enter your email address';
                    if (!emailRegex.hasMatch(s)) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ── CTA Button ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _sendOtp(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2233CC),
                      disabledBackgroundColor: const Color(0xFF2233CC).withOpacity(0.6),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Send OTP', style: TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.w600, color: Colors.white)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 18, color: Colors.white),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // ── Error message ────────────────────────────────────────────────
          if (auth.stage == AuthStage.error && auth.errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: auth.errorMessage!),
          ],
        ],
      ),
    );
  }
}

// ── Brand mark white ────────────────────────────────────────────────────────
class _BrandMarkWhite extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(children: [
      Icon(Icons.local_shipping_rounded, color: Colors.white, size: 48),
      SizedBox(height: 8),
      Text('FleetOS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
          color: Colors.white, letterSpacing: -0.3)),
    ]);
  }
}

// ── Wave Clipper ────────────────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height + 40, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ── Error Banner ────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF8B4B4), width: 1),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFE02424)),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
            style: const TextStyle(fontSize: 13, color: Color(0xFFE02424), height: 1.4))),
      ]),
    );
  }
}