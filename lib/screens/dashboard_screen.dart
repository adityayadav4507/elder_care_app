import 'package:flutter/material.dart';

import '../services/task_store.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskStore = TaskStore();

    return AnimatedBuilder(
      animation: taskStore,
      builder: (context, _) {
        final week = taskStore.weeklyProgress();
        final completed = taskStore.completedTodayCount;
        final total = taskStore.tasks.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const Text(
              'Tracker',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'A simple offline history of ${taskStore.personName}’s care routine.',
              style: const TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 22),
            _TodaySummary(completed: completed, total: total),
            const SizedBox(height: 24),
            const Text(
              'Last 7 days',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _WeeklyChart(days: week),
            const SizedBox(height: 24),
            const Text(
              'Today by category',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final category in TaskCategory.values) ...[
              _CategoryProgress(category: category, taskStore: taskStore),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (completed / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today',
                style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 5),
              Text(
                '$completed of $total done',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            '$percent%',
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.days});

  final List<DayProgress> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(day.percent * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: day.percent.clamp(0.04, 1),
                          child: Container(
                            width: 28,
                            decoration: BoxDecoration(
                              color: day.percent == 1
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      day.label,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryProgress extends StatelessWidget {
  const _CategoryProgress({required this.category, required this.taskStore});

  final TaskCategory category;
  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    final tasks = taskStore.tasksForCategory(category);
    final completed = tasks
        .where((task) => taskStore.isDoneToday(task.id))
        .length;
    final percent = tasks.isEmpty ? 0.0 : completed / tasks.length;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${category.emoji} ${category.label}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$completed/${tasks.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: percent,
              backgroundColor: const Color(0xFFE5E7EB),
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }
}
