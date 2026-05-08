import 'package:flutter/material.dart';
import 'package:fmp_app/presentation/fleetmgr/home/fleet_home_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/drivers/fleet_drivers_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/vehicles/fleet_vehicles_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/trips/fleet_trips_screen.dart';
import 'package:fmp_app/presentation/fleetmgr/profile/fleet_profile_screen.dart';
import 'package:fmp_app/core/models/fleet_dashboard.dart';
import 'package:fmp_app/presentation/fleetmgr/fleet_api.dart';
import 'package:fmp_app/app_session.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/layout/app_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FLEET DASHBOARD — AppShell integrated
// ─────────────────────────────────────────────────────────────────────────────

class FleetDashboardScreen extends StatefulWidget {
  const FleetDashboardScreen({super.key});

  @override
  State<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends State<FleetDashboardScreen> {
  int _index = 0;
  FleetDashboard? _dashboard;
  bool _loading = false;

  static const List<Widget> _subPages = [
    SizedBox.shrink(), // Rendered inline below
    FleetDriversScreen(),
    FleetVehiclesScreen(),
    FleetTripsScreen(),
    FleetProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final phone = AppSession.email;  
    if (phone == null) return;
    setState(() => _loading = true);
    try {
      final api = FleetApi();
      final dto = await api.getFleetDashboardByPhone(phone);
      setState(() => _dashboard = dto);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: _index,
      items: const [
        NavItem(icon: Icons.dashboard_rounded, label: 'Home'),
        NavItem(icon: Icons.people_rounded, label: 'Drivers'),
        NavItem(icon: Icons.local_shipping_rounded, label: 'Vehicles'),
        NavItem(icon: Icons.receipt_long_rounded, label: 'Trips'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
      onTap: (idx) => setState(() => _index = idx),
      body: _index == 0 ? _buildDashboardBody() : _subPages[_index],
    );
  }

  Widget _buildDashboardBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dashboard == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No fleet data available', style: AppTextStyles.headingSm),
            const SizedBox(height: 6),
            const Text('Pull down to refresh', style: AppTextStyles.bodyMd),
          ],
        ),
      );
    }

    final d = _dashboard!;
    final initials = d.fleetOwnerName.trim().isEmpty ? 'FM' : d.fleetOwnerName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
    
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // ── Inline Hero Strip ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF2233CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.fleetOwnerName.isEmpty ? 'Fleet Manager' : d.fleetOwnerName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Fleet Owner', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Main Content ───────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDashboard,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        if (d.vehicleIssues > 0 || d.tripsWithIssues > 0) ...[
                          _buildAlertBanner(d),
                          const SizedBox(height: AppSpacing.md),
                        ],

                  const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),

                  // Compact 4-chip row
                  Row(
                    children: [
                      Expanded(
                        child: _CompactMetricCard(
                          title: 'Active Drivers',
                          value: '${d.activeDrivers}',
                          icon: Icons.people_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CompactMetricCard(
                          title: 'Active Trips',
                          value: '${d.activeTrips}',
                          icon: Icons.route_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CompactMetricCard(
                          title: 'Vehicle Issues',
                          value: '${d.vehicleIssues}',
                          icon: Icons.build_circle_rounded,
                          color: d.vehicleIssues > 0 ? AppColors.warning : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CompactMetricCard(
                          title: 'Trip Issues',
                          value: '${d.tripsWithIssues}',
                          icon: Icons.warning_amber_rounded,
                          color: d.tripsWithIssues > 0 ? AppColors.error : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  _buildMockActivityFeed(),
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

  Widget _buildAlertBanner(FleetDashboard d) {
    final issues = <String>[];
    if (d.vehicleIssues > 0) issues.add('${d.vehicleIssues} vehicle issue${d.vehicleIssues > 1 ? 's' : ''}');
    if (d.tripsWithIssues > 0) issues.add('${d.tripsWithIssues} trip issue${d.tripsWithIssues > 1 ? 's' : ''}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Attention needed: ${issues.join(', ')}.',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockActivityFeed() {
    final activities = [
      {'title': 'Trip TRP-928 Completed', 'subtitle': 'Driver John Doe reached destination.', 'time': '10 mins ago', 'icon': Icons.check_circle_rounded, 'color': AppColors.success},
      {'title': 'New Vehicle Assigned', 'subtitle': 'Truck MH-12-AB-1234 assigned to Jane Smith.', 'time': '1 hr ago', 'icon': Icons.local_shipping_rounded, 'color': AppColors.primary},
      {'title': 'Trip Issue Reported', 'subtitle': 'Trip TRP-925 delayed due to traffic.', 'time': '3 hrs ago', 'icon': Icons.warning_amber_rounded, 'color': AppColors.warning},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final isLast = entry.key == activities.length - 1;
          final a = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: (a['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(a['icon'] as IconData, size: 20, color: a['color'] as Color),
                ),
                title: Text(a['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                subtitle: Text(a['subtitle'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: Text(a['time'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _CompactMetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _CompactMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
