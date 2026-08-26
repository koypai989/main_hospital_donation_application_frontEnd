import 'package:project_final_411/core/network/dio_client.dart';

class SystemAdminService {
  Future<Map<String, dynamic>> getAdminByUserId(int userId) async {
    try {
      var response = await DioClient.dio.get('/v1/system-admins/user/$userId');
      return response.data['result'];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAdmin(int userId, Map<String, dynamic> updateData) async {
    try {
      await DioClient.dio.put('/v1/system-admins/user/$userId', data: updateData);
    } catch (e) {
      rethrow;
    }
  }
}