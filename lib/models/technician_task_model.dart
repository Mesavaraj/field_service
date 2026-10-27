class TechnicianTaskModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String address;
  final String customerId;
  final String? preferredDate;
  final double? latitude;
  final double? longitude;
  final String? scheduledAt;

  const TechnicianTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.address,
    required this.customerId,
    this.preferredDate,
    this.latitude,
    this.longitude,
    this.scheduledAt,
  });

  factory TechnicianTaskModel.fromJson(Map<String, dynamic> json) {
    return TechnicianTaskModel(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? json['category'] ?? 'Service task'}',
      description: '${json['description'] ?? ''}',
      status: '${json['status'] ?? 'assigned'}',
      address: '${json['address'] ?? ''}',
      customerId: '${json['customer_id'] ?? ''}',
      preferredDate: json['preferred_date']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      scheduledAt: json['scheduled_at']?.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status,
    'address': address,
    'customer_id': customerId,
    'preferred_date': preferredDate,
    'latitude': latitude,
    'longitude': longitude,
  };

  String get normalizedStatus =>
      status.trim().toLowerCase().replaceAll(' ', '_');

  bool get isAssigned =>
      normalizedStatus == 'assigned' || normalizedStatus == 'pending';

  bool get isInProgress => normalizedStatus == 'in_progress';

  bool get isCompleted => normalizedStatus == 'completed';
}
