
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'db_helper.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.instance.initDB();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checklist OB Kantor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChecklistPage(),
    );
  }
}

class ChecklistPage extends StatefulWidget {
  @override
  _ChecklistPageState createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  List<TaskItem> tasks = [];
  TextEditingController noteController = TextEditingController();
  SignatureController _sigController = SignatureController(penStrokeWidth: 2, penColor: Colors.black);

  @override
  void initState() {
    super.initState();
    tasks = DBHelper.defaultTasks();
    _loadToday();
  }

  Future<void> _loadToday() async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var entries = await DBHelper.instance.getEntriesByDate(today);
    if (entries.isNotEmpty) {
      // load first entry for simplicity
      var e = entries.first;
      setState(() {
        tasks = e.tasks.map((t) => TaskItem.fromMap(t)).toList();
        noteController.text = e.note ?? '';
      });
    }
  }

  Future<void> _save() async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<Map<String, dynamic>> tmap = tasks.map((t) => t.toMap()).toList();
    var entry = ChecklistEntry(date: today, tasks: tmap, note: noteController.text);
    await DBHelper.instance.insertOrUpdateEntry(entry);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checklist tersimpan')));
  }

  Future<void> _exportWeekly() async {
    // Ensure storage permission
    if (!await Permission.storage.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Izin penyimpanan diperlukan')));
      return;
    }
    String weekStart = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)));
    // collect 7 days
    List<ChecklistEntry> entries = await DBHelper.instance.getEntriesRange(weekStart, DateFormat('yyyy-MM-dd').format(DateTime.now()));
    var excel = Excel.createExcel();
    Sheet sheet = excel['Rekap'];
    sheet.appendRow(['Tanggal','Kegiatan','Status','Catatan']);
    for (var e in entries) {
      for (var t in e.tasks) {
        sheet.appendRow([e.date, t['title'], t['done'] ? 'Selesai' : 'Belum', e.note ?? '']);
      }
    }
    var bytes = excel.encode();
    final dir = await getExternalStorageDirectory();
    String fname = 'rekap_ob_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    String fullPath = '${dir!.path}/$fname';
    File(fullPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ekspor selesai: $fullPath')));
    // Offer to share
    await Share.shareFiles([fullPath], text: 'Rekap Checklist OB');
  }

  Future<void> _captureSignatureAndSave() async {
    if (_sigController.isNotEmpty) {
      Uint8List data = await _sigController.toPngBytes() ?? Uint8List(0);
      String base64Sig = base64Encode(data);
      // Save signature to DB as part of today's entry
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var entry = ChecklistEntry(date: today, tasks: tasks.map((t)=>t.toMap()).toList(), note: noteController.text, signature: base64Sig);
      await DBHelper.instance.insertOrUpdateEntry(entry);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tanda tangan tersimpan')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silakan tanda tangan terlebih dahulu')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist OB Kantor - Harian'),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: _save),
          IconButton(icon: Icon(Icons.file_upload), onPressed: _exportWeekly)
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: Text('Tanggal: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}')),
            ]),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  var t = tasks[index];
                  return CheckboxListTile(
                    title: Text(t.title),
                    subtitle: t.time != null ? Text(t.time!) : null,
                    value: t.done,
                    onChanged: (v) {
                      setState(() { t.done = v ?? false; });
                    },
                  );
                },
              ),
            ),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: 'Catatan / Kendala', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            SizedBox(height: 8),
            Text('Tanda Tangan (OB / Supervisor)'), 
            Container(
              height: 150,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Signature(controller: _sigController, backgroundColor: Colors.white),
            ),
            Row(
              children: [
                ElevatedButton(onPressed: (){ _sigController.clear(); }, child: Text('Bersihkan')),
                SizedBox(width: 8),
                ElevatedButton(onPressed: _captureSignatureAndSave, child: Text('Simpan & Tanda Tangan')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
