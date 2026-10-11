// กฎตรวจสอบข้อมูลการเข้าสู่ระบบ (ใช้ร่วมกันทั้งหน้าเข้าสู่ระบบและหน้าสมัคร
// เพื่อไม่ให้สมัครผ่านแต่ล็อกอินไม่ได้)

// อีเมล
// 1. ต้องมีชื่อผู้ใช้ + @ + ชื่อโดเมน (เช่น user@example.com)
// 2. ยาวไม่เกิน 100 ตัวอักษร
// 3. ต้องไม่มีอักขระพิเศษที่ไม่อนุญาตตามมาตรฐานอีเมล
// 4. ต้องไม่เป็นค่าว่าง
String? validateEmail(String? value) {
  final String email = value?.trim() ?? '';

  if (email.isEmpty) return 'กรุณากรอกอีเมล';
  if (email.length > 100) return 'อีเมลต้องยาวไม่เกิน 100 ตัวอักษร';

  // ชุดอักขระที่อนุญาตตามมาตรฐานอีเมล (RFC 5322) + ต้องมี @ และโดเมนที่มีจุด
  final RegExp emailRegex =
      RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$");
  if (!emailRegex.hasMatch(email)) {
    return 'รูปแบบอีเมลไม่ถูกต้อง (เช่น user@example.com)';
  }
  return null;
}

// รหัสผ่าน
// 1. ต้องเป็น a-z A-Z 0-9 หรืออักขระพิเศษ ! # _ . เท่านั้น
// 2. ความยาว 6-24 ตัวอักษร
// 3. ต้องไม่มีเว้นวรรค
// 4. ต้องไม่เป็นค่าว่าง
String? validatePassword(String? value) {
  final String password = value ?? '';

  if (password.trim().isEmpty) return 'กรุณากรอกรหัสผ่าน';
  if (password.contains(' ')) return 'รหัสผ่านต้องไม่มีเว้นวรรค';
  if (password.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
  if (password.length > 24) return 'รหัสผ่านต้องยาวไม่เกิน 24 ตัวอักษร';

  if (!RegExp(r'^[A-Za-z0-9!#_.]+$').hasMatch(password)) {
    return 'รหัสผ่านใช้ได้เฉพาะ a-z A-Z 0-9 และ ! # _ . เท่านั้น';
  }
  return null;
}
