import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_button.dart';
import '../widgets/bottom_home_bar.dart';
import 'lost_list_page.dart';
import 'my_post_page.dart';
import 'profile_page.dart';
import 'notification_page.dart';

class HomeMenuPage extends StatelessWidget {
  const HomeMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomHomeBar(onHome: null),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'LOST\nAND\nFOUND',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              AppButton(
                  text: 'LOST ITEM',
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LostListPage()));
                  }),
              const SizedBox(height: 12),
              AppButton(
                  text: 'MY POST',
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MyPostPage()));
                  }),
              const SizedBox(height: 12),
              AppButton(
                  text: 'PROFILE',
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()));
                  }),
              const SizedBox(height: 12),
              AppButton(
                  text: 'NOTIFICATION',
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationPage()));
                  }),
              const SizedBox(height: 12),
              AppButton(
                text: 'SIGN OUT',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (context.mounted) {
                    // กลับไปที่ root เพื่อให้ AuthGate สลับไปหน้า Login เอง
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
