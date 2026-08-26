// เติมคำว่า "โรงพยาบาล" นำหน้าชื่อเสมอตอนแสดงผล
// (ข้อมูลที่เก็บจริงในระบบ/ที่ผู้ใช้กรอกไม่มีคำนี้ติดอยู่ — เติมเฉพาะตอนแสดงผลเท่านั้น)
String withHospitalPrefix(String? name) {
  final String n = name?.trim() ?? '';
  if (n.isEmpty) return 'ไม่ระบุชื่อโรงพยาบาล';
  if (n.startsWith('โรงพยาบาล')) return n; // กันซ้อน เผื่อมี prefix อยู่แล้ว
  return 'โรงพยาบาล$n';
}
