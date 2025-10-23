
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:excel/excel.dart' as xls;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  // Contoh data checklist sederhana
  final List<Map<String, String>> checklist = [
    {'nama': 'Mop lantai', 'status': 'Belum'},
    {'nama': 'Buang sampah', 'status': 'Belum'},
    {'nama': 'Cek pintu', 'status': 'Belum'},
  ];

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('username');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Export ke Excel sederhana
  Future<void> exportExcel() async {
    var excel = xls.Excel.createExcel();
    xls.Sheet sheet = excel['Rekap'];

    sheet.appendRow(['No', 'Nama Tugas', 'Status']);
    for (int i = 0; i < checklist.length; i++) {
      sheet.appendRow([i + 1, checklist[i]['nama'], checklist[i]['status']]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Checklist_OB.xlsx');
    file.writeAsBytesSync(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File Excel tersimpan di Dokumen')));
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
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
            ElevatedButton.icon(
              onPressed: exportExcel,
              icon: const Icon(Icons.file_download),
              label: const Text("Export ke Excel"),
            )
          ],
        ),
      ),
    );
  }
}
