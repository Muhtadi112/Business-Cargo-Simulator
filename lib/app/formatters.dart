import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final NumberFormat _usd = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 0,
  );

  static final NumberFormat _number = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimal = NumberFormat('#,##0.0', 'en_US');

  static String money(num value) => _usd.format(value);

  static String number(num value) => _number.format(value);

  static String distance(num kilometers) => '${_decimal.format(kilometers)} km';

  static String weight(num kilograms) {
    if (kilograms >= 1000) {
      return '${_decimal.format(kilograms / 1000)} t';
    }
    return '${_number.format(kilograms)} kg';
  }

  static String percentage(num value) => '${value.toStringAsFixed(0)}%';

  static String duration(Duration value) {
    if (value.isNegative) return '0m';
    final days = value.inDays;
    final hours = value.inHours.remainder(24);
    final minutes = value.inMinutes.remainder(60);
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  static String dateTime(DateTime value) =>
      DateFormat('dd MMM yyyy, HH:mm').format(value.toLocal());
}
