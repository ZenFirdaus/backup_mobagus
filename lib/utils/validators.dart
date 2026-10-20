/// Validasi form sederhana (dipakai Login & Register).
class Validators {
  Validators._();

  static String? required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username wajib diisi';
    final trimmed = v.trim();
    if (trimmed.length < 3) return 'Username minimal 3 karakter';
    if (trimmed.length > 30) return 'Username maksimal 30 karakter';
    final ok = RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed);
    return ok ? null : 'Username hanya boleh huruf, angka, dan underscore';
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
    final trimmed = v.trim();
    final ok = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(trimmed);
    return ok ? null : 'Format email belum benar (contoh: nama@email.com)';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Minimal 8 karakter';
    return null;
  }

  static String? confirm(String? v, String original) {
    if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
    if (v != original) return 'Kata sandi tidak sama';
    return null;
  }
}
