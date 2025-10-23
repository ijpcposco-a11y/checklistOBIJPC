
import 'package:permission_handler/permission_handler.dart';

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
