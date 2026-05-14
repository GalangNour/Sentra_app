import 'package:sentra_app/core/models/transaction.dart';
import 'package:sentra_app/core/services/finance_snapshot.dart';
import 'package:sentra_app/core/utils/formatters.dart';

class AiContextBuilder {
  static String build(FinanceSnapshot snapshot) {
    final now = DateTime.now();

    final thisMonthTxs = snapshot.transactions
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .toList();

    final monthlyIncome = thisMonthTxs
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final monthlyExpense = thisMonthTxs
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final monthlySaldo = monthlyIncome - monthlyExpense;

    final Map<String, double> catTotals = {};
    for (final tx in thisMonthTxs.where((t) => t.type == TransactionType.expense)) {
      final label = snapshot.categoryLabel(tx);
      catTotals[label] = (catTotals[label] ?? 0) + tx.amount;
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final catLines = sortedCats.isEmpty
        ? '(belum ada pengeluaran bulan ini)'
        : sortedCats.map((e) => '- ${e.key}: ${Fmt.full(e.value)}').join('\n');

    final recent = snapshot.transactions.take(10).toList();
    final txLines = recent.isEmpty
        ? '(belum ada transaksi)'
        : recent.asMap().entries.map((e) {
            final tx = e.value;
            final type = tx.type == TransactionType.income ? 'Masuk' : 'Keluar';
            final cat = snapshot.categoryLabel(tx);
            return '${e.key + 1}. [${Fmt.date(tx.date)}] ${tx.title} — $type ${Fmt.full(tx.amount)} ($cat)';
          }).join('\n');

    final totalSaldo = Fmt.full(snapshot.balance);

    // ── Weekly anomaly context ──────────────────────────────────────────────
    final weekday = now.weekday; // 1=Mon … 7=Sun
    final weekStart = DateTime(now.year, now.month, now.day - (weekday - 1));
    final fourWeeksAgo = weekStart.subtract(const Duration(days: 28));

    final thisWeekExpenses = snapshot.transactions.where(
      (tx) =>
          tx.type == TransactionType.expense &&
          !tx.date.isBefore(weekStart) &&
          tx.date.isBefore(now.add(const Duration(days: 1))),
    ).toList();

    final double thisWeekTotal =
        thisWeekExpenses.fold(0.0, (s, tx) => s + tx.amount);

    final Map<String, double> thisWeekCat = {};
    for (final tx in thisWeekExpenses) {
      final label = snapshot.categoryLabel(tx);
      thisWeekCat[label] = (thisWeekCat[label] ?? 0) + tx.amount;
    }

    final priorExpenses = snapshot.transactions.where(
      (tx) =>
          tx.type == TransactionType.expense &&
          !tx.date.isBefore(fourWeeksAgo) &&
          tx.date.isBefore(weekStart),
    ).toList();

    final Map<String, double> priorCatTotal = {};
    for (final tx in priorExpenses) {
      final label = snapshot.categoryLabel(tx);
      priorCatTotal[label] = (priorCatTotal[label] ?? 0) + tx.amount;
    }

    final Map<String, double> weeklyAvgCat =
        priorCatTotal.map((k, v) => MapEntry(k, v / 4.0));

    // Build display lines for weekly category data
    final sortedThisWeek = thisWeekCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final weekCatLines = sortedThisWeek.isEmpty
        ? '(belum ada pengeluaran minggu ini)'
        : sortedThisWeek
            .map((e) => '- ${e.key}: ${Fmt.full(e.value)}')
            .join('\n');

    final sortedAvg = weeklyAvgCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final avgCatLines = sortedAvg.isEmpty
        ? '(belum ada data 4 minggu terakhir)'
        : sortedAvg
            .map((e) => '- ${e.key}: ${Fmt.compact(e.value)}/minggu')
            .join('\n');

    // Detect anomalies
    final anomalies = <String>[];

    // Rule 1: kategori naik >50% dari rata-rata mingguan
    for (final entry in thisWeekCat.entries) {
      final cat = entry.key;
      final thisWeek = entry.value;
      final avg = weeklyAvgCat[cat] ?? 0;
      if (avg > 0 && thisWeek > avg * 1.5) {
        final pct = ((thisWeek / avg - 1) * 100).toStringAsFixed(0);
        anomalies.add(
          '⚠ Lonjakan $cat +$pct% dari rata-rata (${Fmt.compact(avg)}/minggu → ${Fmt.compact(thisWeek)} minggu ini)',
        );
      }
    }

    // Rule 2: kategori baru tiba-tiba masuk top 3 minggu ini
    for (int i = 0; i < sortedThisWeek.length && i < 3; i++) {
      final cat = sortedThisWeek[i].key;
      if (!weeklyAvgCat.containsKey(cat)) {
        anomalies.add(
          '🆕 $cat muncul dominan minggu ini (${Fmt.compact(thisWeekCat[cat]!)}) — tidak ada di 4 minggu sebelumnya',
        );
      }
    }

    // Rule 3: transaksi tunggal >30% dari total pengeluaran minggu ini
    if (thisWeekTotal > 0) {
      for (final tx in thisWeekExpenses) {
        if (tx.amount / thisWeekTotal > 0.30) {
          final pct = (tx.amount / thisWeekTotal * 100).toStringAsFixed(0);
          anomalies.add(
            '💸 "${tx.title}" (${Fmt.compact(tx.amount)}) = $pct% dari total pengeluaran minggu ini',
          );
        }
      }
    }

    final anomalyLines = anomalies.isEmpty
        ? '(tidak ada anomali terdeteksi)'
        : anomalies.join('\n');
    // ───────────────────────────────────────────────────────────────────────

    return '''Kamu adalah Sentra Brain, asisten keuangan pribadi di aplikasi Sentra milik user ini.

RINGKASAN KEUANGAN BULAN INI (${_monthName(now.month)} ${now.year}):
- Total Pemasukan: ${Fmt.full(monthlyIncome)}
- Total Pengeluaran: ${Fmt.full(monthlyExpense)}
- Saldo Bulan Ini: ${Fmt.full(monthlySaldo)}
- Total Saldo Keseluruhan: $totalSaldo

PENGELUARAN PER KATEGORI BULAN INI:
$catLines

10 TRANSAKSI TERBARU:
$txLines

PENGELUARAN MINGGU INI PER KATEGORI (total: ${Fmt.full(thisWeekTotal)}):
$weekCatLines

RATA-RATA PENGELUARAN 4 MINGGU TERAKHIR PER KATEGORI:
$avgCatLines

ANOMALI TERDETEKSI MINGGU INI:
$anomalyLines

INSTRUKSI TONE DAN GAYA:
- Gunakan bahasa Indonesia yang santai, ramah, dan mudah dipahami
- Berikan saran yang spesifik berdasarkan data keuangan user di atas
- Jawab SANGAT SINGKAT, padat, dan to-the-point (maksimal 2-3 paragraf pendek)
- JANGAN menjabarkan atau menganalisis semua transaksi/kategori satu per satu. Fokus hanya pada 1-2 hal yang paling krusial.
- Berikan saran yang actionable dan konkret berdasarkan angka dari data user.
- Jika ada anomali di atas, sebutkan secara proaktif meski user tidak tanya — tapi tetap singkat.
- Jika diminta prediksi atau estimasi, jelaskan asumsi secara ringkas.
- Gunakan emoji secukupnya agar terasa natural dan tidak berlebihan

BATASAN PENTING:
- Jangan rekomendasikan produk keuangan atau investasi spesifik (nama saham, reksa dana, bank tertentu, dll.)
- Selalu ingatkan user untuk verifikasi data dan konsultasi profesional untuk keputusan besar
- Jangan membuat asumsi di luar data yang tersedia di atas

FORMAT RESPONS WAJIB:
Selalu jawab dalam format JSON valid. Pilih type yang paling sesuai:

1. Jawaban teks biasa:
{"type":"text","text":"jawaban kamu disini"}

2. Jawaban dengan pie chart pengeluaran per kategori:
{"type":"chart","text":"kalimat pengantar singkat","chart":{"total":6300000,"items":[{"label":"Makanan","value":2394000,"percentage":38},{"label":"Transport","value":1512000,"percentage":24}]},"actions":["Buat Plan","Lihat Detail"]}

3. Chart + tombol aksi (untuk pertanyaan analisis pengeluaran):
Gunakan type "mixed" — struktur sama dengan "chart" di atas.

4. Input slider (gunakan saat user perlu input nominal/angka):
{"type":"input_slider","text":"pertanyaan untuk user","min":500000,"max":5000000,"default":2000000,"step":100000,"confirm_label":"Simpan Budget"}

5. Input pilihan chip (gunakan saat user perlu memilih satu opsi):
{"type":"input_choice","text":"pertanyaan untuk user","choices":["Opsi A","Opsi B","Opsi C"]}

ATURAN FORMAT:
- Selalu kembalikan JSON valid, tidak ada teks di luar JSON
- Jangan gunakan markdown code block, langsung JSON saja
- PENTING: Jangan gunakan enter (newline) asli di dalam string JSON. Gunakan spasi atau "\\n" jika butuh baris baru.
- Gunakan type "chart" atau "mixed" hanya jika ada data kategori yang relevan
- Gunakan type "input_slider" atau "input_choice" hanya jika perlu input dari user
- Jika ragu, gunakan type "text"''';
  }

  static String _monthName(int month) {
    const names = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return names[month];
  }
}
