import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass  = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _maybeReturnToAuthGate() async {
    // ถ้าหน้านี้ถูก push มาทับ root เอาไว้ ให้กลับไปที่ route แรก
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

      // ปกติ StreamBuilder จะพาไปหน้า Home เอง
      // แต่ถ้า Login ถูก push ทับไว้ ให้ pop กลับไป root
      await _maybeReturnToAuthGate();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'เข้าสู่ระบบไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _signUp() async {
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
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: mail,
        password: pwd,
      );

      // หลังสมัครเสร็จถูกล็อกอินให้อัตโนมัติ -> กลับไป root ถ้าถูก push ทับ
      await _maybeReturnToAuthGate();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'สมัครสมาชิกไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'LOST\nAND\nFOUND',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              AppInput(
                controller: email,
                hint: 'Email',
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: pass,
                hint: 'Password',
                obscure: true,
              ),
              const SizedBox(height: 16),
              loading
                  ? const Center(child: CircularProgressIndicator())
                  : AppButton(text: 'LOG IN', onPressed: _signIn),
              const SizedBox(height: 8),
              TextButton(onPressed: _signUp, child: const Text('Sign up')),
              const Spacer(),
              Container(height: 52, color: const Color(0xFFF0A78A)),
            ],
          ),
        ),
      ),
    );
  }
}
