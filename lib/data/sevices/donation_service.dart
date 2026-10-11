import 'package:dio/dio.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/data/models/donation.dart';

class DonationService {
  // ประวัติการบริจาคของผู้บริจาค
  Future<List<Donation>> getDonationsByCitizenId(String citizenId) async {
    final response = await DioClient.dio.get('/v1/donations/donator/$citizenId');
    return (response.data['result'] as List)
        .map((e) => Donation.fromJson(e))
        .toList();
  }

  // การตรวจสลิปฝั่ง server อาจใช้เวลาถึง ~25 วิ จึงตั้ง timeout ให้ยาวเป็นพิเศษ
  // คืน result = ข้อมูลการบริจาคทั้งหมด
  // { donationId, amount, donationDate, slipImagePath, certificatePath, refNumber, targetType, targetId, targetName }
  // หมายเหตุ: ไม่ต้องส่ง amount — backend อ่านยอดเงินจากสลิปให้เอง
  Future<Map<String, dynamic>?> createDonation(Map<String, dynamic> data) async {
    final response = await DioClient.dio.post(
      '/v1/donations',
      data: data,
      options: Options(
        // backend อาจลองเรียก slip-c ซ้ำถ้าครั้งแรกช้า (สูงสุด ~2x45s) จึงตั้งให้ยาวกว่านั้น
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    return response.data['result'] as Map<String, dynamic>?;
  }
}
