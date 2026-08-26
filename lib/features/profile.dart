import 'package:flutter/material.dart';
import 'package:project_final_411/features/approval_screen.dart';
import 'package:project_final_411/features/donation_history_screen.dart';
import 'package:project_final_411/features/edit_user_screen.dart';
import 'package:project_final_411/features/list_foundation_screen.dart';
import 'package:project_final_411/features/login_screen.dart';
import 'package:project_final_411/features/main_screen.dart';
import 'package:project_final_411/features/user_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  int? userId;
  String userEmail = "";
  String name = "";
  String role = "";
  bool isLoading = false;
  
  // โทนสีหลัก
  final Color primaryTeal = const Color(0xFF0A85A0);
  final Color bgColor = const Color(0xFFF9FAFB);
  final Color textDark = const Color(0xFF0F172A);

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

      setState(() {
        userId = prefs.getInt('user_id');
        userEmail = prefs.getString('user_email') ?? 'Unknown';
        name = prefs.getString('name') ?? 'Unknown';
        role = prefs.getString('user_role') ?? 'Unknown';
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

  // 🌟 ฟังก์ชันแปลงชื่อ Role ให้เป็นภาษาไทย (เพิ่มของ Guest เข้าไป)
  String _getRoleNameThai(String role) {
    if (userId == null) return 'บุคคลทั่วไป (Guest)';
    
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'ผู้ดูแลระบบ';
      case 'HOSPITAL_ADMIN':
        return 'ผู้ดูแลโรงพยาบาล';
      default:
        return 'ผู้บริจาค (Donator)';
    }
  }

  // 🌟 ฟังก์ชันเลือกสีป้าย Tag
  Color _getRoleColor(String role) {
    if (userId == null) return Colors.grey;
    if (role.toUpperCase() == 'ADMIN') return Colors.purple;
    if (role.toUpperCase() == 'HOSPITAL_ADMIN') return const Color(0xFF0A85A0);
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'โปรไฟล์ของฉัน',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // --- 1. ส่วนหัว (แสดงข้อมูลผู้ใช้ หรือ Guest) ---
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: userId == null ? Colors.grey.shade200 : primaryTeal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            userId == null ? Icons.person_outline : Icons.person, 
                            size: 50, 
                            color: userId == null ? Colors.grey : primaryTeal
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userId == null ? "ยินดีต้อนรับ" : name,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userId == null ? "กรุณาเข้าสู่ระบบเพื่อใช้งานเต็มรูปแบบ" : userEmail,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getRoleColor(role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRoleNameThai(role),
                            style: TextStyle(
                              color: _getRoleColor(role),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- 2. ส่วนเมนู (แยกตามสถานะการล็อกอิน) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                          child: Text('เมนูการใช้งาน', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: _buildMenuItems(),
                          ),
                        ),

                        const SizedBox(height: 32),
                        userId == null
                            ? _buildLoginButton()
                            : _buildLogoutButton(),
                            
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: role.toUpperCase() == 'ADMIN' ? 2 : 1, 
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

  // 🌟 จัดการเมนูที่จะแสดง
  List<Widget> _buildMenuItems() {
    List<Widget> menuList = [];

    if (userId == null) {
      return menuList;
    }

    if (role.toUpperCase() == 'ADMIN') {
      menuList.addAll([
        _buildMenuTile(Icons.approval_rounded, "อนุมัติ"),
        _buildMenuTile(Icons.manage_accounts_outlined, "จัดการผู้ใช้", isLast: true),
      ]);
    } else if (role.toUpperCase() == 'HOSPITAL_ADMIN') {
      menuList.addAll([
        _buildMenuTile(Icons.volunteer_activism_outlined, 'จัดการมูลนิธิ'),
        _buildMenuTile(Icons.edit_outlined, 'แก้ไขข้อมูลผู้ใช้', isLast: true),
      ]);
    }else{
          menuList.addAll([
            _buildMenuTile(Icons.receipt_long_outlined, 'ประวัติการบริจาค'),
            _buildMenuTile(Icons.edit_outlined, 'แก้ไขข้อมูลผู้ใช้', isLast: true),
          ]);
    }



    return menuList;
  }

  // Helper สร้างปุ่มเมนู
  Widget _buildMenuTile(IconData icon, String title, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: primaryTeal),
          title: Text(title, style: TextStyle(color: textDark, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            print("กดเมนู: $title");
            if (title == "อนุมัติ"){
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) => ApprovalScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            } else if (title == "จัดการมูลนิธิ"){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListFoundationScreen(),
                ),
              );
            } else if (title == "ประวัติการบริจาค"){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DonationHistoryScreen(),
                ),
              );
            } else if (title == "จัดการผู้ใช้"){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              );
            }else{
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) => EditUserScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }

  // Helper ปุ่ม Login (โค้ดของคุณ)
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        icon: const Icon(Icons.login),
        label: const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A85A0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Helper ปุ่ม Logout (โค้ดของคุณ)
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('ออกจากระบบ', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.redAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}