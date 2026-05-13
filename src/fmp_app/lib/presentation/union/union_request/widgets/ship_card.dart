import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/queue.dart';

class ShipmentRequestCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isApproving;          // ← add
  final bool isRejecting;

  const ShipmentRequestCard({
    super.key,
    required this.shipment,
    required this.onApprove,
    required this.onReject,
    this.isApproving = false,      
    this.isRejecting = false,      
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(shipment.createdAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header: shipment number + urgent badge ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shipment.shipmentNumber,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
                Row(
                  children: [
                    if (shipment.isUrgent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Submitted date ──
            Row(
              children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Submitted $formattedDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ── Route: from → to ──
            Row(
              children: [
                Expanded(
                  child: _RoutePoint(
                    icon: Icons.radio_button_checked,
                    iconColor: Colors.blue.shade600,
                    label: 'From',
                    company: shipment.senderCompany ?? '—',
                    city: shipment.originCity ?? '—',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 18, color: Colors.grey.shade400),
                ),
                Expanded(
                  child: _RoutePoint(
                    icon: Icons.location_on,
                    iconColor: Colors.green.shade600,
                    label: 'To',
                    company: shipment.receiverCompany ?? '—',
                    city: shipment.destinationCity ?? '—',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ── Cargo details ──
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.category_outlined,
                    label: 'Cargo Type',
                    value: shipment.cargoType,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.scale_outlined,
                    label: 'Weight',
                    value: '${shipment.cargoWeightKg.toStringAsFixed(1)} kg',
                  ),
                ),
                if (shipment.packageCount != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.inventory_2_outlined,
                      label: 'Packages',
                      value: '${shipment.packageCount}',
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ── Action buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: isRejecting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.close, size: 18),
                    label: Text(isRejecting ? 'Rejecting…' : 'Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: isApproving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18),
                    label: Text(isApproving ? 'Approving…' : 'Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Route point widget ──
class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String company;
  final String city;

  const _RoutePoint({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.company,
    required this.city,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(company,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text(city,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info tile widget ──
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}