import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/data/sevices/foundation_service.dart';

class CreateFoundationScreen extends StatefulWidget {
  final int hospitalId;

  const CreateFoundationScreen({super.key, required this.hospitalId});

  @override
  State<CreateFoundationScreen> createState() => _CreateFoundationScreenState();
}

class _CreateFoundationScreenState extends State<CreateFoundationScreen> {
  final FoundationService foundationService = FoundationService();

  bool _isLoading = false;

  // โทนสีให้ตรงกับหน้าอื่นในระบบ
  final Color primaryTeal = const Color(0xFF0A85A0);
  final Color bgColor = const Color(0xFFF5F8F8);
  final Color inputBgColor = const Color(0xFFF8FAFC);
  final Color borderColor = const Color(0xFFE2E8F0);
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF64748B);
  final Color successGreen = const Color(0xFF2A9D8F);

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();
  final TextEditingController _signNameCtrl = TextEditingController();

  File? _logo;
  File? _signature;
  File? _qrCode;
  File? _verificationDoc;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _signNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        if (type == 'logo') _logo = File(pickedFile.path);
        if (type == 'sig') _signature = File(pickedFile.path);
        if (type == 'qr') _qrCode = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result != null) {
      setState(() => _verificationDoc = File(result.files.single.path!));
    }
  }

  Future<String?> _uploadFileToServer(File file) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });
    var response = await DioClient.dio.post('/v1/files/upload', data: formData);
    return response.data['result'];
  }

  Future<void> _submit() async {
    // ตรวจสอบข้อมูลให้ครบตาม SRS (ทุกฟิลด์ NN)
    if (_nameCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty ||
        _targetCtrl.text.trim().isEmpty ||
        _logo == null ||
        _signature == null ||
        _qrCode == null ||
        _verificationDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลและแนบไฟล์ให้ครบถ้วน')),
      );
      return;
    }

    final double? target = double.tryParse(_targetCtrl.text.replaceAll(',', ''));
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เป้าหมายการรับบริจาคต้องเป็นตัวเลข')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? logoUrl = await _uploadFileToServer(_logo!);
      final String? sigUrl = await _uploadFileToServer(_signature!);
      final String? qrUrl = await _uploadFileToServer(_qrCode!);
      final String? docUrl = await _uploadFileToServer(_verificationDoc!);

      final Map<String, dynamic> foundationData = {
        "foundationName": _nameCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "logo": logoUrl,
        "signature": sigUrl,
        "signatureName": _signNameCtrl.text.trim(),
        "targetAmount": target,
        "qrCode": qrUrl,
        "verificationDoc": docUrl,
        "hospitalId": widget.hospitalId,
      };

      await foundationService.createFoundation(foundationData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างมูลนิธิสำเร็จ!')),
      );
      Navigator.pop(context, true); // ส่ง true กลับไปให้หน้ารายการรีเฟรช
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ข้อผิดพลาด: ${friendlyDioErrorMessage(e)}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ข้อผิดพลาด: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'สร้างมูลนิธิ',
          style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('ข้อมูลมูลนิธิ'),
            _buildTextField('ชื่อมูลนิธิ', 'เช่น มูลนิธิหัวใจไทย', controller: _nameCtrl),
            _buildTextField('รายละเอียด', 'อธิบายพันธกิจและเป้าหมายของมูลนิธิ...',
                maxLines: 4, controller: _descCtrl),
            _buildTextField('ชื่อผู้มีอำนาจลงนาม', 'เช่น นายสมชาย ใจดี (ใช้ในใบอนุโมทนาบัตร)',
                controller: _signNameCtrl),
            _buildTargetField(),

            const SizedBox(height: 24),
            _buildSectionHeader('รูปภาพและเอกสาร'),
            _buildUploadZone(
              title: 'โลโก้มูลนิธิ',
              icon: Icons.image_outlined,
              uploadText: 'อัปโหลดโลโก้',
              formatText: 'PNG, JPG',
              selectedFile: _logo,
              onTap: () => _pickImage('logo'),
            ),
            _buildUploadZone(
              title: 'ลายเซ็นผู้มีอำนาจ',
              icon: Icons.draw_outlined,
              uploadText: 'อัปโหลดลายเซ็นที่สแกน',
              formatText: 'PNG, JPG',
              selectedFile: _signature,
              onTap: () => _pickImage('sig'),
            ),
            _buildUploadZone(
              title: 'QR Code สำหรับบริจาค',
              icon: Icons.qr_code_2,
              uploadText: 'อัปโหลด QR Code',
              formatText: 'PNG, JPG',
              selectedFile: _qrCode,
              onTap: () => _pickImage('qr'),
            ),
            _buildUploadZone(
              title: 'เอกสารยืนยัน',
              icon: Icons.upload_file,
              uploadText: 'แตะเพื่ออัปโหลดเอกสาร',
              formatText: 'PDF, JPG',
              selectedFile: _verificationDoc,
              onTap: _pickDocument,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                _isLoading ? 'กำลังบันทึก...' : 'เผยแพร่มูลนิธิ',
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

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryTeal,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Divider(color: borderColor, thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(String label, String hint,
      {int maxLines = 1, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor)),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('เป้าหมายการรับบริจาค',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      hintText: '500000',
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: borderColor)),
                  ),
                  child: Text('บาท',
                      style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadZone({
    required String title,
    required IconData icon,
    required String uploadText,
    required String formatText,
    required VoidCallback onTap,
    File? selectedFile,
  }) {
    bool hasFile = selectedFile != null;
    String displayUploadText = hasFile ? selectedFile.path.split('/').last : uploadText;
    Color currentPrimaryColor = hasFile ? successGreen : primaryTeal;
    IconData currentIcon = hasFile ? Icons.check_circle : icon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: hasFile ? successGreen.withOpacity(0.05) : inputBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: hasFile ? successGreen.withOpacity(0.5) : primaryTeal.withOpacity(0.4),
                    width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: currentPrimaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(currentIcon, color: currentPrimaryColor, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayUploadText,
                    style: TextStyle(
                        color: currentPrimaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!hasFile) ...[
                    const SizedBox(height: 4),
                    Text(formatText, style: TextStyle(color: textMuted, fontSize: 12)),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
