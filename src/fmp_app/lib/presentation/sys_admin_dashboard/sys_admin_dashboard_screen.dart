import 'package:flutter/material.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/overview_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/users_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/logs_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/queue_view.dart';
import 'package:fmp_app/presentation/sys_admin_dashboard/views/rules_view.dart';
import 'package:fmp_app/shared/profile/common_profile_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/layout/app_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SYS ADMIN DASHBOARD — AppShell integrated
// ─────────────────────────────────────────────────────────────────────────────

class SysAdminDashboardScreen extends StatefulWidget {
  const SysAdminDashboardScreen({super.key});

  @override
  State<SysAdminDashboardScreen> createState() => _SysAdminDashboardScreenState();
}

class _SysAdminDashboardScreenState extends State<SysAdminDashboardScreen> {
  int _selectedIndex = 0;

  static const _views = [
    OverviewView(),
    UsersView(),
    LogsView(),
    QueueView(),
    RulesView(),
    CommonProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: _selectedIndex,
      items: const [
        NavItem(icon: Icons.dashboard_rounded, label: 'Overview'),
        NavItem(icon: Icons.people_rounded, label: 'Users'),
        NavItem(icon: Icons.history_rounded, label: 'System Logs'),
        NavItem(icon: Icons.inbox_rounded, label: 'Queue'),
        NavItem(icon: Icons.tune_rounded, label: 'Rules Engine'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
      onTap: (index) => setState(() => _selectedIndex = index),
      body: _views[_selectedIndex],
    );
  }
}