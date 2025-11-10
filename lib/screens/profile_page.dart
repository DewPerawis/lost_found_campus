import 'package:flutter/material.dart';
import '../widgets/bottom_home_bar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('PROFILE')),
      bottomNavigationBar: const BottomHomeBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          CircleAvatar(radius: 44, backgroundColor: Colors.black12),
          SizedBox(height: 12),
          Center(child: Text('NAME: John Doe')),
          Center(child: Text('Contact: 0123456789')),
          Divider(height: 32),
          ListTile(title: Text('MY POST'), trailing: Icon(Icons.chevron_right)),
          ListTile(title: Text('SETTING'), trailing: Icon(Icons.chevron_right)),
          ListTile(title: Text('TERM AND POLICY'), trailing: Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}
