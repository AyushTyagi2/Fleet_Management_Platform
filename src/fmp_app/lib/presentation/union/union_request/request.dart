import 'package:flutter/material.dart';
import '../../../core/models/queue.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_shipment.dart';
import './widgets/ship_card.dart';

enum SortOption { newestFirst, oldestFirst, heaviestFirst, lightestFirst }

class UnionRequestScreen extends StatefulWidget {
  const UnionRequestScreen({super.key});

  @override
  State<UnionRequestScreen> createState() => _UnionRequestScreenState();
}

class _UnionRequestScreenState extends State<UnionRequestScreen> {
  final ShipmentApi api = ShipmentApi(ApiClient());

  List<Shipment> _allShipments = [];
  List<Shipment> _filtered = [];

  bool loading = true;
  String _searchQuery = '';
  String? _cargoTypeFilter;   // null = all
  bool? _urgentFilter;        // null = all, true = urgent only, false = non-urgent
  SortOption _sort = SortOption.newestFirst;

  final Set<String> _approvingIds = {};
  final Set<String> _rejectingIds = {};

  final TextEditingController _searchController = TextEditingController();

  // Derived from actual data so filter chips stay accurate
  List<String> get _cargoTypes =>
      _allShipments.map((s) => s.cargoType).toSet().toList()..sort();

  @override
  void initState() {
    super.initState();
    loadShipments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadShipments() async {
    setState(() => loading = true);
    final data = await api.getPendingShipments();
    setState(() {
      _allShipments = data;
      loading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<Shipment> result = List.from(_allShipments);

    // Search: match shipment number, origin, destination, sender, receiver
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) {
        return s.shipmentNumber.toLowerCase().contains(q) ||
            (s.originCity?.toLowerCase().contains(q) ?? false) ||
            (s.destinationCity?.toLowerCase().contains(q) ?? false) ||
            (s.senderCompany?.toLowerCase().contains(q) ?? false) ||
            (s.receiverCompany?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Cargo type filter
    if (_cargoTypeFilter != null) {
      result = result.where((s) => s.cargoType == _cargoTypeFilter).toList();
    }

    // Urgency filter
    if (_urgentFilter != null) {
      result = result.where((s) => s.isUrgent == _urgentFilter).toList();
    }

    // Sort
    switch (_sort) {
      case SortOption.newestFirst:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.oldestFirst:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.heaviestFirst:
        result.sort((a, b) => b.cargoWeightKg.compareTo(a.cargoWeightKg));
        break;
      case SortOption.lightestFirst:
        result.sort((a, b) => a.cargoWeightKg.compareTo(b.cargoWeightKg));
        break;
    }

    setState(() => _filtered = result);
  }

  Future<void> _approve(String id) async {
    if (_approvingIds.contains(id)) return;
    setState(() => _approvingIds.add(id));
    try {
      await api.approveShipment(id);
      await loadShipments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _approvingIds.remove(id));
    }
  }

  Future<void> _reject(String id) async {
    if (_rejectingIds.contains(id)) return;
    setState(() => _rejectingIds.add(id));
    try {
      await api.rejectShipment(id);
      await loadShipments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _rejectingIds.remove(id));
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _cargoTypeFilter = null;
      _urgentFilter = null;
      _sort = SortOption.newestFirst;
    });
    _applyFilters();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _cargoTypeFilter != null ||
      _urgentFilter != null ||
      _sort != SortOption.newestFirst;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Requests'),
        actions: [
          if (_hasActiveFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Clear'),
            ),
          _SortButton(
            current: _sort,
            onChanged: (v) {
              setState(() => _sort = v);
              _applyFilters();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          _buildResultCount(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          setState(() => _searchQuery = v.trim());
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Search by SHP number, city, company…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          // Urgency chips
          _FilterChip(
            label: '🔥 Urgent',
            selected: _urgentFilter == true,
            onTap: () {
              setState(() => _urgentFilter = _urgentFilter == true ? null : true);
              _applyFilters();
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Non-urgent',
            selected: _urgentFilter == false,
            onTap: () {
              setState(() => _urgentFilter = _urgentFilter == false ? null : false);
              _applyFilters();
            },
          ),
          // Cargo type chips
          for (final type in _cargoTypes) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: _capitalize(type),
              selected: _cargoTypeFilter == type,
              onTap: () {
                setState(() => _cargoTypeFilter = _cargoTypeFilter == type ? null : type);
                _applyFilters();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCount() {
    if (loading) return const SizedBox.shrink();
    final total = _allShipments.length;
    final shown = _filtered.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _hasActiveFilters
              ? 'Showing $shown of $total shipments'
              : '$total pending shipment${total == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              _hasActiveFilters ? 'No shipments match your filters.' : 'No pending shipments.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: _clearFilters, child: const Text('Clear filters')),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadShipments,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final shipment = _filtered[index];
          final isApproving = _approvingIds.contains(shipment.id);
          final isRejecting = _rejectingIds.contains(shipment.id);
          return ShipmentRequestCard(
            shipment: shipment,
            onApprove: (isApproving || isRejecting) ? null : () => _approve(shipment.id),
            onReject: (isApproving || isRejecting) ? null : () => _reject(shipment.id),
            isApproving: isApproving,
            isRejecting: isRejecting,
          );
        },
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Reusable filter chip ────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ─── Sort dropdown button ────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  final SortOption current;
  final ValueChanged<SortOption> onChanged;

  const _SortButton({required this.current, required this.onChanged});

  static const _labels = {
    SortOption.newestFirst: 'Newest first',
    SortOption.oldestFirst: 'Oldest first',
    SortOption.heaviestFirst: 'Heaviest first',
    SortOption.lightestFirst: 'Lightest first',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort',
      initialValue: current,
      onSelected: onChanged,
      itemBuilder: (_) => SortOption.values
          .map((o) => PopupMenuItem(
                value: o,
                child: Row(
                  children: [
                    Icon(
                      o == current ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(_labels[o]!),
                  ],
                ),
              ))
          .toList(),
    );
  }
}