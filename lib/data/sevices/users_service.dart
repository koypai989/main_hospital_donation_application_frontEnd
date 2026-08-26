import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/data/models/users.dart';

class UsersService {
  Future<void> createUser(
    String email,
    String password,
    String role,
  ) async {
    try{
      await DioClient.dio.post(
        '/users',
        data: {
          'email': email,
          'password': password,
          'role': role,
        },
      );
    }catch(e){
      rethrow;
    }
  }

  Future<User> getUserById(int id) async {
    try{
      var response = await DioClient.dio.get("/v1/users/$id");
      return User.fromJson(response.data["result"]);
    }catch(e){
      rethrow;
    }
  }

  Future<List<User>> getAllUser() async {
    try{
      var response = await DioClient.dio.get("/v1/users");
      return (response.data["result"] as List).map((item) => User.fromJson(item)).toList();
    }catch(e){
      rethrow;
    }
  }

  // System admin แก้ข้อมูลผู้ใช้ (email/role และตั้งรหัสผ่านใหม่ถ้าส่งมา)
  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    try {
      await DioClient.dio.put('/v1/users/$id', data: data);
    } catch (e) {
      rethrow;
    }
  }
}

