import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> markMissedTasksForUser(String userId) async {
  final now = Timestamp.now();

  final snap = await FirebaseFirestore.instance
      .collection('tasks')
      .where('userId', isEqualTo: userId)
      .where('deadline', isLessThan: now)
      .get();

  if (snap.docs.isEmpty) return;

  final batch = FirebaseFirestore.instance.batch();

  for (final doc in snap.docs) {
    final data = doc.data();
    final status = (data['status'] ?? '').toString().toLowerCase();

    // Only update pending/doing
    if (status == 'pending' || status == 'doing') {
      batch.update(doc.reference, {'status': 'missed'});
    }
  }

  await batch.commit();
}
