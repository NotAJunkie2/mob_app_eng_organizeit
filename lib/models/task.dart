class Task {
  final String id;
  String title;
  String status; 
  String details;
  DateTime? dueDate; 

  Task({
    required this.id,
    required this.title,
    this.status = 'todo',
    this.details = '',
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'details': details,
    'dueDate': dueDate?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      status: json['status'],
      details: json['details'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    );
  }
}
