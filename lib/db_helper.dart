
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _db;
  DBHelper._init();

  Future<void> initDB() async {
    if (_db != null) return;
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'checklist_ob.db');
    _db = await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT UNIQUE,
      tasks TEXT,
      note TEXT,
      signature TEXT
    )''');
  }

  Future<void> insertOrUpdateEntry(ChecklistEntry entry) async {
    final db = _db!;
    String tasksJson = jsonEncode(entry.tasks);
    var existing = await db.query('entries', where: 'date = ?', whereArgs: [entry.date]);
    if (existing.isEmpty) {
      await db.insert('entries', {'date': entry.date, 'tasks': tasksJson, 'note': entry.note, 'signature': entry.signature});
    } else {
      await db.update('entries', {'tasks': tasksJson, 'note': entry.note, 'signature': entry.signature}, where: 'date = ?', whereArgs: [entry.date]);
    }
  }

  Future<List<ChecklistEntry>> getEntriesByDate(String date) async {
    final db = _db!;
    var res = await db.query('entries', where: 'date = ?', whereArgs: [date]);
    return res.map((r) {
      return ChecklistEntry(date: r['date'] as String, tasks: List<Map<String,dynamic>>.from(jsonDecode(r['tasks'] as String)), note: r['note'] as String?, signature: r['signature'] as String?);
    }).toList();
  }

  Future<List<ChecklistEntry>> getEntriesRange(String startDate, String endDate) async {
    final db = _db!;
    var res = await db.rawQuery('SELECT * FROM entries WHERE date BETWEEN ? AND ? ORDER BY date ASC', [startDate, endDate]);
    return res.map((r) {
      return ChecklistEntry(date: r['date'] as String, tasks: List<Map<String,dynamic>>.from(jsonDecode(r['tasks'] as String)), note: r['note'] as String?, signature: r['signature'] as String?);
    }).toList();
  }

  static List<TaskItem> defaultTasks() {
    return [
      TaskItem(title: "Menyapu & mengepel seluruh area kantor (ruang kerja, lobby, pantry, toilet)", time: "06.30 – 08.00"),
      TaskItem(title: "Membersihkan meja, kursi, dan peralatan kerja", time: "06.30 – 08.00"),
      TaskItem(title: "Membersihkan toilet dan mengganti tisu/sabun jika habis", time: "08.00 – 15.00"),
      TaskItem(title: "Membersihkan pantry dan mencuci gelas/piring setelah digunakan", time: "11.30 – 13.00"),
      TaskItem(title: "Menyediakan air minum, kopi, teh untuk staf/rapat", time: "08.00 – 08.30"),
      TaskItem(title: "Mengambil dan mengantar dokumen antar divisi bila diperlukan", time: "09.00 – 15.00"),
      TaskItem(title: "Membuang sampah dari setiap ruangan ke tempat utama", time: "15.30 – 16.30"),
      TaskItem(title: "Menjaga ketersediaan perlengkapan kebersihan (sabun, tisu, pewangi)", time: "Setiap sore"),
      TaskItem(title: "Menyiram dan merawat tanaman kantor (jika ada)", time: "Pagi hari"),
      TaskItem(title: "Membersihkan kaca, pintu, dan area luar kantor (teras/parkir)", time: "Pagi & sore"),
      TaskItem(title: "Membantu menyiapkan ruang rapat dan konsumsi", time: "Sesuai jadwal rapat"),
      TaskItem(title: "Melakukan pengecekan akhir kebersihan sebelum pulang", time: "15.30 – 16.30"),
    ];
  }
}
