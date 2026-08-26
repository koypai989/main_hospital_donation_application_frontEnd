class SystemAdmin {
  final int? adminId;
  final String? fullName;
  final Map<String, dynamic>? user;

  SystemAdmin({
    this.adminId,
    this.fullName,
    this.user,
  });

  factory SystemAdmin.fromJson(Map<String, dynamic> json) => SystemAdmin(
        adminId: json['adminId'],
        fullName: json['fullName'],
        user: json['user'],
      );

  Map<String, dynamic> toJson() => {
        'adminId': adminId,
        'fullName': fullName,
        'user': user,
      };
}