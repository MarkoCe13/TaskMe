import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String status;        
  final DateTime createdAt;

  Task({
    required this.status,
    required this.createdAt,
  });

  factory Task.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      status: (data['status'] as String).toLowerCase(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class TaskStats {
  final int done;
  final int missed;
  final int pending;

  const TaskStats({
    required this.done,
    required this.missed,
    required this.pending,
  });

  int get total => done + missed + pending;

  double get completionRate => total == 0 ? 0 : done / total;

  factory TaskStats.fromTasks(Iterable<Task> tasks) {
    int done = 0, missed = 0, pending = 0;
    for (final t in tasks) {
      switch (t.status) {
        case 'done':
          done++;
          break;
        case 'missed':
          missed++;
          break;
        case 'pending':
          pending++;
          break;
      }
    }
    return TaskStats(done: done, missed: missed, pending: pending);
  }
}
