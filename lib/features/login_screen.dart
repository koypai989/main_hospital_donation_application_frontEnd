import 'package:flutter/material.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/features/main_screen.dart';
import 'package:project_final_411/features/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0A85A0);
    const Color textColor = Color(0xFF0F172A);
    const Color subtitleColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'ยินดีต้อนรับ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'กรุณาเข้าสู่ระบบเพื่อดำเนินการต่อ',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 48),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'อีเมล',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'รหัสผ่าน',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final response = await DioClient.dio.post('/v1/users/login', data: {
                          'email': emailController.text,
                          'password': passwordController.text,
                        });

                        if (response.data['success'] == true && response.data['result'] != null) {
                    
                          final userData = response.data['result']; 
                          
                          final prefs = await SharedPreferences.getInstance();

                          await prefs.setInt('user_id', userData['userId']); 
                          await prefs.setString('user_email', userData['email']);
                          await prefs.setString('user_role', userData['role']);
                          if(userData['role'] == "DONATOR"){
                            final donator = await DioClient.dio.get('/v1/donators/user/${userData['userId']}');
                            print("Donator Name: ${donator.data['result']['firstName']}");
                            await prefs.setString('name', donator.data['result']['firstName']);

                          }else if(userData['role'] == "HOSPITAL_ADMIN"){

                            final hospital = await DioClient.dio.get('/v1/hospital-admins/user/${userData['userId']}');
                            print("Hospital ADMIN Name: ${hospital.data['result']['firstName']}");
                            await prefs.setString('name', hospital.data['result']['firstName']);

                          }else if(userData['role'] == "ADMIN"){
                            final admin = await DioClient.dio.get('/v1/system-admins/user/${userData['userId']}');
                            print(admin.data['result']);
                            print("ADMIN Name: ${admin.data['result']['fullName']}");
                            await prefs.setString('name', admin.data['result']['fullName']);
                          }
                           

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Mainscreen()),
                          );

                        } else {
                          print('รหัสผ่าน หรือ อีเมล ไม่ถูกต้อง');
                        }
                      } catch (e) {
                        print('เกิดข้อผิดพลาด: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ยังไม่มีบัญชีใช่ไหม? ',
                      style: TextStyle(color: subtitleColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation1, animation2) => RegisterScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                      child: const Text(
                        'สมัครเลย',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      
    );
  }
}