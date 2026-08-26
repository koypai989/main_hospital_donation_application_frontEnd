import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/data/models/donator.dart';
import 'package:project_final_411/data/models/hospital.dart';
import 'package:project_final_411/data/sevices/donator_service.dart';
import 'package:project_final_411/data/sevices/hospital_service.dart';
import 'package:project_final_411/data/sevices/users_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});
 
  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}
 
class _EditUserScreenState extends State<EditUserScreen> {
  final UsersService usersService = UsersService();
  final HospitalService hospitalService = HospitalService();
  final DonatorService donatorService = DonatorService();
  bool _isLoading = true;
  bool _isSaving = false;
  String role = "";
  int? userId;
 
  // ==========================================
  // 🎨 โทนสี
  // ==========================================
  final Color primaryTeal = const Color(0xFF0A85A0);
  final Color bgColor = const Color(0xFFF5F8F8);
  final Color inputBgColor = const Color(0xFFF8FAFC);
  final Color borderColor = const Color(0xFFE2E8F0);
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF64748B);
  final Color successGreen = const Color(0xFF2A9D8F);
 
  // ==========================================
  // 📝 Controllers
  // ==========================================
  final TextEditingController _emailCtrl = TextEditingController();
 
  // ADMIN
  final TextEditingController _adminFullNameCtrl = TextEditingController();
 
  // DONATOR
  final TextEditingController _dnFirstNameCtrl = TextEditingController();
  final TextEditingController _dnLastNameCtrl = TextEditingController();
  final TextEditingController _dnCitizenIdCtrl = TextEditingController();
  final TextEditingController _dnAddressCtrl = TextEditingController();
  DateTime? _dnDob;
 
  // HOSPITAL
  final TextEditingController _hpNameCtrl = TextEditingController();
  final TextEditingController _hpDescCtrl = TextEditingController();
  final TextEditingController _hpAddressCtrl = TextEditingController();
  final TextEditingController _hpAdminFirstCtrl = TextEditingController();
  final TextEditingController _hpAdminLastCtrl = TextEditingController();
  final TextEditingController _hpAdminPhoneCtrl = TextEditingController();
  final TextEditingController _hpSignNameCtrl = TextEditingController();
 
  // ไฟล์ใหม่ที่ผู้ใช้เลือก
  File? _hpLogo;
  File? _hpVerificationDoc;
  File? _hpQrCode;
  File? _hpSignature;
 
  // URL ไฟล์เดิมที่มีในระบบ
  String? _existingLogoUrl;
  String? _existingDocUrl;
  String? _existingQrUrl;
  String? _existingSigUrl;
 
  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }
 
  @override
  void dispose() {
    _emailCtrl.dispose();
    _adminFullNameCtrl.dispose();
    _dnFirstNameCtrl.dispose();
    _dnLastNameCtrl.dispose();
    _dnCitizenIdCtrl.dispose();
    _dnAddressCtrl.dispose();
    _hpNameCtrl.dispose();
    _hpDescCtrl.dispose();
    _hpAddressCtrl.dispose();
    _hpAdminFirstCtrl.dispose();
    _hpAdminLastCtrl.dispose();
    _hpAdminPhoneCtrl.dispose();
    _hpSignNameCtrl.dispose();
    super.dispose();
  }
 
  // ==========================================
  // 🔄 โหลดข้อมูลผู้ใช้จาก API จริง
  // ==========================================
  Future<void> _loadCurrentUserData() async {
    final prefs = await SharedPreferences.getInstance();
 
    final id = prefs.getInt('user_id');
    final r = prefs.getString('user_role') ?? 'DONATOR';
 
    setState(() {
      userId = id;
      role = r;
    });
 
    if (id == null) {
      setState(() => _isLoading = false);
      return;
    }
 
    try {
      Map<String, dynamic> profile;
 
      if (role == 'HOSPITAL_ADMIN') {
        var data = await hospitalService.getHospitalByUserId(userId!);
        _emailCtrl.text = prefs.getString('user_email')!;
        _hpAdminFirstCtrl.text = data['firstName'] ?? "";
        _hpAdminLastCtrl.text = data['lastName'] ?? "";
        _hpAdminPhoneCtrl.text = data['phone'] ?? "";
        
        _hpNameCtrl.text = data['hospitalName'] ?? "";
        _hpAddressCtrl.text = data['address'] ?? "";
        _hpDescCtrl.text = data['description'] ?? "";
        _hpSignNameCtrl.text = data['signatureName'] ?? "";
        
        _existingLogoUrl = data['logo'];
        _existingQrUrl = data['qrCode'];
        _existingSigUrl = data['signature'];
        _existingDocUrl = data['verificationDoc'];
      } else {
        profile = await donatorService.getDonatorByUserId(id);
        _emailCtrl.text = prefs.getString('user_email')!;
        _dnFirstNameCtrl.text = profile['firstName'] ?? '';
        _dnLastNameCtrl.text = profile['lastName'] ?? '';
        _dnCitizenIdCtrl.text = profile['citizenID'] ?? '';
        _dnAddressCtrl.text = profile['address'] ?? '';
 
        final dobStr = profile['dateOfBirth'] as String?;
        if (dobStr != null && dobStr.isNotEmpty) {
          try {
            // หั่นข้อความ "15-08-1995" ออกเป็น 3 ท่อน
            List<String> parts = dobStr.split('-');
            if (parts.length == 3) {
              int day = int.parse(parts[0]);
              int month = int.parse(parts[1]);
              int year = int.parse(parts[2]);
              // ประกอบร่างกลับเป็น DateTime (มันเรียงเป็น ปี, เดือน, วัน)
              _dnDob = DateTime(year, month, day);
            }
          } catch (e) {
            print("Date parse error: $e");
          }
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โหลดข้อมูลไม่สำเร็จ: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
 
  // ==========================================
  // ⚙️ Helper Methods
  // ==========================================
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dnDob ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dnDob = picked);
  }
 
  // ส่งไปหา API ในรูปแบบ dd-MM-yyyy ตาม @JsonFormat ของ backend
  String _getFormattedDob() {
    if (_dnDob == null) return '';
    return "${_dnDob!.day.toString().padLeft(2, '0')}-"
        "${_dnDob!.month.toString().padLeft(2, '0')}-"
        "${_dnDob!.year}";
  }
 
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result != null) {
      setState(() => _hpVerificationDoc = File(result.files.single.path!));
    }
  }
 
  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (type == 'logo') _hpLogo = File(pickedFile.path);
        if (type == 'qr') _hpQrCode = File(pickedFile.path);
        if (type == 'sig') _hpSignature = File(pickedFile.path);
      });
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
 
  // ==========================================
  // 💾 บันทึกข้อมูล (ยิง API จริง)
  // ==========================================
  Future<void> _submitUpdate() async {
    if (userId == null) return;
    setState(() => _isSaving = true);
 
    try {
       if (role == 'DONATOR') {
        await donatorService.updateDonator(userId!, {
          "citizenID":   _dnCitizenIdCtrl.text.trim(),
          "firstName":   _dnFirstNameCtrl.text.trim(),
          "lastName":    _dnLastNameCtrl.text.trim(),
          "dateOfBirth": _getFormattedDob(),
          "address":     _dnAddressCtrl.text.trim(),
        });
 
      } else if (role == 'HOSPITAL_ADMIN') {
        final logoUrl = _hpLogo != null
            ? await _uploadFileToServer(_hpLogo!)
            : _existingLogoUrl;
        final docUrl = _hpVerificationDoc != null
            ? await _uploadFileToServer(_hpVerificationDoc!)
            : _existingDocUrl;
        final qrUrl = _hpQrCode != null
            ? await _uploadFileToServer(_hpQrCode!)
            : _existingQrUrl;
        final sigUrl = _hpSignature != null
            ? await _uploadFileToServer(_hpSignature!)
            : _existingSigUrl;
 
        await hospitalService.updateHospitalProfile(userId!, {
          "firstName":       _hpAdminFirstCtrl.text.trim(),
          "lastName":        _hpAdminLastCtrl.text.trim(),
          "phone":           _hpAdminPhoneCtrl.text.trim(),
          "hospitalName":    _hpNameCtrl.text.trim(),
          "address":         _hpAddressCtrl.text.trim(),
          "description":     _hpDescCtrl.text.trim(),
          "logo":            logoUrl,
          "qrCode":          qrUrl,
          "signature":       sigUrl,
          "signatureName":   _hpSignNameCtrl.text.trim(),
          "verificationDoc": docUrl,
        });
      }
 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อัปเดตข้อมูลสำเร็จ!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ข้อผิดพลาด: $msg'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ข้อผิดพลาด: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
 
  // ==========================================
  // 📱 Build
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'แก้ไขข้อมูลส่วนตัว',
          style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Email (read-only ทุก role)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('ACCOUNT CREDENTIALS'),
                              _buildTextField(
                                'Email Address',
                                '',
                                prefixIcon: Icons.email_outlined,
                                controller: _emailCtrl,
                                isReadOnly: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (role == 'DONATOR') _buildDonatorForm(),
                        if (role == 'HOSPITAL_ADMIN') _buildHospitalForm(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading || _isSaving ? null : _submitUpdate,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

 
  Widget _buildDonatorForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('PERSONAL DETAILS'),
          _buildTextField('First Name', 'Enter first name', controller: _dnFirstNameCtrl),
          _buildTextField('Last Name', 'Enter last name', controller: _dnLastNameCtrl),
          _buildTextField(
            'Citizen ID',
            'X-XXXX-XXXXX-XX-X',
            prefixIcon: Icons.badge_outlined,
            controller: _dnCitizenIdCtrl,
            isReadOnly: true,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of Birth',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDateOfBirth(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_outlined, color: primaryTeal, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _dnDob == null ? 'Select your date of birth' : _getFormattedDob(),
                          style: TextStyle(
                            color: _dnDob == null ? textMuted : textDark,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildTextField(
            'Address',
            'Full address...',
            maxLines: 3,
            prefixIcon: Icons.home_outlined,
            controller: _dnAddressCtrl,
          ),
        ],
      ),
    );
  }
 
  Widget _buildHospitalForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('GENERAL INFORMATION'),
          _buildTextField('Hospital Name', 'Enter official hospital name', controller: _hpNameCtrl,
              prefixText: 'โรงพยาบาล'),
          _buildTextField('Description', 'Brief description...', maxLines: 3, controller: _hpDescCtrl),
          _buildTextField('Address', 'Full hospital address...', maxLines: 3, controller: _hpAddressCtrl),
          _buildTextField('Authorized Signer Name', 'ชื่อผู้มีอำนาจลงนาม (ใช้ในใบอนุโมทนาบัตร)', controller: _hpSignNameCtrl),
          _buildUploadZone(
            title: 'Hospital Logo',
            icon: Icons.image_outlined,
            uploadText: 'Change Logo',
            formatText: 'PNG, JPG',
            selectedFile: _hpLogo,
            existingUrl: _existingLogoUrl,
            onTap: () => _pickImage('logo'),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('ADMIN DETAILS'),
          _buildTextField('First Name', 'Admin First Name', controller: _hpAdminFirstCtrl),
          _buildTextField('Last Name', 'Admin Last Name', controller: _hpAdminLastCtrl),
          _buildTextField(
            'Phone Number',
            '02-XXX-XXXX',
            prefixIcon: Icons.phone_outlined,
            controller: _hpAdminPhoneCtrl,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('REQUIRED DOCUMENTS'),
          _buildUploadZone(
            title: 'Verification Document',
            icon: Icons.upload_file,
            uploadText: 'Change Document',
            formatText: 'PDF/JPG',
            selectedFile: _hpVerificationDoc,
            existingUrl: _existingDocUrl,
            onTap: _pickDocument,
          ),
          _buildUploadZone(
            title: 'e-Donation QR Code',
            icon: Icons.qr_code_scanner,
            uploadText: 'Change QR Image',
            formatText: 'PNG, JPG',
            selectedFile: _hpQrCode,
            existingUrl: _existingQrUrl,
            onTap: () => _pickImage('qr'),
          ),
          _buildUploadZone(
            title: 'Authorized Signature',
            icon: Icons.draw_outlined,
            uploadText: 'Change Signature',
            formatText: 'Image of signature',
            selectedFile: _hpSignature,
            existingUrl: _existingSigUrl,
            onTap: () => _pickImage('sig'),
          ),
        ],
      ),
    );
  }
 
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: borderColor, thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }
 
  Widget _buildTextField(
    String label,
    String hint, {
    int maxLines = 1,
    IconData? prefixIcon,
    bool isReadOnly = false,
    TextEditingController? controller,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isReadOnly ? Colors.grey.shade100 : inputBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // label ตายตัว แสดงตลอดเวลาไม่ว่าจะโฟกัส/มีข้อความหรือไม่ก็ตาม
                // (ไม่ใช่ InputDecoration.prefixText เพราะ Flutter บางเวอร์ชันซ่อนมันตอนช่องว่าง+ไม่โฟกัส)
                if (prefixText != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(prefixText,
                        style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    readOnly: isReadOnly,
                    maxLines: maxLines,
                    style: TextStyle(color: isReadOnly ? textMuted : textDark),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(
                        left: prefixText != null ? 4 : 16,
                        right: 16,
                        top: 12,
                        bottom: 12,
                      ),
                      prefixIcon: prefixIcon != null
                          ? Icon(prefixIcon,
                              color: isReadOnly ? Colors.grey : primaryTeal, size: 20)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
 // ==========================================
  // 🎨 UI Helper: อัปเกรด UploadZone ให้โชว์รูปพรีวิว
  // ==========================================
  Widget _buildUploadZone({
    required String title,
    required IconData icon,
    required String uploadText,
    required String formatText,
    required VoidCallback onTap,
    File? selectedFile,
    String? existingUrl,
  }) {
    final bool hasNewFile = selectedFile != null;
    final bool hasExistingFile = existingUrl != null && existingUrl.isNotEmpty;
    
    // ฟังก์ชันช่วยจัดการ URL รูปภาพ (ดึง helper จากตัวอย่างก่อนหน้ามาใช้)
    String getFullImageUrl(String? path) {
      return resolveImageUrl(path);
    }

    final String finalImageUrl = getFullImageUrl(existingUrl);

    // กำหนดสีและไอคอนตามสถานะ (มีไฟล์ใหม่ > มีไฟล์เก่า > ไม่มีไฟล์)
    Color activeColor = primaryTeal;
    IconData activeIcon = icon;
    String displayText = uploadText;

    if (hasNewFile) {
      activeColor = successGreen;
      activeIcon = Icons.check_circle;
      displayText = "เลือกรูปใหม่แล้ว: ${selectedFile.path.split('/').last}";
    } else if (hasExistingFile) {
      activeColor = Colors.orange;
      activeIcon = Icons.image; // เปลี่ยนเป็นไอคอนรูปภาพ
      displayText = "รูปภาพปัจจุบัน (กดเพื่อเปลี่ยน)";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12), // ปรับมุมให้มนขึ้น
            child: Container(
              width: double.infinity,
              height: 150, // กำหนดความสูงคงที่เพื่อให้เป็นกล่องพรีวิว
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (hasNewFile || hasExistingFile)
                      ? activeColor.withOpacity(0.5)
                      : primaryTeal.withOpacity(0.4),
                  width: 1.5,
                ),
                // 🌟 หัวใจสำคัญ: ใส่รูปเป็น Background 🌟
                image: hasNewFile
                    ? DecorationImage(
                        image: FileImage(selectedFile), // โชว์รูปใหม่จากเครื่อง
                        fit: BoxFit.cover,
                      )
                    : hasExistingFile
                        ? DecorationImage(
                            image: NetworkImage(finalImageUrl), // โชว์รูปเก่าจากเน็ต
                            fit: BoxFit.cover,
                          )
                        : null, // ถ้าไม่มีรูปเลย ไม่ต้องใส่ Background
              ),
              child: Stack(
                children: [
                  // 1. ส่วนแสดงไอคอนและข้อความ (จะจางลงถ้ามีรูป Background)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      // ถ้ามีรูป ใส่ Overlay สีดำจางๆ เพื่อให้ข้อความอ่านง่าย
                      color: (hasNewFile || hasExistingFile)
                          ? Colors.black.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: hasExistingFile && !hasNewFile
                                ? Colors.white.withOpacity(0.8) // ถ้าโชว์รูปเก่า ให้วงกลมไอคอนเด่นขึ้น
                                : activeColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(activeIcon, color: hasExistingFile && !hasNewFile ? Colors.orange : activeColor, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: hasExistingFile || hasNewFile ? Colors.white : activeColor, // เปลี่ยนสีตัวหนังสือเป็นขาวถ้ามีรูป
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!hasNewFile && !hasExistingFile) ...[
                          const SizedBox(height: 4),
                          Text(formatText, style: TextStyle(color: textMuted, fontSize: 12)),
                        ]
                      ],
                    ),
                  ),
                  
                  // 2. ป้ายบอกสถานะเล็กๆ มุมขวาบน (ถ้ามีรูป)
                  if (hasNewFile || hasExistingFile)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hasNewFile ? "New" : "Current",
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}