final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email is required.';
  if (!_email.hasMatch(email)) return 'Enter a valid email address.';
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
