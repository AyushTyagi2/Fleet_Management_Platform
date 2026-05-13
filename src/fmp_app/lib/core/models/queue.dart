class Shipment {
  final String id;
  final String shipmentNumber;
  final String cargoType;
  final double cargoWeightKg;
  final String status;
  final bool isUrgent;
  final int? packageCount;
  final DateTime createdAt;
  final String? originCity;
  final String? destinationCity;
  final String? senderCompany;
  final String? receiverCompany;

  Shipment({
    required this.id,
    required this.shipmentNumber,
    required this.cargoType,
    required this.cargoWeightKg,
    required this.status,
    required this.isUrgent,
    this.packageCount,
    required this.createdAt,
    this.originCity,
    this.destinationCity,
    this.senderCompany,
    this.receiverCompany,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'],
      shipmentNumber: json['shipmentNumber'],
      cargoType: json['cargoType'],
      cargoWeightKg: (json['cargoWeightKg'] as num).toDouble(),
      status: json['status'] ?? 'unknown',
      isUrgent: json['isUrgent'] ?? false,
      packageCount: json['packageCount'],
      createdAt: DateTime.parse(json['createdAt']),
      originCity: json['originCity'],
      destinationCity: json['destinationCity'],
      senderCompany: json['senderCompany'],
      receiverCompany: json['receiverCompany'],
    );
  }
}