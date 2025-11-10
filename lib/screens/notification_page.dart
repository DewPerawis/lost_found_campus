import 'package:flutter/material.dart';
import '../widgets/bottom_home_bar.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('NOTIFICATION')),
      bottomNavigationBar: const BottomHomeBar(),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemBuilder: (_, i) => const ListTile(
          title: Text('มีการโพสต์ของใหม่'),
          subtitle: Text('Lorem ipsum lorem ipsum'),
        ),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: 6,
      ),
    );
  }
}
