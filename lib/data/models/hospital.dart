class Hospital {
  final int? hospitalId;
  final String? hospitalName;
  final String? address;
  final String? description;
  final String? logo;
  final String? qrCode;
  final String? signature;
  final String? signatureName;
  final String? verificationStatus;
  final String? verificationDoc;

  // ข้อมูลผู้ยื่นคำขอ — มีค่าเฉพาะตอนดึงคำขอที่รออนุมัติ (/v1/hospitals/pendings)
  // endpoint อื่นจะเป็น null
  final String? adminFirstName;
  final String? adminLastName;
  final String? adminPhone;
  final String? adminEmail;

  Hospital({
    this.hospitalId,
    this.hospitalName,
    this.address,
    this.description,
    this.logo,
    this.qrCode,
    this.signature,
    this.signatureName,
    this.verificationStatus,
    this.verificationDoc,
    this.adminFirstName,
    this.adminLastName,
    this.adminPhone,
    this.adminEmail,
  });

  // ชื่อ-นามสกุลผู้ยื่นคำขอ (ถ้าไม่มีข้อมูลจะเป็น null)
  String? get adminFullName {
    final String full =
        '${adminFirstName ?? ''} ${adminLastName ?? ''}'.trim();
    return full.isEmpty ? null : full;
  }

  factory Hospital.fromJson(Map<String, dynamic> json) => Hospital(
        hospitalId: json['hospitalId'],
        hospitalName: json['hospitalName'],
        address: json['address'],
        description: json['description'],
        logo: json['logo'],
        qrCode: json['qrCode'],
        signature: json['signature'],
        signatureName: json['signatureName'],
        verificationStatus: json['verificationStatus'],
        verificationDoc: json['verificationDoc'],
        adminFirstName: json['adminFirstName'],
        adminLastName: json['adminLastName'],
        adminPhone: json['adminPhone'],
        adminEmail: json['adminEmail'],
      );

  Map<String, dynamic> toJson() => {
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'address': address,
        'description': description,
        'logo': logo,
        'qrCode': qrCode,
        'signature': signature,
        'signatureName': signatureName,
        'verificationStatus': verificationStatus,
        'verificationDoc': verificationDoc,
      };
}
