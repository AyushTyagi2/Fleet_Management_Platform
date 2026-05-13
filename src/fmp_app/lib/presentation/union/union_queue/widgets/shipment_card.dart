import 'package:flutter/material.dart';
import '../../../../core/models/shipment.dart';

class ShipmentCard extends StatefulWidget {
  final Shipment shipment;
  final VoidCallback? onTap;
  final bool isFavourite;
  final ValueChanged<bool>? onFavouriteToggle;

  const ShipmentCard({
    super.key,
    required this.shipment,
    this.onTap,
    this.isFavourite = false,
    this.onFavouriteToggle,
  });

  @override
  State<ShipmentCard> createState() => _ShipmentCardState();
}

class _ShipmentCardState extends State<ShipmentCard> {
  late bool _isFavourite;

  @override
  void initState() {
    super.initState();
    _isFavourite = widget.isFavourite;
  }

  void _toggleFavourite() {
    setState(() => _isFavourite = !_isFavourite);
    widget.onFavouriteToggle?.call(_isFavourite);
  }

  Color _statusColor(String status) => switch (status) {
    'waiting'    => const Color(0xFF2196F3),
    'accepted'   => const Color(0xFFFF9800),
    'in_transit' => const Color(0xFF9C27B0),
    'delivered'  => const Color(0xFF4CAF50),
    'cancelled'  => const Color(0xFFF44336),
    _            => const Color(0xFF9E9E9E),
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _StatusBadge(
                status: widget.shipment.status,
                color: _statusColor(widget.shipment.status),
              ),
              Row(children: [
                if (widget.shipment.isUrgent)
                  const Row(children: [
                    Icon(Icons.flash_on, size: 14, color: Colors.red),
                    Text('URGENT', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                  ]),
                if (widget.shipment.agreedPrice != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '₹${widget.shipment.agreedPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                  ),
                // ⭐ Favourite star button
                GestureDetector(
                  onTap: _toggleFavourite,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      _isFavourite ? Icons.star : Icons.star_border,
                      key: ValueKey(_isFavourite),
                      size: 22,
                      color: _isFavourite ? const Color(0xFFFFC107) : Colors.grey,
                    ),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 12),
            _LocationRow(icon: Icons.circle, iconColor: const Color(0xFF4CAF50), label: 'Pickup', location: widget.shipment.pickupLocation),
            Padding(padding: const EdgeInsets.only(left: 9), child: Container(width: 2, height: 18, color: const Color(0xFFBDBDBD))),
            _LocationRow(icon: Icons.location_on, iconColor: const Color(0xFFF44336), label: 'Drop', location: widget.shipment.dropLocation),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.scale, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${widget.shipment.cargoWeightKg.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(_formatTime(widget.shipment.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ]),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// _StatusBadge and _LocationRow stay the same...