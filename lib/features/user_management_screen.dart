import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:project_final_411/core/network/dio_client.dart';
import 'package:project_final_411/data/models/users.dart';
import 'package:project_final_411/data/sevices/users_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UsersService usersService = UsersService();

  final Color primaryTeal = const Color(0xFF0A85A0);
  final Color bgColor = const Color(0xFFF5F8F8);
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF64748B);

  static const List<String> _roles = ['DONATOR', 'HOSPITAL_ADMIN', 'ADMIN'];

  bool _isLoading = true;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await usersService.getAllUser();
      setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดรายชื่อผู้ใช้ไม่สำเร็จ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _roleThai(String? role) {
    switch ((role ?? '').toUpperCase()) {
      case 'ADMIN':
        return 'ผู้ดูแลระบบ';
      case 'HOSPITAL_ADMIN':
        return 'ผู้ดูแลโรงพยาบาล';
      case 'DONATOR':
        return 'ผู้บริจาค';
      default:
        return role ?? '-';
    }
  }

  Color _roleColor(String? role) {
    switch ((role ?? '').toUpperCase()) {
      case 'ADMIN':
        return Colors.purple;
      case 'HOSPITAL_ADMIN':
        return primaryTeal;
      default:
        return Colors.orange;
    }
  }

  Future<void> _openEditDialog(User user) async {
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final passwordCtrl = TextEditingController();
    String selectedRole = _roles.contains((user.role ?? '').toUpperCase())
        ? user.role!.toUpperCase()
        : _roles.first;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('แก้ไขผู้ใช้'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'บทบาท (role)',
                        border: OutlineInputBorder(),
                      ),
                      items: _roles
                          .map((r) => DropdownMenuItem(value: r, child: Text(_roleThai(r))))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedRole = v ?? selectedRole),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'รหัสผ่านใหม่ (เว้นว่างถ้าไม่เปลี่ยน)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          try {
                            final Map<String, dynamic> data = {
                              'email': emailCtrl.text.trim(),
                              'role': selectedRole,
                            };
                            if (passwordCtrl.text.isNotEmpty) {
                              data['password'] = passwordCtrl.text;
                            }
                            await usersService.updateUser(user.id!, data);
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('บันทึกสำเร็จ')),
                              );
                              _loadData();
                            }
                          } on DioException catch (e) {
                            setDialogState(() => saving = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('บันทึกไม่สำเร็จ: ${friendlyDioErrorMessage(e)}')),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => saving = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('ผิดพลาด: ${e.toString()}')),
                              );
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('บันทึก', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
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
          'จัดการผู้ใช้',
          style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : RefreshIndicator(
              color: primaryTeal,
              onRefresh: _loadData,
              child: _users.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(child: Text('ไม่มีผู้ใช้', style: TextStyle(color: textMuted))),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) => _buildUserCard(_users[index]),
                    ),
            ),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(user.role).withOpacity(0.12),
          child: Icon(Icons.person, color: _roleColor(user.role)),
        ),
        title: Text(user.email ?? '-',
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('ID: ${user.id}  •  ${_roleThai(user.role)}',
            style: TextStyle(color: textMuted, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _roleColor(user.role).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_roleThai(user.role),
              style: TextStyle(color: _roleColor(user.role), fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        onTap: () => _openEditDialog(user),
      ),
    );
  }
}
