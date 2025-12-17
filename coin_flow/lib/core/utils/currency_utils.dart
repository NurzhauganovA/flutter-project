import 'package:intl/intl.dart';

class CurrencyUtils {
  // Форматирование в тенге
  static String formatTenge(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat('#,##0.00', 'kk_KZ');
    final formatted = formatter.format(amount);
    return showSymbol ? '$formatted ₸' : formatted;
  }

  // Краткое форматирование (для больших сумм)
  static String formatTengeShort(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₸';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K ₸';
    }
    return formatTenge(amount);
  }

  // Форматирование для ввода
  static String formatInputTenge(String input) {
    // Удаляем все кроме цифр и точки
    String cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');

    // Убеждаемся что только одна точка
    List<String> parts = cleaned.split('.');
    if (parts.length > 2) {
      cleaned = '${parts[0]}.${parts.sublist(1).join()}';
    }

    return cleaned;
  }

  // Парсинг из строки
  static double? parseTenge(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned);
  }
}