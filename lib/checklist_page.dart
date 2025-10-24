
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
    {'nama': 'Membersihkan meja kerja, kursi & lantai ruangan kerja', 'status': 'Belum', 'note': ''},
    {'nama': 'Menyapu & mengepel seluruh area kantor', 'status': 'Belum', 'note': ''},
    {'nama': 'Membersihkan toilet & mengganti perlengkapan (tissue, sabun, pewangi)', 'status': 'Belum', 'note': ''},
    {'nama': 'Membersihkan pantry, mencuci gelas/piring dan menjaga kebersihan alat makan', 'status': 'Belum', 'note': ''},
    {'nama': 'Membantu menyiapkan ruang rapat dan komsumsi rapat', 'status': 'Belum', 'note': ''},
    {'nama': 'Membuang sampah ke tempat penampungan sampah', 'status': 'Belum', 'note': ''},
    {'nama': 'Menjaga ketersediaanperlengkapan kebersihan(sabun, tisu, pewangi, pel, sapu, dll)', 'status': 'Belum', 'note': ''},
  ];

  @override
  void initState() {
    super.initState();
    loadChecklist();
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('username');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> saveChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'checklistData',
      checklist.map((e) => '${e['nama']}||${e['status']}||${e['note']}').toList(),
    );
  }

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

  // ✅ Fungsi export Excel sudah benar & utuh
  Future<void> exportExcel() async {
    try {
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
            checklist[i]['note'],
          ]);
        }

        // Nama file
        String fileName =
            'Checklist_OB_${DateTime.now().toIso8601String().split("T")[0]}.xlsx';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist OB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveChecklist,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: exportExcel,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: checklist.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              title: Text(checklist[index]['nama'] ?? ''),
              subtitle: TextField(
                decoration: const InputDecoration(
                  labelText: 'Catatan Kendala',
                ),
                onChanged: (val) {
                  checklist[index]['note'] = val;
                  saveChecklist();
                },
              ),
              trailing: DropdownButton<String>(
                value: checklist[index]['status'],
                items: const [
                  DropdownMenuItem(value: 'Belum', child: Text('Belum')),
                  DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                ],
                onChanged: (val) {
                  setState(() {
                    checklist[index]['status'] = val!;
                    saveChecklist();
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
