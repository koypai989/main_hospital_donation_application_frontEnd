import 'package:flutter/material.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/data/models/foundation.dart';
import 'package:project_final_411/features/donate_screen.dart';

class FoundationDetailScreen extends StatelessWidget {
  final Foundation foundation;

  const FoundationDetailScreen({super.key, required this.foundation});

  // โทนสี
  Color get primaryTeal => const Color(0xFF0A85A0);
  Color get bgColor => const Color(0xFFF5F8F8);
  Color get textDark => const Color(0xFF0F172A);
  Color get textMuted => const Color(0xFF64748B);

  String _formatAmount(double? amount) {
    if (amount == null) return '-';
    final String fixed = amount.toStringAsFixed(0);
    final RegExp reg = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return fixed.replaceAllMapped(reg, (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final String logoUrl = resolveImageUrl(foundation.logo);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        title: Text(
          'รายละเอียดมูลนิธิ',
          style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      // ปุ่มลอยบริจาค อยู่ล่างจอเสมอ
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DonateScreen(
              targetName: foundation.foundationName ?? 'มูลนิธิ',
              targetType: 'มูลนิธิ',
              qrCode: foundation.qrCode,
              foundationId: foundation.foundationId,
            ),
          ),
        ),
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.favorite, color: Colors.white),
        label: const Text(
          'บริจาค',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. ส่วนหัว (Logo และชื่อ) ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1E9EE),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryTeal.withOpacity(0.2), width: 2),
                      image: logoUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(logoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: logoUrl.isEmpty
                        ? Icon(Icons.volunteer_activism, size: 40, color: primaryTeal)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    foundation.foundationName ?? "ไม่ระบุชื่อมูลนิธิ",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. เกี่ยวกับมูลนิธิ ---
                  _buildSectionTitle(Icons.info_outline, "เกี่ยวกับมูลนิธิ"),
                  _buildInfoCard(foundation.description ?? "ไม่มีข้อมูลรายละเอียด"),

                  const SizedBox(height: 20),

                  // --- 3. เป้าหมายการรับบริจาค ---
                  _buildSectionTitle(Icons.flag_outlined, "เป้าหมายการรับบริจาค"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${_formatAmount(foundation.targetAmount)} บาท",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: primaryTeal),
                    ),
                  ),

                  // เผื่อพื้นที่ให้ปุ่มลอยด้านล่าง
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: primaryTeal, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        content,
        style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
      ),
    );
  }
}
