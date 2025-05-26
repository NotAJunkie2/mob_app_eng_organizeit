import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';

class ProjectStorage {
  static const String _key = 'projects';

  static Future<void> saveProjects(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(projects.map((p) => p.toJson()).toList());
    print("Saving JSON: $encoded");
    await prefs.setString(_key, encoded);
  }

  static Future<List<Project>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final decoded = jsonDecode(data) as List<dynamic>;
    print("Loading JSON: $decoded");
    return decoded.map((item) => Project.fromJson(item)).toList();
  }
}
