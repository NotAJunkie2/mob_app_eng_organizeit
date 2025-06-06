import 'package:flutter/material.dart';
import 'package:organizeit/models/task.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;
  final Function(Task updatedTask) onUpdate;

  const TaskDetailsScreen({
    super.key,
    required this.task,
    required this.onUpdate,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late Task _task;

  @override
  void initState() {
    _task = Task(
      id: widget.task.id,
      title: widget.task.title,
      status: widget.task.status,
      details: widget.task.details,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_task.title),
      ),
    );
  }
}
