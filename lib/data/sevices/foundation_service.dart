import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/data/models/foundation.dart';

class FoundationService {
  Future<Foundation> createFoundation(Map<String, dynamic> foundationData) async {
    var response = await DioClient.dio.post('/v1/foundations', data: foundationData);
    return Foundation.fromJson(response.data['result']);
  }

  Future<Foundation> updateFoundation(int id, Map<String, dynamic> foundationData) async {
    var response = await DioClient.dio.put('/v1/foundations/$id', data: foundationData);
    return Foundation.fromJson(response.data['result']);
  }

  Future<void> deleteFoundation(int id) async {
    await DioClient.dio.delete('/v1/foundations/$id');
  }

  Future<List<Foundation>> getFoundationsByHospitalId(int hospitalId) async {
    try {
      var response = await DioClient.dio.get('/v1/foundations/hospital/$hospitalId');
      return (response.data['result'] as List)
          .map((item) => Foundation.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Foundation> getFoundationById(int id) async {
    try {
      var response = await DioClient.dio.get('/v1/foundations/$id');
      return Foundation.fromJson(response.data['result']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Foundation>> getAllFoundations() async {
    try {
      var response = await DioClient.dio.get('/v1/foundations');
      return (response.data['result'] as List)
          .map((item) => Foundation.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
