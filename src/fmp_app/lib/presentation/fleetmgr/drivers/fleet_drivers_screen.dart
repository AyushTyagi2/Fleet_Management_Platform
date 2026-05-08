import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../fleetmgr/fleet_api.dart';
import '../../fleetmgr/fleet_state.dart';
import '../../../core/models/driver.dart';
import '../../../app_session.dart';
import '../../../shared/theme/app_theme.dart';

// ─── Design tokens (mirrors driver-side palette) ────────────────────────────
const _kNavy       = Color(0xFF1B3A6B);
const _kNavyLight  = Color(0xFF254E96);
const _kSurface    = Color(0xFFF4F6FA);
const _kCardRadius = 12.0;
// ────────────────────────────────────────────────────────────────────────────

class FleetDriversScreen extends StatefulWidget {
  const FleetDriversScreen({super.key});

  @override
  State<FleetDriversScreen> createState() => _FleetDriversScreenState();
}

class _FleetDriversScreenState extends State<FleetDriversScreen> {
  bool _loading = false;
  String _searchQuery = '';
  String _activeFilter = 'All';

  final List<String> _filters = ['All', 'Active', 'Inactive', 'On Trip'];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final phone = AppSession.email;
    if (phone == null) return;
    setState(() => _loading = true);
    try {
      final api = FleetApi();
      final drivers = await api.getDriversByFleetOwnerPhone(phone);
      final state = context.read<FleetState>();
      state.drivers = drivers;
      state.notifyListeners();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load drivers: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Driver> _getFilteredDrivers(List<dynamic> allDrivers) {
    var filtered = allDrivers.cast<Driver>();

    // Apply text search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((d) =>
        (d.fullName.toLowerCase().contains(q)) ||
        (d.phone.contains(q)) ||
        (d.licenseNumber?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    // Apply chip filter
    if (_activeFilter != 'All') {
      final f = _activeFilter.toLowerCase().replaceAll(' ', '_');
      filtered = filtered.where((d) => (d.status ?? '').toLowerCase() == f).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FleetState>();
    final filteredDrivers = _getFilteredDrivers(state.drivers);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Container(
      color: _kSurface,
      child: Column(
        children: [
          // Header with Search and Filters
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search by name, phone or license...',
                      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isActive = f == _activeFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _activeFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                color: isActive ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Drivers List/Grid
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredDrivers.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadDrivers,
                        color: AppColors.primary,
                        child: isDesktop
                            ? GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3.5,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: filteredDrivers.length,
                                itemBuilder: (context, index) => _DriverCard(driver: filteredDrivers[index]),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredDrivers.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) => _DriverCard(driver: filteredDrivers[index]),
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.people_outline, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('No drivers found', style: AppTextStyles.headingSm),
            const SizedBox(height: 4),
            const Text('Try adjusting your search or filters.', style: AppTextStyles.bodyMd),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final Driver driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final name = driver.fullName.trim();
    String initials = '';
    if (name.isNotEmpty) {
      initials = name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
    } else if (driver.phone.isNotEmpty) {
      initials = driver.phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (initials.length > 2) initials = initials.substring(initials.length - 2);
    }

    final status = (driver.status ?? 'unknown').toLowerCase();
    Color statusBg = AppColors.background;
    Color statusFg = AppColors.textSecondary;
    
    if (status == 'active') {
      statusBg = const Color(0xFFDEF7EC); // light green
      statusFg = const Color(0xFF03543F); // dark green
    } else if (status == 'on_trip') {
      statusBg = AppColors.primaryLight;
      statusFg = AppColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(_kCardRadius),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FleetDriverDetailsScreen(driverId: driver.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  initials.isNotEmpty ? initials : 'DR',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),

              // Middle column: Name, License, Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      driver.fullName.isNotEmpty ? driver.fullName : driver.phone,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Lic: ${driver.licenseNumber ?? 'N/A'}',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            driver.status ?? 'unknown',
                            style: TextStyle(color: statusFg, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right column: Rating & Trips
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 2),
                      Text(
                        (driver.averageRating ?? 0).toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${driver.totalTripsCompleted ?? 0} trips',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Driver Details Screen ────────────────────────────────────────────────────

class FleetDriverDetailsScreen extends StatefulWidget {
  final String driverId;
  const FleetDriverDetailsScreen({required this.driverId, super.key});

  @override
  State<FleetDriverDetailsScreen> createState() => _FleetDriverDetailsScreenState();
}

class _FleetDriverDetailsScreenState extends State<FleetDriverDetailsScreen> {
  Driver? _driver;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final api = FleetApi();
      final d = await api.getDriverById(widget.driverId);
      setState(() => _driver = d);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load driver: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A56DB), // Updated to AppShell blue theme
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Driver Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _driver == null
              ? const Center(child: Text('No details found.'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Extended Hero Header
                      _buildHeroHeader(),
                      
                      // Body content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Combined Info Card
                            _buildInfoCard(),
                            const SizedBox(height: 12),

                            // Stats Row
                            _buildStatsRow(),
                            const SizedBox(height: 12),

                            // Assigned Vehicle
                            if (_driver!.currentVehicle != null) ...[
                              _buildAssignedVehicleCard(),
                              const SizedBox(height: 12),
                            ],

                            // Recent Trips
                            const Text('Recent Trips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 12),
                            _buildRecentTrips(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroHeader() {
    final name = (_driver!.fullName).trim();
    final initials = name.isNotEmpty
        ? name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'DR';
    final fleetName = AppSession.email ?? 'Fleet Manager'; // fallback
    
    final status = (_driver!.status ?? 'unknown').toLowerCase();
    Color statusBg = AppColors.background;
    Color statusFg = AppColors.textSecondary;
    if (status == 'active') {
      statusBg = const Color(0xFFDEF7EC); // light green
      statusFg = const Color(0xFF03543F); // dark green
    } else if (status == 'on_trip') {
      statusBg = Colors.white;
      statusFg = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF2233CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: const TextStyle(color: Color(0xFF1A56DB), fontWeight: FontWeight.w800, fontSize: 24),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _driver!.fullName,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _driver!.status ?? 'unknown',
                  style: TextStyle(color: statusFg, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Fleet: $fleetName',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Contact Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact Number', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(_driver!.phone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // License Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.badge_outlined, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Driver License', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('${_driver!.licenseNumber ?? 'N/A'}  ·  ${_driver!.licenseType ?? 'N/A'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.star_rounded, Colors.amber[700]!, 'Rating', (_driver!.averageRating ?? 0).toStringAsFixed(1)),
          Container(width: 1, height: 32, color: AppColors.border),
          _statItem(Icons.alt_route, AppColors.primary, 'Trips', '${_driver!.totalTripsCompleted ?? 0}'),
          Container(width: 1, height: 32, color: AppColors.border),
          _statItem(Icons.access_time_rounded, AppColors.success, 'Last Active', '2h ago'), // Mock 3rd stat
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, Color color, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAssignedVehicleCard() {
    final v = _driver!.currentVehicle!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2))],
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_shipping_rounded, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assigned Vehicle', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(v.registrationNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${v.vehicleType} • ${v.capacityTons ?? '0'} tons', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrips() {
    // Mock recent trips to fill the UI
    final mockTrips = [
      {'date': 'Oct 12', 'route': 'Mumbai → Pune', 'status': 'Completed'},
      {'date': 'Oct 05', 'route': 'Mumbai → Surat', 'status': 'Completed'},
    ];

    if (mockTrips.isEmpty) {
      return const Center(child: Text('No recent trips.', style: TextStyle(color: AppColors.textHint)));
    }

    return Column(
      children: mockTrips.map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Text(t['date']!.split(' ')[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    Text(t['date']!.split(' ')[1], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['route']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(t['status']!, style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        );
      }).toList(),
    );
  }
}