import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/core/utils/validators.dart';
import 'package:project_final_411/data/sevices/donator_service.dart';
import 'package:project_final_411/data/sevices/hospital_service.dart';
import 'package:project_final_411/features/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final DonatorService donatorService = DonatorService();
  final HospitalService hospitalService = HospitalService();
  int _selectedFormIndex = 0; // 0 = Donator, 1 = Hospital
  bool _isLoading = false;
  bool _obscurePassword = true;

  final GlobalKey<FormState> _donatorFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _hospitalFormKey = GlobalKey<FormState>();

  final Color primaryTeal = const Color(0xFF0A85A0);
  final Color bgColor = const Color(0xFFF5F8F8);
  final Color inputBgColor = const Color(0xFFF8FAFC);
  final Color borderColor = const Color(0xFFE2E8F0);
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF64748B);
  final Color successGreen = const Color(0xFF2A9D8F);


  final TextEditingController _dnFirstNameCtrl = TextEditingController();
  final TextEditingController _dnLastNameCtrl = TextEditingController();
  final TextEditingController _dnCitizenIdCtrl = TextEditingController();
  final TextEditingController _dnAddressCtrl = TextEditingController();
  final TextEditingController _dnEmailCtrl = TextEditingController();
  final TextEditingController _dnPasswordCtrl = TextEditingController();
  DateTime? _dnDob;

  final TextEditingController _hpNameCtrl = TextEditingController();
  final TextEditingController _hpDescCtrl = TextEditingController();
  final TextEditingController _hpAddressCtrl = TextEditingController();
  final TextEditingController _hpSignNameCtrl = TextEditingController();
  final TextEditingController _hpAdminFirstCtrl = TextEditingController();
  final TextEditingController _hpAdminLastCtrl = TextEditingController();
  final TextEditingController _hpAdminPhoneCtrl = TextEditingController();
  final TextEditingController _hpAdminEmailCtrl = TextEditingController();
  final TextEditingController _hpAdminPasswordCtrl = TextEditingController();

  File? _hpLogo;
  File? _hpVerificationDoc;
  File? _hpQrCode;
  File? _hpSignature;

  @override
  void dispose() {
    _dnFirstNameCtrl.dispose(); _dnLastNameCtrl.dispose();
    _dnCitizenIdCtrl.dispose(); _dnAddressCtrl.dispose();
    _dnEmailCtrl.dispose(); _dnPasswordCtrl.dispose();

    _hpNameCtrl.dispose(); _hpDescCtrl.dispose(); _hpAddressCtrl.dispose(); _hpSignNameCtrl.dispose();
    _hpAdminFirstCtrl.dispose(); _hpAdminLastCtrl.dispose();
    _hpAdminPhoneCtrl.dispose(); _hpAdminEmailCtrl.dispose(); _hpAdminPasswordCtrl.dispose();
    super.dispose();
  }

  // ==========================================
  // ✅ Validators
  // ==========================================
  String? _requiredValidator(String? v, [String label = 'ข้อมูลนี้']) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอก$label';
    return null;
  }

  String? _citizenIdValidator(String? v) {
    final id = v?.trim() ?? '';
    if (id.isEmpty) return 'กรุณากรอกเลขบัตรประชาชน';
    if (!RegExp(r'^\d{13}$').hasMatch(id)) return 'เลขบัตรประชาชนต้องมี 13 หลัก';
    return null;
  }

  String? _phoneValidator(String? v) {
    final p = v?.trim() ?? '';
    if (p.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
    if (!RegExp(r'^\d{9,10}$').hasMatch(p)) return 'เบอร์โทรศัพท์ไม่ถูกต้อง (9-10 หลัก)';
    return null;
  }

  // ==========================================
  // ⚙️ Helper Methods: จัดการไฟล์ & วันที่
  // ==========================================
  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryTeal, onPrimary: Colors.white, onSurface: textDark),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dnDob = picked);
  }

  String _getFormattedDob() {
    if (_dnDob == null) return '';
    return "${_dnDob!.day.toString().padLeft(2, '0')}-${_dnDob!.month.toString().padLeft(2, '0')}-${_dnDob!.year}";
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'pdf']);
    if (result != null) setState(() => _hpVerificationDoc = File(result.files.single.path!));
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

  // ฟังก์ชันย่อยสำหรับอัปโหลดไฟล์ไปที่ Spring Boot
  Future<String?> _uploadFileToServer(File file) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });
    var response = await DioClient.dio.post('/v1/files/upload', data: formData);
    return response.data['result'];
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // popup แจ้งเตือนตอนสมัครสำเร็จ — ข้อความต่างกันตามประเภทฟอร์ม
  Future<void> _showSuccessDialog() async {
    final bool isHospital = _selectedFormIndex == 1;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: successGreen.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.check_circle, color: successGreen, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              isHospital ? 'ส่งใบสมัครสำเร็จ!' : 'สมัครสมาชิกสำเร็จ!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          isHospital
              ? 'ใบสมัครของโรงพยาบาลถูกส่งเรียบร้อยแล้ว กรุณารอการตรวจสอบและอนุมัติจากผู้ดูแลระบบก่อนเข้าใช้งาน'
              : 'คุณสามารถเข้าสู่ระบบเพื่อเริ่มบริจาคได้ทันที',
          textAlign: TextAlign.center,
          style: TextStyle(color: textMuted, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('ตกลง', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitApplication() async {
    // ---- ตรวจสอบฟอร์มก่อนส่งจริง ----
    if (_selectedFormIndex == 0) {
      if (!(_donatorFormKey.currentState?.validate() ?? false)) return;
      if (_dnDob == null) {
        _showMessage('กรุณาเลือกวันเกิด');
        return;
      }
    } else {
      if (!(_hospitalFormKey.currentState?.validate() ?? false)) return;
      if (_hpLogo == null) {
        _showMessage('กรุณาแนบโลโก้โรงพยาบาล');
        return;
      }
      if (_hpVerificationDoc == null) {
        _showMessage('กรุณาแนบเอกสารยืนยันตัวตน');
        return;
      }
      if (_hpQrCode == null) {
        _showMessage('กรุณาแนบ QR Code สำหรับรับบริจาค');
        return;
      }
      if (_hpSignature == null) {
        _showMessage('กรุณาแนบรูปลายเซ็นผู้มีอำนาจ');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedFormIndex == 0) {
        // --- 🟢 ส่งฟอร์ม DONATOR ---
        Map<String, dynamic> donatorData = {
          "email": _dnEmailCtrl.text.trim(),
          "password": _dnPasswordCtrl.text,
          "role": "DONATOR",
          "citizenID": _dnCitizenIdCtrl.text.trim(),
          "firstName": _dnFirstNameCtrl.text.trim(),
          "lastName": _dnLastNameCtrl.text.trim(),
          "dateOfBirth": _getFormattedDob(),
          "address": _dnAddressCtrl.text.trim(),
        };
        await donatorService.createDonator(donatorData);

      } else {
        String? logoUrl = await _uploadFileToServer(_hpLogo!);
        String? docUrl = await _uploadFileToServer(_hpVerificationDoc!);
        String? qrUrl = await _uploadFileToServer(_hpQrCode!);
        String? sigUrl = await _uploadFileToServer(_hpSignature!);

        // 2. ประกอบร่าง JSON
        Map<String, dynamic> hospitalData = {
          "email": _hpAdminEmailCtrl.text.trim(),
          "password": _hpAdminPasswordCtrl.text,
          "role": "HOSPITAL_ADMIN",
          "firstName": _hpAdminFirstCtrl.text.trim(),
          "lastName": _hpAdminLastCtrl.text.trim(),
          "phone": _hpAdminPhoneCtrl.text.trim(),
          "hospitalName": _hpNameCtrl.text.trim(),
          "address": _hpAddressCtrl.text.trim(),
          "description": _hpDescCtrl.text.trim(),
          "logo": logoUrl,
          "qrCode": qrUrl,
          "signature": sigUrl,
          "signatureName": _hpSignNameCtrl.text.trim(),
          "verificationStatus": "PENDING",
          "verificationDoc": docUrl,
        };
        await hospitalService.createHospital(hospitalData);
      }

      if (!mounted) return;
      await _showSuccessDialog();
      if (!mounted) return;
      Navigator.pop(context);

    } on DioException catch (e) {
      _showMessage('ข้อผิดพลาด: ${friendlyDioErrorMessage(e)}');
    } catch (e) {
      _showMessage('ข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textDark), onPressed: () => Navigator.pop(context)),
        title: Text('Register', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFormIndex == 0 ? 'Create an Account' : 'Register Your Hospital',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedFormIndex == 0 ? 'Join us to start donating today.' : 'Enter details to join the donation network.',
                  style: TextStyle(fontSize: 14, color: primaryTeal.withOpacity(0.8)),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                  child: Row(
                    children: [
                      _buildTabButton('Donator', 0),
                      _buildTabButton('Hospital', 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedFormIndex == 0 ? _buildDonatorForm() : _buildHospitalForm(),
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
              onPressed: _isLoading ? null : _submitApplication,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                _isLoading ? 'Processing...' : 'Submit Application',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

  // ==========================================
  // 🎨 UI: สร้างส่วนประกอบย่อย
  // ==========================================
  Widget _buildTabButton(String title, int index) {
    bool isSelected = _selectedFormIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFormIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? primaryTeal : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(title, style: TextStyle(color: isSelected ? Colors.white : textMuted, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  // --- ฟอร์ม 1: DONATOR ---
  Widget _buildDonatorForm() {
    return Container(
      key: const ValueKey('donator_form'),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _donatorFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('PERSONAL DETAILS'),
            _buildTextField('First Name', 'Enter first name', controller: _dnFirstNameCtrl,
                validator: (v) => _requiredValidator(v, 'ชื่อ')),
            _buildTextField('Last Name', 'Enter last name', controller: _dnLastNameCtrl,
                validator: (v) => _requiredValidator(v, 'นามสกุล')),
            _buildTextField('Citizen ID', 'X-XXXX-XXXXX-XX-X', prefixIcon: Icons.badge_outlined, controller: _dnCitizenIdCtrl,
                keyboardType: TextInputType.number, validator: _citizenIdValidator),

            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date of Birth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDateOfBirth(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, color: primaryTeal, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _dnDob == null ? 'Select your date of birth' : _getFormattedDob(),
                            style: TextStyle(color: _dnDob == null ? textMuted : textDark, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildTextField('Address', 'Full address...', maxLines: 3, prefixIcon: Icons.home_outlined, controller: _dnAddressCtrl,
                validator: (v) => _requiredValidator(v, 'ที่อยู่')),
            const SizedBox(height: 24),
            _buildSectionHeader('ACCOUNT CREDENTIALS'),
            _buildTextField('Email Address', 'your@email.com', prefixIcon: Icons.email_outlined, controller: _dnEmailCtrl,
                keyboardType: TextInputType.emailAddress, validator: validateEmail),
            _buildTextField('Password', 'Create a password', prefixIcon: Icons.lock_outline, isPassword: true, controller: _dnPasswordCtrl,
                validator: validatePassword),
          ],
        ),
      ),
    );
  }

  // --- ฟอร์ม 2: HOSPITAL ---
  Widget _buildHospitalForm() {
    return Container(
      key: const ValueKey('hospital_form'),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _hospitalFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('GENERAL INFORMATION'),
            _buildTextField('Hospital Name', 'Enter official hospital name', controller: _hpNameCtrl,
                prefixText: 'โรงพยาบาล',
                validator: (v) => _requiredValidator(v, 'ชื่อโรงพยาบาล')),
            _buildTextField('Description', 'Brief description...', maxLines: 3, controller: _hpDescCtrl,
                validator: (v) => _requiredValidator(v, 'รายละเอียด')),
            _buildTextField('Address', 'Full hospital address...', maxLines: 3, controller: _hpAddressCtrl,
                validator: (v) => _requiredValidator(v, 'ที่อยู่')),
            _buildTextField('Authorized Signer Name', 'ชื่อผู้มีอำนาจลงนาม (ใช้ในใบอนุโมทนาบัตร)', controller: _hpSignNameCtrl,
                validator: (v) => _requiredValidator(v, 'ชื่อผู้มีอำนาจลงนาม')),
            _buildUploadZone(title: 'Hospital Logo', icon: Icons.image_outlined, uploadText: 'Upload Logo', formatText: 'PNG, JPG', selectedFile: _hpLogo, onTap: () => _pickImage('logo')),

            const SizedBox(height: 24),
            _buildSectionHeader('ADMIN DETAILS'),
            _buildTextField('First Name', 'Admin First Name', controller: _hpAdminFirstCtrl,
                validator: (v) => _requiredValidator(v, 'ชื่อผู้ดูแล')),
            _buildTextField('Last Name', 'Admin Last Name', controller: _hpAdminLastCtrl,
                validator: (v) => _requiredValidator(v, 'นามสกุลผู้ดูแล')),
            _buildTextField('Phone Number', '02-XXX-XXXX', prefixIcon: Icons.phone_outlined, controller: _hpAdminPhoneCtrl,
                keyboardType: TextInputType.phone, validator: _phoneValidator),

            const SizedBox(height: 24),
            _buildSectionHeader('ADMIN CREDENTIALS'),
            _buildTextField('Email Address', 'admin@hospital.com', prefixIcon: Icons.email_outlined, controller: _hpAdminEmailCtrl,
                keyboardType: TextInputType.emailAddress, validator: validateEmail),
            _buildTextField('Password', 'Create a password', prefixIcon: Icons.lock_outline, isPassword: true, controller: _hpAdminPasswordCtrl,
                validator: validatePassword),

            const SizedBox(height: 24),
            _buildSectionHeader('REQUIRED DOCUMENTS'),
            _buildUploadZone(title: 'Verification Document', icon: Icons.upload_file, uploadText: 'Upload PDF/JPG', formatText: 'Proof of registration', selectedFile: _hpVerificationDoc, onTap: _pickDocument),
            _buildUploadZone(title: 'e-Donation QR Code', icon: Icons.qr_code_scanner, uploadText: 'Upload QR Image', formatText: 'PNG, JPG', selectedFile: _hpQrCode, onTap: () => _pickImage('qr')),
            _buildUploadZone(title: 'Authorized Signature', icon: Icons.draw_outlined, uploadText: 'Upload Signature', formatText: 'Image of signature', selectedFile: _hpSignature, onTap: () => _pickImage('sig')),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTeal, letterSpacing: 1.2)),
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
    bool isPassword = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
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
                  child: TextFormField(
                    controller: controller,
                    obscureText: isPassword ? _obscurePassword : false,
                    maxLines: isPassword ? 1 : maxLines,
                    keyboardType: keyboardType,
                    validator: validator,
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
                      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryTeal, size: 20) : null,
                      suffixIcon: isPassword
                          ? IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: primaryTeal, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            )
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

  Widget _buildUploadZone({required String title, required IconData icon, required String uploadText, required String formatText, required VoidCallback onTap, File? selectedFile}) {
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
                border: Border.all(color: hasFile ? successGreen.withOpacity(0.5) : primaryTeal.withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: currentPrimaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(currentIcon, color: currentPrimaryColor, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayUploadText,
                    style: TextStyle(color: currentPrimaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
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
