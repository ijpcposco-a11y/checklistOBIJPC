
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:excel/excel.dart' as xls;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  List<Map<String, dynamic>> checklist = [
    {'nama': '1.Membersihkan meja kerja, kursi & lantai ruangan kerja', 'selesai': false, 'note': ''},
    {'nama': '2.Menyapu & mengepel seluruh area kantor', 'selesai': false, 'note': ''},
    {'nama': '3.Membersihkan toilet & mengganti perlengkapan (tissue, sabun, pewangi)', 'selesai': false, 'note': ''},
    {'nama': '4.Membersihkan pantry, mencuci gelas/piring dan menjaga kebersihan alat makan', 'selesai': false, 'note': ''},
    {'nama': '5.Membantu menyiapkan ruang rapat dan komsumsi rapat', 'selesai': false, 'note': ''},
    {'nama': '6.Membuang sampah ke tempat penampungan sampah', 'selesai': false, 'note': ''},
    {'nama': '7.Menjaga ketersediaan perlengkapan kebersihan(sabun, tisu, pewangi, pel, sapu, dll)', 'selesai': false, 'note': ''},
  ];

  DateTime selectedDate = DateTime.now();

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
    // Pastikan convert bool ke string
    List<String> dataToSave = checklist.map((e) =>
        '${e['nama']}||${e['selesai'] ? 'true' : 'false'}||${e['note']}').toList();
    await prefs.setStringList('checklistData', dataToSave);
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
            'selesai': parts.length > 1 ? parts[1] == 'true' : false,
            'note': parts.length > 2 ? parts[2] : '',
          };
        }).toList();
      });
    }
  }

  Future<void> exportExcel() async {
    try {
      if (await Permission.storage.request().isGranted) {
        var excel = xls.Excel.createExcel();
        xls.Sheet sheet = excel['Rekap'];
        sheet.appendRow(['No', 'Tanggal', 'Nama Tugas', 'Status', 'Catatan Kendala']);

        for (int i = 0; i < checklist.length; i++) {
          sheet.appendRow([
            i + 1,
            DateFormat('yyyy-MM-dd').format(selectedDate),
            checklist[i]['nama'],
            checklist[i]['selesai'] ? 'Selesai' : 'Belum',
            checklist[i]['note'],
          ]);
        }

        String fileName = 'Checklist_OB_${DateFormat('yyyyMMdd').format(selectedDate)}.xlsx';

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
      backgroundColor: Colors.lightBlue[100],
      appBar: AppBar(
        title: const Text('Checklist OB'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: saveChecklist),
          IconButton(icon: const Icon(Icons.download), onPressed: exportExcel),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => logout(context)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'Tanggal: ${DateFormat('EEEE, dd MMMM yyyy').format(selectedDate)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: checklist.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: checklist[index]['selesai'] ? Colors.green[100] : null,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(checklist[index]['nama'] ?? '',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                              Checkbox(
                                value: checklist[index]['selesai'],
                                onChanged: (val) {
                                  setState(() {
                                    checklist[index]['selesai'] = val!;
                                    saveChecklist();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Catatan Kendala',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (val) {
                              checklist[index]['note'] = val;
                              saveChecklist();
                            },
                            controller: TextEditingController(
                                text: checklist[index]['note']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
