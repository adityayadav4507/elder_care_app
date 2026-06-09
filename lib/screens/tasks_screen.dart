import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../main.dart';
import '../services/alarm_service.dart';
import '../services/task_store.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskStore = TaskStore();

    return AnimatedBuilder(
      animation: taskStore,
      builder: (context, _) {
        final completed = taskStore.completedTodayCount;
        final total = taskStore.tasks.length;
        final percent = taskStore.todayProgress;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            _Header(taskStore: taskStore),
            const SizedBox(height: 22),
            _ProgressPanel(
              completed: completed,
              total: total,
              percent: percent,
            ),
            const SizedBox(height: 26),
            _AddAlarmPanel(taskStore: taskStore),
            const SizedBox(height: 26),
            for (final category in TaskCategory.values) ...[
              _CategorySection(category: category, taskStore: taskStore),
              const SizedBox(height: 22),
            ],
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.taskStore});

  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0EA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    taskStore.personInitial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good morning',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 17),
                    ),
                    Text(
                      taskStore.personName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Change name',
          iconSize: 34,
          color: const Color(0xFF111827),
          onPressed: () => _showNameDialog(context, taskStore),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }

  Future<void> _showNameDialog(
    BuildContext context,
    TaskStore taskStore,
  ) async {
    final controller = TextEditingController(text: taskStore.personName);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Person name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                await taskStore.updatePersonName(controller.text);
                navigator.pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.completed,
    required this.total,
    required this.percent,
  });

  final int completed;
  final int total;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Progress",
                  style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed of $total tasks\ndone',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          CircularPercentIndicator(
            radius: 48,
            lineWidth: 9,
            percent: percent.clamp(0, 1),
            center: Text(
              '${(percent * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            progressColor: Colors.white,
            backgroundColor: Colors.white24,
          ),
        ],
      ),
    );
  }
}

class _AddAlarmPanel extends StatefulWidget {
  const _AddAlarmPanel({required this.taskStore});

  final TaskStore taskStore;

  @override
  State<_AddAlarmPanel> createState() => _AddAlarmPanelState();
}

class _AddAlarmPanelState extends State<_AddAlarmPanel> {
  final TextEditingController _nameController = TextEditingController();
  TaskCategory _category = TaskCategory.medicine;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(context, _time);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add alarm',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Alarm name',
              hintText: 'Example: Vitamin D',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskCategory>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: TaskCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text('${category.emoji} ${category.label}'),
              );
            }).toList(),
            onChanged: (category) {
              if (category == null) return;
              setState(() => _category = category);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final title = _nameController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an alarm name.'),
                        ),
                      );
                      return;
                    }
                    await widget.taskStore.addTask(
                      title: title,
                      time: timeText,
                      category: _category,
                    );
                    _nameController.clear();
                  },
                  icon: const Icon(Icons.add_alarm_rounded),
                  label: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() => _time = picked);
  }

  String _formatTime(BuildContext context, TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.taskStore});

  final TaskCategory category;
  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    final tasks = taskStore.tasksForCategory(category);

    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${category.emoji} ${category.label}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        for (final task in tasks) ...[
          _TaskTile(task: task, isDone: taskStore.isDoneToday(task.id)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.isDone});

  final CareTask task;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final alarmService = AlarmService();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isDone ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : Icons.schedule_rounded,
                  color: isDone ? const Color(0xFF166534) : task.category.color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      task.time,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 76,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDone
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFF111827),
                    foregroundColor: isDone
                        ? const Color(0xFF166534)
                        : Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => TaskStore().toggleDone(task.id),
                  child: Text(
                    isDone ? 'Done' : 'Mark',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  alarmService.triggerAlarm(
                    navigatorKey,
                    task.voiceLabel,
                    task.time,
                    taskId: task.id,
                  );
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Test'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF991B1B),
                ),
                onPressed: () => _confirmDelete(context, task),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CareTask task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete alarm?'),
          content: Text('Remove ${task.title} at ${task.time}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF991B1B),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await TaskStore().deleteTask(task.id);
    }
  }
}
