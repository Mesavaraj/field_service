String? validateEmail(String? value) {
  final email = value?.trim() ?? '';

  if (email.isEmpty) return 'Please enter your email';

  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email address';
  }
  return null;
}
