import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;

  // ---------- create / open ----------
  static Future<String> openOrCreateChat({
    required String uidA,
    required String uidB,
    String? itemId,
  }) async {
    final ids = [uidA, uidB]..sort();
    final chatId = itemId != null ? '${ids.join("_")}__item_$itemId' : ids.join("_");
    final chatRef = _db.collection('chats').doc(chatId);

    try {
      await chatRef.set({
        'participants': ids,
        'itemRef': itemId != null ? _db.doc('items/$itemId') : null,
        'lastMessage': '',
        'lastAt': FieldValue.serverTimestamp(),
        'unread': {ids[0]: 0, ids[1]: 0},
      }, SetOptions(merge: false));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow; // มีอยู่แล้ว -> ปล่อยผ่าน
    }
    return chatId;
  }

  // ---------- send ----------
  static Future<void> sendText({
    required String chatId,
    required String text,
    required String senderUid,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(chatRef);
      final data = snap.data()!;
      final List parts = List.from(data['participants']);
      final other = parts.firstWhere((u) => u != senderUid);

      tx.set(msgRef, {
        'senderId': senderUid,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [senderUid],
      });

      final Map<String, dynamic> unread = Map<String, dynamic>.from(data['unread'] ?? {});
      unread[other] = (unread[other] ?? 0) + 1;

      tx.update(chatRef, {
        'lastMessage': text.trim(),
        'lastAt': FieldValue.serverTimestamp(),
        'unread': unread,
      });
    });
  }

  // ---------- mark as read ----------
  static Future<void> markAsRead({
    required String chatId,
    required String currentUid,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final msgsRef = chatRef.collection('messages')
        .orderBy('createdAt', descending: true).limit(50);

    final batch = _db.batch();

    final chatSnap = await chatRef.get();
    final Map<String, dynamic> unread =
        Map<String, dynamic>.from(chatSnap.data()?['unread'] ?? {});
    if ((unread[currentUid] ?? 0) != 0) {
      unread[currentUid] = 0;
      batch.update(chatRef, {'unread': unread});
    }

    final recent = await msgsRef.get();
    for (final d in recent.docs) {
      final List readBy = List.from(d['readBy'] ?? []);
      if (!readBy.contains(currentUid)) {
        batch.update(d.reference, {'readBy': FieldValue.arrayUnion([currentUid])});
      }
    }

    await batch.commit();
  }

  // ---------- delete whole chat (with messages) ----------
  static Future<void> deleteChat(String chatId) async {
    final chatRef = _db.collection('chats').doc(chatId);
    // ลบข้อความเป็นชุด ๆ
    const page = 300;
    while (true) {
      final snap = await chatRef.collection('messages')
          .orderBy('createdAt').limit(page).get();
      if (snap.docs.isEmpty) break;
      final b = _db.batch();
      for (final d in snap.docs) {
        b.delete(d.reference);
      }
      await b.commit();
      if (snap.docs.length < page) break;
    }
    // แล้วลบห้อง
    await chatRef.delete();
  }

  // ---------- user helpers ----------
  static Stream<Map<String, dynamic>?> otherUserStream(String otherUid) {
    return _db.collection('users').doc(otherUid).snapshots().map((s) => s.data());
  }

  static String displayNameFrom(Map<String, dynamic>? u, {String fallback = 'Unknown'}) {
    if (u == null) return fallback;
    final name = (u['name'] ?? u['displayName'] ?? '').toString().trim();
    return name.isEmpty ? fallback : name;
  }

  static String? photoFrom(Map<String, dynamic>? u) {
    final p = (u?['photoUrl'] ?? u?['avatarUrl'] ?? '').toString().trim();
    return p.isEmpty ? null : p;
  }
}
