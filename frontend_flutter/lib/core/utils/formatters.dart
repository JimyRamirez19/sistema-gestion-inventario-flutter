import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _copCurrency = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat.decimalPattern('es_CO');

  static String formatCurrency(num amount) {
    return _copCurrency.format(amount);
  }

  static String formatInteger(int number) {
    return _numberFormat.format(number);
  }
}
