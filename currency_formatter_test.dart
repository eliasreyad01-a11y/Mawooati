import 'package:flutter_test/flutter_test.dart';
import 'package:mawoonati/core/utils/currency_formatter.dart';

void main() {
  test('JOD uses Arabic symbol and trims zeros', () {
    expect(formatMoney(65), '65 د.أ');
    expect(formatMoney(150.5), '150.5 د.أ');
    expect(formatMoney(1234.567), '1,234.567 د.أ');
  });
  test('other currencies use 2 decimals max', () {
    expect(formatMoney(10.456, code: 'USD'), r'10.46 $');
  });
}
