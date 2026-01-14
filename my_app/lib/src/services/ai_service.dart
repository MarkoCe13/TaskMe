import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:my_app/src/models/daily_plan_models.dart';

class AiDailyPlanService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static CollectionReference<Map<String, dynamic>> _plansCol(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dailyPlans');
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static Future<DailyPlanResult> generateDailyPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in.');
    }

    final now = DateTime.now();
    final start = _startOfDay(now);
    final end = start.add(const Duration(days: 1));

    final qs = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .where('deadline', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('deadline', isLessThan: Timestamp.fromDate(end))
        .get();

    final tasks = qs.docs.map((d) {
      final data = d.data();
      final deadline = (data['deadline'] as Timestamp?)?.toDate();

      return {
        'id': d.id,
        'title': (data['title'] ?? '').toString(),
        'description': (data['description'] ?? '').toString(),
        'status': (data['status'] ?? 'pending').toString(),
        'deadlineTime':
            deadline == null ? '' : DateFormat('HH:mm').format(deadline),
        'deadlineIso': deadline?.toIso8601String() ?? '',
      };
    }).toList();

    final dateLabel = DateFormat('EEEE, dd MMM yyyy').format(now);

    final callable = _functions.httpsCallable('generateDailyPlan');
    final resp = await callable.call({
      'dateLabel': dateLabel,
      'tasks': tasks,
    });

    final data = resp.data;
    if (data == null || data['plan'] == null) {
      return DailyPlanResult(
        summary: 'No plan generated.',
        plan: const [],
        tips: const [],
      );
    }

    final rawPlan = data['plan'];
    final planMap = Map<String, dynamic>.from(rawPlan as Map);

    return DailyPlanResult.fromJson(planMap);
  }

  static Future<DocumentReference<Map<String, dynamic>>> saveDailyPlan({
    required DailyPlanResult result,
    String? title,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be signed in.');
    }

    final now = DateTime.now();
    final defaultTitle = 'Plan for ${DateFormat('EEE, dd MMM').format(now)}';

    final docRef = _plansCol(user.uid).doc();

    await docRef.set({
      'title': (title ?? defaultTitle).trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'summary': result.summary,
      'plan': result.plan
          .map((p) => {
                'time': p.time,
                'title': p.title,
                'details': p.details,
              })
          .toList(),
      'tips': result.tips,
    });

    return docRef;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> savedPlansStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _plansCol(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<DailyPlanResult> getSavedPlan(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final snap = await ref.get();
    if (!snap.exists) {
      throw Exception('Plan not found.');
    }
    final data = snap.data()!;
    return DailyPlanResult.fromJson(data);
  }

  static Future<void> deleteSavedPlan(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    await ref.delete();
  }
}
