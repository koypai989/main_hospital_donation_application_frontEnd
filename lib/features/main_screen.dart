import 'package:flutter/material.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/core/utils/formatters.dart';
import 'package:project_final_411/data/models/foundation.dart';
import 'package:project_final_411/data/models/hospital.dart';
import 'package:project_final_411/data/sevices/foundation_service.dart';
import 'package:project_final_411/data/sevices/hospital_service.dart';
import 'package:project_final_411/data/sevices/users_service.dart';
import 'package:project_final_411/features/approval_screen.dart';
import 'package:project_final_411/features/foundation_detail_screen.dart';
import 'package:project_final_411/features/hospital_detail_screen.dart';
import 'package:project_final_411/features/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ประเภทของรายการในหน้าหลัก
enum FeedType { hospital, foundation }

// รายการรวมในหน้าหลัก (โรงพยาบาล + มูลนิธิ) เพื่อแสดงปนกันแบบสุ่ม
class FeedItem {
  final FeedType type;
  final String title;
  final String description;
  final String? logo;
  final String? subtitle; // ชื่อโรงพยาบาลที่มูลนิธิสังกัด (เฉพาะมูลนิธิ)
  final Hospital? hospital;
  final Foundation? foundation;

  FeedItem.hospital(Hospital h)
      : type = FeedType.hospital,
        title = withHospitalPrefix(h.hospitalName),
        description = h.description ?? 'ไม่มีรายละเอียดเพิ่มเติม',
        logo = h.logo,
        subtitle = null,
        hospital = h,
        foundation = null;

  FeedItem.foundation(Foundation f, String? hospitalName)
      : type = FeedType.foundation,
        title = f.foundationName ?? 'ไม่ระบุชื่อมูลนิธิ',
        description = f.description ?? 'ไม่มีรายละเอียดเพิ่มเติม',
        logo = f.logo,
        subtitle = hospitalName,
        hospital = null,
        foundation = f;
}

class Mainscreen extends StatefulWidget {
  const Mainscreen({super.key});

  @override
  State<Mainscreen> createState() => _MainscreenState();
}

class _MainscreenState extends State<Mainscreen> {
  final UsersService usersService = UsersService();
  final HospitalService hospitalService = HospitalService();
  final FoundationService foundationService = FoundationService();
  final TextEditingController _searchController = TextEditingController();
  int? userId;
  String userEmail = "";
  String name = "";
  String role = "";

  bool isLoading = false;

  List<FeedItem> _allItems = []; // ข้อมูลทั้งหมด (ไว้ค้นหา)
  List<FeedItem> _items = []; // ข้อมูลที่แสดงจริง (หลังกรอง/ค้นหา)
  FeedType? _selectedTypeFilter; // null = ทั้งหมด (ค่าเริ่มต้น)
  List<Hospital> _suggested = []; // โรงพยาบาลแนะนำ (ได้รับบริจาคน้อยที่สุด)

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();

      final hospitalResponse = await hospitalService.getApprovedHospitals();

      // โรงพยาบาลแนะนำ (ได้รับบริจาคน้อยที่สุด) — ถ้าพลาดก็ยังแสดงหน้าหลักได้
      List<Hospital> suggestedResponse = [];
      try {
        suggestedResponse = await hospitalService.getSuggestedHospitals(limit: 5);
      } catch (e) {
        print('Error loading suggested hospitals: $e');
      }

      // ดึงมูลนิธิทั้งหมด (ถ้าพลาดก็ยังแสดงโรงพยาบาลได้)
      List<Foundation> foundationResponse = [];
      try {
        foundationResponse = await foundationService.getAllFoundations();
      } catch (e) {
        print('Error loading foundations: $e');
      }

      // map hospitalId -> ชื่อ (เฉพาะโรงพยาบาลที่อนุมัติแล้ว)
      final Set<int> approvedIds = {
        for (final h in hospitalResponse)
          if (h.hospitalId != null) h.hospitalId!
      };
      final Map<int, String> hospitalNameById = {
        for (final h in hospitalResponse)
          if (h.hospitalId != null) h.hospitalId!: (h.hospitalName ?? '')
      };

      // รวมโรงพยาบาล + มูลนิธิ (แสดงเฉพาะมูลนิธิของโรงพยาบาลที่อนุมัติแล้ว)
      final List<FeedItem> items = [];
      for (final h in hospitalResponse) {
        items.add(FeedItem.hospital(h));
      }
      for (final f in foundationResponse) {
        if (f.hospitalId != null && approvedIds.contains(f.hospitalId)) {
          final String? rawHospitalName = (f.hospitalName != null && f.hospitalName!.isNotEmpty)
              ? f.hospitalName
              : hospitalNameById[f.hospitalId];
          final String? hName = rawHospitalName != null && rawHospitalName.isNotEmpty
              ? withHospitalPrefix(rawHospitalName)
              : null;
          items.add(FeedItem.foundation(f, hName));
        }
      }
      items.shuffle(); // สุ่มลำดับให้ปนกัน

