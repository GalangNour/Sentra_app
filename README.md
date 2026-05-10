# Sentra - Smart Budget & Keuangan 💸

**Sentra** adalah aplikasi pencatatan keuangan pribadi dan *budgeting* modern berbasis Flutter. Aplikasi ini dirancang untuk memberikan pengalaman pengguna yang premium, cepat, dan intuitif dengan fitur unggulan **Quick Parse AI (Gemini)**, **SentraBrain AI**, dan pemindaian struk otomatis (OCR) menggunakan **Google ML Kit**. Seluruh data disimpan secara lokal di perangkat Anda menggunakan **Hive**, menjamin privasi dan kecepatan maksimal.

Aplikasi ini menggunakan arsitektur **BLoC (Business Logic Component)** untuk *state management* yang tangguh dan mudah dikembangkan (*clean code principles*).

---

## ✨ Fitur Utama

*   **💳 Pencatatan Transaksi:** Catat pemasukan dan pengeluaran dengan antarmuka yang bersih dan interaktif. Tersedia formatter otomatis untuk nominal (ribuan/jutaan).
*   **🤖 Quick Input AI & Voice Input:** Cukup ketik kalimat sehari-hari atau **gunakan suara Anda** untuk mendikte transaksi (dilengkapi dengan efek animasi *typewriter*). AI (Gemini 2.5 Flash) akan secara otomatis mendeteksi, mengekstrak, dan memisahkan seluruh transaksi Anda.
*   **📸 Scan Struk Otomatis (OCR):** Gunakan kamera pintar untuk memindai struk belanja fisik Anda. Sentra mendeteksi nominal transaksi dan total belanja secara otomatis.
*   **🧠 SentraBrain AI:** Asisten AI cerdas terintegrasi di beranda yang memberikan wawasan (insights), ringkasan, dan saran keuangan secara *real-time* dengan dukungan visualisasi data grafik (*fl_chart*).
*   **💳 Manajemen Cicilan (Installments):** Pantau rencana cicilan Anda, hubungkan pengeluaran bulanan dengan cicilan yang sedang berjalan, serta kemampuan untuk mengedit cicilan aktif.
*   **🎨 Tema Dinamis & Kategori Kustom:** Buat kategori transaksi sendiri (icon, warna, dan penentuan tipe Pemasukan/Pengeluaran). Pengguna juga dapat mengubah tema warna utama aplikasi secara dinamis sesuai selera.
*   **💱 Dukungan Multi Mata Uang:** Ubah mata uang secara langsung di pengaturan (Rupiah, USD, SGD, EUR, dll) dengan bottom sheet pintar yang mendukung *scroll* dinamis.
*   **📊 Statistik & Budgeting:** Pantau pengeluaran vs pemasukan dan lihat pembagian kategori transaksi Anda secara visual di tab Statistik khusus.
*   **🔒 Privasi Penuh (Local-First):** Aplikasi 100% *offline*. Seluruh riwayat transaksi dan preferensi aman tersimpan di dalam perangkat Anda (`Hive`).

---

## 📸 Teknologi & Arsitektur yang Digunakan

*   **Framework:** [Flutter](https://flutter.dev/)
*   **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc) (Pemisahan *business logic* yang clean dan testable)
*   **Penyimpanan Lokal:** [Hive](https://pub.dev/packages/hive_flutter) (Cepat, NoSQL database dengan `AppStorage` abstraction)
*   **Kamera & OCR:** `camera`, `google_mlkit_text_recognition`
*   **AI (Generative AI):** `google_generative_ai` (Gemini 2.5 Flash API)
*   **Speech & Chart:** `speech_to_text`, `fl_chart`
*   **UI/UX:** Desain khusus dengan *gradient*, *haptic feedback*, transisi mulus, dan arsitektur *Clean Code* terpisah antara *Main Navigation* dan *Screens*.

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
3.  **Menjalankan Aplikasi:**
    ```bash
    flutter run
    ```
    *Catatan: Sangat disarankan untuk menjalankan aplikasi di perangkat Android fisik jika ingin menguji fitur Kamera (Pemindaian Struk OCR) dan Voice Input (Mikrofon).*

---

## 🎨 Arsitektur Folder (BLoC)
```text
lib/
├── core/
│   ├── config/        # Konfigurasi aplikasi (ApiConfig)
│   ├── models/        # Model data (Transaction, BudgetItem, dll)
│   ├── services/      # Abstraksi sistem (AppStorage, AiService, OcrService)
│   └── theme/         # Konstanta warna, gaya teks, tema kustom
├── features/          # Feature-first structure (State Management)
│   ├── categories/    # CategoriesCubit
│   ├── installments/  # InstallmentsCubit
│   ├── settings/      # SettingsCubit
│   └── transactions/  # TransactionsCubit
├── screens/           # Antarmuka Halaman
│   ├── main_screen.dart             # Root navigasi (Tab controller)
│   ├── home_screen.dart             # Dashboard utama
│   ├── activity_screen.dart         # Layar riwayat aktivitas
│   ├── statistik_screen.dart        # Layar analitik & grafik
│   ├── sentra_brain_screen.dart     # Layar obrolan AI
│   ├── quick_input_screen.dart      # Input via Teks/Voice (AI)
│   ├── camera_screen.dart           # Antarmuka kamera kustom (OCR)
│   └── ...
├── widgets/           # Reusable UI Components
│   ├── main_bottom_nav.dart         # Bottom Navigation kustom
│   ├── ai_modal_sheet.dart          # Modal interaksi AI
│   └── ...
└── main.dart                        # Entry point aplikasi
```
