import 'dart:io';

import 'package:flutter/material.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/core/utils/formatters.dart';
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
  int? userId;
  String userEmail = "";
  String name = "";
  String role = "";
  bool isLoading = false;
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
        userEmail = prefs.getString('user_email') ?? 'Unknown';
        name = prefs.getString('name') ?? 'Unknown';
        role = prefs.getString('user_role') ?? 'Unknown';
        pendingHospitals = hospitals;
        print("ทดสอบๆ: $pendingHospitals");
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




  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF9FAFB);
    const Color primaryTeal = Color(0xFF0A85A0);
    const Color successGreen = Color(0xFF2A9D8F);
    const Color dangerRed = Color(0xFFEF4444);
    const Color textDark = Color(0xFF111827);
    const Color textMuted = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor, // สีพื้นหลังตามแบบ
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: textDark),
          onPressed: () {},
        ),
        title: const Text(
          'Pending Approvals',
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
            const Text(
              'New Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryTeal))
                  : pendingHospitals.isEmpty
                      ? const Center(
                          child: Text('ไม่มีรายการคำขอใหม่', style: TextStyle(color: textMuted)))
                      : ListView.builder(
                          itemCount: pendingHospitals.length,
                          itemBuilder: (context, index) {
                            final Hospital hospital = pendingHospitals[index];
                            final int? hospitalId = hospital.hospitalId;
                            final String? hospitalName = hospital.hospitalName;
                            final String? verificationStatus = hospital.verificationStatus;
                            final String? verificationDoc = hospital.verificationDoc;
                            final String? logo = hospital.logo;

                            String logoUrl = "";
                            if (logo != null && logo.isNotEmpty) {
                              logoUrl = resolveImageUrl(logo);
                            }

                            String docUrl = "";
                            String docNameDisplay = 'ไม่มีเอกสารแนบ';
                            if (verificationDoc != null && verificationDoc.isNotEmpty) {
                              docUrl = resolveImageUrl(verificationDoc);
                              docNameDisplay = verificationDoc.split('/').last;
                              print("docname = "+docUrl);
                            }

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
                                  // --- 1. ส่วนหัว (เปลี่ยน Icon เป็นแสดง Logo จริง) ---
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
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
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              withHospitalPrefix(hospitalName),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textDark,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'ID: #REQ-${hospitalId ?? '-'}',
                                              style: const TextStyle(fontSize: 13, color: textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                    child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                                  ),

                                  // --- 2. Status ---
                                  const Text('Status', style: TextStyle(fontSize: 12, color: textMuted)),
                                  const SizedBox(height: 4),
                                  Text(
                                    verificationStatus ?? 'N/A',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
                                  ),
                                  const SizedBox(height: 16),

                                  // --- 3. เอกสารแนบ (โชว์รูปหรือให้กดเปิดดู) ---
                                  const Text('Verification Document', style: TextStyle(fontSize: 12, color: textMuted)),
                                  const SizedBox(height: 8),
                                  
                                  if (docUrl.isNotEmpty && (docUrl.endsWith('.jpg') || docUrl.endsWith('.png')))
                                    Container(
                                      height: 120, // ความสูงของรูปเอกสาร
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          docUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    // ถ้าไม่ใช่รูปภาพ (เช่น เป็น PDF หรือไม่มีไฟล์) ให้โชว์ชื่อไฟล์เฉยๆ
                                    Row(
                                      children: [
                                        const Icon(Icons.attach_file, size: 16, color: primaryTeal),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            docNameDisplay,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: primaryTeal,
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 24),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            if (hospitalId != null) {
                                              hospitalService.rejectHospital(hospitalId);
                                              _loadUserData();
                                              print("Rejecting Hospital ID: $hospitalId");
                                            }
                                          },
                                          icon: const Icon(Icons.close, color: dangerRed, size: 18),
                                          label: const Text('Reject', style: TextStyle(color: dangerRed)),
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
                                          onPressed: () {
                                            if (hospitalId != null) {
                                              hospitalService.approveHospital(hospitalId);
                                              _loadUserData();
                                              print("Approving Hospital ID: $hospitalId");
                                            }
                                          },
                                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                                          label: const Text('Approve', style: TextStyle(color: Colors.white)),
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
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFF0A85A0),
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
            const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'อนุมัติ'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}
