class Hospital {
  final int? hospitalId;
  final String? hospitalName;
  final String? address;
  final String? description;
  final String? logo;
  final String? qrCode;
  final String? signature;
  final String? verificationStatus;
  final String? verificationDoc;

  Hospital({
    this.hospitalId,
    this.hospitalName,
    this.address,
    this.description,
    this.logo,
    this.qrCode,
    this.signature,
    this.verificationStatus,
    this.verificationDoc,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) => Hospital(
        hospitalId: json['hospitalId'],
        hospitalName: json['hospitalName'],
        address: json['address'],
        description: json['description'],
        logo: json['logo'],
        qrCode: json['qrCode'],
        signature: json['signature'],
        verificationStatus: json['verificationStatus'],
        verificationDoc: json['verificationDoc'],
      );

  Map<String, dynamic> toJson() => {
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'address': address,
        'description': description,
        'logo': logo,
        'qrCode': qrCode,
        'signature': signature,
        'verificationStatus': verificationStatus,
        'verificationDoc': verificationDoc,
      };
}