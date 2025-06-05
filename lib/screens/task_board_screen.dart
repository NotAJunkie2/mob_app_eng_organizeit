import 'package:flutter/material.dart';
import 'package:organizeit/models/project.dart';
import 'package:organizeit/models/task.dart';
import 'dart:math';

class TaskBoardScreen extends StatefulWidget {
  final Project project;
  final Function(Project updatedProject) onUpdate;

  const TaskBoardScreen({
    super.key,
    required this.project,
    required this.onUpdate,
  });

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = Project(
      id: widget.project.id,
      name: widget.project.name,
      tasks: List<Task>.from(widget.project.tasks),
    );
  }

  void _addTask(String title) {
    final newTask = Task(
      id: Random().nextDouble().toString(),
      title: title,
      status: 'todo',
    );
    setState(() {
      _project.tasks.add(newTask);
    });
    _saveProject();
  }

  void _deleteTask(String taskId) {
    setState(() {
      _project.tasks.removeWhere((task) => task.id == taskId);
    });
    _saveProject();
  }

  void _moveTask(Task task, String newStatus) {
    setState(() {
      task.status = newStatus;
    });
    _saveProject();
  }

  void _saveProject() async {
    widget.onUpdate(_project);
  }

  void _showAddTaskDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Task'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Task Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                _addTask(title);
              }
              Navigator.pop(context);
            },
            child: Text('Add', style: TextStyle(
              color: Colors.white,
            ),),
          ),
        ],
      ),
    );
  }

  List<Task> _getTasksByStatus(String status) {
    return _project.tasks.where((task) => task.status == status).toList();
  }

  Widget _buildDraggableTaskCard(Task task, String status) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        child: SizedBox(
          width: 300,
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(task.title),
            ),
          ),
        ),
      ),
      childWhenDragging: Container(),
      onDragCompleted: () {
        // Optionally handle drag completion
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text(task.title),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteTask(task.id);
              } else {
                _moveTask(task, value);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'todo', child: Text('Move to To-Do')),
              PopupMenuItem(value: 'in_progress', child: Text('Move to In Progress')),
              PopupMenuItem(value: 'done', child: Text('Move to Done')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: Text('Delete Task', style: TextStyle(color: Colors.red))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumn(String title, String status) {
    final tasks = _getTasksByStatus(status);

    return Expanded(
      child: DragTarget<Task>(
        onAcceptWithDetails: (details) => _moveTask(details.data, status),
        onWillAcceptWithDetails: (details) => details.data.status != status,
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: candidateData.isNotEmpty ? Colors.blue : Colors.grey[300]!,
                width: candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                SizedBox(height: 8),
                if (candidateData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Move to $title',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (_, index) {
                      final task = tasks[index];
                      return _buildDraggableTaskCard(task, status);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_project.name),
      ),
      body: Row(
        children: [
          _buildColumn('To-Do', 'todo'),
          _buildColumn('In Progress', 'in_progress'),
          _buildColumn('Done', 'done'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