      setState(() {
        userId = prefs.getInt('user_id');
        // ถ้ายังไม่ได้เข้าสู่ระบบ (ผู้เยี่ยมชม) ให้เป็นค่าว่าง ไม่ใช่ "Unknown"
        userEmail = prefs.getString('user_email') ?? '';
        name = prefs.getString('name') ?? '';
        role = prefs.getString('user_role') ?? '';
        _suggested = suggestedResponse;
        _allItems = items;
        _items = List.from(items);
        print("User ID: $userId, Email: $userEmail, Name: $name, Role: $role");
      });
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ค้นหาแบบ client-side ให้เจอทั้งโรงพยาบาลและมูลนิธิ (ตามชื่อ + ชื่อโรงพยาบาลของมูลนิธิ)
  void _onSearchChanged(String query) {
    _applyFilters();
  }

  void _onFilterChanged(FeedType? type) {
    setState(() => _selectedTypeFilter = type);
    _applyFilters();
  }

  // รวมทั้งตัวกรองประเภท (โรงพยาบาล/มูลนิธิ) และคำค้นหาเข้าด้วยกัน
  void _applyFilters() {
    final String q = _searchController.text.trim().toLowerCase();
    setState(() {
      _items = _allItems.where((item) {
        final bool matchesType =
            _selectedTypeFilter == null || item.type == _selectedTypeFilter;
        if (!matchesType) return false;
        if (q.isEmpty) return true;
        final bool matchTitle = item.title.toLowerCase().contains(q);
        final bool matchHospital =
            item.subtitle?.toLowerCase().contains(q) ?? false;
        return matchTitle || matchHospital;
      }).toList();
    });
  }

  void _openDetail(FeedItem item) {
    if (item.type == FeedType.hospital) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HospitalDetailScreen(hospitalId: item.hospital!.hospitalId!),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FoundationDetailScreen(foundation: item.foundation!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F8),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------
            // 1. ส่วน Header พื้นหลังสีเขียวอมน้ำเงิน
            // ----------------------------------------
            Container(
              padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
              decoration: const BoxDecoration(
                color: Color(0xFF0A85A0),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สวัสดี 👋',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          Text(
                            name.isNotEmpty ? name : 'ผู้เยี่ยมชม',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.local_hospital, color: Colors.white),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  // ช่องค้นหา
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'ค้นหาโรงพยาบาลหรือมูลนิธิ...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                  FocusScope.of(context).unfocus();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // แนะนำโรงพยาบาลที่ยังได้รับบริจาคน้อย (ซ่อนตอนกำลังค้นหา)
            if (!isLoading && _suggested.isNotEmpty && _searchController.text.trim().isEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'โรงพยาบาลที่ยังได้รับบริจาคน้อย',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 4),
                child: Text(
                  'ร่วมเป็นกำลังใจให้โรงพยาบาลเหล่านี้',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 182,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  itemCount: _suggested.length,
                  itemBuilder: (context, index) => _buildSuggestedCard(_suggested[index]),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'โรงพยาบาลและมูลนิธิในระบบ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('ทั้งหมด', null),
                  _buildFilterChip('โรงพยาบาล', FeedType.hospital),
                  _buildFilterChip('มูลนิธิ', FeedType.foundation),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                ),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'ไม่พบผลลัพธ์',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) => _buildFeedCard(_items[index]),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF0A85A0),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          Widget? nextScreen;

          if (role == 'ADMIN') {
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
          if (role == 'ADMIN')
            const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'อนุมัติ'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard(Hospital h) {
    final String imageUrl = resolveImageUrl(h.logo);
    return GestureDetector(
      onTap: () {
        if (h.hospitalId == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HospitalDetailScreen(hospitalId: h.hospitalId!),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 96,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFD1E9EE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.local_hospital, size: 36, color: Colors.white),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.local_hospital, size: 36, color: Colors.white),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    withHospitalPrefix(h.hospitalName),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 13, color: Color(0xFF0A85A0)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'รอการสนับสนุน',
                          style: const TextStyle(
                              color: Color(0xFF0A85A0), fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, FeedType? type) {
    final bool selected = _selectedTypeFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _onFilterChanged(type),
      selectedColor: const Color(0xFF0A85A0),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF0F172A),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? const Color(0xFF0A85A0) : const Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildFeedCard(FeedItem item) {
    final bool isFoundation = item.type == FeedType.foundation;
    final String imageUrl = resolveImageUrl(item.logo);
    final Color badgeColor =
        isFoundation ? const Color(0xFF7C3AED) : const Color(0xFF0A85A0);
    final String badgeText = isFoundation ? 'มูลนิธิ' : 'โรงพยาบาล';
    final IconData fallbackIcon =
        isFoundation ? Icons.volunteer_activism : Icons.local_hospital;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // พื้นที่รูปภาพ
          Container(
            height: 144,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFD1E9EE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(fallbackIcon, size: 48, color: Colors.white),
                        );
                      },
                    )
                  : Center(
                      child: Icon(fallbackIcon, size: 48, color: Colors.white),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ป้ายบอกประเภท (โรงพยาบาล / มูลนิธิ)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // มูลนิธิ: บอกว่าเป็นของโรงพยาบาลอะไร
                if (isFoundation && item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.local_hospital, size: 14, color: Color(0xFF0A85A0)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'โดย ${item.subtitle}',
                          style: const TextStyle(
                              color: Color(0xFF0A85A0),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _openDetail(item),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0A85A0), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      'ดูรายละเอียด',
                      style: TextStyle(
                        color: Color(0xFF0A85A0),
                        fontWeight: FontWeight.bold,
                      ),
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
}
