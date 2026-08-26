import 'package:flutter/material.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/core/utils/formatters.dart';
import 'package:project_final_411/data/models/donation.dart';
import 'package:project_final_411/data/sevices/donation_service.dart';
import 'package:project_final_411/data/sevices/donator_service.dart';
import 'package:project_final_411/features/certificate_view_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  final DonationService donationService = DonationService();
  final DonatorService donatorService = DonatorService();

  final Color primaryTeal = const Color(0xFF0A85A0);
  final Color bgColor = const Color(0xFFF5F8F8);
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF64748B);

  bool _isLoading = true;
  List<Donation> _donations = [];

  static const List<String> _thaiMonths = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');
      if (userId == null) {
        throw Exception('กรุณาเข้าสู่ระบบ');
      }

      final donator = await donatorService.getDonatorByUserId(userId);
      final String? citizenId = donator['citizenID']?.toString();
      if (citizenId == null || citizenId.isEmpty) {
        throw Exception('บัญชีนี้ไม่ใช่ผู้บริจาค');
      }

      final donations = await donationService.getDonationsByCitizenId(citizenId);
      // เรียงใหม่สุดก่อน
      donations.sort((a, b) {
        final da = a.donationDate ?? DateTime(1900);
        final db = b.donationDate ?? DateTime(1900);
        return db.compareTo(da);
      });

      setState(() => _donations = donations);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดประวัติไม่สำเร็จ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalAmount =>
      _donations.fold(0.0, (sum, d) => sum + (d.amount ?? 0));

  String _formatAmount(double? amount) {
    if (amount == null) return '-';
    final String fixed = amount.toStringAsFixed(0);
    final RegExp reg = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return fixed.replaceAllMapped(reg, (m) => '${m[1]},');
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    final String hh = d.hour.toString().padLeft(2, '0');
    final String mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_thaiMonths[d.month]} ${d.year + 543} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        title: Text(
          'ประวัติการบริจาค',
          style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : RefreshIndicator(
              color: primaryTeal,
              onRefresh: _loadData,
              child: _donations.isEmpty ? _buildEmptyState() : _buildList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(Icons.volunteer_activism_outlined, size: 64, color: textMuted.withOpacity(0.5)),
        const SizedBox(height: 16),
        Center(
          child: Text('ยังไม่มีประวัติการบริจาค',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('เมื่อคุณบริจาค รายการจะแสดงที่นี่',
              style: TextStyle(fontSize: 14, color: textMuted)),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // สรุปยอดรวม
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryTeal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('บริจาคทั้งหมด',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text('${_formatAmount(_totalAmount)} บาท',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${_donations.length} รายการ',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._donations.map(_buildDonationCard),
      ],
    );
  }

  Widget _buildDonationCard(Donation d) {
    final bool isFoundation = d.isFoundation;
    final Color badgeColor =
        isFoundation ? const Color(0xFF7C3AED) : primaryTeal;
    final String badgeText = isFoundation ? 'มูลนิธิ' : 'โรงพยาบาล';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFoundation ? Icons.volunteer_activism : Icons.local_hospital,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(badgeText,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isFoundation ? (d.targetName ?? 'ไม่ระบุปลายทาง') : withHospitalPrefix(d.targetName),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(d.donationDate),
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                // ปุ่มดู/ดาวน์โหลดใบอนุโมทนาบัตร
                if (d.certificatePath != null && d.certificatePath!.isNotEmpty)
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CertificateViewScreen(
                          certificateUrl: resolveImageUrl(d.certificatePath),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 15, color: primaryTeal),
                        const SizedBox(width: 4),
                        Text('ใบอนุโมทนาบัตร',
                            style: TextStyle(
                                color: primaryTeal,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${_formatAmount(d.amount)}',
            style: TextStyle(
                color: primaryTeal, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
