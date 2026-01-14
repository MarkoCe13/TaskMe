import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/src/services/notification_service.dart';
import 'package:my_app/src/services/tasks_status_service.dart';

import '../components/header.dart';
import '../components/footer.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

enum DeadlineOrder { oldestFirst, newestFirst }

class _TasksScreenState extends State<TasksScreen> {
  String _statusFirst = 'pending';
  DeadlineOrder _deadlineOrder = DeadlineOrder.oldestFirst;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('You must be signed in.')),
      );
    }

    markMissedTasksForUser(user.uid);

    final tasksQuery = FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: user.uid);

    return Scaffold(
      appBar: const Header(),
      bottomNavigationBar: const Footer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _statusFirst,
                      decoration: _dropdownDecoration(),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('PENDING'),
                        ),
                        DropdownMenuItem(
                          value: 'missed',
                          child: Text('MISSED'),
                        ),
                        DropdownMenuItem(
                          value: 'done',
                          child: Text('DONE'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _statusFirst = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<DeadlineOrder>(
                      value: _deadlineOrder,
                      decoration: _dropdownDecoration(),
                      items: const [
                        DropdownMenuItem(
                          value: DeadlineOrder.oldestFirst,
                          child: Text('Oldest first'),
                        ),
                        DropdownMenuItem(
                          value: DeadlineOrder.newestFirst,
                          child: Text('Newest first'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _deadlineOrder = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: tasksQuery.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('No tasks yet'));
                    }

                    final tasks = docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return _TaskItem(
                        id: d.id,
                        title: (data['title'] ?? '') as String,
                        description: (data['description'] ?? '') as String,
                        status: (data['status'] ?? 'pending') as String,
                        deadline: (data['deadline'] as Timestamp?)?.toDate(),
                      );
                    }).toList();

                    final baseOrder = ['pending', 'missed', 'done'];
                    var order = List<String>.from(baseOrder);

                    final idx = order.indexOf(_statusFirst);
                    if (idx > 0) {
                      order = [...order.sublist(idx), ...order.sublist(0, idx)];
                    }

                    int rank(String s) {
                      final i = order.indexOf(s.toLowerCase());
                      return i == -1 ? 999 : i;
                    }

                    DateTime safeDeadline(_TaskItem t) =>
                        t.deadline ?? DateTime(9999);

                    int cmpDeadline(_TaskItem a, _TaskItem b) {
                      final cmp = safeDeadline(a).compareTo(safeDeadline(b));
                      return _deadlineOrder == DeadlineOrder.oldestFirst
                          ? cmp
                          : -cmp;
                    }

                    tasks.sort((a, b) {
                      final ra = rank(a.status);
                      final rb = rank(b.status);
                      if (ra != rb) return ra.compareTo(rb);

                      return cmpDeadline(a, b);
                    });

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == tasks.length - 1 ? 0 : 12,
                          ),
                          child: _TaskCard(task: task),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() => InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );
}

class _TaskItem {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime? deadline;

  _TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.deadline,
  });
}

class _TaskCard extends StatelessWidget {
  final _TaskItem task;

  const _TaskCard({required this.task});

  Color get _statusColor {
    switch (task.status.toLowerCase()) {
      case 'done':
        return const Color(0xFF4CAF50);
      case 'missed':
        return const Color(0xFFE53935);
      default:
        return Colors.grey.shade400;
    }
  }

  String get _statusLabel => task.status.toUpperCase();

  String get _deadlineText {
    if (task.deadline == null) return 'No deadline';
    final d = task.deadline!;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year, $hour:$minute';
  }

  bool get _isDone => task.status.toLowerCase() == 'done';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Colors.black87,
                ),
                const SizedBox(width: 6),
                Text(_deadlineText, style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditTaskScreen(task: task),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    final isDone = task.status.toLowerCase() == 'done';

                    if (isDone) {
                      await FirebaseFirestore.instance
                          .collection('tasks')
                          .doc(task.id)
                          .update({'status': 'pending'});

                      if (task.deadline != null &&
                          task.deadline!.isAfter(DateTime.now())) {
                        await NotificationService.instance
                            .scheduleDeadlineReminder(
                          docId: task.id,
                          title: task.title,
                          deadline: task.deadline!,
                          before: const Duration(minutes: 30),
                        );
                      }
                    } else {
                      await FirebaseFirestore.instance
                          .collection('tasks')
                          .doc(task.id)
                          .update({'status': 'done'});
                      await NotificationService.instance
                          .cancelForDocId(task.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isDone ? Colors.green : Colors.black87,
                        width: 2,
                      ),
                      color: _isDone ? Colors.green : Colors.white,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 20,
                      color: _isDone ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final _TaskItem task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late String _status;
  DateTime? _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      markMissedTasksForUser(user.uid);
    }

    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _status = widget.task.status.toLowerCase();
    _deadline = widget.task.deadline;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final base = _deadline ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a deadline')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.task.id)
          .update({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'status': _status,
        'deadline': Timestamp.fromDate(_deadline!),
      });

      // Notification sync
      try {
        if (_status.toLowerCase() == 'done') {
          await NotificationService.instance.cancelForDocId(widget.task.id);
        } else if (_deadline!.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleDeadlineReminder(
            docId: widget.task.id,
            title: _titleCtrl.text.trim(),
            deadline: _deadline!,
            before: const Duration(minutes: 30),
          );
        }
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task'),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.task.id)
          .delete();

      try {
        await NotificationService.instance.cancelForDocId(widget.task.id);
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _deadlineLabel() {
    if (_deadline == null) return 'Choose date & time';
    final d = _deadline!;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      bottomNavigationBar: const Footer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Title',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Title',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Title is required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

   
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Description',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'missed',
                              child: Text('Missed'),
                            ),
                            DropdownMenuItem(
                              value: 'done',
                              child: Text('Done'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _status = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

 
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDeadline,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deadline',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _deadlineLabel(),
                            style: TextStyle(
                              color: _deadline == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 44,
                      width: 140,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save changes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 44,
                      width: 140,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _saving ? null : _deleteTask,
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
