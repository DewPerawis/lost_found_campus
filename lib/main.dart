import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/login_page.dart';
import 'screens/home_menu_page.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('🔥 storageBucket = ${Firebase.app().options.storageBucket}');

   if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // DEBUG: ถ้าอยากบังคับให้ออกจากระบบทุกครั้งที่เปิดแอป (ชั่วคราว)
  // await FirebaseAuth.instance.signOut();
  runApp(const LostFoundApp());
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = snap.data;
          return user == null ? const LoginPage() : const HomeMenuPage();
        },
      ),
    );
  }
}
