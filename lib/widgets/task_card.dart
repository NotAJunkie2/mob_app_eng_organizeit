import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final String currentStatus;
  final double width;
  final VoidCallback? onTap;
  final Function(String) onMove;
  final VoidCallback onDelete;
  final bool isDragging;
  final Function? onDragStarted;
  final Function? onDragEnd;
  final Function(DragUpdateDetails)? onDragUpdate;

  const TaskCard({
    super.key,
    required this.task,
    required this.currentStatus,
    required this.width,
    this.onTap,
    required this.onMove,
    required this.onDelete,
    this.isDragging = false,
    this.onDragStarted,
    this.onDragEnd,
    this.onDragUpdate,
  });

  Widget _buildCardContent() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(task.title),
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            } else {
              onMove(value);
            }
          },
          itemBuilder: (_) => [
            if (currentStatus != 'todo') PopupMenuItem(value: 'todo', child: Text('Move to To-Do')),
            if (currentStatus != 'in_progress') PopupMenuItem(value: 'in_progress', child: Text('Move to In Progress')),
            if (currentStatus != 'done') PopupMenuItem(value: 'done', child: Text('Move to Done')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'delete', child: Text('Delete Task', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _buildDragFeedback() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width - 16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          child: ListTile(
            title: Text(task.title),
          ),
        ),
      ),
    );
  }

  Widget _buildChildWhenDragging() {
    return Opacity(
      opacity: 0.3,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text(task.title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Task>(
      data: task,
      delay: Duration(milliseconds: 150),
      onDragStarted: () => onDragStarted?.call(),
      onDragEnd: (_) => onDragEnd?.call(),
      onDragUpdate: onDragUpdate,
      feedback: _buildDragFeedback(),
      childWhenDragging: _buildChildWhenDragging(),
      child: _buildCardContent(),
    );
  }
}