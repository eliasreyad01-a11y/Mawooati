import 'package:intl/intl.dart';

const _symbols = {
  'JOD': 'د.أ',
  'USD': r'$',
  'EUR': '€',
  'SAR': 'ر.س',
  'AED': 'د.إ',
};

/// يُنسّق مبلغاً بأرقام لاتينية (كما في التصميم) ورمز العملة.
/// الدينار الأردني: حتى 3 منازل عشرية بدون أصفار زائدة.
String formatMoney(num amount, {String code = 'JOD'}) {
  final decimals = code == 'JOD' ? '###' : '##';
  final f = NumberFormat('#,##0.$decimals', 'en');
  return '${f.format(amount)} ${_symbols[code] ?? code}';
}
