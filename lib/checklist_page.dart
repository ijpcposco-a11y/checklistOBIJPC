


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:excel/excel.dart' as xls;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  List<Map<String, String>> checklist = [
    {'nama': 'Membersihkan meja kerja, kursi & lantai ruagan merja ', 'status': 'Belum', 'note': ''},
    {'nama': 'Menyapu & mengepel seluruh area kantor', 'status': 'Belum', 'note': ''},
    {'nama': 'Membersihakan toilet & mengganti perlengkapan (tissue, sabun, pewangi)', 'status': 'Belum', 'note': ''},
  ];

  @override
  void initState() {
    super.initState();
    loadChecklist();
  }

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

  // Simpan checklist ke SharedPreferences
  Future<void> saveChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'checklistData',
        checklist
            .map((e) => '${e['nama']}||${e['status']}||${e['note']}')
            .toList());
  }

  // Load checklist dari SharedPreferences
  Future<void> loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('checklistData');
    if (data != null) {
      setState(() {
        checklist = data.map((e) {
          final parts = e.split('||');
          return {
            'nama': parts[0],
            'status': parts[1],
            'note': parts.length > 2 ? parts[2] : '',
          };
        }).toList();
      });
    }
  }

  // Fungsi export ke Excel
  Future<void> exportExcel() async {
   

Future<void> exportExcel() async {
  try {
    // Minta izin penyimpanan
    if (await Permission.storage.request().isGranted) {
      var excel = xls.Excel.createExcel();
      xls.Sheet sheet = excel['Rekap'];

      // Header
      sheet.appendRow(['No', 'Nama Tugas', 'Status', 'Catatan Kendala']);

      // Data checklist
      for (int i = 0; i < checklist.length; i++) {
        sheet.appendRow([
          i + 1,
          checklist[i]['nama'],
          checklist[i]['status'],
          checklist[i]['note']
        ]);
      }

      // Nama file dengan tanggal
      String fileName =
          'Checklist_OB_${DateTime.now().toIso8601String().split("T")[0]}.xlsx';

      // Simpan ke folder Download
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(excel.encode()!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ File Excel tersimpan di:\n${file.path}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      // Kalau izin ditolak
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Izin penyimpanan ditolak.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Gagal export: $e')),
    );
  }
}

  }
}
