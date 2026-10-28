/// Shared form validation so login and registration stay consistent.
class Validators {
  const Validators._();

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final _digitsOnly = RegExp(r'^\d+$');

  static String? mobile(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Mobile number is required';
    if (!_digitsOnly.hasMatch(input)) return 'Digits only';
    if (input.length != 10) return 'Enter a 10 digit mobile number';
    return null;
  }

  static String? required(String? value, String label) {
    if ((value?.trim() ?? '').isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(input)) return 'Enter a valid email';
    return null;
  }

  /// Sign-in only checks that something was typed: existing accounts may have
  /// shorter passwords than the rule we apply to new ones.
  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required';
    return null;
  }

  /// Rule applied when choosing a new password.
  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password is required';
    if (input.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
