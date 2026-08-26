class User {
  final int? id;
  final String? email;
  final String? role;

  User({
    this.id,
    this.email,
    this.role,
  });

  // backend คืน DTO { userId, email, role }
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['userId'],
        email: json['email'],
        role: json['role'],
      );

  Map<String, dynamic> toJson() => {
        'userId': id,
        'email': email,
        'role': role,
      };
}
