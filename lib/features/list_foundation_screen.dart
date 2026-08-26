import 'package:flutter/material.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/data/models/foundation.dart';
import 'package:project_final_411/data/sevices/foundation_service.dart';
import 'package:project_final_411/features/create_foundation_screen.dart';
import 'package:project_final_411/features/edit_foundation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListFoundationScreen extends StatefulWidget {
  const ListFoundationScreen({super.key});

  @override
  State<ListFoundationScreen> createState() => _ListFoundationScreenState();
}

class _ListFoundationScreenState extends State<ListFoundationScreen> {
  final FoundationService foundationService = FoundationService();

  final Color primaryTeal = const Color(0xFF0A85A0);
  final Color bgColor = const Color(0xFFF5F8F8);
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF64748B);

  bool _isLoading = true;
  int? _hospitalId;
  List<Foundation> _foundations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      }

      // ดึง hospitalId ของผู้ดูแลโรงพยาบาลที่ล็อกอินอยู่
      final adminResponse = await DioClient.dio.get('/v1/hospital-admins/user/$userId');
      final hospital = adminResponse.data['result']?['hospital'];
      final int? hospitalId = hospital?['hospitalId'];
      if (hospitalId == null) {
        throw Exception('ไม่พบโรงพยาบาลที่สังกัด');
      }

      final foundations = await foundationService.getFoundationsByHospitalId(hospitalId);

      setState(() {
        _hospitalId = hospitalId;
        _foundations = foundations;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateFoundation() async {
    if (_hospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่พบโรงพยาบาลที่สังกัด กรุณาลองใหม่')),
      );
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateFoundationScreen(hospitalId: _hospitalId!),
      ),
    );
    if (result == true) {
      _loadData(); // รีเฟรชรายการหลังสร้างสำเร็จ
    }
  }

  Future<void> _openEditFoundation(Foundation foundation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditFoundationScreen(foundation: foundation),
      ),
    );
    if (result == true) {
      _loadData(); // รีเฟรชรายการหลังแก้ไขสำเร็จ
    }
  }

  // ยืนยันก่อนลบ แล้วค่อยเรียก API ลบ
  Future<void> _confirmDeleteFoundation(Foundation foundation) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text(
          'ต้องการลบมูลนิธิ "${foundation.foundationName ?? ''}" ใช่หรือไม่?\nการลบไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await foundationService.deleteFoundation(foundation.foundationId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบมูลนิธิสำเร็จ')),
      );
      _loadData(); // รีเฟรชรายการหลังลบ
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: ${e.toString()}')),
      );
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
          'จัดการมูลนิธิ',
          style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        color: primaryTeal,
        onRefresh: _loadData,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryTeal))
            : _foundations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _foundations.length,
                    itemBuilder: (context, index) => _buildFoundationCard(_foundations[index]),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateFoundation,
        backgroundColor: primaryTeal,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      // ใช้ ListView เพื่อให้ RefreshIndicator ทำงานได้แม้ไม่มีข้อมูล
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(Icons.domain_add, size: 64, color: textMuted.withOpacity(0.5)),
        const SizedBox(height: 16),
        Center(
          child: Text('ยังไม่มีมูลนิธิ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('กดปุ่ม + เพื่อสร้างมูลนิธิใหม่',
              style: TextStyle(fontSize: 14, color: textMuted)),
        ),
      ],
    );
  }

  Widget _buildFoundationCard(Foundation foundation) {
    final String imageUrl = resolveImageUrl(foundation.logo);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openEditFoundation(foundation), // แตะที่การ์ดเพื่อแก้ไข
          borderRadius: BorderRadius.circular(16),
          child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFD1E9EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foundation.foundationName ?? 'ไม่ระบุชื่อมูลนิธิ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    foundation.description ?? 'ไม่มีรายละเอียด',
                    style: TextStyle(color: textMuted, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 16, color: primaryTeal),
                      const SizedBox(width: 4),
                      Text(
                        'เป้าหมาย ${_formatAmount(foundation.targetAmount)} บาท',
                        style: TextStyle(
                            color: primaryTeal, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _confirmDeleteFoundation(foundation),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'ลบมูลนิธิ',
            ),
          ],
        ),
      ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '-';
    final String fixed = amount.toStringAsFixed(0);
    // ใส่ comma คั่นหลักพัน
    final RegExp reg = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return fixed.replaceAllMapped(reg, (m) => '${m[1]},');
  }
}
