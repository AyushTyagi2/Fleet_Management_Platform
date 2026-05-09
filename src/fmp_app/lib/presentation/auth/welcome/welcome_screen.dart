import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../routes/app_router.dart';
import '../auth_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _pulse;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _floatController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
    _fadeIn = CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _slideUp = CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _float = Tween<double>(begin: -5.0, end: 5.0).animate(
        CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final isDesktop = AppLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: Stack(
        children: [
          // ── Background decorations ─────────────────────────────────────
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          Positioned(top: -60, right: -40,
              child: _LightBlob(color: const Color(0xFFDDE8FF), size: 280)),
          Positioned(bottom: -30, left: -50,
              child: _LightBlob(color: const Color(0xFFDCEAFF), size: 200)),

          // ── Content ────────────────────────────────────────────────────
          SafeArea(
            child: isDesktop ? _buildDesktop(auth) : _buildMobile(auth),
          ),
        ],
      ),
    );
  }

  // ── Desktop: two-column split ──────────────────────────────────────────
  Widget _buildDesktop(AuthController auth) {
    return Row(
      children: [
        // Left — illustration panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0C3997)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _float,
                    builder: (_, child) => Transform.translate(
                        offset: Offset(0, _float.value), child: child),
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, child) =>
                          Transform.scale(scale: _pulse.value, child: child),
                      child: _TruckIllustration(lightMode: false),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text('Move Freight.\nSmarter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w900,
                      color: Colors.white, height: 1.15, letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connect drivers, fleets, and senders\non one intelligent platform.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15, height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right — login actions
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: _buildActions(auth),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile: single-column scrollable ───────────────────────────────────
  Widget _buildMobile(AuthController auth) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const SizedBox(height: 20),
          // Logo badge
          FadeTransition(
            opacity: _fadeIn,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A6DFF).withOpacity(0.10),
                    blurRadius: 12, offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: Color(0xFF1A6DFF), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text('FMP Platform',
                    style: TextStyle(color: Color(0xFF1A3A6B), fontSize: 12,
                        fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ]),
            ),
          ),
          const SizedBox(height: 36),

          // Illustration
          Center(
            child: AnimatedBuilder(
              animation: _float,
              builder: (_, child) => Transform.translate(
                  offset: Offset(0, _float.value), child: child),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) =>
                    Transform.scale(scale: _pulse.value, child: child),
                child: _TruckIllustration(lightMode: true),
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Headline
          AnimatedBuilder(
            animation: _slideUp,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, 30 * (1 - _slideUp.value)),
              child: Opacity(opacity: _slideUp.value, child: child),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900,
                        height: 1.1, letterSpacing: -1),
                    children: [
                      TextSpan(text: 'Move Freight.\n',
                          style: TextStyle(color: Color(0xFF0D1B2E))),
                      TextSpan(text: 'Smarter.',
                          style: TextStyle(color: Color(0xFF1A6DFF))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Connect drivers, fleets, and senders\non one intelligent platform.',
                  style: TextStyle(
                    color: const Color(0xFF4A5568).withOpacity(0.85),
                    fontSize: 14, height: 1.65,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildActions(auth),
          const SizedBox(height: 32),
        ],
      ),
    ),
  ),
);
  }

  // ── Shared action buttons ──────────────────────────────────────────────
  Widget _buildActions(AuthController auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email button
        _PressableButton(
          onTap: () => Navigator.pushNamed(context, AppRouter.email),
          color: const Color(0xFF1A6DFF),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.mail_outline_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Continue with Email',
                style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white70, size: 16),
          ]),
        ),
        const SizedBox(height: 14),

        // // Divider
        // Row(children: [
        //   Expanded(child: Divider(
        //       color: const Color(0xFF4A5568).withOpacity(0.18), thickness: 1)),
        //   Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 12),
        //     child: Text('or', style: TextStyle(
        //         color: const Color(0xFF4A5568).withOpacity(0.45), fontSize: 13)),
        //   ),
        //   Expanded(child: Divider(
        //       color: const Color(0xFF4A5568).withOpacity(0.18), thickness: 1)),
        // ]),
        // const SizedBox(height: 14),

        // Google button
        // _PressableButton(
        //   onTap: () => auth.signInWithGoogle(context),
        //   color: Colors.white,
        //   border: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        //   child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        //     SizedBox(width: 24, height: 24,
        //         child: CustomPaint(painter: _GoogleGPainter())),
        //     const SizedBox(width: 10),
        //     const Text('Continue with Google',
        //         style: TextStyle(color: Color(0xFF1A202C), fontSize: 15,
        //             fontWeight: FontWeight.w600)),
        //   ]),
        // ),
        const SizedBox(height: 18),

        // Terms
        Center(
          child: Text(
            'By continuing, you agree to our Terms & Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF4A5568).withOpacity(0.45),
              fontSize: 11, height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pressable button with scale animation ────────────────────────────────────

class _PressableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  final BorderSide? border;
  final Widget child;
  const _PressableButton({required this.onTap, required this.color,
      this.border, required this.child});
  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity, height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.color,
            border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
            boxShadow: widget.border == null ? [
              BoxShadow(color: widget.color.withOpacity(0.25),
                  blurRadius: 16, offset: const Offset(0, 6)),
            ] : [
              BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Truck Illustration ───────────────────────────────────────────────────────

class _TruckIllustration extends StatelessWidget {
  final bool lightMode;
  const _TruckIllustration({required this.lightMode});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240, height: 160,
      child: CustomPaint(painter: _TruckPainter(lightMode: lightMode)),
    );
  }
}

class _TruckPainter extends CustomPainter {
  final bool lightMode;
  _TruckPainter({required this.lightMode});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final accent = lightMode ? const Color(0xFF1A6DFF) : Colors.white;
    final lineColor = lightMode ? const Color(0xFFB0C4E8) : Colors.white.withOpacity(0.3);
    final fillColor = lightMode ? const Color(0xFFE8EFFF) : Colors.white.withOpacity(0.1);
    final cabFillColor = lightMode ? const Color(0xFFD8E6FF) : Colors.white.withOpacity(0.15);

    // Road
    final roadPaint = Paint()..color = lineColor..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, h * 0.80), Offset(w, h * 0.80), roadPaint);
    final dashPaint = Paint()..color = lineColor.withOpacity(0.6)..strokeWidth = 1.5;
    for (double x = 0; x < w; x += 20) {
      canvas.drawLine(Offset(x, h * 0.80), Offset(x + 10, h * 0.80), dashPaint);
    }

    // Cargo
    final cargoRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.30, w * 0.62, h * 0.46), const Radius.circular(7));
    canvas.drawRRect(cargoRect, Paint()..color = fillColor);
    canvas.drawRRect(cargoRect, Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.30, w * 0.62, h * 0.055), const Radius.circular(7)),
        Paint()..color = accent);

    // Doors
    canvas.drawLine(Offset(w * 0.35, h * 0.36), Offset(w * 0.35, h * 0.76),
        Paint()..color = lineColor..strokeWidth = 1.0);
    canvas.drawLine(Offset(w * 0.20, h * 0.53), Offset(w * 0.66, h * 0.53),
        Paint()..color = lineColor..strokeWidth = 1.0);

    // Cab
    final cabPath = Path()
      ..moveTo(w * 0.66, h * 0.76)..lineTo(w * 0.66, h * 0.42)
      ..quadraticBezierTo(w * 0.66, h * 0.35, w * 0.73, h * 0.34)
      ..lineTo(w * 0.84, h * 0.34)
      ..quadraticBezierTo(w * 0.96, h * 0.36, w * 0.97, h * 0.46)
      ..lineTo(w * 0.97, h * 0.76)..close();
    canvas.drawPath(cabPath, Paint()..color = cabFillColor);
    canvas.drawPath(cabPath, Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Window
    final windowPath = Path()
      ..moveTo(w * 0.70, h * 0.44)..lineTo(w * 0.70, h * 0.37)
      ..quadraticBezierTo(w * 0.71, h * 0.36, w * 0.73, h * 0.36)
      ..lineTo(w * 0.83, h * 0.36)
      ..quadraticBezierTo(w * 0.92, h * 0.38, w * 0.93, h * 0.44)..close();
    canvas.drawPath(windowPath, Paint()..color = accent.withOpacity(0.20));
    canvas.drawPath(windowPath, Paint()..color = accent.withOpacity(0.55)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Wheels
    _drawWheel(canvas, Offset(w * 0.20, h * 0.785), 12, lightMode);
    _drawWheel(canvas, Offset(w * 0.52, h * 0.785), 12, lightMode);
    _drawWheel(canvas, Offset(w * 0.845, h * 0.785), 10, lightMode);

    // Taillight
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.945, h * 0.56, w * 0.035, h * 0.07), const Radius.circular(3)),
        Paint()..color = const Color(0xFFFFB800));
  }

  void _drawWheel(Canvas canvas, Offset center, double r, bool light) {
    canvas.drawCircle(center, r, Paint()..color = light ? const Color(0xFF3D4F6B) : Colors.white.withOpacity(0.6));
    canvas.drawCircle(center, r * 0.44, Paint()..color = light ? const Color(0xFFD8E6FF) : Colors.white.withOpacity(0.3));
    canvas.drawCircle(center, r * 0.12, Paint()..color = light ? const Color(0xFF1A6DFF) : Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.width * 0.42;
    final colors = [const Color(0xFF4285F4), const Color(0xFF34A853),
        const Color(0xFFFBBC05), const Color(0xFFEA4335)];
    final paint = Paint()..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          i * 90 * 3.14159 / 180, 90 * 3.14159 / 180, false, paint);
    }
    canvas.drawLine(Offset(cx, cy), Offset(cx + r, cy),
        Paint()..color = const Color(0xFF4285F4)..strokeWidth = size.width * 0.15
          ..strokeCap = StrokeCap.square);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LightBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _LightBlob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color, const Color(0xFFF5F7FF).withOpacity(0)]),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A6DFF).withOpacity(0.055);
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}