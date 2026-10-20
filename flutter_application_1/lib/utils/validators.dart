/// Validasi form sederhana (dipakai Login & Register).
class Validators {
  Validators._();

  static String? required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
    final ok = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v.trim());
    return ok ? null : 'Format email belum benar';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Minimal 8 karakter';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Sertakan minimal 1 huruf besar';
    if (!RegExp(r'\d').hasMatch(v)) return 'Sertakan minimal 1 angka';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nomor WhatsApp wajib diisi';
    final cleaned = v.replaceAll(RegExp(r'[\s\-]'), '');
    final ok = RegExp(r'^(\+62|62|0)8\d{8,11}$').hasMatch(cleaned);
    return ok ? null : 'Gunakan nomor Indonesia, contoh 0812 3456 7890';
  }

  static String? confirm(String? v, String original) {
    if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
    if (v != original) return 'Kata sandi tidak sama';
    return null;
  }
}
