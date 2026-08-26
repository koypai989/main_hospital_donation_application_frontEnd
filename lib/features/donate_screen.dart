import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/data/sevices/donation_service.dart';
import 'package:project_final_411/data/sevices/donator_service.dart';
import 'package:project_final_411/features/certificate_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// หน้าบริจาค — ใช้ร่วมกันทั้งการบริจาคให้โรงพยาบาลและมูลนิธิ
// แนบสลิป -> ส่งให้ backend เรา -> backend เรียก slip-c ตรวจสอบ -> บันทึก donation
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

  final TextEditingController _amountCtrl = TextEditingController();
  final List<int> _quickAmounts = [100, 500, 1000, 2000];
  int? _selectedQuick;

  File? _slip;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _selectQuick(int amount) {
    setState(() {
      _selectedQuick = amount;
      _amountCtrl.text = amount.toString();
    });
  }

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

  // แตะ QR เพื่อขยายเต็มจอ (ซูมได้)
  void _showZoomedQr(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.qr_code_2, size: 160, color: Colors.white70),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDonation() async {
    // ตรวจ input
    final int? amount = int.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _snack('กรุณากรอกจำนวนเงินให้ถูกต้อง');
      return;
    }
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

      final Map<String, dynamic> payload = {
        'amount': amount.toDouble(),
        'citizenId': citizenId,
        'hospitalId': widget.hospitalId,
        'foundationId': widget.foundationId,
        'slipBase64': dataUri,
      };

      final result = await donationService.createDonation(payload);
      final String? certPath = result?['certificatePath'] as String?;

      if (!mounted) return;
      _snack('บริจาคสำเร็จ ขอบคุณสำหรับน้ำใจ 🙏');

      if (certPath != null && certPath.isNotEmpty) {
        // เปิดใบอนุโมทนาบัตรให้ดู/ดาวน์โหลดทันที
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CertificateViewScreen(
              certificateUrl: resolveImageUrl(certPath),
            ),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
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
    final bool isFoundation = widget.targetType == 'มูลนิธิ';
    final Color badgeColor =
        isFoundation ? const Color(0xFF7C3AED) : primaryTeal;
    final String qrUrl = resolveImageUrl(widget.qrCode);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        title: Text(
          'บริจาค',
          style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isSubmitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
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

              // --- จำนวนเงิน ---
              _buildSectionHeader('จำนวนเงินที่โอน (ต้องตรงกับสลิป)'),
              Container(
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() => _selectedQuick = null),
                        decoration: InputDecoration(
                          hintText: '0',
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((amount) {
                  final bool selected = _selectedQuick == amount;
                  return ChoiceChip(
                    label: Text('$amount'),
                    selected: selected,
                    onSelected: (_) => _selectQuick(amount),
                    selectedColor: primaryTeal,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: selected ? primaryTeal : borderColor),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // --- ช่องทางการชำระเงิน (QR) ---
              _buildSectionHeader('ช่องทางการชำระเงิน'),
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
                          onTap: () => _showZoomedQr(qrUrl),
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
                        qrUrl.isNotEmpty ? 'แตะที่ QR เพื่อขยาย' : 'สแกนเพื่อชำระเงิน',
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

              const SizedBox(height: 8),
              Center(
                child: Text(
                  '* ระบบจะตรวจสอบสลิปอัตโนมัติ อาจใช้เวลาถึง 1-2 นาที กรุณารอสักครู่',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
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
          ),
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
