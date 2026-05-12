import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/shared/theme/app_theme.dart';

class CommonProfileScreen extends StatelessWidget {
  const CommonProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AppSession.email ?? '—';
    final role = AppSession.roleLabel;
    final driverId = AppSession.driverId;
    final (accent, icon) = _roleStyle(AppSession.role);
    final initials = _initials(email);
    
    // Fallback full name since it's not directly in AppSession
    final fullName = AppSession.role == 'fleet_owner' ? 'Fleet Manager' : 'Logistics User';

    final displayRole = _formatRole(AppSession.role ?? role);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Edge-to-edge Hero ──────────────────────────────────────
            _ProfileHero(
              fullName: fullName,
              email: email,
              role: displayRole,
              initials: initials,
              accent: accent,
              icon: icon,
            ),

            // ── Internal Content (centered & constrained) ─────────────
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Quick stats row ──
                      _buildUnifiedStatsCard(),
                      const SizedBox(height: 16),

                      // ── Account info ──
                      const _SectionHeader('Account Info'),
                      const SizedBox(height: 8),
                      _buildAccountInfoCard(email, AppSession.role ?? 'unknown', displayRole, driverId, accent, icon),
                      const SizedBox(height: 16),

                      // ── Quick actions ──
                      // Quick Actions section commented out per request.
                      // const _SectionHeader('Quick Actions'),
                      // const SizedBox(height: 8),
                      // _buildQuickActionsGrid(accent),
                      // const SizedBox(height: 16),

                      // ── App info ──
                      // App Info section commented out per request.
                      // _buildAppInfoCard(accent),
                      // const SizedBox(height: 16),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String email) {
    final name = email.split('@').first;
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.toUpperCase();
  }

  (Color, IconData) _roleStyle(String? role) => switch (role) {
    'driver' => (const Color(0xFF1A56DB), Icons.directions_car_rounded),
    'sender' || 'organization' => (const Color(0xFF0E9F6E), Icons.inventory_2_rounded),
    'fleet_owner' => (const Color(0xFFD97706), Icons.account_balance_rounded),
    'admin' || 'super_admin' => (const Color(0xFF7C3AED), Icons.admin_panel_settings_rounded),
    'union_admin' => (const Color(0xFF0891B2), Icons.groups_rounded),
    _ => (AppColors.primary, Icons.person_rounded),
  };

  String _formatRole(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final s = raw.replaceAll('_', ' ').toLowerCase();
    return s.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  Widget _buildUnifiedStatsCard() {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _UnifiedStatItem(label: 'Trips', value: '—', icon: Icons.route_rounded, color: AppColors.primary)),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: _UnifiedStatItem(label: 'Rating', value: '4.8', icon: Icons.star_rounded, color: AppColors.warning)),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: _UnifiedStatItem(label: 'Since', value: '2026', icon: Icons.calendar_today_rounded, color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(String email, String rawRole, String roleLabel, String? driverId, Color accent, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.email_rounded, label: 'Email', valueWidget: Text(email, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)), accent: accent),
          const Divider(height: 1, color: AppColors.border),
          _InfoRow(
            icon: icon,
            label: 'Role',
            valueWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(roleLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
            ),
            accent: accent,
          ),
          if (driverId != null) ...[
            const Divider(height: 1, color: AppColors.border),
            _InfoRow(icon: Icons.badge_rounded, label: 'Driver ID', valueWidget: Text(driverId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)), accent: accent),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(Color accent) {
    final chips = [
      _ActionChip(icon: Icons.description_rounded, label: 'Documents', onTap: () {}),
      _ActionChip(icon: Icons.directions_car_rounded, label: 'Vehicle', onTap: () {}),
      _ActionChip(icon: Icons.headset_mic_rounded, label: 'Support', onTap: () {}),
      _ActionChip(icon: Icons.settings_rounded, label: 'Settings', onTap: () {}),
    ];

    // Fixed-height row to avoid AspectRatio-driven overflow on narrow screens
    return SizedBox(
      height: 72,
      child: Row(
        children: chips.map((c) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: c == chips.last ? 0 : 10),
            child: GestureDetector(
              onTap: c.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icon, size: 20, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text(c.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildAppInfoCard(Color accent) {
    // About & Terms sections commented out per request.
    // Original UI preserved below for easy restoration:
    // return Container(
    //   decoration: BoxDecoration(
    //     color: Colors.white,
    //     borderRadius: BorderRadius.circular(AppRadius.md),
    //     border: Border.all(color: AppColors.border),
    //     boxShadow: AppShadows.card,
    //   ),
    //   child: Column(
    //     children: [
    //       _SimpleActionRow(icon: Icons.info_outline_rounded, label: 'About FleetOS', onTap: () {}),
    //       const Divider(height: 1, color: AppColors.border),
    //       _SimpleActionRow(icon: Icons.policy_outlined, label: 'Terms & Privacy', onTap: () {}),
    //     ],
    //   ),
    // );
    return const SizedBox.shrink();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Container(width: 32, height: 2, color: AppColors.border),
        ],
      ),
    );
  }
}

class _UnifiedStatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _UnifiedStatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget valueWidget;
  final Color accent;
  const _InfoRow({required this.icon, required this.label, required this.valueWidget, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary))),
          valueWidget,
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEEF3FF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary), textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _SimpleActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SimpleActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String fullName, email, role, initials;
  final Color accent;
  final IconData icon;
  const _ProfileHero({required this.fullName, required this.email, required this.role,
      required this.initials, required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withOpacity(0.8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        // No border radius here, it's meant to be edge-to-edge
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          ),
          child: Center(child: Text(initials,
              style: const TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(email, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13,
              fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 12, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 5),
              Text(role, style: TextStyle(color: Colors.white.withOpacity(0.95),
                  fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ])),
      ]),
    );
  }
}

