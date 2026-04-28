# Sentra - Smart Budget & Keuangan 💸

**Sentra** adalah aplikasi pencatatan keuangan pribadi dan *budgeting* modern berbasis Flutter. Aplikasi ini dirancang untuk memberikan pengalaman pengguna yang premium, cepat, dan intuitif dengan fitur unggulan **Quick Parse AI (Gemini)** dan pemindaian struk otomatis (OCR) menggunakan **Google ML Kit**. Seluruh data disimpan secara lokal di perangkat Anda menggunakan **Hive**, menjamin privasi dan kecepatan maksimal.

Aplikasi ini baru saja melalui migrasi besar-besaran dengan menerapkan arsitektur **BLoC (Business Logic Component)** untuk *state management* yang lebih tangguh dan mudah dikembangkan (*clean code principles*).

---

## ✨ Fitur Utama

*   **💳 Pencatatan Transaksi:** Catat pemasukan dan pengeluaran dengan antarmuka yang bersih dan interaktif. Tersedia formatter otomatis untuk nominal (ribuan/jutaan).
*   **🤖 Quick Input AI (Gemini 2.5 Flash):** Cukup ketik kalimat sehari-hari (misal: "makan bakso 15 ribu dan bayar parkir 2rb"), AI akan secara otomatis mendeteksi, mengekstrak, dan memisahkan seluruh transaksi Anda.
*   **📸 Scan Struk Otomatis (OCR):** Gunakan kamera pintar untuk memindai struk belanja fisik Anda. Sentra mendeteksi nominal transaksi dan total belanja secara otomatis.
*   **💳 Manajemen Cicilan (Installments):** Pantau rencana cicilan Anda, hubungkan pengeluaran bulanan dengan cicilan yang sedang berjalan secara rapi dan terorganisir.
*   **🎨 Tema Dinamis & Kategori Kustom:** Buat kategori transaksi sendiri (icon & warna). Pengguna juga dapat mengubah tema warna utama aplikasi secara dinamis sesuai selera.
*   **💱 Dukungan Multi Mata Uang:** Ubah mata uang secara langsung di pengaturan (Rupiah, USD, SGD, EUR, dll) dengan bottom sheet pintar yang mendukung *scroll* dinamis.
*   **📊 Statistik & Budgeting:** Pantau pengeluaran vs pemasukan dan lihat pembagian kategori transaksi Anda secara visual di tab Statistik.
*   **🔒 Privasi Penuh (Local-First):** Aplikasi 100% *offline*. Seluruh riwayat transaksi dan preferensi aman tersimpan di dalam perangkat Anda (`Hive`).

---

## 📸 Teknologi & Arsitektur yang Digunakan

*   **Framework:** [Flutter](https://flutter.dev/) (SDK ^3.11.4)
*   **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc) (Pemisahan *business logic* yang clean dan testable)
*   **Penyimpanan Lokal:** [Hive](https://pub.dev/packages/hive_flutter) (Cepat, NoSQL database dengan `AppStorage` abstraction)
*   **Kamera & OCR:** `camera`, `google_mlkit_text_recognition`
*   **AI (Generative AI):** `google_generative_ai` (Gemini 2.5 Flash API)
*   **UI/UX:** Desain khusus dengan *gradient*, *haptic feedback*, transisi mulus, dan ekstraksi *Clean Code UI widgets* (`FocusFieldWrapper`, `TransactionListItem`).

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
3.  **Menjalankan Aplikasi (Menambahkan API Key Gemini):**
    Karena fitur **Quick Input** bergantung pada Gemini AI, Anda perlu menyertakan API Key saat *build/run* melalui argumen `--dart-define`:
    ```bash
    flutter run --dart-define=GEMINI_API_KEY=KODE_API_KEY_ANDA_DISINI
    ```
    *Catatan: Sangat disarankan untuk menjalankan aplikasi di perangkat Android fisik jika ingin menguji fitur Kamera (Pemindaian Struk OCR).*

---

## 🎨 Arsitektur Folder (BLoC)
```text
lib/
├── core/
│   ├── config/        # Konfigurasi aplikasi (ApiConfig)
│   ├── models/        # Model data (Transaction, BudgetItem, dll)
│   ├── services/      # Abstraksi sistem (AppStorage, OcrService, QuickParseService)
│   └── theme/         # Konstanta warna, gaya teks, tema kustom
├── features/          # Feature-first structure (State Management)
│   ├── finance/       # FinanceBloc (Menangani state transaksi, kategori, cicilan)
│   └── settings/      # SettingsBloc (Menangani state tema, mata uang, dll)
├── screens/           # Antarmuka Halaman
│   ├── home_screen.dart             # Dashboard utama & Daftar transaksi
│   ├── quick_input_screen.dart      # Input via Teks (AI Gemini)
│   ├── add_transaction_screen.dart  # Form tambah/edit transaksi manual
│   ├── add_installment_screen.dart  # Manajemen cicilan bulanan
│   ├── camera_screen.dart           # Antarmuka kamera kustom (OCR)
│   └── transaction_detail_screen.dart # Layar detail transaksi
├── widgets/           # Reusable UI Components
│   ├── transaction_list_item.dart
│   └── focus_field_wrapper.dart
└── main.dart                        # Entry point aplikasi
```

---

## 🤝 Berkontribusi
Jika Anda ingin memperbaiki *bug*, meningkatkan algoritma BLoC, atau menambahkan fitur baru:
1. *Fork* proyek ini
2. Buat *branch* fitur Anda (`git checkout -b fitur-baru`)
3. *Commit* perubahan Anda (`git commit -m 'Menambahkan fitur keren'`)
4. *Push* ke *branch* (`git push origin fitur-baru`)
5. Buka sebuah *Pull Request*
