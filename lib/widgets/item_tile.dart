import 'package:flutter/material.dart';

class ItemTile extends StatelessWidget {
  final String title;
  final String? place;
  final String? imageUrl;
  final VoidCallback onTap;
  const ItemTile({
    super.key,
    required this.title,
    this.place,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 54, height: 54, color: Colors.black12,
          child: imageUrl != null
              ? Image.network(imageUrl!, fit: BoxFit.cover)
              : const Icon(Icons.image, size: 28),
        ),
      ),
      title: Text(title),
      subtitle: Text('PLACE: ${place ?? '-'}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
