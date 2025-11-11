import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ เพิ่มบรรทัดนี้
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _AuthMode { signIn, reset, signUp }

class _LoginPageState extends State<LoginPage> {
  // controllers หลัก
  final email = TextEditingController();
  final pass  = TextEditingController();
  // เพิ่มสำหรับ sign up
  final confirm = TextEditingController();
  final displayName = TextEditingController();
  final contact = TextEditingController();

  // state
  bool loading = false;
  bool showPwd = false;
  bool showConfirmPwd = false;
  _AuthMode mode = _AuthMode.signIn;

  // dropdowns
  static const List<String> faculties = [
    'ไม่ระบุ','Other','SI','RA','BM','PY','DT','NS','MT','PH','PT','VS','TM','SC','EN','LA','SH','EG','ICT','CRS','SS','RS'
  ];
  static const List<String> roles = ['ไม่ระบุ','Student','Teacher','Staff','Other'];

  String faculty = 'ไม่ระบุ';
  String role = 'ไม่ระบุ';

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    confirm.dispose();
    displayName.dispose();
    contact.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode m) {
    if (loading) return;
    setState(() {
      mode = m;
      showPwd = false;
      showConfirmPwd = false;
    });
  }

  Future<void> _maybeReturnToAuthGate() async {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _signIn() async {
    if (loading) return;
    FocusScope.of(context).unfocus();

    final mail = email.text.trim();
    final pwd  = pass.text.trim();
    if (mail.isEmpty || pwd.isEmpty) {
      _showError('กรอกอีเมลและรหัสผ่านให้ครบก่อนนะ');
      return;
    }

    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: mail,
        password: pwd,
      );
      await _maybeReturnToAuthGate();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'เข้าสู่ระบบไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submitReset() async {
    if (loading) return;
    final mail = email.text.trim();
    if (mail.isEmpty) {
      _showError('พิมพ์อีเมลก่อน แล้วกด “ยืนยัน” อีกครั้งนะ');
      return;
    }
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: mail);
      _showInfo('ส่งลิงก์รีเซ็ตรหัสผ่านไปที่ $mail แล้ว');
      // กลับสู่การ์ดเข้าสู่ระบบ
      _switchMode(_AuthMode.signIn);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'ส่งอีเมลรีเซ็ตรหัสผ่านไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submitSignUp() async {
    if (loading) return;
    FocusScope.of(context).unfocus();

    final mail = email.text.trim();
    final pwd  = pass.text.trim();
    final cPwd = confirm.text.trim();

    if (mail.isEmpty || pwd.isEmpty || cPwd.isEmpty) {
      _showError('กรอก Email / Password / Confirm Password ให้ครบก่อนนะ');
      return;
    }
    if (pwd != cPwd) {
      _showError('รหัสผ่านทั้งสองช่องไม่ตรงกัน');
      return;
    }

    setState(() => loading = true);
    try {
      // สมัคร user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: mail,
        password: pwd,
      );

      // เตรียมข้อมูลโปรไฟล์
      final uid = cred.user!.uid;
      final data = {
        'uid'     : uid,
        'email'   : mail,
        'name'    : (displayName.text.trim().isEmpty) ? 'Unknown' : displayName.text.trim(),
        'contact' : (contact.text.trim().isEmpty) ? 'None' : contact.text.trim(),
        'faculty' : faculty, // ตัวย่อ
        'role'    : role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // สร้างเอกสารใน Firestore (ปรับชื่อคอลเลกชันได้ตามโปรเจ็กต์)
      await FirebaseFirestore.instance.collection('users').doc(uid).set(data);

      // createUser จะล็อกอินให้อยู่แล้ว -> กลับ gateway
      await _maybeReturnToAuthGate();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'สมัครสมาชิกไม่สำเร็จ');
    } catch (e) {
      _showError('บันทึกข้อมูลผู้ใช้ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppTheme.cream;
    const cardBg = Color(0xFFFFF7EF);
    final viewportH = MediaQuery.of(context).size.height;

    final title = switch (mode) {
      _AuthMode.signIn => 'เข้าสู่ระบบ',
      _AuthMode.reset  => 'Reset Password',
      _AuthMode.signUp => 'สร้างบัญชี',
    };

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // พื้นหลังวาดครอบคลุมความสูงทั้งหมด
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewportH),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _SoftShapesPainter()),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 18,
                                      offset: Offset(0, 10),
                                      color: Color(0x14000000),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.search_rounded, size: 36),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'LOST AND FOUND',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ตามหา • ส่งคืน • ง่ายและปลอดภัย',
                                style: TextStyle(
                                  color: Colors.brown.shade400,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // การ์ดฟอร์ม
                          Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 22,
                                  offset: Offset(0, 12),
                                  color: Color(0x1A000000),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 16),

                                // ฟอร์มแต่ละโหมด
                                ...switch (mode) {
                                  _AuthMode.signIn => _buildSignInForm(),
                                  _AuthMode.reset  => _buildResetForm(),
                                  _AuthMode.signUp => _buildSignUpForm(),
                                },

                                // แถบลิงก์เปลี่ยนโหมดด้านล่าง
                                const SizedBox(height: 10),
                                if (mode == _AuthMode.signIn) ...[
                                  _OrDivider(textColor: Colors.brown.shade300),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      children: [
                                        Text(
                                          'ยังไม่มีบัญชี?',
                                          style: TextStyle(
                                            color: Colors.brown.shade400,
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: loading ? null : () => _switchMode(_AuthMode.signUp),
                                          child: const Text('สร้างบัญชีใหม่'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: loading ? null : () => _switchMode(_AuthMode.signIn),
                                    child: const Text('กลับไปหน้าเข้าสู่ระบบ'),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading overlay
            if (loading)
              Container(
                color: Colors.black.withOpacity(0.08),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 36, height: 36,
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Forms ----------
  List<Widget> _buildSignInForm() {
    return [
      AppInput(
        controller: email,
        hint: 'Email',
        type: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      AppInput(
        controller: pass,
        hint: 'Password',
        obscure: !showPwd,
        suffix: IconButton(
          onPressed: () => setState(() => showPwd = !showPwd),
          icon: Icon(showPwd ? Icons.visibility_off : Icons.visibility),
        ),
      ),

      // ✅ ลิงก์ "ลืมรหัสผ่าน?" ชิดขวา ใต้ช่องรหัสผ่าน
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: loading ? null : () => _switchMode(_AuthMode.reset),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            foregroundColor: const Color(0xFFE69A8C), // โทนชมพูอ่อนคล้ายในภาพ
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          child: const Text('ลืมรหัสผ่าน?'),
        ),
      ),

      const SizedBox(height: 4),
      AppButton(
        text: 'LOG IN',
        onPressed: loading ? null : _signIn,
        icon: Icons.login_rounded,
      ),
    ];
  }


  List<Widget> _buildResetForm() {
    return [
      AppInput(
        controller: email,
        hint: 'Email',
        type: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      AppButton(
        text: 'ยืนยัน',
        onPressed: loading ? null : _submitReset,
        icon: Icons.check_circle_rounded,
      ),
    ];
  }

  List<Widget> _buildSignUpForm() {
    return [
      AppInput(
        controller: email,
        hint: 'Email *',
        type: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      AppInput(
        controller: pass,
        hint: 'Password *',
        obscure: !showPwd,
        suffix: IconButton(
          onPressed: () => setState(() => showPwd = !showPwd),
          icon: Icon(showPwd ? Icons.visibility_off : Icons.visibility),
        ),
      ),
      const SizedBox(height: 12),
      AppInput(
        controller: confirm,
        hint: 'Confirm Password *',
        obscure: !showConfirmPwd,
        suffix: IconButton(
          onPressed: () => setState(() => showConfirmPwd = !showConfirmPwd),
          icon: Icon(showConfirmPwd ? Icons.visibility_off : Icons.visibility),
        ),
      ),
      const SizedBox(height: 12),
      AppInput(
        controller: displayName,
        hint: 'ชื่อ (เว้นว่าง = Unknown)',
      ),
      const SizedBox(height: 12),
      AppInput(
        controller: contact,
        hint: 'Contact (เว้นว่าง = None)',
      ),
      const SizedBox(height: 12),
      _DropField<String>(
        label: 'Faculty',
        value: faculty,
        items: faculties,
        onChanged: (v) => setState(() => faculty = v ?? 'ไม่ระบุ'),
      ),
      const SizedBox(height: 12),
      _DropField<String>(
        label: 'Role',
        value: role,
        items: roles,
        onChanged: (v) => setState(() => role = v ?? 'ไม่ระบุ'),
      ),
      const SizedBox(height: 12),
      AppButton(
        text: 'ยืนยัน',
        onPressed: loading ? null : _submitSignUp,
        icon: Icons.check_circle_rounded,
      ),
    ];
  }
}

/// เส้นคั่น "หรือ"
class _OrDivider extends StatelessWidget {
  final Color? textColor;
  const _OrDivider({this.textColor});

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? Theme.of(context).textTheme.bodySmall?.color;
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('หรือ', style: TextStyle(color: color)),
        ),
        const Expanded(child: Divider(thickness: 1, height: 1)),
      ],
    );
  }
}

/// Dropdown ให้หน้าตาเข้าเค้ากับ AppInput
class _DropField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  const _DropField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.brown.shade100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.brown.shade100),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(e.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// พื้นหลังลายโค้งนุ่ม ๆ
class _SoftShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final peach = AppTheme.peach;
    final paint1 = Paint()..color = peach.withOpacity(0.18);
    final paint2 = Paint()..color = peach.withOpacity(0.10);

    final path1 = Path()
      ..moveTo(0, size.height * 0.20)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.10, size.width, size.height * 0.22)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    final path2 = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.86, size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
