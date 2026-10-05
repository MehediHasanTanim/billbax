import 'package:intl/intl.dart';

/// Bangladeshi Taka formatting helpers.
abstract final class CurrencyFormat {
  static final NumberFormat _bd = NumberFormat.currency(
    locale: 'en_BD',
    symbol: '৳ ',
    decimalDigits: 0,
  );

  static String taka(num amount) => _bd.format(amount);

  static String takaWithDecimals(num amount) {
    return NumberFormat.currency(
      locale: 'en_BD',
      symbol: '৳ ',
      decimalDigits: 2,
    ).format(amount);
  }
}
