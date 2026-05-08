import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fmp_app/presentation/auth/auth_controller.dart';

// lib/presentation/onboarding/role_selection/role_selection_screen.dart

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedRole == null) return;
    final auth = context.read<AuthController>();
    await auth.chooseRole(context, _selectedRole!);
  }

  static const _roles = [
    _RoleOption(
      id: 'driver',
      label: 'Driver',
      subtitle: 'Accept shipments & manage trips',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF1A56DB),
      bg: Color(0xFFEBF0FE),
    ),
    _RoleOption(
      id: 'organization',
      label: 'Sender / Receiver',
      subtitle: 'Create & track your shipments',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF0E9F6E),
      bg: Color(0xFFDEF7EC),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.stage == AuthStage.verifyingOtp;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
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

          // Header Block
          Positioned(
            top: 0, left: 0, right: 0,
            height: 180,
            child: Container(
              padding: const EdgeInsets.only(bottom: 20),
              color: const Color(0xFF2233CC),
              alignment: Alignment.bottomCenter,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline_rounded, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'Who are you?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      const SizedBox(height: 180), // Offset for header
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select your role to get the right experience',
                                style: TextStyle(
                                    fontSize: 15, color: Color(0xFF6B7280), height: 1.5,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 32),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _roles.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 24),
                                itemBuilder: (_, i) {
                                  final role = _roles[i];
                                  final selected = _selectedRole == role.id;
                                  return _RoleCard(
                                    option: role,
                                    selected: selected,
                                    onTap: () => setState(() => _selectedRole = role.id),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              if (auth.stage == AuthStage.error &&
                                  auth.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE8E8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.error_outline_rounded,
                                        size: 16, color: Color(0xFFE02424)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(auth.errorMessage!,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFFE02424)))),
                                  ]),
                                ),
                                const SizedBox(height: 16),
                              ],
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: (_selectedRole == null || isLoading)
                                      ? null
                                      : _confirm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2233CC),
                                    disabledBackgroundColor: const Color(0xFFD1D5DB),
                                    disabledForegroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white)))
                                      : const Text('Continue',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                ),
                              ),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;

  const _RoleOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        highlightColor: option.color.withOpacity(0.05),
        splashColor: option.color.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: selected ? option.color.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? option.color : const Color(0xFFE5E9F0),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected ? option.color.withOpacity(0.12) : const Color(0x0F000000),
                blurRadius: selected ? 16 : 8,
                offset: Offset(0, selected ? 4 : 2),
              )
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left colored border ──
                if (selected)
                  Container(width: 4, color: option.color),
                
                // ── Card content ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selected ? option.color : option.bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(option.icon,
                              size: 26,
                              color: selected ? Colors.white : option.color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? option.color
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.subtitle,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selected ? option.color : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? option.color
                                  : const Color(0xFFD1D5DB),
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}