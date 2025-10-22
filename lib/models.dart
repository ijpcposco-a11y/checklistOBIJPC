
class TaskItem {
  String title;
  String? time;
  bool done;

  TaskItem({required this.title, this.time, this.done = false});

  Map<String, dynamic> toMap() {
    return {'title': title, 'time': time, 'done': done ? 1 : 0};
  }

  factory TaskItem.fromMap(Map<String, dynamic> m) {
    return TaskItem(title: m['title'], time: m['time'], done: m['done']==1 || m['done']==true);
  }
}

class ChecklistEntry {
  String date;
  List<Map<String, dynamic>> tasks;
  String? note;
  String? signature; // base64 png

  ChecklistEntry({required this.date, required this.tasks, this.note, this.signature});

  Map<String, dynamic> toMap() {
    return {'date': date, 'tasks': tasks, 'note': note, 'signature': signature};
  }
}
