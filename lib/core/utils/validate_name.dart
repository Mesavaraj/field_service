String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter your full name';
  }
  if (value.trim().length < 2) {
    return 'Name must contain at least 2 characters';
  }
  return null;
}
