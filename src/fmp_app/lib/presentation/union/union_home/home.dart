import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../app_session.dart';

class UnionHomeScreen extends StatefulWidget {
  const UnionHomeScreen({super.key});

  @override
  State<UnionHomeScreen> createState() => _UnionHomeScreenState();
}

class _UnionHomeScreenState extends State<UnionHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Mock data - in real app, fetch from API
  final Map<String, int> _stats = {
    'pendingRequests': 12,
    'activeShipments': 8,
    'completedToday': 24,
    'driversOnline': 15,
  };

  final List<Map<String, dynamic>> _recentActivity = [
    {
      'type': 'request',
      'title': 'New Shipment Request',
      'subtitle': 'From Downtown Warehouse',
      'time': '2 min ago',
      'status': 'pending',
      'amount': 450.00,
    },
    {
      'type': 'assignment',
      'title': 'Shipment Assigned',
      'subtitle': 'Driver #123 - Route A1',
      'time': '15 min ago',
      'status': 'active',
      'amount': 320.50,
    },
    {
      'type': 'completion',
      'title': 'Shipment Completed',
      'subtitle': 'Delivered to North District',
      'time': '1 hour ago',
      'status': 'completed',
      'amount': 180.25,
    },
  ];

  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Edge-to-edge header
                _buildHeader(),
                // Body content constrained by padding
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      _buildRecentActivity(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Union Manager',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your logistics network',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Live status inline
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isLive ? 'Live' : 'Offline', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isLive,
                    onChanged: (value) {
                      setState(() => _isLive = value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value ? 'You are now live and receiving requests!' : 'You are now offline',
                          ),
                          backgroundColor: value ? AppColors.success : AppColors.warning,
                        ),
                      );
                    },
                    activeColor: AppColors.success,
                    activeTrackColor: AppColors.success.withOpacity(0.3),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    // Unified single card with four compact stats
    final statsList = [
      {'icon': Icons.pending_rounded, 'value': _stats['pendingRequests'], 'label': 'Pending', 'color': AppColors.warning, 'trend': '+3'},
      {'icon': Icons.local_shipping_rounded, 'value': _stats['activeShipments'], 'label': 'Active', 'color': AppColors.primary, 'trend': '+2'},
      {'icon': Icons.check_circle_rounded, 'value': _stats['completedToday'], 'label': 'Completed', 'color': AppColors.success, 'trend': '+8'},
      {'icon': Icons.person_rounded, 'value': _stats['driversOnline'], 'label': 'Online', 'color': AppColors.info, 'trend': '+5'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today\'s Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
          child: Row(
            children: List.generate(statsList.length, (i) {
              final s = statsList[i];
              return Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s['icon'] as IconData, size: 18, color: s['color'] as Color),
                        const SizedBox(height: 6),
                        Text('${s['value']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(s['label'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    if (i < statsList.length - 1) const VerticalDivider(width: 20, color: AppColors.border),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final items = _recentActivity.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            TextButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View All Activity'))), child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
          child: Column(
            children: List.generate(items.length, (i) {
              final activity = items[i];
              return Column(
                children: [
                  _CompactActivityRow(activity: activity),
                  if (i < items.length - 1) const Divider(height: 1, color: AppColors.border),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics Dashboard'),
        content: const Text(
          'Advanced analytics and reporting features will be available soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Alerts'),
        content: const Text(
          'No active alerts at this time. All systems operating normally.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _CompactActivityRow extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _CompactActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _getActivityColor(activity['type']).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_getActivityIcon(activity['type']), color: _getActivityColor(activity['type']), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(activity['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(activity['subtitle'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Row(children: [
                Text(activity['time'], style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                const SizedBox(width: 12),
                Text('\$${activity['amount'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ])
            ]),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _getStatusColor(activity['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(activity['status'].toString().toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getStatusColor(activity['status'])))),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'request':
        return AppColors.warning;
      case 'assignment':
        return AppColors.primary;
      case 'completion':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'request':
        return Icons.assignment_rounded;
      case 'assignment':
        return Icons.local_shipping_rounded;
      case 'completion':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'active':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final String trend;
  final Color trendColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend.startsWith('+') ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: trendColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
