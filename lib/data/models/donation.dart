class Donation {
  final int? donationId;
  final double? amount;
  final DateTime? donationDate;
  final String? slipImagePath;
  final String? certificatePath;
  final String? refNumber;
  final String? targetType; // "HOSPITAL" หรือ "FOUNDATION"
  final int? targetId;
  final String? targetName;

  Donation({
    this.donationId,
    this.amount,
    this.donationDate,
    this.slipImagePath,
    this.certificatePath,
    this.refNumber,
    this.targetType,
    this.targetId,
    this.targetName,
  });

  bool get isFoundation => targetType == 'FOUNDATION';

  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
        donationId: json['donationId'],
        amount: (json['amount'] as num?)?.toDouble(),
        donationDate: json['donationDate'] != null
            ? DateTime.tryParse(json['donationDate'].toString())
            : null,
        slipImagePath: json['slipImagePath'],
        certificatePath: json['certificatePath'],
        refNumber: json['refNumber'],
        targetType: json['targetType'],
        targetId: json['targetId'],
        targetName: json['targetName'],
      );
}
