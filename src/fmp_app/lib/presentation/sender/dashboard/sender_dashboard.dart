import 'package:flutter/material.dart';
import '../home/sender_home_screen.dart';
import '../create/sender_create_shipment_screen.dart';
import '../shipments/sender_shipments_screen.dart';
import '../billing/sender_billing_screen.dart';
import '../profile/sender_profile_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/layout/app_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SENDER DASHBOARD — AppShell integrated
// ─────────────────────────────────────────────────────────────────────────────

class SenderDashboardScreen extends StatefulWidget {
  const SenderDashboardScreen({super.key});

  @override
  State<SenderDashboardScreen> createState() => _SenderDashboardScreenState();
}

class _SenderDashboardScreenState extends State<SenderDashboardScreen> {
  int _index = 0;

  final _pages = const [
    SenderHomeScreen(),
    SenderCreateShipmentScreen(),
    SenderShipmentsScreen(),
    SenderBillingScreen(),
    SenderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: _index,
      items: const [
        NavItem(icon: Icons.dashboard_rounded, label: 'Home'),
        NavItem(icon: Icons.add_box_rounded, label: 'Create'),
        NavItem(icon: Icons.local_shipping_rounded, label: 'Shipments'),
        NavItem(icon: Icons.receipt_long_rounded, label: 'Billing'),
        NavItem(icon: Icons.business_rounded, label: 'Profile'),
      ],
      onTap: (i) => setState(() => _index = i),
      body: _pages[_index],
    );
  }
}
