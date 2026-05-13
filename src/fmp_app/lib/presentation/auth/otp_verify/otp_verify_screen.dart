import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fmp_app/shared/theme/app_theme.dart';
import 'package:fmp_app/core/network/auth_controller.dart';

// lib/presentation/auth/otp_verify/otp_verify_screen.dart

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});
  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _digitCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String get _otpValue => _digitCtrls.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    for (final c in _digitCtrls) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _digitCtrls[i].text = digits[i];
      }
      if (digits.length >= 6) {
        _focusNodes[5].requestFocus();
        _tryVerify();
      }
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otpValue.length == 6) _tryVerify();
  }

  void _tryVerify() {
    final auth = context.read<AuthController>();
    // Pass context so verifyOtp can do routing inline (keeps spinner alive)
    auth.verifyOtp(_otpValue, context: context);
  }

  String _formatSeconds(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isWorking = auth.stage == AuthStage.verifyingOtp ||
        auth.stage == AuthStage.routing;
    final hasError = auth.stage == AuthStage.error && auth.errorMessage != null;
    final isDesktop = AppLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 24,
                    vertical: isDesktop ? 40 : 24,
                  ),
                  child: isDesktop
                      ? Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0C000000),
                                  blurRadius: 24, offset: Offset(0, 8)),
                            ],
                          ),
                          child: _buildContent(auth, isWorking, hasError),
                        )
                      : _buildContent(auth, isWorking, hasError),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AuthController auth, bool isWorking, bool hasError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // ── Back ──────────────────────────────────────────────────────
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          color: const Color(0xFF111827),
        ),
        const SizedBox(height: 24),

        // ── Icon ──────────────────────────────────────────────────────
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF0FE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              size: 26, color: Color(0xFF1A56DB)),
        ),
        const SizedBox(height: 20),

        // ── Headline ──────────────────────────────────────────────────
        const Text('Check your email',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                color: Color(0xFF111827), letterSpacing: -0.5)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280),
                height: 1.5),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: auth.email ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600,
                    color: Color(0xFF111827)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // ── OTP Boxes — centered with gaps, NOT spaceBetween ─────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DigitBox(
                  controller: _digitCtrls[index],
                  focusNode: _focusNodes[index],
                  onChanged: (v) => _onDigitChanged(index, v),
                  onBackspace: () {
                    if (_digitCtrls[index].text.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                      _digitCtrls[index - 1].clear();
                    }
                  },
                  hasError: hasError,
                ),
                if (index < 5) const SizedBox(width: 6),
                // visual separator between groups of 3
                if (index == 2) const SizedBox(width: 4),
              ],
            );
          }),
        ),
        const SizedBox(height: 24),

        // ── Error banner ──────────────────────────────────────────────
        if (hasError) ...[
          _buildErrorBanner(auth.errorMessage!),
          const SizedBox(height: 16),
        ],

        // ── Verify Button ─────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isWorking ? null : _tryVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              disabledBackgroundColor: const Color(0xFF1A56DB).withOpacity(0.6),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: isWorking
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white))),
                    const SizedBox(width: 10),
                    Text(
                      auth.stage == AuthStage.routing
                          ? 'Signing you in…'
                          : 'Verifying…',
                      style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ])
                : const Text('Verify & Continue',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 20),

        // ── Timer / Resend ────────────────────────────────────────────
        Center(
          child: auth.secondsLeft > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, size: 14,
                        color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text('Resend code in ${_formatSeconds(auth.secondsLeft)}',
                        style: const TextStyle(fontSize: 13,
                            color: Color(0xFF6B7280))),
                  ],
                )
              : TextButton(
                  onPressed: () {
                    for (final c in _digitCtrls) c.clear();
                    _focusNodes[0].requestFocus();
                    context.read<AuthController>().sendOtp();
                  },
                  child: const Text("Didn't receive it? Resend code",
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A56DB))),
                ),
        ),
        const SizedBox(height: 12),

        // ── Spam hint ─────────────────────────────────────────────────
        Center(
          child: Text("Check your spam folder if you don't see it",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF8B4B4), width: 1),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 18,
            color: Color(0xFFE02424)),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
            style: const TextStyle(fontSize: 13, color: Color(0xFFE02424),
                height: 1.4))),
      ]),
    );
  }
}

// ── Digit box — compact size ─────────────────────────────────────────────────

class _DigitBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;
  final bool hasError;

  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
    required this.hasError,
  });

  @override
  State<_DigitBox> createState() => _DigitBoxState();
}

class _DigitBoxState extends State<_DigitBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.controller.text.isNotEmpty;
    final errorMode = widget.hasError;

    Color borderColor;
    Color fillColor;
    if (errorMode) {
      borderColor = const Color(0xFFE02424);
      fillColor = const Color(0xFFFDE8E8);
    } else if (_focused) {
      borderColor = const Color(0xFF1A56DB);
      fillColor = const Color(0xFFEBF0FE);
    } else if (filled) {
      borderColor = const Color(0xFF1A56DB).withOpacity(0.4);
      fillColor = const Color(0xFFEBF0FE).withOpacity(0.5);
    } else {
      borderColor = const Color(0xFFE5E9F0);
      fillColor = Colors.white;
    }

    return SizedBox(
      width: 38, height: 48,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) {
          if (e.logicalKey.keyLabel == 'Backspace') widget.onBackspace();
        },
        child: TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          onChanged: widget.onChanged,
          style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: errorMode ? const Color(0xFFE02424) : const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: fillColor,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE02424), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}