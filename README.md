# Sentra - Smart Budget & Keuangan 💸

**Sentra** adalah aplikasi pencatatan keuangan pribadi dan *budgeting* modern berbasis Flutter. Aplikasi ini dirancang untuk memberikan pengalaman pengguna yang premium, cepat, dan intuitif dengan fitur unggulan pemindaian struk otomatis (OCR) menggunakan **Google ML Kit**. Seluruh data disimpan secara lokal di perangkat Anda menggunakan **Hive**, menjamin privasi dan kecepatan maksimal.

---

## ✨ Fitur Utama

*   **💳 Pencatatan Transaksi:** Catat pemasukan dan pengeluaran dengan antarmuka yang bersih dan interaktif. Tersedia formatter otomatis untuk nominal (ribuan/jutaan).
*   **📸 Scan Struk Otomatis (OCR):** Gunakan kamera pintar untuk memindai struk belanja fisik Anda. Sentra menggunakan kecerdasan buatan dari Google ML Kit untuk mendeteksi total harga secara otomatis sehingga Anda tidak perlu mengetik manual.
*   **📂 Kategori Kustom:** Buat kategori pengeluaran/pemasukan Anda sendiri. Pilih dari berbagai *icon* dan *warna* kustom untuk menyesuaikan dengan gaya personal Anda.
*   **💱 Dukungan Multi Mata Uang:** Ubah mata uang secara langsung di pengaturan (Rupiah, USD, SGD, EUR, dll) dengan bottom sheet pintar yang mendukung *scroll* dinamis.
*   **📊 Statistik & Budgeting:** Pantau pengeluaran vs pemasukan dan lihat pembagian kategori transaksi Anda secara visual di tab Statistik.
*   **🛠️ Edit & Manajemen Transaksi:** Buka kartu transaksi untuk melihat detail lengkap, ubah catatan, ubah kategori, atau hapus riwayat secara permanen.
*   **🔒 Privasi Penuh (Local-First):** Aplikasi 100% *offline*. Seluruh riwayat transaksi dan preferensi aman tersimpan di dalam perangkat Anda.

---

## 📸 Teknologi yang Digunakan

*   **Framework:** [Flutter](https://flutter.dev/) (SDK ^3.11.4)
*   **Penyimpanan Lokal:** [Hive](https://pub.dev/packages/hive_flutter) (Cepat, NoSQL database)
*   **Kamera & OCR:** `camera`, `google_mlkit_text_recognition`
*   **UI/UX:** Desain khusus dengan *gradient*, animasi transisi mikro (`TweenAnimationBuilder`, `AnimatedContainer`), dan tipografi dari `google_fonts`.
*   **Lainnya:** `intl`, `uuid`, `shared_preferences`.

---

## 🚀 Cara Menjalankan Proyek Lokal

### Prasyarat
Pastikan Anda sudah menginstal alat-alat berikut:
1.  [Flutter SDK](https://docs.flutter.dev/get-started/install)
2.  Android Studio / Visual Studio Code
3.  Emulator Android / Perangkat Fisik (Minimal Android API 24 untuk mendukung ML Kit)

### Langkah Instalasi
1.  **Clone repositori ini:**
    ```bash
    git clone https://github.com/GalangNour/Sentra_app.git
    cd Sentra_app
    ```
2.  **Unduh dependensi pub:**
    ```bash
    flutter pub get
    ```
3.  **Jalankan aplikasi (Debug):**
    ```bash
    flutter run
    ```
    *Catatan: Sangat disarankan untuk menjalankan aplikasi di perangkat Android fisik jika ingin menguji fitur Kamera (Pemindaian Struk OCR).*

---

## 🎨 Arsitektur & Folder Struktur (Singkat)
```text
lib/
├── core/
│   ├── services/      # Logic database (AppState dengan Hive), OcrService (ML Kit)
│   ├── theme/         # Konstanta warna, gaya teks, gradien kustom
│   └── utils/         # Model data (Transaction, BudgetItem, CurrencyInfo)
├── screens/
│   ├── home_screen.dart             # Dashboard utama & Daftar transaksi
│   ├── add_transaction_screen.dart  # Form tambah/edit transaksi
│   ├── transaction_detail_screen.dart # Layar detail transaksi
│   ├── camera_screen.dart           # Antarmuka kamera kustom
│   ├── scan_result_screen.dart      # Layar validasi hasil scan struk
│   └── settings_screen.dart         # Pengaturan & Manajemen kategori
└── main.dart                        # Entry point aplikasi
```

---

## 🤝 Berkontribusi
Jika Anda ingin memperbaiki *bug*, meningkatkan algoritma ekstraksi teks struk, atau menambahkan fitur baru:
1. *Fork* proyek ini
2. Buat *branch* fitur Anda (`git checkout -b fitur-baru`)
3. *Commit* perubahan Anda (`git commit -m 'Menambahkan fitur keren'`)
4. *Push* ke *branch* (`git push origin fitur-baru`)
5. Buka sebuah *Pull Request*
