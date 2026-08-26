import 'package:flutter/material.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/core/utils/formatters.dart';
import 'package:project_final_411/data/models/foundation.dart';
import 'package:project_final_411/data/models/hospital.dart';
import 'package:project_final_411/data/sevices/foundation_service.dart';
import 'package:project_final_411/data/sevices/hospital_service.dart';
import 'package:project_final_411/features/donate_screen.dart';
import 'package:project_final_411/features/foundation_detail_screen.dart';

class HospitalDetailScreen extends StatefulWidget {
  final int hospitalId; // 🌟 รับ ID ของโรงพยาบาลมาเพื่อดึงข้อมูล

  const HospitalDetailScreen({super.key, required this.hospitalId});

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  final HospitalService hospitalService = HospitalService();
  final FoundationService foundationService = FoundationService();
  bool isLoading = true;
  Hospital? hospital;
  List<Foundation> foundations = [];

  // โทนสี
  final Color primaryTeal = const Color(0xFF0A85A0);
  final Color bgColor = const Color(0xFFF5F8F8);
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _fetchHospitalDetail();
  }

  Future<void> _fetchHospitalDetail() async {
    try {
      var result = await hospitalService.getHospitalById(widget.hospitalId);

      // ดึงรายการมูลนิธิของโรงพยาบาลนี้ (ถ้าล้มเหลวก็ยังแสดงข้อมูลโรงพยาบาลได้)
      List<Foundation> foundationResult = [];
      try {
        foundationResult = await foundationService.getFoundationsByHospitalId(widget.hospitalId);
      } catch (e) {
        print("Error fetching foundations: $e");
      }

      setState(() {
        hospital = result;
        foundations = foundationResult;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching hospital detail: $e");
      setState(() => isLoading = false);
      // TODO: อาจจะเพิ่ม SnackBar แจ้งเตือน Error ตรงนี้
    }
  }

  // ฟังก์ชันช่วยจัดการ URL รูปภาพ
  String _getImageUrl(String? path) {
    return resolveImageUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      // ปุ่มลอยบริจาค อยู่ล่างจอเสมอ (แสดงเมื่อโหลดข้อมูลโรงพยาบาลแล้ว)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: hospital == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DonateScreen(
                    targetName: withHospitalPrefix(hospital!.hospitalName),
                    targetType: 'โรงพยาบาล',
                    qrCode: hospital!.qrCode,
                    hospitalId: hospital!.hospitalId,
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        title: Text(
          'รายละเอียดโรงพยาบาล',
          style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : hospital == null
              ? const Center(child: Text("ไม่พบข้อมูลโรงพยาบาล"))
              : SingleChildScrollView(
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
                                image: _getImageUrl(hospital!.logo).isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(_getImageUrl(hospital!.logo)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _getImageUrl(hospital!.logo).isEmpty
                                  ? const Icon(Icons.local_hospital, size: 40, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              withHospitalPrefix(hospital!.hospitalName),
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "รหัสอ้างอิง: REQ-${hospital!.hospitalId}",
                                style: TextStyle(color: primaryTeal, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- 2. ข้อมูลทั่วไป ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(Icons.info_outline, "เกี่ยวกับโรงพยาบาล"),
                            _buildInfoCard(hospital!.description ?? "ไม่มีข้อมูลรายละเอียด"),

                            const SizedBox(height: 20),

                            _buildSectionTitle(Icons.location_on_outlined, "ที่อยู่ติดต่อ"),
                            _buildInfoCard(hospital!.address ?? "ไม่มีข้อมูลที่อยู่"),

                            const SizedBox(height: 24),

                            // --- 3. รายการมูลนิธิของโรงพยาบาล ---
                            const Divider(thickness: 1),
                            const SizedBox(height: 16),
                            _buildSectionTitle(Icons.volunteer_activism_outlined, "มูลนิธิของโรงพยาบาล"),
                            _buildFoundationList(),

                            const SizedBox(height: 90), // เผื่อพื้นที่ให้ปุ่มลอย
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // Helper สร้างหัวข้อ
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

  // Helper สร้างกล่องข้อความ
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

  // Helper แสดงรายการมูลนิธิของโรงพยาบาลนี้
  Widget _buildFoundationList() {
    if (foundations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "โรงพยาบาลนี้ยังไม่มีมูลนิธิ",
            style: TextStyle(color: textMuted, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: foundations.map(_buildFoundationCard).toList(),
    );
  }

  Widget _buildFoundationCard(Foundation foundation) {
    final String imageUrl = _getImageUrl(foundation.logo);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoundationDetailScreen(foundation: foundation),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFD1E9EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.volunteer_activism, color: primaryTeal),
                    )
                  : Icon(Icons.volunteer_activism, color: primaryTeal),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foundation.foundationName ?? "ไม่ระบุชื่อมูลนิธิ",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  foundation.description ?? "ไม่มีรายละเอียด",
                  style: TextStyle(color: textMuted, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 15, color: primaryTeal),
                    const SizedBox(width: 4),
                    Text(
                      "เป้าหมาย ${_formatAmount(foundation.targetAmount)} บาท",
                      style: TextStyle(
                          color: primaryTeal, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: textMuted),
        ],
      ),
      ),
    );
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '-';
    final String fixed = amount.toStringAsFixed(0);
    final RegExp reg = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return fixed.replaceAllMapped(reg, (m) => '${m[1]},');
  }
}
