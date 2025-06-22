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

  void _addTask(String title, String status, {DateTime? dueDate}) {
  final newTask = Task(
    id: Random().nextDouble().toString(),
    title: title,
    status: status,
    dueDate: dueDate,
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
    dueDate: task.dueDate, // Preservar la fecha
  );
  _updateTask(task.id, updatedTask);
}

  void _saveProject() async {
    widget.onUpdate(_project);
  }

  void _showAddTaskDialog() {
  final controller = TextEditingController();
  String selectedStatus = 'todo'; // Default status
  DateTime? selectedDate;

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
            SizedBox(height: 16),
            Row(
              children: [
                Text('Due Date:'),
                SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Select Date',
                  ),
                ),
                if (selectedDate != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        selectedDate = null;
                      });
                    },
                  ),
              ],
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
                _addTask(title, selectedStatus, dueDate: selectedDate);
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
  return Draggable<Task>(
    data: task,
    feedback: Material(
      elevation: 4,
      child: Container(
        width: width,
        child: _buildCardContent(task, true),
      ),
    ),
    childWhenDragging: Opacity(
      opacity: 0.5,
      child: _buildCardContent(task, false),
    ),
    onDragStarted: () {
      setState(() => _isDragging = true);
    },
    onDragEnd: (_) {
      setState(() => _isDragging = false);
      _stopAutoScroll();
    },
    onDragUpdate: (details) {
      if (_isDragging) {
        final screenWidth = MediaQuery.of(context).size.width;
        final sensitivity = 60.0;
        final scrollSpeed = 7.5;

        if (details.globalPosition.dx < sensitivity && 
            _boardScrollController.position.pixels > 0) {
          _startAutoScroll(true, scrollSpeed);
        } else if (details.globalPosition.dx > screenWidth - sensitivity &&
                 _boardScrollController.position.pixels < _boardScrollController.position.maxScrollExtent) {
          _startAutoScroll(false, scrollSpeed);
        } else {
          _stopAutoScroll();
        }
      }
    },
    child: _buildCardContent(task, false),
  );
}

Widget _buildCardContent(Task task, bool isDragging) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    color: isDragging ? Colors.grey[200] : null,
    child: InkWell(
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      _ensureDeleteTask(task.id);
                    }
                  },
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
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

