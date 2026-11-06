import 'package:flutter_test/flutter_test.dart';
import 'package:mawoonati/core/utils/validators.dart';

void main() {
  test('email', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('abc'), isNotNull);
    expect(Validators.email('a@b'), isNotNull);
    expect(Validators.email(' a@b.com '), isNull);
  });
  test('password', () {
    expect(Validators.password('short1'), isNotNull);
    expect(Validators.password('onlyletters'), isNotNull);
    expect(Validators.password('12345678'), isNotNull);
    expect(Validators.password('abcdefg1'), isNull);
    expect(Validators.password('كلمةسر123'), isNull);
  });
  test('confirm and required', () {
    expect(Validators.confirmPassword('a', 'b'), isNotNull);
    expect(Validators.confirmPassword('a', 'a'), isNull);
    expect(Validators.required('  ', 'x'), 'x');
    expect(Validators.required('ok', 'x'), isNull);
  });
}
