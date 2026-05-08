import 'package:flutter/material.dart';
import 'package:fmp_app/app_session.dart';
import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/core/network/api_trips.dart';

// lib/presentation/driver/billing/driver_billing_screen.dart

class DriverBillingScreen extends StatefulWidget {
  const DriverBillingScreen({super.key});

  @override
  State<DriverBillingScreen> createState() => _DriverBillingScreenState();
}

class _DriverBillingScreenState extends State<DriverBillingScreen> {
  final _apiClient = ApiClient();
  late final TripApiService _tripApi;

  List<TripSummary> _trips = [];
  bool _loading = true;
  String? _error;
  int _selectedFilter = 1; // 0=Today, 1=Week, 2=Month

  @override
  void initState() {
    super.initState();
    _tripApi = TripApiService(_apiClient);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrips());
  }

  Future<void> _loadTrips() async {
    final driverId = AppSession.driverId;
    if (driverId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Session expired';
        });
      }
      return;
    }

    try {
      final trips = await _tripApi.getDriverTrips(driverId);
      if (mounted) {
        setState(() {
          _trips = trips;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  double get _totalEarnings => _trips
      .where((t) => t.agreedPrice != null)
      .fold<double>(0, (sum, t) => sum + t.agreedPrice!);

  List<TripSummary> get _paidTrips => _trips
      .where((t) => t.currentStatus == 'completed' || t.currentStatus == 'delivered')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F6FA),
      child: Stack(
        children: [
          Positioned.fill(
            child: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF2233CC))))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadTrips)
              : RefreshIndicator(
                  color: const Color(0xFF2233CC),
                  onRefresh: _loadTrips,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 220,
                        pinned: true,
                        backgroundColor: const Color(0xFF2233CC),
                        iconTheme: const IconThemeData(color: Colors.white),
                        title: const Text('Billing Dashboard',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        centerTitle: true,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF2233CC), Color(0xFF162082)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: _EarningsSummaryContent(
                                  totalEarnings: _totalEarnings,
                                  completedTrips: _paidTrips.length,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Trip Payments',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                                      _buildFilterChips(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      _paidTrips.isEmpty
                          ? const SliverFillRemaining(child: _EmptyBilling())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 600),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                      child: _BillingCard(trip: _paidTrips[i]),
                                    ),
                                  ),
                                ),
                                childCount: _paidTrips.length,
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for FAB
                    ],
                  ),
                ),
          ),
          // if (!_loading && _error == null)
          //   Positioned(
          //     bottom: 24,
          //     left: 0,
          //     right: 0,
          //     child: Center(
          //       child: FloatingActionButton.extended(
          //         onPressed: () {},
          //         backgroundColor: const Color(0xFF2233CC),
          //         icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
          //         label: const Text('Withdraw Earnings',
          //             style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Today', 'Week', 'Month'];
    return Row(
      children: List.generate(filters.length, (i) {
        final isSelected = _selectedFilter == i;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2233CC) : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2233CC) : const Color(0xFFE5E9F0),
                ),
              ),
              child: Text(
                filters[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EarningsSummaryContent extends StatelessWidget {
  final double totalEarnings;
  final int completedTrips;
  const _EarningsSummaryContent({required this.totalEarnings, required this.completedTrips});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Earnings', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('₹${totalEarnings.toStringAsFixed(0)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(label: 'This Week', value: '₹4,500'),
                const SizedBox(width: 8),
                _StatChip(label: 'Pending', value: '₹1,200', isWarning: true),
                const SizedBox(width: 8),
                _StatChip(label: 'Trips', value: completedTrips.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;

  const _StatChip({required this.label, required this.value, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isWarning ? const Color(0xFFFFE4A0) : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  final TripSummary trip;
  const _BillingCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: const Color(0xFFDEF7EC), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long_rounded, size: 22, color: Color(0xFF0E9F6E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trip.tripNumber, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(trip.shipmentNumber, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (trip.agreedPrice != null)
              Text('₹${trip.agreedPrice!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFDEF7EC), borderRadius: BorderRadius.circular(100)),
              child: const Text('Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF057A55))),
            ),
          ]),
        ],
      ),
    );
  }
}

class _EmptyBilling extends StatelessWidget {
  const _EmptyBilling();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5, style: BorderStyle.solid), // Dashed isn't natively supported easily without a package, using solid gray for now.
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: const Color(0xFFEEF1F8), borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.receipt_long_rounded, size: 40, color: Color(0xFF2233CC)),
              ),
              const SizedBox(height: 24),
              const Text('No payments yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              const SizedBox(height: 8),
              const Text('Completed trips will appear here with payment details.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFFDE8E8), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.error_outline_rounded, size: 32, color: Color(0xFFE02424))),
          const SizedBox(height: 16),
          const Text('Failed to load billing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(height: 20),
          TextButton(onPressed: onRetry, child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2233CC)))),
        ]),
      ),
    );
  }
}