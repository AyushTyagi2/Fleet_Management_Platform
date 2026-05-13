import 'package:flutter/material.dart';
import '../../../core/models/shipment.dart';

class ShipmentDetailScreen extends StatelessWidget {
  final Shipment shipment;

  const ShipmentDetailScreen({
    super.key,
    required this.shipment,
  });

  @override
  Widget build(BuildContext context) {
    final s = shipment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipment Details'),
        backgroundColor: const Color(0xFF1B3A6B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s.agreedPrice != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B3A6B), Color(0xFF2E75B6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Payout',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      '₹${s.agreedPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('${s.cargoWeightKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            _SectionCard(
              title: 'Route',
              child: Column(
                children: [
                  _DetailRow(
                    icon:  Icons.circle,
                    color: const Color(0xFF4CAF50),
                    label: 'Pickup',
                    value: s.pickupLocation,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Column(
                      children: [
                        SizedBox(height: 4),
                        _DotDivider(),
                        SizedBox(height: 4),
                      ],
                    ),
                  ),
                  _DetailRow(
                    icon:  Icons.location_on,
                    color: const Color(0xFFF44336),
                    label: 'Drop-off',
                    value: s.dropLocation,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _SectionCard(
              title: 'Details',
              child: Column(
                children: [
                  _InfoRow(label: 'Shipment #', value: s.shipmentNumber),
                  _InfoRow(label: 'Status',     value: s.status),
                  _InfoRow(label: 'Weight',     value: '${s.cargoWeightKg.toStringAsFixed(1)} kg'),
                  if (s.agreedPrice != null)
                    _InfoRow(label: 'Price',
                        value: '₹${s.agreedPrice!.toStringAsFixed(0)}'),
                  _InfoRow(
                    label: 'Posted',
                    value: s.createdAt.toLocal().toString().substring(0, 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: child,
          ),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;

  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}

class _DotDivider extends StatelessWidget {
  const _DotDivider();

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
            3,
            (_) => Container(
                  width: 2,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  color: Colors.grey.shade300,
                )),
      );
}