import 'package:flutter_test/flutter_test.dart';
import 'package:tathakkar/core/forms/form_inputs.dart';
import 'package:tathakkar/core/localization/l10n_keys.dart';

void main() {
  group('EmailInput', () {
    test('empty -> required', () => expect(const EmailInput.dirty('').error, L.errEmailRequired));
    test('bad format -> invalid', () => expect(const EmailInput.dirty('abc@').error, L.errEmailInvalid));
    test('valid -> no error', () => expect(const EmailInput.dirty('sara@mail.com').error, isNull));
  });

  group('PasswordInput', () {
    test('empty', () => expect(const PasswordInput.dirty('').error, L.errPasswordRequired));
    test('short', () => expect(const PasswordInput.dirty('abc123').error, L.errPasswordShort));
    test('ok', () => expect(const PasswordInput.dirty('password1').error, isNull));
  });

  test('ConfirmPasswordInput mismatch', () {
    expect(const ConfirmPasswordInput.dirty(password: 'password1', value: 'password2').error,
        L.errPasswordMismatch);
  });
}
