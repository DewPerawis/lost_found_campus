import 'item.dart';

final mockItems = List.generate(6, (i) => Item(
  id: 'id$i',
  title: 'Item ${i+1}',
  status: i.isEven ? 'lost' : 'found',
  imageUrl: null, // ใส่ URL รูปจริงทีหลัง
  place: 'Building ${i+1}',
  date: DateTime.now().subtract(Duration(days: i)),
  desc: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
));
