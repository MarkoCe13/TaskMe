import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/src/theme/app_colors.dart';

import '../models/daily_plan_models.dart';
import '../services/ai_service.dart';

class DailyPlanDetailScreen extends StatelessWidget {
  final DailyPlanResult result;

  final bool allowSave;

  final DocumentReference<Map<String, dynamic>>? planDocRef;

  const DailyPlanDetailScreen({
    super.key,
    required this.result,
    required this.allowSave,
    required this.planDocRef,
  });

  bool _isNonTaskBlock(String title) {
    final t = title.trim().toLowerCase();
    const nonTasks = {
      'break',
      'lunch',
      'dinner',
      'free time',
      'buffer',
      'rest',
      'commute',
    };
    return nonTasks.contains(t);
  }

  Future<void> _savePlan(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final title =
        'Plan for ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    await AiDailyPlanService.saveDailyPlan(
      title: title,
      result: result,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Daily Plan'),
        actions: [
          if (allowSave)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                tooltip: 'Save plan',
                iconSize: 30,
                onPressed: () => _savePlan(context),
                icon: const Icon(
                  Icons.bookmark_add_outlined,
                  color: AppColors.taskMeGreen,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 60),
          children: [
            Text(
              result.summary,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...result.plan.map((p) {
              final isNonTask = _isNonTaskBlock(p.title);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.time,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isNonTask ? FontWeight.w500 : FontWeight.w600,
                            color: isNonTask ? Colors.black54 : Colors.black87,
                          ),
                        ),
                        if (p.details.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            p.details,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (result.tips.isNotEmpty) ...[
              const SizedBox(height: 6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tips 💡',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...result.tips.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(t),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
