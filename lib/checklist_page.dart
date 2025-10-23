
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
  List<Map<String, String>> checklist = [
    {'nama': 'Mop lantai', 'status': 'Belum', 'note': ''},
    {'nama': 'Buang sampah', 'status': 'Belum', 'note': ''},
    {'nama': 'Cek pintu', 'status': 'Belum', 'note': ''},
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
                      subtitle: checklist[index]['note']!.isNotEmpty
                          ? Text('Catatan: ${checklist[index]['note']}')
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Dropdown status
                          DropdownButton<String>(
                            value: checklist[index]['status'],
                            items: ['Belum', 'Selesai'].map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                checklist[index]['status'] = value!;
                                saveChecklist();
                              });
                            },
                          ),
                          const SizedBox(width: 5),
                          // Icon catatan
                          IconButton(
                            icon: const Icon(Icons.note),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  TextEditingController noteController =
                                      TextEditingController(
                                          text: checklist[index]['note']);
                                  return AlertDialog(
                                    title: const Text('Catatan Kendala'),
                                    content: TextField(
                                      controller: noteController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        hintText: 'Masukkan catatan',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            checklist[index]['note'] =
                                                noteController.text;
                                            saveChecklist();
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Simpan'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
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
