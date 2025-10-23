
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:excel/excel.dart' as xls;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  // Data checklist OB
  final List<Map<String, String>> checklist = [
    {'nama': 'Mop lantai', 'status': 'Belum'},
    {'nama': 'Buang sampah', 'status': 'Belum'},
    {'nama': 'Cek pintu', 'status': 'Belum'},
  ];

  // Fungsi logout
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('username');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Fungsi export ke Excel
  Future<void> exportExcel() async {
    var excel = xls.Excel.createExcel();
    xls.Sheet sheet = excel['Rekap'];

    // Header
    sheet.appendRow(['No', 'Nama Tugas', 'Status']);

    // Data checklist
    for (int i = 0; i < checklist.length; i++) {
      sheet.appendRow([i + 1, checklist[i]['nama'], checklist[i]['status']]);
    }

    // Simpan file di folder dokumen
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Checklist_OB.xlsx');
    file.writeAsBytesSync(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File Excel tersimpan di: ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checklist OB Kantor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Checklist tampil dengan scroll
            Expanded(
              child: ListView.builder(
                itemCount: checklist.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(checklist[index]['nama']!),
                      trailing: Text(checklist[index]['status']!),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Tombol export
            ElevatedButton.icon(
              onPressed: exportExcel,
              icon: const Icon(Icons.file_download),
              label: const Text("Export ke Excel"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
