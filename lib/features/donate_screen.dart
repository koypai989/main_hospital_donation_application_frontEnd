import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/core/widgets/image_viewer.dart';
import 'package:project_final_411/data/sevices/donation_service.dart';
import 'package:project_final_411/data/sevices/donator_service.dart';
import 'package:project_final_411/features/certificate_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// หน้าบริจาค — ใช้ร่วมกันทั้งการบริจาคให้โรงพยาบาลและมูลนิธิ
// แนบสลิป -> ส่งให้ backend เรา -> backend เรียก slip-c อ่าน/ตรวจสอบสลิป -> บันทึก donation
// ผู้ใช้ไม่ต้องกรอกยอดเงิน ระบบอ่านยอดจากสลิปให้เอง
class DonateScreen extends StatefulWidget {
  final String targetName; // ชื่อโรงพยาบาล/มูลนิธิ
  final String targetType; // 'โรงพยาบาล' หรือ 'มูลนิธิ'
  final String? qrCode; // path ของ QR สำหรับชำระเงิน (อาจเป็น null)
  final int? hospitalId; // ระบุถ้าบริจาคให้โรงพยาบาล
  final int? foundationId; // ระบุถ้าบริจาคให้มูลนิธิ

  const DonateScreen({
    super.key,
    required this.targetName,
    required this.targetType,
    this.qrCode,
    this.hospitalId,
    this.foundationId,
  });

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final DonationService donationService = DonationService();
  final DonatorService donatorService = DonatorService();

