class Foundation {
  final int? foundationId;
  final String? foundationName;
  final String? description;
  final String? logo;
  final String? signature;
  final String? signatureName; // ชื่อผู้มีอำนาจลงนาม
  final double? targetAmount;
  final String? qrCode;
  final String? verificationDoc;
  final int? hospitalId;
  final String? hospitalName; // ชื่อโรงพยาบาลที่มูลนิธินี้สังกัด (จาก relation)

  Foundation({
    this.foundationId,
    this.foundationName,
    this.description,
    this.logo,
    this.signature,
    this.signatureName,
    this.targetAmount,
    this.qrCode,
    this.verificationDoc,
    this.hospitalId,
    this.hospitalName,
  });

  factory Foundation.fromJson(Map<String, dynamic> json) {
    // hospital อาจถูกส่งกลับมาเป็น object ซ้อน (จาก entity relation) หรือเป็น id ตรงๆ
    int? resolvedHospitalId;
    String? resolvedHospitalName;
    final hospital = json['hospital'];
    if (hospital is Map<String, dynamic>) {
      resolvedHospitalId = hospital['hospitalId'];
      resolvedHospitalName = hospital['hospitalName'];
    } else if (json['hospitalId'] != null) {
      resolvedHospitalId = json['hospitalId'];
    }

    return Foundation(
      foundationId: json['foundationId'],
      foundationName: json['foundationName'],
      description: json['description'],
      logo: json['logo'],
      signature: json['signature'],
      signatureName: json['signatureName'],
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      qrCode: json['qrCode'],
      verificationDoc: json['verificationDoc'],
      hospitalId: resolvedHospitalId,
      hospitalName: resolvedHospitalName,
    );
  }

  Map<String, dynamic> toJson() => {
        'foundationName': foundationName,
        'description': description,
        'logo': logo,
        'signature': signature,
        'signatureName': signatureName,
        'targetAmount': targetAmount,
        'qrCode': qrCode,
        'verificationDoc': verificationDoc,
        'hospitalId': hospitalId,
      };
}
