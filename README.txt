
Checklist OB Kantor - Flutter (Offline) Prototype
===============================================

Isi paket ini:
- pubspec.yaml
- lib/main.dart
- lib/models.dart
- lib/db_helper.dart

Fitur:
- Checklist harian (local SQLite)
- Catatan / Kendala
- Tanda tangan digital (signature)
- Ekspor rekap mingguan ke file Excel (.xlsx)
- Multi-device (setiap HP menyimpan datanya lokal). Export dapat dibagikan/diunggah ke supervisor.

Cara build APK (di mesin dengan Flutter terpasang):
1. Pastikan Flutter SDK terpasang dan path sudah diatur.
2. Copy folder ini ke workspace Flutter anda.
3. Jalankan: flutter pub get
4. Untuk debug: flutter run -d emulator-<id> atau perangkat Android terhubung.
5. Untuk membuat APK release: flutter build apk --release
6. Hasil APK berada di build/app/outputs/flutter-apk/app-release.apk

Catatan & batasan:
- Aplikasi ini menyimpan semua data di storage lokal perangkat (SQLite).
- Untuk penggunaan multi-device, supervisor dapat meminta OB mengekspor file Excel mingguan dan menggabungkannya secara manual.
- Silakan tambahkan mekanisme sinkronisasi (server lokal) jika menginginkan pengumpulan otomatis.
