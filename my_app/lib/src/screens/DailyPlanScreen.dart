import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/src/screens/DailyPlanDetailScreen.dart';

import '../models/daily_plan_models.dart';
import '../services/ai_service.dart';

class DailyPlanScreen extends StatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  bool _generating = false;
  String? _error;

  Future<void> _generateAndMaybeSave() async {
    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final result = await AiDailyPlanService.generateDailyPlan();

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DailyPlanDetailScreen(
            result: result,
            allowSave: true,
            planDocRef: null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _openSavedPlan(
      DocumentReference<Map<String, dynamic>> ref) async {
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final result = DailyPlanResult.fromJson(data);

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyPlanDetailScreen(
          result: result,
          allowSave: false,
          planDocRef: ref,
        ),
      ),
    );
  }

  Future<void> _deletePlan(DocumentReference<Map<String, dynamic>> ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete plan?'),
        content: const Text('This will permanently delete the saved plan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You must be signed in.')),
      );
    }

    final plansQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyPlans')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Daily Plans')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: plansQuery.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No saved plans yet.\nGenerate one below! 🤖',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final data = doc.data();
                      final title = (data['title'] ?? 'Saved plan').toString();
                      final createdAt = data['createdAt'];
                      final when = createdAt is Timestamp
                          ? createdAt.toDate().toString()
                          : '';

                      return Card(
                        child: ListTile(
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () => _openSavedPlan(doc.reference),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            onPressed: () => _deletePlan(doc.reference),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 60), 
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _generateAndMaybeSave,
                  icon: _generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _generating ? 'Generating...' : 'Generate a plan for today',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
