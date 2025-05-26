class Task {
  final String id;
  String title;
  String status; // 'todo', 'in_progress', 'done'

  Task({required this.id, required this.title, this.status = 'todo'});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      status: json['status'],
    );
  }
}
