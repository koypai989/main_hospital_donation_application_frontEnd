class Donator {
  final String? citizenID;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? address;
  final Map<String, dynamic>? user;

  Donator({
    this.citizenID,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.address,
    this.user,
  });

  factory Donator.fromJson(Map<String, dynamic> json) => Donator(
        citizenID: json['citizenID'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        dateOfBirth: json['dateOfBirth'],
        address: json['address'],
        user: json['user'],
      );

  Map<String, dynamic> toJson() => {
        'citizenID': citizenID,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'user': user,
      };
}