import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DioClient {
  // URL ของ backend (รวม /api) อ่านจาก BASE_URL ในไฟล์ .env — แก้ที่เดียวจบ
  // ต้องเรียก dotenv.load() ใน main() ก่อนใช้งาน
  static String get baseUrl {
    final String url = (dotenv.maybeGet('BASE_URL') ?? '').trim();
    if (url.isEmpty) {
      throw StateError('ไม่พบ BASE_URL ในไฟล์ .env');
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))..interceptors.add(
   LogInterceptor(
    requestBody: true,
    responseBody: true
   )
  );
}

// แปลง path ที่ได้จาก API (เช่น "/images/xxx.jpg") ให้เป็น URL เต็มสำหรับโหลดรูป
// ไฟล์ static ถูกเสิร์ฟอยู่ใต้ context path "/api" เดียวกับ REST endpoint
String resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${DioClient.dio.options.baseUrl}$path';
}

// แปลง DioException ให้เป็นข้อความที่อ่านเข้าใจง่ายสำหรับผู้ใช้
String friendlyDioErrorMessage(DioException e) {
  final statusCode = e.response?.statusCode;
  if (statusCode == 413) {
    return 'ไฟล์ที่แนบมีขนาดใหญ่เกินไป กรุณาเลือกไฟล์ที่มีขนาดเล็กลงแล้วลองใหม่อีกครั้ง';
  }

  final responseData = e.response?.data;
  if (responseData is Map && responseData['message'] != null) {
    return responseData['message'].toString();
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
    case DioExceptionType.connectionError:
      return 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
    default:
      return e.message ?? 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
  }
}