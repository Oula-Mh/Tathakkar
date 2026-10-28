import 'package:formz/formz.dart';

import '../constants/app_constants.dart';
import '../localization/l10n_keys.dart';

/// Every input returns a localization key as its error, or null when valid.
final _emailRegex = RegExp(r'^[\w.+\-]+@([\w\-]+\.)+[\w\-]{2,}$');

class NameInput extends FormzInput<String, String> {
  const NameInput.pure() : super.pure('');
  const NameInput.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) =>
      value.trim().isEmpty ? L.errNameRequired : null;
}

class EmailInput extends FormzInput<String, String> {
  const EmailInput.pure() : super.pure('');
  const EmailInput.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    final v = value.trim();
    if (v.isEmpty) return L.errEmailRequired;
    if (!_emailRegex.hasMatch(v)) return L.errEmailInvalid;
    return null;
  }
}

class PasswordInput extends FormzInput<String, String> {
  const PasswordInput.pure() : super.pure('');
  const PasswordInput.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    if (value.isEmpty) return L.errPasswordRequired;
    if (value.length < BusinessRules.minPasswordLength) {
      return L.errPasswordShort;
    }
    return null;
  }
}

/// Login only checks "not empty" so old/short passwords can still sign in.
class LoginPasswordInput extends FormzInput<String, String> {
  const LoginPasswordInput.pure() : super.pure('');
  const LoginPasswordInput.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) =>
      value.isEmpty ? L.errPasswordRequired : null;
}

class ConfirmPasswordInput extends FormzInput<String, String> {
  const ConfirmPasswordInput.pure({this.password = ''}) : super.pure('');
  const ConfirmPasswordInput.dirty({required this.password, String value = ''})
      : super.dirty(value);

  final String password;

  @override
  String? validator(String value) {
    if (value.isEmpty) return L.errConfirmRequired;
    if (value != password) return L.errPasswordMismatch;
    return null;
  }
}
