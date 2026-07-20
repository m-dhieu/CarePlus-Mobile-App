final RegExp _e164Phone = RegExp(r'^\+[1-9]\d{7,14}$');

String? validatePhone(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty) return 'Phone number is required.';
  if (!_e164Phone.hasMatch(phone)) {
    return 'Enter phone number in international format, e.g. +250788123456.';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Password is required.';
  if (password.length < 8) return 'Password must be at least 8 characters.';
  return null;
}

String? validateFullName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Full name is required.';
  if (name.length < 2) return 'Enter your full name.';
  return null;
}

String? validateOtpCode(String? value) {
  final code = value?.trim() ?? '';
  if (code.isEmpty) return 'Enter the code you received.';
  if (!RegExp(r'^\d{6}$').hasMatch(code)) return 'Enter the 6-digit code.';
  return null;
}
