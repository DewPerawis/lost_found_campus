import 'package:flutter/material.dart';
import '../theme.dart';

class BottomHomeBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onHome;
  const BottomHomeBar({super.key, this.onHome});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppTheme.peach,
      child: IconButton(
        icon: const Icon(Icons.home_outlined, color: Colors.white),
        onPressed: onHome ?? () => Navigator.popUntil(context, (r) => r.isFirst),
      ),
    );
  }
}
