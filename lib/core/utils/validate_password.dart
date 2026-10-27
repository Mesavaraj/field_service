String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please create a password';
  }
  if (value.length < 8) {
    return 'Password must contain at least 8 characters';
  }
  return null;
}
