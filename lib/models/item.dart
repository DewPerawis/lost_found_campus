class Item {
  final String id;
  final String title;
  final String status; // lost | found
  final String? imageUrl;
  final String? place;
  final DateTime? date;
  final String? desc;

  Item({
    required this.id,
    required this.title,
    required this.status,
    this.imageUrl,
    this.place,
    this.date,
    this.desc,
  });
}
