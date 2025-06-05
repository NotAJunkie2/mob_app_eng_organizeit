import 'package:flutter/material.dart';
import 'package:organizeit/screens/task_board_screen.dart';
import 'package:organizeit/utils/storage.dart';
import '../models/project.dart';
import '../widgets/project_card.dart';
import 'dart:math';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ProjectListScreenState createState() => ProjectListScreenState();
}

class ProjectListScreenState extends State<ProjectListScreen> {
  List<Project> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _saveProjects();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final loaded = await ProjectStorage.loadProjects();
    setState(() => _projects = loaded);
  }

  Future<void> _saveProjects() async {
    await ProjectStorage.saveProjects(_projects);
  }

  void _addProject(String name) {
    setState(() {
      _projects.add(Project(id: Random().nextDouble().toString(), name: name));
    });
    _saveProjects();
  }

  void _editProject(String id, String newName) {
    setState(() {
      final index = _projects.indexWhere((proj) => proj.id == id);
      if (index != -1) {
        _projects[index].name = newName;
      }
    });
    _saveProjects();
  }

  void _deleteProject(String id) {
    setState(() {
      _projects.removeWhere((proj) => proj.id == id);
    });
    _saveProjects();
  }

  void _ensureDeleteProject(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Project'),
        content: Text('Are you sure you want to delete this project?'),
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
              _deleteProject(id);
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

  void _showProjectDialog({Project? project, bool isEditing = false}) {
    final controller = TextEditingController(text: project?.name ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(project == null ? 'Create New Project' : 'Edit Project'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Project Name'),
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
              final name = controller.text.trim();
              if (name.isEmpty) return;
              project == null
                  ? _addProject(name)
                  : _editProject(project.id, name);
              Navigator.pop(context);
            },
            child: Text((isEditing ? 'Save' : 'Create'), style: TextStyle(
              color: Colors.white,
            ),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Projects')),
      body: _projects.isEmpty
          ? Center(child: Text('No projects yet. Add one!'))
          : ListView.builder(
              itemCount: _projects.length,
              itemBuilder: (ctx, index) {
                final proj = _projects[index];
                return ProjectCard(
                  project: proj,
                  onDelete: _ensureDeleteProject,
                  onEdit: () => _showProjectDialog(project: proj, isEditing: true),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskBoardScreen(
                          project: proj,
                          onUpdate: (updatedProject) {
                            setState(() {
                              _projects[index] = updatedProject;
                            });
                            _saveProjects();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProjectDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
