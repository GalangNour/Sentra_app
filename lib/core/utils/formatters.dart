import 'package:sentra_app/core/models/currency_info.dart';

class Fmt {
  static String _symbol = 'Rp';
  static bool _before = true;

  static void setCurrency(CurrencyInfo currency) {
    _symbol = currency.symbol;
    _before = currency.symbolBefore;
  }

  static String compact(double amount) {
    String num;
    if (amount >= 1000000) {
      final m = amount / 1000000;
      num = '${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      num = '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(0)}rb';
    } else {
      num = amount.toInt().toString();
    }
    return _before ? '$_symbol $num' : '$num $_symbol';
  }

  static String full(double amount) {
    final str = amount.toInt().toString();
    final chars = <String>[];
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) chars.add('.');
      chars.add(str[i]);
      count++;
    }
    final number = chars.reversed.join();
    return _before ? '$_symbol $number' : '$number $_symbol';
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return date(dt);
  }

  static String date(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
