import 'package:flutter/material.dart';
import 'package:organizeit/models/project.dart';
import 'package:organizeit/models/task.dart';
import 'package:organizeit/screens/task_details_screen.dart';
import 'package:organizeit/widgets/task_card.dart';
import 'dart:math';
import 'dart:async';

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
  static const _minimumColumnWidth = 300.0;

  final ScrollController _boardScrollController = ScrollController();
  bool _isDragging = false;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _project = Project(
      id: widget.project.id,
      name: widget.project.name,
      tasks: List<Task>.from(widget.project.tasks),
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _boardScrollController.dispose();
    super.dispose();
  }

  void _addTask(String title, String status) {
    final newTask = Task(
      id: Random().nextDouble().toString(),
      title: title,
      status: status,
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

  void _ensureDeleteTask(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              _deleteTask(id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(
              color: Colors.white,
            )),
          ),
        ],
      ),
    );
  }

  void _moveTask(Task task, String newStatus) {
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      status: newStatus,
      details: task.details,
    );
    _updateTask(task.id, updatedTask);
  }

  void _saveProject() async {
    widget.onUpdate(_project);
  }

  void _showAddTaskDialog() {
    final controller = TextEditingController();
    String selectedStatus = 'todo'; // Default status

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(labelText: 'Status'),
                items: [
                  DropdownMenuItem(value: 'todo', child: Text('To-Do')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'done', child: Text('Done')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),
            ],
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
                  _addTask(title, selectedStatus);
                }
                Navigator.pop(context);
              },
              child: Text('Add', style: TextStyle(
                color: Colors.white,
              ),),
            ),
          ],
        ),
      ),
    );
  }

  List<Task> _getTasksByStatus(String status) {
    return _project.tasks.where((task) => task.status == status).toList();
  }

  void _startAutoScroll(bool scrollLeft, double scrollSpeed) {
    _autoScrollTimer?.cancel();

    _autoScrollTimer = Timer.periodic(Duration(milliseconds: 20), (timer) {
      if (_boardScrollController.hasClients) {
        if (scrollLeft && _boardScrollController.position.pixels > 0) {
          _boardScrollController.jumpTo(
            (_boardScrollController.position.pixels - scrollSpeed).clamp(
              0.0,
              _boardScrollController.position.maxScrollExtent
            )
          );
        } else if (!scrollLeft &&
            _boardScrollController.position.pixels < _boardScrollController.position.maxScrollExtent) {
          _boardScrollController.jumpTo(
            (_boardScrollController.position.pixels + scrollSpeed).clamp(
              0.0,
              _boardScrollController.position.maxScrollExtent
            )
          );
        } else {
          _autoScrollTimer?.cancel();
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  Widget _buildTaskCard(Task task, String status, double width) {
    return TaskCard(
      task: task,
      currentStatus: status,
      width: width,
      onMove: (newStatus) => _moveTask(task, newStatus),
      onDelete: () => _ensureDeleteTask(task.id),
      onDragStarted: () {
        setState(() {
          _isDragging = true;
        });
      },
      onDragEnd: () {
        setState(() {
          _isDragging = false;
        });
        _stopAutoScroll();
      },
      onDragUpdate: (details) {
        if (_isDragging) {
          final screenWidth = MediaQuery.of(context).size.width;
          final sensitivity = 60.0;
          final scrollSpeed = 7.5;

          if (details.globalPosition.dx < sensitivity && _boardScrollController.position.pixels > 0) {
            // Near left edge => start scrolling left
            _startAutoScroll(true, scrollSpeed);
          } else if (details.globalPosition.dx > screenWidth - sensitivity &&
                    _boardScrollController.position.pixels < _boardScrollController.position.maxScrollExtent) {
            // Near right edge => start scrolling right
            _startAutoScroll(false, scrollSpeed);
          } else {
            _stopAutoScroll();
          }
        }
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailsScreen(
              task: task,
              onUpdate: (updatedTask) => _updateTask(task.id, updatedTask),
            ),
          ),
        );
      },
    );
  }

  void _updateTask(String taskId, Task updatedTask) {
    setState(() {
      final index = _project.tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _project.tasks[index] = updatedTask;
      }
    });
    _saveProject();
  }

  Widget _buildColumn(String title, String status, double width) {
    final tasks = _getTasksByStatus(status);

    return Container(
      width: width,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: DragTarget<Task>(
        onAcceptWithDetails: (details) => _moveTask(details.data, status),
        onWillAcceptWithDetails: (details) => details.data.status != status,
        builder: (context, candidateData, rejectedData) {
          return Container(
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
                      return _buildTaskCard(task, status, width);
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate if all columns can fit on screen
          const int columnCount = 3; // todo, in_progress, done
          const double columnMargin = 16; // Total horizontal margin per column
          final double screenWidth = constraints.maxWidth;
          final double totalColumnWidth = _minimumColumnWidth * columnCount + (columnMargin * columnCount);
          final bool canFitAllColumns = screenWidth >= totalColumnWidth;

          // If we can fit all columns, expand them to fill screen
          final double columnWidth =
            canFitAllColumns ? (screenWidth / columnCount) - columnMargin : _minimumColumnWidth;

          return SingleChildScrollView(
            controller: _boardScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumn('To-Do', 'todo', columnWidth),
                _buildColumn('In Progress', 'in_progress', columnWidth),
                _buildColumn('Done', 'done', columnWidth),
              ],
            ),
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
