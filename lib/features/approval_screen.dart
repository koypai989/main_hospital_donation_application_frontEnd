import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/core/utils/formatters.dart';
import 'package:project_final_411/core/widgets/image_viewer.dart';
import 'package:project_final_411/data/models/hospital.dart';
import 'package:project_final_411/data/sevices/hospital_service.dart';
import 'package:project_final_411/features/main_screen.dart';
import 'package:project_final_411/features/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final HospitalService hospitalService = HospitalService();

  static const Color bgColor = Color(0xFFF9FAFB);
  static const Color primaryTeal = Color(0xFF0A85A0);
  static const Color successGreen = Color(0xFF2A9D8F);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color lineColor = Color(0xFFF3F4F6);

  int? userId;
  String userEmail = "";
  String name = "";
  String role = "";
  bool isLoading = false;
  bool _isProcessing = false; // กันกดซ้ำระหว่างรออนุมัติ/ปฏิเสธ
  List<Hospital> pendingHospitals = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      var hospitals = await hospitalService.getPendingHospitals();
      setState(() {
        userId = prefs.getInt('user_id');
        userEmail = prefs.getString('user_email') ?? '';
        name = prefs.getString('name') ?? '';
        role = prefs.getString('user_role') ?? '';
        pendingHospitals = hospitals;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดรายการคำขอไม่สำเร็จ: ${_errorText(e)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // แปลง error เป็นข้อความไทย (ไม่ให้ขึ้นข้อความ exception ภาษาอังกฤษ)
  String _errorText(Object e) {
    if (e is DioException) return friendlyDioErrorMessage(e);
    return 'กรุณาลองใหม่อีกครั้ง';
  }

  // รออนุมัติให้เสร็จก่อน แล้วค่อยรีเฟรชรายการ 1 ครั้ง
  Future<void> _handleApprove(int hospitalId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await hospitalService.approveHospital(hospitalId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อนุมัติโรงพยาบาลเรียบร้อยแล้ว')),
      );
      await _loadUserData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อนุมัติไม่สำเร็จ: ${_errorText(e)}')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject(int hospitalId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await hospitalService.rejectHospital(hospitalId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ปฏิเสธคำขอเรียบร้อยแล้ว')),
      );
      await _loadUserData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ปฏิเสธไม่สำเร็จ: ${_errorText(e)}')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
        title: const Text(
          'คำขออนุมัติโรงพยาบาล',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'คำขอที่รออนุมัติ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pendingHospitals.length} รายการ',
                      style: const TextStyle(
                          fontSize: 12, color: primaryTeal, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryTeal))
                  : RefreshIndicator(
                      color: primaryTeal,
                      onRefresh: _loadUserData,
                      child: pendingHospitals.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                Icon(Icons.inbox_outlined, size: 56, color: textMuted),
                                SizedBox(height: 12),
                                Center(
                                  child: Text('ไม่มีรายการคำขอใหม่',
                                      style: TextStyle(color: textMuted)),
                                ),
                              ],
                            )
                          : ListView.builder(
                              itemCount: pendingHospitals.length,
                              itemBuilder: (context, index) =>
                                  _buildRequestCard(pendingHospitals[index]),
                            ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: primaryTeal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          Widget? nextScreen;

          if (role.toUpperCase() == 'ADMIN') {
            if (index == 0) nextScreen = const Mainscreen();
            else if (index == 1) nextScreen = const ApprovalScreen();
            else if (index == 2) nextScreen = const Profile();
          } else {
            if (index == 0) nextScreen = const Mainscreen();
            else if (index == 1) nextScreen = const Profile();
          }

          if (nextScreen != null) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => nextScreen!,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          if (role.toUpperCase() == 'ADMIN')
            const BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings), label: 'อนุมัติ'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  // ---------------- การ์ดคำขอ 1 รายการ (แสดงข้อมูลโรงพยาบาลทั้งหมด) ----------------

  Widget _buildRequestCard(Hospital h) {
    final int? hospitalId = h.hospitalId;
    final String logoUrl = resolveImageUrl(h.logo);
    final String qrUrl = resolveImageUrl(h.qrCode);
    final String signatureUrl = resolveImageUrl(h.signature);
    final String docUrl = resolveImageUrl(h.verificationDoc);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- หัวการ์ด: โลโก้ + ชื่อ + เลขคำขอ + สถานะ ---
          Row(
            children: [
              GestureDetector(
                onTap: logoUrl.isEmpty ? null : () => showZoomableImage(context, logoUrl),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    shape: BoxShape.circle,
                    image: logoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(logoUrl),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {},
                          )
                        : null,
                  ),
                  child: logoUrl.isEmpty
                      ? const Icon(Icons.local_hospital, color: primaryTeal)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      withHospitalPrefix(h.hospitalName),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'ID: #REQ-${hospitalId ?? '-'}',
                          style: const TextStyle(fontSize: 12, color: textMuted),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(h.verificationStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          _divider(),

          // --- ข้อมูลโรงพยาบาล ---
          _sectionTitle('ข้อมูลโรงพยาบาล', Icons.local_hospital_outlined),
          _infoRow('ชื่อโรงพยาบาล', withHospitalPrefix(h.hospitalName)),
          _infoRow('ที่อยู่', h.address),
          _infoRow('รายละเอียด', h.description),

          _divider(),

          // --- ผู้ยื่นคำขอ (เจ้าหน้าที่โรงพยาบาล) ---
          _sectionTitle('ผู้ยื่นคำขอ', Icons.person_outline),
          _infoRow('ชื่อ-นามสกุล', h.adminFullName),
          _infoRow('เบอร์โทรศัพท์', h.adminPhone),
          _infoRow('อีเมล', h.adminEmail),

          _divider(),

          // --- ผู้มีอำนาจลงนาม + ลายเซ็น ---
          _sectionTitle('ผู้มีอำนาจลงนาม', Icons.draw_outlined),
          _infoRow('ชื่อผู้ลงนาม', h.signatureName),
          const SizedBox(height: 4),
          _buildImageBox(
            url: signatureUrl,
            height: 80,
            emptyText: 'ไม่มีไฟล์ลายเซ็น',
          ),

          _divider(),

          // --- QR รับบริจาค ---
          _sectionTitle('คิวอาร์โค้ดรับบริจาค', Icons.qr_code_2),
          _buildImageBox(
            url: qrUrl,
            height: 140,
            emptyText: 'ไม่มีคิวอาร์โค้ดรับบริจาค',
          ),

          _divider(),

          // --- เอกสารยืนยันตัวตน ---
          _sectionTitle('เอกสารยืนยันตัวตน', Icons.description_outlined),
          _buildDocument(docUrl, h.verificationDoc),

          const SizedBox(height: 20),

          // --- ปุ่มดำเนินการ ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_isProcessing || hospitalId == null)
                      ? null
                      : () => _handleReject(hospitalId),
                  icon: const Icon(Icons.close, color: dangerRed, size: 18),
                  label: const Text('ปฏิเสธ', style: TextStyle(color: dangerRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: dangerRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isProcessing || hospitalId == null)
                      ? null
                      : () => _handleApprove(hospitalId),
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text('อนุมัติ', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14.0),
        child: Divider(height: 1, color: lineColor),
      );

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryTeal),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: primaryTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final String s = (status ?? '').toUpperCase();
    late Color color;
    late String label;
    switch (s) {
      case 'APPROVED':
        color = successGreen;
        label = 'อนุมัติแล้ว';
        break;
      case 'REJECT':
      case 'REJECTED':
        color = dangerRed;
        label = 'ปฏิเสธ';
        break;
      case 'PENDING':
        color = const Color(0xFFF59E0B);
        label = 'รออนุมัติ';
        break;
      default:
        // สถานะในระบบมีแค่ รออนุมัติ/อนุมัติแล้ว/ปฏิเสธ — กรณีอื่นถือว่าไม่ระบุ
        color = textMuted;
        label = 'ไม่ระบุสถานะ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    final String text = (value == null || value.trim().isEmpty) ? 'ไม่ระบุ' : value;
    final bool empty = value == null || value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: textMuted)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: empty ? textMuted : textDark,
                fontStyle: empty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // รูปภาพประกอบคำขอ (โลโก้/QR/ลายเซ็น) แตะเพื่อขยายได้
  Widget _buildImageBox({
    required String url,
    required double height,
    required String emptyText,
  }) {
    if (url.isEmpty) {
      return Text(emptyText,
          style: const TextStyle(
              fontSize: 12, color: textMuted, fontStyle: FontStyle.italic));
    }
    return GestureDetector(
      onTap: () => showZoomableImage(context, url),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: lineColor),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, color: textMuted)),
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 12),
                    SizedBox(width: 3),
                    Text('แตะเพื่อขยาย',
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // เอกสารยืนยัน: ถ้าเป็นรูปให้ดู/ขยายได้ ถ้าเป็น PDF ให้โชว์ชื่อไฟล์
  Widget _buildDocument(String docUrl, String? docPath) {
    if (docUrl.isEmpty) {
      return const Text('ไม่มีเอกสารแนบ',
          style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic));
    }

    final String lower = docUrl.toLowerCase();
    final bool isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    if (isImage) {
      return _buildImageBox(
        url: docUrl,
        height: 160,
        emptyText: 'ไม่มีเอกสารแนบ',
      );
    }

    // ไฟล์ PDF หรือไฟล์อื่น — แสดงชื่อไฟล์และลิงก์ให้คัดลอกไปเปิดดูได้
    final String fileName = (docPath ?? docUrl).split('/').last;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, size: 18, color: dangerRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(
                      fontSize: 13, color: textDark, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            docUrl,
            style: const TextStyle(fontSize: 11, color: primaryTeal),
          ),
          const SizedBox(height: 2),
          const Text('แตะลิงก์เพื่อคัดลอกไปเปิดในเบราว์เซอร์',
              style: TextStyle(fontSize: 10, color: textMuted)),
        ],
      ),
    );
  }
}
