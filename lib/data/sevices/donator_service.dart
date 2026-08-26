import 'package:project_final_411/core/network/dio_client.dart';

class DonatorService {
  
  Future<void>  createDonator(Map<String, dynamic> donatorData) async {
    await DioClient.dio.post('/v1/donators/register', data: donatorData);
  } 
  Future<Map<String, dynamic>> getDonatorByUserId(int userId) async {
    try {
      var response = await DioClient.dio.get('/v1/donators/user/$userId');
      return response.data['result'];
    } catch (e) {
      rethrow;
    }
  }
  Future<void> updateDonator(int userId, Map<String, dynamic> updateData) async {
    try {
      await DioClient.dio.put('/v1/donators/user/$userId', data: updateData);
    } catch (e) {
      rethrow;
    }
  }
}