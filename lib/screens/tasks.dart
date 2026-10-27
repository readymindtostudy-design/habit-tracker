import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final List<Task> open = app.tasks.where((Task t) => !t.done).toList();
    final List<Task> done = app.tasks.where((Task t) => t.done).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (String v) {
                  app.addTask(v);
                  _controller.clear();
                },
                decoration: InputDecoration(
                  hintText: 'What needs doing?',
                  filled: true,
                  fillColor: AppColors.card,
                  hintStyle: const TextStyle(color: AppColors.muted),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  app.addTask(_controller.text);
                  _controller.clear();
                },
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(Icons.add_rounded,
                      color: AppColors.greenInk, size: 26),
                ),
              ),
            ),
          ],
        ),
        const SectionHeader(title: 'Open'),
        if (open.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('All caught up.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          )
        else
          ...open.map((Task t) => _taskTile(app, t, false)),
        if (done.isNotEmpty) ...<Widget>[
          SectionHeader(title: 'Done (${done.length})'),
          ...done.map((Task t) => _taskTile(app, t, true)),
        ],
      ],
    );
  }

  Widget _taskTile(AppState app, Task t, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: () => app.toggleTask(t),
              icon: Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: done ? AppColors.green : AppColors.muted,
              ),
              tooltip: done ? 'Mark not done' : 'Mark done',
            ),
            Expanded(
              child: Text(
                t.text,
                style: TextStyle(
                  fontSize: 15.5,
                  color: done ? AppColors.muted : AppColors.text,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            IconButton(
              onPressed: () => app.deleteTask(t.id),
              icon: const Icon(Icons.close, size: 20, color: AppColors.muted),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
