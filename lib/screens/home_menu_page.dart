import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_home_bar.dart';
import 'lost_list_page.dart';
import 'my_post_page.dart';
import 'profile_page.dart';
import 'chat_list_page.dart';

class HomeMenuPage extends StatelessWidget {
  const HomeMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBar: BottomHomeBar(onHome: null),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Welcome back!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _menuCard(
                      context,
                      icon: Icons.search,
                      iconBg: cs.secondary.withOpacity(.15),
                      iconColor: Colors.orange.shade700,
                      title: 'Lost & Found Item',
                      subtitle: "Report an item you've lost",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LostListPage()),
                        );
                      },
                    ),
                    _menuCard(
                      context,
                      icon: Icons.inventory_2_outlined,
                      iconBg: Colors.teal.withOpacity(.15),
                      iconColor: Colors.teal,
                      title: 'My Post',
                      subtitle: 'View your posted items',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyPostPage()),
                        );
                      },
                    ),
                    _menuCard(
                      context,
                      icon: Icons.person_outline,
                      iconBg: Colors.deepPurple.withOpacity(.12),
                      iconColor: Colors.deepPurple,
                      title: 'Profile',
                      subtitle: 'Manage your information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfilePage()),
                        );
                      },
                    ),
                    // ⬇️ แท็บใหม่: Chat List
                    _menuCard(
                      context,
                      icon: Icons.chat_bubble_outline_rounded,
                      iconBg: Colors.redAccent.withOpacity(.12),
                      iconColor: Colors.redAccent,
                      title: 'Chat',
                      subtitle: 'Message with item owners',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatListPage()),
                        );
                      },
                    ),
                    _menuCard(
                      context,
                      icon: Icons.logout_rounded,
                      iconBg: Colors.grey.withOpacity(.15),
                      iconColor: Colors.grey.shade700,
                      title: 'Sign Out',
                      subtitle: 'Log out from your account',
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- UI helper ----
  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color.fromARGB(255, 255, 251, 247),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
