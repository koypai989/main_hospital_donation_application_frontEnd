import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/core/utils/validators.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage; // ข้อความแจ้งเตือนเมื่อเข้าสู่ระบบไม่สำเร็จ

  static const Color primaryColor = Color(0xFF0A85A0);
  static const Color textColor = Color(0xFF0F172A);
  static const Color subtitleColor = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color hintColor = Color(0xFF94A3B8);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // ล้างข้อความแจ้งเตือนเดิมก่อนเริ่มรอบใหม่
    setState(() => _errorMessage = null);

    // ตรวจรูปแบบอีเมล/รหัสผ่านก่อน ถ้าไม่ผ่านจะขึ้น error ใต้ช่องที่ผิดทุกช่อง
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final response = await DioClient.dio.post('/v1/users/login', data: {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });

      if (response.data['success'] == true && response.data['result'] != null) {
        final userData = response.data['result'];
        final prefs = await SharedPreferences.getInstance();

        await prefs.setInt('user_id', userData['userId']);
        await prefs.setString('user_email', userData['email']);
        await prefs.setString('user_role', userData['role']);

        // ดึงชื่อสำหรับแสดงผล — ถ้าพลาดก็ไม่ควรทำให้การเข้าสู่ระบบล้มเหลว
        try {
          if (userData['role'] == "DONATOR") {
            final donator = await DioClient.dio.get('/v1/donators/user/${userData['userId']}');
            await prefs.setString('name', donator.data['result']['firstName'] ?? '');
          } else if (userData['role'] == "HOSPITAL_ADMIN") {
            final hospital = await DioClient.dio.get('/v1/hospital-admins/user/${userData['userId']}');
            await prefs.setString('name', hospital.data['result']['firstName'] ?? '');
          } else if (userData['role'] == "ADMIN") {
            final admin = await DioClient.dio.get('/v1/system-admins/user/${userData['userId']}');
            await prefs.setString('name', admin.data['result']['fullName'] ?? '');
          }
        } catch (e) {
          print('ไม่สามารถดึงชื่อผู้ใช้: $e');
        }

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Mainscreen()),
        );
      } else {
        setState(() => _errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
      }
    } on DioException catch (e) {
      // backend ตอบ 401 เมื่ออีเมล/รหัสผ่านไม่ถูกต้อง
      setState(() {
        _errorMessage = e.response?.statusCode == 401
            ? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง'
            : friendlyDioErrorMessage(e);
      });
    } catch (e) {
      setState(() => _errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  const SizedBox(height: 32),

                  // แถบแจ้งเตือนเมื่อเข้าสู่ระบบไม่สำเร็จ
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 100,
                      validator: validateEmail,
                      decoration: const InputDecoration(
                        hintText: 'อีเมล',
                        hintStyle: TextStyle(color: hintColor),
                        prefixIcon: Icon(Icons.email_outlined, color: hintColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                        counterText: '', // ซ่อนตัวนับตัวอักษร
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      maxLength: 24,
                      validator: validatePassword,
                      decoration: InputDecoration(
                        hintText: 'รหัสผ่าน',
                        hintStyle: const TextStyle(color: hintColor),
                        prefixIcon: const Icon(Icons.lock_outline, color: hintColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: hintColor,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
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
      ),
    );
  }
}
