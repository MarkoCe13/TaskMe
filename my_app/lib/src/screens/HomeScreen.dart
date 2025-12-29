import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/task_stats.dart';
import '../components/header.dart';
import '../components/footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_ProfileData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadProfileData();
  }

  Future<_ProfileData> _loadProfileData() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      throw Exception('User not signed in');
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(authUser.uid)
        .get();

    final userData = userDoc.data() ?? {};
    final displayName =
        (userData['displayName'] as String?) ?? authUser.email ?? 'User';

    final qs = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: authUser.uid)
        .get();

    final tasks = qs.docs.map((d) => Task.fromDoc(d)).toList();
    final now = DateTime.now();

    final allTime = TaskStats.fromTasks(tasks);
    final last7 = TaskStats.fromTasks(
      tasks.where(
        (t) => t.createdAt.isAfter(now.subtract(const Duration(days: 7))),
      ),
    );
    final last30 = TaskStats.fromTasks(
      tasks.where(
        (t) => t.createdAt.isAfter(now.subtract(const Duration(days: 30))),
      ),
    );

    return _ProfileData(
      displayName: displayName,
      allTime: allTime,
      last7: last7,
      last30: last30,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),                
      bottomNavigationBar: const Footer(),   
      body: FutureBuilder<_ProfileData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to your profile,\n${data.displayName}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                StatsCard(
                  title: 'All-time stats',
                  stats: data.allTime,
                  showRate: true,
                ),
                const SizedBox(height: 16),

                StatsCard(
                  title: 'Last 7 days',
                  stats: data.last7,
                ),
                const SizedBox(height: 16),

                StatsCard(
                  title: 'Last month',
                  stats: data.last30,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileData {
  final String displayName;
  final TaskStats allTime;
  final TaskStats last7;
  final TaskStats last30;

  _ProfileData({
    required this.displayName,
    required this.allTime,
    required this.last7,
    required this.last30,
  });
}

class StatsCard extends StatelessWidget {
  final String title;
  final TaskStats stats;
  final bool showRate;

  const StatsCard({
    super.key,
    required this.title,
    required this.stats,
    this.showRate = false,
  });

  @override
  Widget build(BuildContext context) {
    final completionPercent = (stats.completionRate * 100).round();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stats.done} tasks DONE',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${stats.missed} tasks MISSED',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${stats.pending} tasks PENDING',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showRate) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$completionPercent% completion rate',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              height: 110,
              child: TaskPieChart(stats: stats),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskPieChart extends StatelessWidget {
  final TaskStats stats;

  const TaskPieChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.total == 0 ? 1 : stats.total;

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 0,
        sections: [
          PieChartSectionData(
            value: stats.done.toDouble(),
            color: Colors.green,
            title: '${(stats.done / total * 100).round()}%',
            titleStyle: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            value: stats.missed.toDouble(),
            color: Colors.red,
            title: stats.missed == 0
                ? ''
                : '${(stats.missed / total * 100).round()}%',
            titleStyle: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            value: stats.pending.toDouble(),
            color: Colors.orange,
            title: stats.pending == 0
                ? ''
                : '${(stats.pending / total * 100).round()}%',
            titleStyle: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
