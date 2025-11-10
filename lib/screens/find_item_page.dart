import 'package:flutter/material.dart';
import '../widgets/bottom_home_bar.dart';
import 'search_result_page.dart';

class FindItemPage extends StatefulWidget { const FindItemPage({super.key}); @override State<FindItemPage> createState()=>_FindItemPageState(); }
class _FindItemPageState extends State<FindItemPage> {
  final q = TextEditingController();
  String? date, location, status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('FIND ITEM')),
      bottomNavigationBar: const BottomHomeBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(controller: q, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search item')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
  initialValue: date,
  items: const [
    DropdownMenuItem(value: 'today', child: Text('Today')),
    DropdownMenuItem(value: 'last7', child: Text('Last 7 Days')),
  ],
  onChanged: (v) => setState(() => date = v),
  decoration: const InputDecoration(hintText: 'Date'),
),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
  initialValue: location,
  items: const [
    DropdownMenuItem(value: 'Building A', child: Text('Building A')),
    DropdownMenuItem(value: 'Library', child: Text('Library')),
  ],
  onChanged: (v) => setState(() => location = v),
  decoration: const InputDecoration(hintText: 'Location'),
),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
  initialValue: status,
  items: const [
    DropdownMenuItem(value: 'lost', child: Text('Lost')),
    DropdownMenuItem(value: 'found', child: Text('Found')),
  ],
  onChanged: (v) => setState(() => status = v!),
  decoration: const InputDecoration(hintText: 'Status'),
),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchResultPage(
                  keyword: q.text.trim(),
                  status: status,
                  location: location,
                ),
              ),
            ),
            child: const Text('Apply'),
          ),

        ],
      ),
    );
  }
}
