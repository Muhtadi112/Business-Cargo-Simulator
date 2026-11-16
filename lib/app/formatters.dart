import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final NumberFormat _usd = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 0,
  );
  static final NumberFormat _number = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimal = NumberFormat('#,##0.0', 'en_US');

  static String money(num value) {
    final absolute = value.abs();
    String compact(double amount, int decimals) {
      var result = amount.toStringAsFixed(decimals);
      if (result.contains('.')) {
        while (result.endsWith('0')) {
          result = result.substring(0, result.length - 1);
        }
        if (result.endsWith('.')) {
          result = result.substring(0, result.length - 1);
        }
      }
      return result;
    }

    final prefix = value < 0 ? '-' : '';
    if (absolute >= 1000000000) {
      return prefix + r'$' + compact(absolute / 1000000000, 2) + 'B';
    }
    if (absolute >= 1000000) {
      return prefix + r'$' + compact(absolute / 1000000, 2) + 'M';
    }
    if (absolute >= 1000) {
      return prefix + r'$' + compact(absolute / 1000, 1) + 'K';
    }
    return _usd.format(value);
  }

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

abstract final class GameFormatters {
  static String currency(num value) => AppFormatters.money(value);
}
