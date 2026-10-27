class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
    this.address = '',
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String role;
  final String? email;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProfileModel.fromMap(Map<String, dynamic> map, {String? email}) {
    return ProfileModel(
      id: map['id'].toString(),
      fullName: map['full_name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'customer',
      email: email ?? map['email']?.toString(),
      address: map['address']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.parse(map['created_at'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(map['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      'email': email,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
