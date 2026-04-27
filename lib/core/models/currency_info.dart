class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final bool symbolBefore;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    this.symbolBefore = true,
  });

  static const idr = CurrencyInfo(
    code: 'IDR',
    symbol: 'Rp',
    name: 'Rupiah Indonesia',
  );
  static const usd = CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar');
  static const sgd = CurrencyInfo(
    code: 'SGD',
    symbol: 'S\$',
    name: 'Singapore Dollar',
  );
  static const myr = CurrencyInfo(
    code: 'MYR',
    symbol: 'RM',
    name: 'Malaysian Ringgit',
  );
  static const eur = CurrencyInfo(code: 'EUR', symbol: 'EUR', name: 'Euro');
  static const gbp = CurrencyInfo(
    code: 'GBP',
    symbol: 'GBP',
    name: 'British Pound',
  );
  static const jpy = CurrencyInfo(
    code: 'JPY',
    symbol: 'JPY',
    name: 'Japanese Yen',
  );
  static const aud = CurrencyInfo(
    code: 'AUD',
    symbol: 'A\$',
    name: 'Australian Dollar',
  );
  static const cny = CurrencyInfo(
    code: 'CNY',
    symbol: 'CNY',
    name: 'Chinese Yuan',
  );
  static const krw = CurrencyInfo(
    code: 'KRW',
    symbol: 'KRW',
    name: 'Korean Won',
  );
  static const thb = CurrencyInfo(
    code: 'THB',
    symbol: 'THB',
    name: 'Thai Baht',
  );
  static const php = CurrencyInfo(
    code: 'PHP',
    symbol: 'PHP',
    name: 'Philippine Peso',
  );

  static const all = [
    idr,
    usd,
    sgd,
    myr,
    eur,
    gbp,
    jpy,
    aud,
    cny,
    krw,
    thb,
    php,
  ];

  static CurrencyInfo fromCode(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => idr);
}
