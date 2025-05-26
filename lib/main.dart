import 'package:flutter/material.dart';
import 'screens/project_list_screen.dart';

void main() {
  runApp(OrganizeIT());
}

class OrganizeIT extends StatelessWidget {
  const OrganizeIT({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrganizeIT',
      theme: ThemeData(
      primarySwatch: Colors.teal,
      ),
      home: ProjectListScreen(),
    );
  }
}
