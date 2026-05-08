import 'package:flutter/material.dart';
import '../union_queue/queue.dart';
import '../union_request/request.dart';
import '../union_profile/profile.dart';
import '../union_home/home.dart';
import '../queue_events/queue_events_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/layout/app_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UNION DASHBOARD — AppShell integrated
// ─────────────────────────────────────────────────────────────────────────────

class UnionDashboardScreen extends StatefulWidget {
  final String driverId;

  const UnionDashboardScreen({super.key, required this.driverId});

  @override
  State<UnionDashboardScreen> createState() => _UnionDashboardScreenState();
}

class _UnionDashboardScreenState extends State<UnionDashboardScreen> {
  int _index = 0;

  late final _pages = [
    const UnionHomeScreen(),
    QueueScreen(driverId: widget.driverId),
    const QueueEventsScreen(),
    const UnionRequestScreen(),
    const UnionProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: _index,
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Icons.inbox_rounded, label: 'Queue'),
        NavItem(icon: Icons.event_note_rounded, label: 'Events'),
        NavItem(icon: Icons.folder_rounded, label: 'Requests'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
      onTap: (i) => setState(() => _index = i),
      body: _pages[_index],
    );
  }
}