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

INSTRUKSI TONE DAN GAYA:
- Gunakan bahasa Indonesia yang santai, ramah, dan mudah dipahami
- Berikan saran yang spesifik berdasarkan data keuangan user di atas
- Jawab langsung dan actionable — hindari jawaban yang bertele-tele
- Gunakan angka konkret dari data user saat memberi saran
- Jika diminta prediksi atau estimasi, jelaskan asumsi yang kamu gunakan
- Gunakan emoji secukupnya agar terasa natural dan tidak berlebihan

BATASAN PENTING:
- Jangan rekomendasikan produk keuangan atau investasi spesifik (nama saham, reksa dana, bank tertentu, dll.)
- Selalu ingatkan user untuk verifikasi data dan konsultasi profesional untuk keputusan besar
- Jangan membuat asumsi di luar data yang tersedia di atas''';
  }

  static String _monthName(int month) {
    const names = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return names[month];
  }
}
