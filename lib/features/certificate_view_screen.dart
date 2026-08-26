import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:project_final_411/core/network/dio_client.dart';

// แสดงใบอนุโมทนาบัตร + ปุ่มบันทึกลงคลังภาพของเครื่อง
class CertificateViewScreen extends StatefulWidget {
  final String certificateUrl;

  const CertificateViewScreen({super.key, required this.certificateUrl});

  @override
  State<CertificateViewScreen> createState() => _CertificateViewScreenState();
}

class _CertificateViewScreenState extends State<CertificateViewScreen> {
  final Color primaryTeal = const Color(0xFF0A85A0);
  bool _isSaving = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final bool granted = await Gal.requestAccess();
        if (!granted) {
          _showMessage('กรุณาอนุญาตสิทธิ์เข้าถึงคลังภาพเพื่อบันทึกใบอนุโมทนาบัตร');
          return;
        }
      }

      final response = await DioClient.dio.get<List<int>>(
        widget.certificateUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final Uint8List bytes = Uint8List.fromList(response.data!);

      await Gal.putImageBytes(bytes, name: 'certificate_${DateTime.now().millisecondsSinceEpoch}');

      _showMessage('บันทึกใบอนุโมทนาบัตรลงคลังภาพแล้ว');
    } catch (e) {
      _showMessage('บันทึกไม่สำเร็จ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'ใบอนุโมทนาบัตร',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            widget.certificateUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(40),
              child: Text('โหลดใบอนุโมทนาบัตรไม่สำเร็จ',
                  style: TextStyle(color: Colors.white70)),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveToGallery,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_alt, color: Colors.white),
              label: Text(
                _isSaving ? 'กำลังบันทึก...' : 'บันทึกลงคลังภาพ',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