  final Color primaryTeal = const Color(0xFF0A85A0);
  final Color bgColor = const Color(0xFFF5F8F8);
  final Color inputBgColor = const Color(0xFFF8FAFC);
  final Color borderColor = const Color(0xFFE2E8F0);
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF64748B);
  final Color successGreen = const Color(0xFF2A9D8F);

  static const List<String> _thaiMonths = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  File? _slip;
  bool _isSubmitting = false;

  // ผลลัพธ์การบริจาคจาก backend — ถ้ามีค่าแล้วจะแสดงสรุปการบริจาคในหน้านี้เลย
  Map<String, dynamic>? _result;

  Future<void> _pickSlip() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _slip = File(picked.path));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatAmount(num? amount) {
    if (amount == null) return '-';
    final String fixed = amount.toStringAsFixed(0);
    final RegExp reg = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return fixed.replaceAllMapped(reg, (m) => '${m[1]},');
  }

  String _formatDate(String? iso) {
    final DateTime? d = iso == null ? null : DateTime.tryParse(iso);
    if (d == null) return '-';
    final String hh = d.hour.toString().padLeft(2, '0');
    final String mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_thaiMonths[d.month]} ${d.year + 543} เวลา $hh:$mm';
  }

  Future<void> _submitDonation() async {
    if (_slip == null) {
      _snack('กรุณาแนบสลิปการโอนเงิน');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // หา citizenId ของผู้บริจาคที่ล็อกอินอยู่
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');
      if (userId == null) {
        _snack('กรุณาเข้าสู่ระบบด้วยบัญชีผู้บริจาคก่อน');
        return;
      }

      String? citizenId;
      try {
        final donator = await donatorService.getDonatorByUserId(userId);
        citizenId = donator['citizenID']?.toString();
      } catch (_) {
        citizenId = null;
      }
      if (citizenId == null || citizenId.isEmpty) {
        _snack('บัญชีนี้ไม่ใช่ผู้บริจาค ไม่สามารถบริจาคได้');
        return;
      }

      // แปลงสลิปเป็น data URI (base64)
      final bytes = await _slip!.readAsBytes();
      final String ext = _slip!.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      final String dataUri = 'data:image/$ext;base64,${base64Encode(bytes)}';

      // ไม่ส่ง amount — ให้ backend อ่านยอดเงินจากสลิป
      final Map<String, dynamic> payload = {
        'citizenId': citizenId,
        'hospitalId': widget.hospitalId,
        'foundationId': widget.foundationId,
        'slipBase64': dataUri,
      };

      final result = await donationService.createDonation(payload);

      if (!mounted) return;
      // อยู่หน้าเดิม แล้วแสดงข้อมูลการบริจาคทั้งหมดแทนฟอร์ม
      setState(() => _result = result);
    } on DioException catch (e) {
      _snack('บริจาคไม่สำเร็จ: ${friendlyDioErrorMessage(e)}');
    } catch (e) {
      _snack('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDone = _result != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSubmitting) Navigator.pop(context, isDone);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textDark),
            onPressed:
                _isSubmitting ? null : () => Navigator.pop(context, isDone),
          ),
          title: Text(
            isDone ? 'ผลการบริจาค' : 'บริจาค',
            style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: AbsorbPointer(
          absorbing: _isSubmitting,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: isDone ? _buildResultView() : _buildForm(),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: isDone ? _buildDoneButton() : _buildSubmitButton(),
          ),
        ),
      ),
    );
  }

  // ---------------- ฟอร์มบริจาค ----------------

  Widget _buildForm() {
    final bool isFoundation = widget.targetType == 'มูลนิธิ';
    final Color badgeColor = isFoundation ? const Color(0xFF7C3AED) : primaryTeal;
    final String qrUrl = resolveImageUrl(widget.qrCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- ข้อมูลผู้รับบริจาค ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('บริจาคให้', style: TextStyle(color: textMuted, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.targetType,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.targetName,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- ช่องทางการชำระเงิน (QR) ---
        _buildSectionHeader('สแกน QR เพื่อโอนเงิน'),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                if (qrUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => showZoomableImage(context, qrUrl),
                    child: Image.network(
                      qrUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.qr_code_2, size: 120, color: Colors.grey),
                    ),
                  )
                else
                  const Icon(Icons.qr_code_2, size: 120, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  qrUrl.isNotEmpty ? 'แตะที่ QR เพื่อขยาย' : 'ยังไม่มี QR สำหรับชำระเงิน',
                  style: TextStyle(color: textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // --- แนบสลิป ---
        _buildSectionHeader('แนบสลิปการโอนเงิน'),
        InkWell(
          onTap: _pickSlip,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _slip != null ? successGreen.withOpacity(0.05) : inputBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _slip != null
                      ? successGreen.withOpacity(0.5)
                      : primaryTeal.withOpacity(0.4),
                  width: 1.5),
            ),
            child: _slip != null
                ? Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _slip!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('แตะเพื่อเปลี่ยนสลิป',
                          style: TextStyle(
                              color: successGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: primaryTeal.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.upload_file, color: primaryTeal, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text('แตะเพื่อแนบสลิป',
                            style: TextStyle(
                                color: primaryTeal,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('PNG, JPG', style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryTeal.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: primaryTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ไม่ต้องกรอกจำนวนเงิน ระบบจะอ่านยอดเงินจากสลิปให้อัตโนมัติ '
                  'การตรวจสอบอาจใช้เวลาถึง 1-2 นาที กรุณารอสักครู่',
                  style: TextStyle(color: textMuted, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitDonation,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.favorite, color: Colors.white),
        label: Text(
          _isSubmitting ? 'กำลังตรวจสอบสลิป...' : 'ยืนยันการบริจาค',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  // ---------------- สรุปผลการบริจาค (อยู่หน้าเดิม) ----------------

  Widget _buildResultView() {
    final Map<String, dynamic> r = _result!;
    final bool isFoundation = widget.targetType == 'มูลนิธิ';
    final Color badgeColor = isFoundation ? const Color(0xFF7C3AED) : primaryTeal;
    final String? certPath = r['certificatePath'] as String?;
    final String? slipPath = r['slipImagePath'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หัวข้อสำเร็จ + ยอดเงินที่อ่านได้จากสลิป
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: successGreen.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: successGreen, size: 36),
              ),
              const SizedBox(height: 12),
              Text('บริจาคสำเร็จ',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 4),
              Text('ขอบคุณสำหรับน้ำใจ 🙏',
                  style: TextStyle(fontSize: 13, color: textMuted)),
              const SizedBox(height: 16),
              Text(
                '${_formatAmount(r['amount'] as num?)} บาท',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: successGreen),
              ),
              Text('ยอดเงินที่อ่านได้จากสลิป',
                  style: TextStyle(fontSize: 12, color: textMuted)),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // รายละเอียดการบริจาคทั้งหมด
        _buildSectionHeader('รายละเอียดการบริจาค'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('บริจาคให้',
                        style: TextStyle(color: textMuted, fontSize: 13)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.targetType,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  widget.targetName,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                ),
              ),
              Divider(color: borderColor, height: 24),
              _buildInfoRow('เลขที่รายการ', '#${r['donationId'] ?? '-'}'),
              _buildInfoRow('จำนวนเงิน', '${_formatAmount(r['amount'] as num?)} บาท'),
              _buildInfoRow('วันที่โอน', _formatDate(r['donationDate']?.toString())),
              _buildInfoRow('เลขอ้างอิงสลิป', (r['refNumber'] as String?) ?? '-'),
              _buildInfoRow('สถานะ', 'ตรวจสอบสลิปสำเร็จ', valueColor: successGreen),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // สลิปที่ใช้บริจาค
        if (slipPath != null && slipPath.isNotEmpty) ...[
          _buildSectionHeader('สลิปที่ใช้บริจาค'),
          Center(
            child: GestureDetector(
              onTap: () => showZoomableImage(context, resolveImageUrl(slipPath)),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    resolveImageUrl(slipPath),
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => _slip != null
                        ? Image.file(_slip!, height: 200, fit: BoxFit.contain)
                        : const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ใบอนุโมทนาบัตร
        _buildSectionHeader('ใบอนุโมทนาบัตร'),
        if (certPath != null && certPath.isNotEmpty)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CertificateViewScreen(
                    certificateUrl: resolveImageUrl(certPath),
                  ),
                ),
              ),
              icon: Icon(Icons.receipt_long, color: primaryTeal),
              label: Text('ดู / ดาวน์โหลดใบอนุโมทนาบัตร',
                  style: TextStyle(
                      color: primaryTeal, fontSize: 15, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryTeal),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ยังไม่สามารถออกใบอนุโมทนาบัตรได้ แต่การบริจาคถูกบันทึกเรียบร้อยแล้ว '
              'สามารถดูย้อนหลังได้ที่หน้าประวัติการบริจาค',
              style: TextStyle(color: textMuted, fontSize: 12, height: 1.5),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: textMuted, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          'เสร็จสิ้น',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
      ),
    );
  }
}
