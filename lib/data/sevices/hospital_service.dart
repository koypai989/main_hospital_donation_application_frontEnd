import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/data/models/hospital.dart';

class HospitalService {
  Future<void> createHospital(Map<String, dynamic> hospitalData) async {
    await DioClient.dio.post('/v1/hospital-admins/register', data: hospitalData);
  }


  Future<Hospital> getHospitalById(int id) async {
    try {
      var response = await DioClient.dio.get('/v1/hospitals/$id');
      return Hospital.fromJson(response.data["result"]);
    } catch (e) {
      rethrow;
    }
  }
  Future<List<Hospital>> searchHospitals(String keyword) async {
    try {
      final response = await DioClient.dio.get(
        '/v1/hospitals/search',
        queryParameters: {'keyword': keyword},
      );

      if (response.data['success']) {
        List<dynamic> result = response.data['result'];
        return result.map((json) => Hospital.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search hospitals');
      }
    } catch (e) {
      print('Error searching hospitals: $e');
      throw Exception('Failed to search hospitals: $e');
    }
  }

  Future<List<Hospital>> getAllHospitals() async {
    try {
      var response = await DioClient.dio.get('/v1/hospitals');
      return (response.data["result"] as List)
          .map((item) => Hospital.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Hospital>> getPendingHospitals() async {
    try {
      var response = await DioClient.dio.get('/v1/hospitals/pendings');
      return (response.data["result"] as List)
          .map((item) => Hospital.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // โรงพยาบาลแนะนำ = ได้รับบริจาคน้อยที่สุด
  Future<List<Hospital>> getSuggestedHospitals({int limit = 5}) async {
    try {
      var response = await DioClient.dio.get(
        '/v1/hospitals/suggested',
        queryParameters: {'limit': limit},
      );
      return (response.data["result"] as List)
          .map((item) => Hospital.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Hospital>> getApprovedHospitals() async {
    try {
      var response = await DioClient.dio.get('/v1/hospitals/approved');
      return (response.data["result"] as List)
          .map((item) => Hospital.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveHospital(int hospitalId) async {
    try {
      await DioClient.dio.post('/v1/hospitals/approve/$hospitalId');
    } catch (e) {
      rethrow;
    }
  }
  Future<void> rejectHospital(int hospitalId) async {
    try {
      await DioClient.dio.post('/v1/hospitals/reject/$hospitalId');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHospitalByUserId(int userId) async {
    try {
      var response = await DioClient.dio.get('/v1/hospitals/user/$userId');
      return response.data['result']; 
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateHospitalProfile(int userId, Map<String, dynamic> updateData) async {
    try {
      await DioClient.dio.put('/v1/hospitals/user/$userId', data: updateData);
    } catch (e) {
      rethrow;
    }
  }


}