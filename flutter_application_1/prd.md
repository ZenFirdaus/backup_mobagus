# FOODIE — Product Requirements Document & Development Rules
# PRO • MATARAMAN EDITION (Yogyakarta & Jawa Tengah)
**Product:** FOODIE — Smart Culinary & Food Discovery (Mataraman Edition)  
**Tagline:** Menyingkap Warisan Rasa Autentik Nusantara  
**Platform:** Android & iOS (Cross-Platform Mobile App)  
**Frontend Framework:** Flutter / Dart  
**Online Database & Auth:** Supabase PostgreSQL & Supabase Auth  
**Local Storage & Offline Cache:** Hive  
**Backend Services:** Supabase Database, Storage, and Edge Functions  
**Design Direction:** Culinary Editorial Futurism  
**Primary Service Area:** Daerah Istimewa Yogyakarta (DIY) dan Provinsi Jawa Tengah  
**Figma Design Reference:** `mobagus.zip` (18 Core Screens)
---
# PART 1 — PRODUCT REQUIREMENTS DOCUMENT (PRD)
## 1. Product Overview
### 1.1 Tentang FOODIE
FOODIE adalah aplikasi mobile penemuan kuliner cerdas yang dirancang khusus untuk mengangkat dan mengeksplorasi warisan kuliner autentik di wilayah Daerah Istimewa Yogyakarta (DIY) dan Provinsi Jawa Tengah (Keraton Yogyakarta, Surakarta Hadiningrat, dan Jalur Rempah Mataram).
Aplikasi mengintegrasikan:
1. Penemuan kuliner berbasis lokasi presisi (Location-Based Services / LBS) dengan pembatasan geografis ketat (DIY & Jateng Scope).
2. Asisten AI Gastronomi berbasis Large Language Model (LLM) yang terhubung langsung ke basis data terverifikasi Supabase.
3. Fitur interaktif pemilihan makanan berbasis sensor gerak (*Shake to Decide* menggunakan Accelerometer) dan orientasi (*Gyroscope*).
4. Verifikasi check-in fisik menggunakan radar Geofence GPS (< 50 meter) dengan integritas anti-cheat dan dukungan sinkronisasi luring (*Hive Offline Sync*).
5. Gamifikasi Gastronomi Mataraman (Level Kurator, Foodie Points, Lencana Warisan Kuliner, dan Katalog Penukaran Voucher Kuliner).
6. Mini Game edukatif harian (*Tebak Kuliner Jogja*) dengan timer dan ensiklopedia rasa.
7. Utilitas wisatawan mancanegara dan domestik: Konverter Kurs Mata Uang (IDR, USD, MYR) dilengkapi tolok ukur harga kuliner riil di Jogja, serta Konverter Zona Waktu (WIB, WITA, WIT, London BST) yang disinkronkan dengan jadwal waktu makan lokal (sarapan, makan siang, makan malam lesehan, dan *supper* angkringan).
### 1.2 Product Vision
Menjadi platform kurasi dan eksplorasi gastronomi warisan lokal terdepan yang memadukan keaslian rasa tradisional dengan kecanggihan rekayasa teknologi mobile modern.
### 1.3 Product Principles
1. **Food & Heritage First:** Makanan autentik dan narasi sejarah kuliner menjadi fokus utama.
2. **Strict Geographic Truth:** Seluruh data kuliner dibatasi secara tegas pada wilayah administratif resmi DIY dan Jawa Tengah.
3. **Data Integrity & Anti-Cheat:** Validasi check-in wajib diverifikasi melalui sinyal GPS riil (<50m), tidak ada klaim check-in palsu.
4. **Offline Resilience:** Akses restoran favorit, riwayat pencarian, dan antrean check-in tetap berfungsi tanpa sinyal berkat database lokal Hive.
5. **Culinary Editorial Futurism:** Visual foto makanan hangat dan menggugah selera dipadukan dengan tipografi editorial berkarakter dan komponen UI modern.
6. **No Phantom Buttons:** Setiap tombol, chip filter, dan kontrol navigasi memiliki fungsi nyata dan penanganan status (*state management*) yang jelas.
### 1.4 Target Users
| Segmen Pengguna | Kebutuhan Utama | Fitur Terkait di FOODIE |
|---|---|---|
| Wisatawan Domestik & Mancanegara | Panduan kuliner legendaris, konversi mata uang, sinkronisasi jam makan lintas zona waktu | Explore, Detail Restoran, Currency & Timezone Converter, Maps |
| Mahasiswa & Pecinta Kuliner Hemat | Tempat makan terjangkau di sekitar kampus/tempat tinggal (< Rp25.000) | Filter Budget, Nearby (< 2km), Home Dashboard |
| Food Explorer & Pecinta Budaya | Eksplorasi resep kuno, kuis edukasi, dan lencana petualangan rasa | Mini Game Tebak Kuliner, Catatan Gastronomi Keraton, Achievements |
| Pengguna Bingung (*Decision Fatigue*) | Keputusan cepat memilih tempat makan tanpa membuang waktu | Shake to Decide (Accelerometer), AI Assistant |
---
## 2. Inventory & Spesifikasi 18 Screen Figma (`mobagus.zip`)
Sesuai dengan acuan utama file desain Figma di `mobagus.zip`, aplikasi FOODIE terdiri dari 18 antarmuka utama:
### 2.1 Screen 1: Intro (`Intro.png`)
- **Fungsi:** Splash screen pembuka dengan identitas *brand* dan inisialisasi sistem.
- **Elemen UI:**
  - Label Scope Geografis: "DAERAH ISTIMEWA YOGYAKARTA & JAWA TENGAH"
  - Titik GNSS Radial Anchor: `7.7956° S, 110.3695° E` (Titik Nol KM Yogyakarta)
  - Badge Edisi: "PRO • MATARAMAN EDITION • 1756"
  - Judul & Tagline: "FOODIE — Menyingkap Warisan Rasa Autentik Nusantara"
  - Sorotan Rasa Hari Ini (3 Dapur Pusaka): Gudeg Kendil Resep 1950, Mangut Lele Asap Kayu Bakar, Kopi Joss Arang Membara
  - Indikator Status Sistem: "Memuat Basis Data Kuliner Offline (Hive)... 100% Siap"
  - Tombol Utama: "Mulai Petualangan Kuliner" -> Navigasi ke Onboarding / Login.
### 2.2 Screen 2: Onboarding (`Onboarding.png`)
- **Fungsi:** Edukasi nilai unik aplikasi dan pengenalan fitur utama sebelum pendaftaran akun.
- **Elemen UI:**
  - Header: Logo "FOODIE PRO", tombol "Lewati" di sudut kanan atas.
  - Tag Validasi: "GPS Sah < 50m • KURASI AUTENTIK KERATON"
  - Headline Editorial: "Rasa Asli yang Tak Pernah Berbohong. Validasi check-in instan via sinyal radar fisik di lokasi warung untuk memastikan ulasan 100% riil dari kurator terdaftar."
  - Highlight Fitur: "Offline Ready (Hive DB)", "Tebak Kuliner Mini-Game", "Konverter Valas & Zona Waktu".
  - Banner Insentif Pengguna: "Dapatkan +100 Foodie Points saat mendaftar akun baru dan buka lencana kurator warisan kuliner Kraton."
  - Badges Statistik: "420+ Warung Legendaris Terverifikasi", "Koleksi Lencana & Tukar Voucher Makan", "Rekomendasi AI & Shake to Decide".
  - Tombol Tindakan:
    - Primary CTA: "Daftar Akun Baru (+100 Poin) ->" (Menuju Register)
    - Secondary Link: "Masuk ke Akun Anda" (Menuju Login)
  - Footer Legalitas: Persetujuan Ketentuan Layanan Kurasi FOODIE DIY & Jateng.
### 2.3 Screen 3: Login (`Login.png`)
- **Fungsi:** Masuk ke akun kurator menggunakan Supabase Auth atau autentikasi biometrik lokal.
- **Elemen UI:**
  - Header: "FOODIE PRO • DIY & Jateng", label "Masuk Akun".
  - Tab Switcher: Tab "Masuk Akun" (Aktif) | Tab "Daftar Akun".
  - Salutation Banner: "Sugeng Rawuh, Kurator Rasa. Masuk ke akun FOODIE Anda untuk mengakses 420+ kurasi kuliner legendaris, simpan favorit, dan kumpulkan Foodie Points."
  - Formulir Masuk:
    - Input Alamat Email (contoh: `dimas.dananjaya@culinary.id`).
    - Input Kata Sandi dengan proteksi masked string dan toggle visibilitas.
    - Checkbox: "Ingat Saya di Perangkat Ini".
    - Link text: "Lupa Kata Sandi?".
  - Tombol Masuk Utama: "Masuk dengan Supabase ->".
  - Tombol Biometrik: "Masuk dengan autentikasi wajah (Tersambung ke Biometrik Lokal)".
  - Pembatas SSO: "ATAU MASUK DENGAN: Google SSO | Passkey ID".
  - Link Beralih: "Belum memiliki akun FOODIE? Daftar Sekarang".
  - Indikator Keamanan: "Supabase Auth • TLS 1.3 End-to-End".
### 2.4 Screen 4: Register (`Register.png`)
- **Fungsi:** Pendaftaran akun baru dengan reward poin dan data validasi check-in warung.
- **Elemen UI:**
  - Header: "FOODIE • DIY & Jateng — MATARAMAN GASTRONOMIC PASS".
  - Judul: "Mulai Petualangan Gastronomi".
  - Tab Switcher: Tab "Masuk Akun" | Tab "Daftar Akun" (Aktif).
  - Perk Anggota Baru: "+100 Poin Selamat Datang instan & Akses Peta Kuliner Offline".
  - Field Formulir:
    - Nama Lengkap (Kurator): `Dimas Dananjaya`.
    - Alamat Email: `nama@email.com`.
    - Nomor WhatsApp / Kontak: `0812 3456 7890` (Keterangan: Digunakan untuk autentikasi check-in GPS warung kuliner tradisional).
    - Kata Sandi: Minimal 8 karakter unik, dilengkapi indikator kekuatan (*Strength Meter: Menengah*).
    - Konfirmasi Kata Sandi.
    - Checkbox Syarat & Kebijakan: "Saya menyetujui Syarat & Ketentuan FOODIE serta kebijakan kurasi kuliner wilayah DIY & Jateng."
  - Tombol Tindakan: "Daftar Akun Baru" (Menuju Langkah 2: Verifikasi Email).
  - Opsi Registrasi Cepat: Google SSO, Apple ID / Passkey.
### 2.5 Screen 5: Verifikasi Email (`Verif Email.png`)
- **Fungsi:** Langkah ke-2 dari 3 tahap registrasi untuk memastikan validitas alamat email kurator.
- **Elemen UI:**
  - Top Bar: Tombol Kembali, Indikator Langkah: "LANGKAH 2 DARI 3".
  - Judul: "Verifikasi Kurator Rasa — Konfirmasi Email Anda".
  - Deskripsi: Informasi pengiriman kode keamanan 6 digit ke email pengguna (`dimas.pratama@kulinerjogja.id`) dilengkapi tautan "Ubah".
  - Kotak Input OTP: 6-digit input box terpisah dengan auto-focus.
  - Penghitung Waktu Mundur: Countdown timer `00:48`.
  - Aksi Alternatif:
    - "Kirim Ulang Surel" (Aktif saat timer berakhir).
    - "Buka Aplikasi Email" (Shortcut intent membuka client email Gmail/Mail di smartphone).
  - Tombol Utama: "Verifikasi & Lanjutkan ->" (Menuju Langkah 3: Setup Biometrik).
  - Footer Keamanan: "Dilindungi oleh Supabase Auth SSL 256-bit. Memastikan kurasi gastronomi terbebas dari akun palsu."
### 2.6 Screen 6: Verifikasi & Aktivasi Biometrik (`Verif biometrik.png`)
- **Fungsi:** Langkah ke-3 registrasi untuk mengaitkan sensor Face ID perangkat ke sesi lokal.
- **Elemen UI:**
  - Top Bar: Label "Langkah 3 dari 3: Keamanan Biometrik", tombol "Nanti Saja" (Lewati).
  - Judul: "AUTENTIKASI BIOMETRIK PRESISI — Masuk Cepat dengan autentikasi wajah".
  - Ilustrasi Sensor: Ikon pemindai autentikasi wajah dengan status "Sensor Biometrik Perangkat Terdeteksi (Android Biometric Prompt / Apple Touch ID)".
  - 3 Keunggulan Fitur:
    1. Akses 1-Ketukan: Masuk aplikasi seketika tanpa input kata sandi berulang.
    2. Validasi Check-in Cepat: Konfirmasi kehadiran GPS di warung mitra & klaim voucher dalam hitungan detik.
    3. Privasi Terisolasi: Kunci biometrik disimpan aman di hardware Secure Enclave perangkat.
  - Tombol Tindakan:
    - Primary CTA: "Aktifkan Autentikasi Wajah Sekarang" (Memicu prompt biometrik sistem).
    - Secondary Link: "Gunakan PIN 6-Digit Sebagai Cadangan".
### 2.7 Screen 7: Home Dashboard (`Home Screen.png`)
- **Fungsi:** Beranda utama penjelajahan kuliner, rekomendasi terkurasi, dan pintu masuk ke semua fitur.
- **Elemen UI:**
  - Top Bar Lokasi: "Cari Kuliner di: Yogyakarta • DIY & Jateng Scope".
  - Ucapan Personal: "Sugeng Rawuh, Dimas — Lagi pengin makan apa hari ini?".
  - Search Bar: Input pencarian dengan placeholder "Cari gudeg, bakpia, bakmi jawa, s...".
  - Category Chips: "Semua", "Gudeg Legendaris", "Bakmi Jawa", dll.
  - Featured Editorial Card (Pilihan Editor):
    - Badge: "PILIHAN EDITOR • CITA RASA OTENTIK"
    - Rating & Jarak: `★ 4.9 (1.2k ulasan) • 1.4 km`
    - Judul: "Menelusuri Rahasia Krecek & Areh Gurih Kotagede"
    - Kisaran Harga: `Rp20.000 - Rp45.000 / porsi`
    - CTA: "Baca Ulasan & Rute ->"
  - Interactive Sensor Banner (Curated Shake):
    - Judul: "Bingung Pilih Makanan?"
    - Deskripsi: "Goyangkan ponselmu atau biarkan FOODIE AI memilihkan menu legendaris terbaik di sekitarmu."
    - Tombol Aksi: "Shake to Decide" (Ikon sensor getar/kocok).
  - Bagian "Dekat Lokasimu": Radius < 2 km, tombol "Lihat Semua (42)", menampilkan kartu horizontal:
    - Gudeg Yu Djum: `★ 4.9 • Rp25.000 - Rp50.000 • 800 m • Buka Sekarang`
    - Bakmi Jawa Mbah Gito: `★ 4.8 • Rp20.000 - Rp35.000 • Buka Sekarang`
  - Bagian "Hemat & Nikmat (< Rp25rb)":
    - Soto Kadipiro Asli (Bantul, `★ 4.8`)
    - Kopi Joss Lik Man (Stasiun Tugu, `★ 4.7`)
  - Bagian Edukasi Budaya (Warisan Kuliner Mataram): Artikel mendalam "Mengapa Gudeg Memakai Kayu Bakar?".
  - Navigasi Bawah: Tab Bar dengan ikon Home, Explore, Decide, Profile (dilengkapi akses AI Assistant & Notifikasi).
### 2.8 Screen 8: Explore & Pencarian Kuliner (`Explore.png`)
- **Fungsi:** Pencarian restoran mendalam, filter multi-kriteria, dan penegakan batas wilayah DIY-Jateng.
- **Elemen UI:**
  - Header: Dropdown Lokasi "Yogyakarta (DIY & Jateng) v", Search bar kuliner & warung.
  - Status Wilayah Aktif: Badge "Cakupan Aktif: DIY & Jawa Tengah", tombol "Reset".
  - Filter Chips Interaktif: Chip dengan tombol hapus, contoh: `Budget < Rp25rb [X]`, `Buka Sekarang [X]`.
  - Header Hasil: "Menampilkan 38 Tempat Kuliner", Dropdown Pengurutan: "URUTKAN: Terdekat v".
  - Kartu Kuliner Eksplorasi:
    - Card 1: Gudeg Yu Djum 167 Wijilan (`1.2 km • Kraton, DIY`, `Rp20.000 - Rp45.000`, Resep Tradisional Kayu Bakar, `★ 4.8 (2.4k)`, Buka Tutup 21:00 WIB, Tombol "Detail ->").
    - Card 2: Mangut Lele Mbah Marto (`4.5 km • Sewon, Bantul`, `Rp25.000 - Rp35.000`, Asap Tradisional Pedas Gurih, `★ 4.9 (1.8k)`, Buka Sekarang, Tombol "Detail ->").
    - Card 3: Soto Bathok Mbah Katro (`3.1 km • Kalasan, Sleman`, `Rp8.000 - Rp15.000`, Pemandangan Sawah, `★ 4.7 (950)`, Buka Ramai, Tombol "Detail ->").
  - Out of Bounds Disclaimer Card:
    - Pesan Wilayah: "Mencari di luar DIY & Jateng? FOODIE saat ini hanya menyediakan eksplorasi kuliner terkurasi di wilayah Daerah Istimewa Yogyakarta dan Jawa Tengah untuk menjaga keaslian riset rasa kurator kami."
    - Link: "Pelajari Ekosistem Kami >".
### 2.9 Screen 9: Detail Restoran (`Detail.png`)
- **Fungsi:** Informasi komprehensif sebuah restoran, menu, fasilitas, rute, check-in, dan ulasan terverifikasi.
- **Elemen UI:**
  - Top Bar: Tombol Kembali, Share, Favorite/Bookmark icon.
  - Galeri Foto Restoran: Indikator foto (contoh: `1/18 Foto`).
  - Identitas Restoran:
    - Badge: Sentra Gudeg Mataraman • Pilihan Editor • Warisan Kuliner 1950 • Kraton Kasultanan.
    - Nama: Gudeg Yu Djum Wijilan 167 (Kuliner Legendaris Yogyakarta).
    - Metrik: Rating `4.8 (2.418 ulasan)`, Kisaran harga `Rp20k - Rp45k`.
    - Jam Operasional & Jarak: `Buka Sekarang • 06.00 - 21.00 WIB • 1.2 km dari lokasimu (Kraton, Kota Yogyakarta, DIY)`.
  - 4 Tombol Aksi Cepat:
    1. Petunjuk (Membuka rute maps).
    2. Check-in (Membuka validasi Geofence).
    3. Simpan (Menyimpan ke favorit Hive & Supabase).
    4. Ulas (Menulis review kurator).
  - Catatan Gastronomi Keraton: Cerita resep asli (slow cooked 24 jam dengan kayu bakar pohon asam).
  - Menu Unggulan (Resep Asli Dapur Wijilan - 3 Pilihan Terlaris):
    - Paket Gudeg Komplit Telur & Suwir Ayam (Rp25.000) - Porsi Reguler.
    - Paket Nasi Gudeg Paha Atas & Krecek Mercon (Rp38.000) - Rekomendasi.
    - Besek Gudeg Kendil Oleh-oleh 5 Porsi (Rp120.000) - Oleh-oleh Khas.
  - Fasilitas Restoran (5 chip fasilitas): Mushola Nyaman, Parkir Bus/Mobil, Dapur Tradisional Terbuka, Pembayaran QRIS/Tunai, Non-AC / Area Terbuka.
  - Lokasi & Akses:
    - Alamat: Jl. Wijilan No. 167, Panembahan, Kraton, Yogyakarta 55151.
    - Petunjuk: 400 meter di sebelah timur Alun-alun Utara Yogyakarta.
    - Tombol: "Buka di Google Maps" (Akurasi GPS 25m).
  - Catatan Rasa Komunitas (Ulasan):
    - Kartu review kurator (contoh: Arya Dananjaya - Food Historian, `★★★★★`, ulasan rasa krecek & areh, badge "Kunjungan Terkonfirmasi").
  - Sticky Bottom Bar: Tombol "Petunjuk Arah (1.2 km)".
### 2.10 Screen 10: Shake to Decide (`Shake to Decide.png`)
- **Fungsi:** Memilih kuliner secara acak dan terkurasi menggunakan sensor Accelerometer atau tombol manual.
- **Elemen UI:**
  - Header: Wilayah "DIY & Jateng Scope • Yogyakarta", Indikator Sensor: "Sensor Accelerometer: Siap (Sensitivitas Normal)".
  - Judul: "Bingung Mau Makan Apa? Goyangkan ponselmu atau biarkan sensor cerdas FOODIE memilihkan rasa terbaik di DIY & Jateng."
  - Kriteria Keputusan (Filter Aktif): Chip filter yang dapat dihapus (`< Rp30.000 [X]`, `Gudeg & Tradisional [X]`, tombol `Reset Filter`).
  - Area Interaksi Sensor:
    - Status: "HAPTIK & SENSOR GERAK AKTIF: Goyangkan HP untuk Menentukan. AI FOODIE akan mengacak kurasi dari 420+ warisan kuliner Mataraman & kreasi kontemporer terbaik."
    - 2 Tombol Tindakan:
      - "Goyang Ponsel (Simulasi Shake)" (Untuk pengujian / pemicu manual haptik).
      - "Pilihkan Untuk Saya (Manual Pick)" (Fallback jika sensor tidak didukung).
  - Kartu Hasil Pilihan Acak Cerdas:
    - Status: "Hasil Pilihan Acak Cerdas • Legenda Mataraman • Dipilih barusan • 12:42 WIB".
    - Restoran terpilih: Mangut Lele Asap Mbah Marto (`★ 4.9 • 1.8k ulasan kurator • Warisan Resep 1965`).
    - Kategori: Kuliner Tradisional Bantul • Ikan Asap Kuah Pedas Gurih.
    - Kisaran Harga: Rp25.000 - Rp35.000 per porsi lengkap nasi.
    - Jarak: 4.5 km (Sewon, Bantul, DIY).
    - Kotak Penjelasan AI: "MENGAPA DIPILIHKAN? Sesuai filter budget <Rp30rb dan status buka sekarang. Cita rasa asap otentik kayu bakar pohon klampok yang jarang ditemukan di tempat lain di Yogyakarta."
    - Tombol Aksi:
      - "Lihat Detail Restoran ->"
      - "Coba Acak Lagi (Kocok Ulang)"
  - Panduan Akses Sensor & Fallback di bagian bawah.
### 2.11 Screen 11: AI Assistant (`AI Assistant.png`)
- **Fungsi:** Asisten cerdas percakapan gastronomi berbasis LLM yang terintegrasi dengan database Supabase.
- **Elemen UI:**
  - Header: "FOODIE AI Assistant", Subtitle: "LLM GASTRONOMI DIY & JATENG • Online • Terhubung ke Basis Data Supabase".
  - Prompt Kurasi Cepat (Chips): "Cari makanan pedas di bawah Rp30.000", "Cerdas Rasa", dll.
  - Riwayat Obrolan:
    - Pesan Pembuka AI: Salam Mataraman "Sugeng rawuh! Saya asisten AI kuliner FOODIE. Beritahu saya preferensi rasa, budget, atau suasana yang kamu inginkan di seputar DIY dan Jawa Tengah."
    - Prompt Pengguna: "Carikan rekomendasi makan malam khas Yogyakarta untuk 2 orang, budget di bawah Rp35.000 per orang, rasa pedas gurih, dan wajib buka sampai malam."
    - Balasan AI Terstruktur: Penjelasan AI mengenai preferensi yang diminta, badge kriteria aktif (`<= Rp35k/pax`, `Night Hours`, `Pedas Gurih`), diikuti kartu rekomendasi restoran nyata dari database:
      1. Oseng Mercon Bu Narti (`WARUNG TENDA`, `★ 4.7 (3.1k)`, Jl. KH. Ahmad Dahlan, `Rp25.000 - Rp35.000`, Alasan AI: Pionir oseng mercon koyor sapi cabai rawit pedas meledak, Tombol "Lihat Detail Resto ->").
      2. Bakmi Jawa Pak Pale (`WARUNG HERITAGE KRATON`, `★ 4.8 (2.4k)`, Alun-alun Utara, `Rp22.000 - Rp30.000`, Alasan AI: Bakmi godhog pedas dengan telur bebek dan kaldu ayam kampung gurih kental, Tombol "Lihat Detail Resto ->").
  - Footer Penegasan Transparansi: "BATASAN GEOGRAFIS KETAT & TRANSPARANSI DATA: AI hanya merekomendasikan entitas kuliner terverifikasi dalam batas administratif DIY & Jawa Tengah tanpa memanipulasi data riil."
  - Input Obrolan: Field teks dengan placeholder "Tanyakan kuliner favoritmu (cth: gudeg b...)" dan tombol kirim.
### 2.12 Screen 12: Favorites & Search History (`Favorites & Search History.png`)
- **Fungsi:** Pengelolaan koleksi restoran tersimpan dan riwayat pencarian dengan ketahanan offline Hive.
- **Elemen UI:**
  - Header: "Koleksi & Riwayat", Keterangan: "Tersimpan di Penyimpanan Lokal Hive • Sinkronisasi Cloud".
  - Tab Switcher: Tab `Restoran Favorit (142)` | Tab `Riwayat Pencarian`.
  - Banner Mode Offline: "MODE OFFLINE AKTIF • 142 Entri. Data kuliner diakses lancar via database lokal Hive tanpa koneksi internet. Pembaruan tersinkron otomatis saat daring."
  - Filter Kategori Favorit: "Semua Koleksi (142)", "Gudeg Mataraman (14)".
  - Daftar Restoran Favorit:
    - Item 1: Gudeg Yu Djum Wijilan 167 (Kraton, DIY • 1.2 km • Rp20k - Rp45k • Badge "Tersedia Offline", Tombol "Lihat Detail Restoran", Tombol "Hapus").
    - Item 2: Mangut Lele Asap Mbah Marto (Sewon, Bantul • 4.5 km • Rp25k - Rp35k • Badge "Tersedia Offline", Tombol "Lihat Detail Restoran", Tombol "Hapus").
    - Item 3: Bakmi Jawa Mbah Gito (Kotagede, DIY • 3.8 km • Rp20k - Rp35k • Badge "Tersedia Offline", Tombol "Lihat Detail Restoran", Tombol "Hapus").
  - Riwayat Pencarian Terakhir (Memori Hive):
    - Tombol "Hapus semua riwayat".
    - Item riwayat dengan tombol "Ulangi":
      - `gudeg koyor pedas kotagede` (Hari ini, 14:20 WIB • 8 hasil)
      - `bakmi godhog arang kayu` (Kemarin • 15 hasil)
      - `soto bathok murah meriah sleman` (3 hari lalu • 6 hasil)
      - `kopi klotok pakem pagi` (Minggu lalu • 4 hasil)
  - Kiat Kurasi Kuliner di bagian bawah: Penjelasan bahwa daftar favorit tetap dapat diakses rute peta dan nomor kontaknya saat sinyal seluler di pelosok Yogyakarta tidak stabil.
### 2.13 Screen 13: Check-in Kuliner & Riwayat Kunjungan (`Check-in & History Screen.png`)
- **Fungsi:** Validasi kedatangan fisik pengguna di restoran mitra menggunakan radar Geofence GPS (<50m).
- **Elemen UI:**
  - Status GPS Top Bar: Wilayah "Daerah Istimewa Yogyakarta", Akurasi GPS: `±4 meter (Tinggi)`, `8 GNSS Aktif`.
  - Restoran Terpilih: Gudeg Yu Djum Wijilan 167 (Sentra Wijilan, Kraton, Kota Yogyakarta).
  - Status Geofence Radar:
    - Indikator: "STATUS GEOFENCE: Sinyal Sinkron Presisi 18m / 50m".
    - Validasi Geografis: "Berada di Lokasi Restoran (Jarak 18 meter)".
    - Status Siap: "SIAP CHECK-IN TERVERIFIKASI • ID-DIY-7740".
    - Timestamp: `Waktu Saat Ini: 19:42 WIB • 24 Okt 2025`.
  - Tombol Utama: "Konfirmasi Check-in Sah".
  - Ketentuan Integritas Data: "Integritas Data: Do not label a check-in as verified without appropriate GPS validation. Check-in hanya dapat dilakukan jika berada dalam radius < 50m dari lokasi fisik restoran terverifikasi di DIY & Jateng."
  - Reward Preview: `+50 Foodie Points` diberikan setelah validasi, Progres lencana: Level Penjelajah Gudeg Kraton (3/5 kunjungan menuju lencana).
  - Riwayat Kunjungan Terverifikasi (Total 28 Check-in Sah):
    - Mangut Lele Mbah Marto (Sewon, Bantul • 18 Okt 2025 • Verified Green Checkmark GPS • +50 Poin).
    - Bakmi Jawa Pak Pale (Alun-alun Utara • 12 Okt 2025 • Verified Green Checkmark GPS • +50 Poin).
    - Soto Bathok Mbah Katro (Sambisari, Sleman • 05 Okt 2025 • Verified Green Checkmark GPS • +50 Poin).
  - Banner Sinkronisasi Offline Hive: "HIVE OFFLINE SYNC: Tersedia Check-in Offline didukung via Hive. Data tersimpan lokal dengan cap waktu terenkripsi dan akan divalidasi ke server Supabase saat terhubung kembali ke internet."
### 2.14 Screen 14: Currency & Timezone Converter (`Currency & Timezone.png`)
- **Fungsi:** Utilitas wisatawan untuk estimasi pengeluaran kuliner dan sinkronisasi jam makan lintas zona waktu.
- **Elemen UI:**
  - Header: "Utilitas Wisatawan — Konverter Kurs & Zona Waktu Kuliner", "PUSAT BANTUAN TAMU • DIY & Jateng".
  - Tab Switcher: Tab `Konverter Kurs` | Tab `Zona Waktu Makan`.
  - Tab Konverter Kurs:
    - Mata Uang yang Didukung: IDR, USD, MYR.
    - Keterangan Kurs: "Kurs Acuan Wisatawan — Simulasi Real-Time (Update 10 Menit)".
    - Input Nominal: `150.000` IDR (Seratus Lima Puluh Ribu Rupiah).
    - Estimasi Konversi:
      - USD: `$ 9.42` (Acuan 1 USD = Rp15.923).
      - MYR: `RM 41.50` (Acuan 1 MYR = Rp3.614).
    - Tolok Ukur Kuliner Nyata di Jogja (Real Culinary Benchmarks):
      - 1 Porsi Gudeg Kendil Komplit (~Rp45.000 -> `$2.85 USD • 12.50 MYR`).
      - 1 Mangkuk Soto Bathok Sambisari (~Rp12.000 -> `$0.75 USD • 3.30 MYR`).
      - 1 Cangkir Kopi Joss Arang Membara (~Rp8.000 -> `$0.50 USD • 2.20 MYR`).
    - Tabel Kurs Acuan Wisatawan (Bebas Pajak Bank).
  - Tab Zona Waktu Makan:
    - Zona Waktu Wajib: WIB (`Asia/Jakarta`), WITA (`Asia/Makassar`), WIT (`Asia/Jayapura`), London (`Europe/London`).
    - Fitur Khusus: Memperhitungkan British Summer Time (BST / GMT+1).
    - Preset Jadwal Makan Lokal: Sarapan (06:00), Makan Siang (12:00), Makan Malam (19:00), Supper (23:00).
    - Tampilan Konversi Jam:
      - WIB (Yogyakarta UTC+7): `19:00 WIB` (Makan Malam Gudeg Lesehan & Wedang).
      - London, UK BST (GMT+1): `13:00` (Selisih -6 Jam, waktu santap siang).
      - WITA (Bali/Makassar UTC+8): `20:00` (Selisih +1 Jam).
      - WIT (Jayapura/Maluku UTC+9): `21:00` (Selisih +2 Jam).
    - Kiat Wisata Jam Operasional Jogja (Gudeg Wijilan 06:00 WIB vs Angkringan Kopi Joss 18:00 - 02:00 WIB).
    - Tombol Aksi: "Simpan Preferensi Zona Wisatawan".
### 2.15 Screen 15: Mini Games (`Mini Games.png`)
- **Fungsi:** Kuis harian "Tebak Kuliner Jogja" untuk edukasi kuliner Mataraman dan perolehan Foodie Points.
- **Elemen UI:**
  - Header: "Tebak Kuliner Jogja — TANTANGAN GASTRONOMI MATARAMAN".
  - Status Game: Progres Soal `Pertanyaan 4 dari 5`, Timer `15 detik tersisa`, Skor Berjalan `300 Poin` (+30 Foodie Points siap diklaim).
  - Petunjuk Kurator: "Pawon Dusun Tiwir, Sewon, Bantul • Kuliner Tradisional Bantul".
  - Teka-teki Rasa (#04): "Hidangan berbahan dasar lele asap dengan kuah santan cabai rawit pedas gurih yang dimasak di pawon arang khas Sewon ini adalah...?"
  - Pilihan Ganda:
    - [A] Mangut Lele Asap Mbah Marto (Pilihan Benar -> Tampil Status: "Benar! +100 Poin Telah Ditambahkan").
    - [B] Brongkos Daging Koyor Alun-Alun.
    - [C] Gudeg Manggar Bantul.
    - [D] Tongseng Kambing Pak Kribo.
  - Ensiklopedia Gastronomi Mataraman: Narasi edukasi kuliner mengenai proses pengasapan ikan lele dengan kayu klampok selama 24 jam.
  - Keterangan Jarak: "4.5 km dari Kraton".
  - Tombol Aksi:
    - "Lanjut ke Pertanyaan Berikutnya (5/5) ->"
    - "Lihat Restoran di Explore"
### 2.16 Screen 16: Achievements & Rewards (`Achievements.png`)
- **Fungsi:** Menampilkan level kurator, koleksi lencana warisan, saldo poin, dan katalog penukaran reward.
- **Elemen UI:**
  - Header: "Pencapaian & Poin — Hadiah Gastronomi Mataraman".
  - Kartu Kurator: Dimas Dananjaya, Level: "Level 4: Penjelajah Mataraman", Saldo Poin: `1.850 Poin`.
  - Target Progres Level: Target Level 5: Kurator Agung Kesultanan, Progress bar: `74% (1.850 / 2.500 Poin)`, kurang 650 poin untuk lencana ningrat.
  - Statistik Aktivitas: `28 Check-in Sah`, `14 Ulasan Kurator`.
  - Tab Switcher: Tab `Lencana Kuliner (Badges)` | Tab `Katalog Hadiah`.
  - Koleksi Lencana (12 dari 20 Lencana Warisan Terverifikasi):
    - Penjelajah Gudeg (Emas - Tier III - 5 Kunjungan Sah Sentra Wijilan - Lencana Diperoleh • +350 Poin).
    - Ksatria Mangut Lele (Perak - Kunjungan Sewon & Bantul Terverifikasi - Lencana Diperoleh • +200 Poin).
    - Pencari Bakmi Jawa (Warung arang legendaris - Kunjungi 2 warung lagi).
    - Pecinta Kopi Joss (1 dari 3 Angkringan Heritage Dikunjungi).
    - Kurator Wedang Ronde (Status: Terkunci - Hadiah: +250 Poin & Akses Resep Rahasia).
  - Katalog Penukaran Foodie Points:
    - Voucher Rp25.000 Gudeg Wijilan (500 Poin) -> Tombol "Tukarkan Poin".
    - Gratis 1 Cangkir Kopi Joss Lik Man (200 Poin) -> Tombol "Tukarkan Poin".
    - Paket Besek Oleh-oleh Eksklusif (1.500 Poin) -> Tombol "Tukarkan Poin".
  - Integritas Poin FOOTNOTE: Poin hanya diperoleh dari check-in GPS sah (<50m), kuis harian, dan ulasan terverifikasi.
### 2.17 Screen 17: Notifications (`Notifications.png`)
- **Fungsi:** Pusat pemberitahuan kontekstual mencakup jadwal makan, radar geofence, tantangan kuis, dan valas.
- **Elemen UI:**
  - Header: "Notifikasi Kuliner", Status: `3 Baru`, Waktu: `19:04 WIB`, Tombol "Tandai Semua Dibaca".
  - Tab Filter: Tab `Semua (12)` | Tab `Waktu Makan` | Tab `Geofence GPS`.
  - Daftar Notifikasi Interaktif:
    - Pengingat Waktu Makan: "Waktunya Santap Malam Gudeg & Wedang! Lesehan Wijilan & Malioboro sedang aktif..." -> Tombol Aksi: [Lihat Rekomendasi Malam], [Tunda 30m].
    - Radar Geofence GPS (Radius 40m): "Kamu Berada Dekat Mangut Lele Mbah Marto! GPS mendeteksi kamu berada dalam radius check-in sah..." -> Tombol Aksi: [Check-in Sekarang].
    - Gamifikasi Mataraman: "Selamat! Lencana Ksatria Mangut Lele Terbuka... (+50 Poin & lencana perak)" -> Tombol Aksi: [Lihat Lemari Trofi].
    - Uji Lidah Mataraman: "Tantangan Harian Tebak Kuliner Jogja Siap Dimainkan!" -> Tombol Aksi: [Mainkan Sekarang].
    - Info Valas Wisatawan: "Pembaruan Simulasi Kurs Valas Wisatawan (1 USD ~ Rp15.680 • 1 MYR ~ Rp3.520)".
  - Card Manajemen Notifikasi: "Kelola Frekuensi Pengingat (Atur jam sarapan, makan siang, makan malam, atau sensitivitas radar geofence GPS) -> [Buka Pengaturan Notifikasi]".
### 2.18 Screen 18: Profile & Settings (`Profile & Settings.png`)
- **Fungsi:** Dashboard profil kurator, akses ke seluruh aktivitas, utilitas wisatawan, preferensi sistem, dan logout.
- **Elemen UI:**
  - Header & Info Kurator: Avatar foto, Nama: Dimas Dananjaya, Email: `dimas.dananjaya@culinary.id`, Badge: "Level 4 Mataraman", Tombol "Edit Profil".
  - Metrik Kurator (3 Kartu):
    - `142` Tempat Disimpan.
    - `28` Check-in Sah.
    - `1.850` Foodie Points.
  - Banner Promosi Kuis: "Mainkan Tantangan Harian Tebak Kuliner Jogja".
  - Menu Navigasi Berkelompok:
    - **AKTIVITAS KULINER (Tersinkronisasi Cloud):**
      - Favorit & Koleksi Saya (142 item).
      - Riwayat Pencarian & Eksplorasi.
      - Foodie Points & Pencapaian.
    - **UTILITY WISATAWAN:**
      - Konverter Kurs IDR / Valas (USD, MYR) -> "Buka Konverter ->".
      - Zona Waktu Makan (WIB, WITA, WIT, GMT) -> "Cek Jadwal ->".
    - **PREFERENSI SISTEM:**
      - Pengingat Waktu Makan (Jadwal sarapan, makan siang, makan malam).
      - Biometrik & Autentikasi (autentikasi wajah).
      - Cakupan Wilayah (DIY Jogja & Jawa Tengah).
      - Saran & Kesan Kurator (Formulir masukan mata kuliah).
      - Keluar Akun (Logout dengan dialog konfirmasi: Batal / Ya, Keluar).
  - Footer Aplikasi: "FOODIE INDONESIA • MATARAMAN EDITION • Versi 3.41 (Build 2025.04) • Daerah Istimewa Yogyakarta".
---
## 3. Scope & Feature Priority
### P0 — Core Features (Fondasi & Wajib Kuliah)
1. Autentikasi 3-Tahap (Register, Email OTP, Biometrik, Login, Session, Logout) menggunakan Supabase Auth.
2. Home Dashboard & Eksplorasi dengan cakupan wilayah DIY & Jateng.
3. Pencarian, Filter Multi-Kriteria, dan Pengurutan (Terdekat, Rating, Budget).
4. Detail Restoran (Galeri foto, Menu Unggulan, Fasilitas, Alamat, Rute).
5. LBS Presisi & Peta Navigasi.
6. Basis Data Online Supabase PostgreSQL & Penyimpanan Lokal Hive.
7. Profile Kurator, Pengaturan, dan Formulir Saran & Kesan mata kuliah.
8. Konverter Mata Uang (IDR, USD, MYR) & Konverter Zona Waktu (WIB, WITA, WIT, London BST).
9. Sensor Accelerometer (*Shake to Decide*) & Gyroscope (*Device Orientation*).
10. Mobile Notifications (Local Notifications & Contextual Geofence/Meal Reminder).
### P1 — Smart Features & Gamifikasi
1. FOODIE AI Assistant berbasis LLM dengan koneksi data Supabase (*Mataraman Taste Engine*).
2. Favorit & Riwayat Pencarian dengan dukungan mode luring Hive.
3. Radar Geofence Check-in (< 50m) dengan perlindungan integritas anti-cheat.
4. Gamifikasi Gastronomi: Sistem Level Kurator, Foodie Points, 20 Lencana Warisan, dan Katalog Voucher.
5. Mini Game Harian *Tebak Kuliner Jogja* dengan timer 15 detik dan akumulasi skor.
### P2 — Advanced Features
1. Verifikasi Integritas Data ulasan menggunakan cryptographic hash.
2. Panorama 360° interaktif restoran berbasis sensor Gyroscope.
---
## 4. Geographic Scope — DIY & Jawa Tengah Only
### 4.1 Batas Wilayah Layanan
Wilayah operasional FOODIE dibatasi secara eksklusif pada batas administrasi resmi:
- **Daerah Istimewa Yogyakarta:** Kota Yogyakarta, Kab. Sleman, Kab. Bantul, Kab. Kulon Progo, Kab. Gunungkidul.
- **Provinsi Jawa Tengah:** Seluruh kabupaten dan kota dalam Provinsi Jawa Tengah (termasuk Kota Surakarta, Kota Semarang, Kab. Klaten, Kab. Magelang, dll.).
### 4.2 Aturan Validasi Geografis
1. Restoran di luar DIY & Jateng dilarang tampil dalam query atau rekomendasi AI.
2. Jika GPS perangkat mendeteksi pengguna di luar DIY & Jateng, aplikasi menampilkan pesan edukasi:
*"FOODIE saat ini hanya menyediakan eksplorasi kuliner terkurasi di wilayah Daerah Istimewa Yogyakarta dan Jawa Tengah untuk menjaga keaslian riset rasa kurator kami."*
3. Pengguna di luar area tetap dapat menjelajah secara manual dengan memilih lokasi pencarian di DIY atau Jateng.
---
## 5. UI/UX Design System (Culinary Editorial Futurism)
### 5.1 Palet Warna Resmi
| Nama Token | Kode HEX | Penggunaan Utama pada Antarmuka |
|---|---|---|
| **Roasted Charcoal** | `#252D30` | Latar belakang gelap, teks utama pada tema terang |
| **Slate Blue** | `#607783` | Surface sekunder, border kartu, teks sekunder |
| **Saffron Yellow** | `#F5BD50` | Primary CTA, aksen badge, tombol utama, highlight |
| **Paprika Orange** | `#EF8235` | Aksen eksplorasi rasa, badge pedas, alert |
| **Tomato Red** | `#A92F27` | Aksen highlight terbatas, status tutup |
| **Warm Cream** | `#FFF7E8` | Latar belakang terang lembut, kartu editorial |
| **Warm White** | `#FFFFFF` | Latar kartu, teks pada background gelap |
| **Muted Gray** | `#8A9398` | Border divider, status non-aktif, placeholder |
### 5.2 Tipografi
- **Display / Editorial:** *DM Serif Display* atau *Playfair Display* (digunakan untuk judul editorial, headline budaya, dan kutipan gastronomi).
- **Interface / Body:** *Inter* atau *Manrope* (digunakan untuk tombol, harga, label form, angka GPS, dan teks obrolan).
---
## 6. Basis Data & Arsitektur Sistem
### 6.1 Supabase PostgreSQL Tables
1. `profiles`: id, user_id (FK auth.users), full_name, email, phone_number, avatar_url, curator_level (1-5), foodie_points, created_at.
2. `restaurants`: id, name, category, subcategory, address, regency_city, province, latitude, longitude, price_min, price_max, rating, total_reviews, image_urls (array), opening_hours, facilities (array), editorial_notes, created_at.
3. `foods`: id, restaurant_id (FK), name, description, price, category, image_url, is_bestseller, created_at.
4. `favorites`: id, user_id (FK), restaurant_id (FK), created_at.
5. `reviews`: id, user_id (FK), restaurant_id (FK), rating, content, is_verified_visit, data_hash, created_at.
6. `checkins`: id, user_id (FK), restaurant_id (FK), checkin_code, latitude, longitude, distance_meters, points_awarded, is_synced, created_at.
7. `search_history`: id, user_id (FK), query, result_count, searched_at.
8. `game_scores`: id, user_id (FK), question_id, score_earned, points_claimed, played_at.
9. `achievements`: id, user_id (FK), badge_code, badge_tier (Gold/Silver/Bronze), points_awarded, unlocked_at.
10. `feedback`: id, user_id (FK), rating, comments, created_at.
### 6.2 Hive Boxes (Penyimpanan Lokal)
- `settings`: preferensi bahasa, notifikasi, status onboarding, zona waktu wisatawan terpilih.
- `cache`: cache data restoran dan makanan terkompresi untuk akses offline.
- `favorites_local`: daftar ID restoran favorit untuk akses seketika saat offline.
- `search_history_local`: daftar query pencarian lokal dengan cap waktu.
- `offline_checkin_queue`: antrean check-in yang dicatat saat luring beserta koordinat dan tanda tangan hash untuk disinkronkan saat terhubung kembali.
- `draft_feedback`: draf ulasan atau feedback yang belum terkirim.
---
## 7. Acceptance Criteria Sesuai Desain Figma
1. **Intro & Onboarding:** Indikator Hive 100% tampil, navigasi mulus ke Onboarding dan Auth.
2. **Autentikasi 3-Tahap:** Registrasi meminta nomor kontak untuk validasi warung, OTP email 6-digit terverifikasi, dan aktivasi biometrik dapat diaktifkan atau dilewati.
3. **Pencarian & Detail:** Filter budget dan jam buka berfungsi memfilter 38+ item, halaman detail menampilkan 18 galeri foto, catatan kurator, 3 menu terlaris, 5 fasilitas, dan rute peta.
4. **Shake to Decide:** Accelerometer mendeteksi goyangan fisik dengan cooldown 2 detik, filter budget < Rp30k dihormati, dan tombol fallback manual tersedia.
5. **AI Assistant:** Respon chat menyertakan kartu kuliner nyata dengan tombol "Lihat Detail Resto" dan batas wilayah terjamin.
6. **Geofence Check-in:** Jarak di bawah 50 meter memicu tombol "Konfirmasi Check-in Sah", menambah +50 poin, dan dapat disimpan di Hive saat offline.
7. **Utilitas Wisatawan:** Konverter mata uang mendukung IDR, USD, MYR dengan tolok ukur riil Jogja; konverter waktu menghitung selisih jam WIB vs London BST, WITA, WIT.
8. **Mini Game:** Kuis 5 soal dengan timer 15 detik menghitung skor dan mengedukasi sejarah kuliner Mataraman.
9. **Achievements:** Leveling dan 20 lencana terverifikasi dapat diklaim dan ditukar voucher makan.
PART 3 — ERROR HANDLING, RELIABILITY & DEPLOYMENT READINESS
Aturan utama: aplikasi tidak boleh crash karena kesalahan yang dapat ditangani, tidak boleh menampilkan data palsu seolah-olah valid, dan tidak boleh mengklaim suatu aksi berhasil sebelum hasilnya dikonfirmasi. Target “siap deploy” harus dibuktikan melalui pengujian dan konfigurasi lingkungan, bukan hanya karena aplikasi berhasil dijalankan di perangkat developer.

10. Prinsip Error Handling
1. Gagal dengan aman: jika sebuah fitur gagal, aplikasi tetap dapat digunakan dan tidak kehilangan data yang sudah tersimpan.
2. Pesan yang bisa dipahami: tampilkan pesan dalam bahasa Indonesia yang menjelaskan masalah dan langkah berikutnya. Jangan tampilkan stack trace, query SQL, token, API key, atau detail internal kepada pengguna.
3. Jangan memalsukan keberhasilan: check-in, sinkronisasi, login, klaim poin, penukaran voucher, dan pengiriman ulasan hanya boleh berstatus berhasil setelah mendapat konfirmasi yang sesuai.
4. Sediakan tindakan pemulihan: jika memungkinkan, sediakan tombol Coba Lagi, Buka Pengaturan, Pilih Lokasi Manual, Simpan Draf, atau Kembali.
5. Pisahkan status: bedakan status loading, berhasil, kosong, gagal, offline, menunggu sinkronisasi, dan perlu autentikasi. Jangan menggunakan satu indikator untuk semua kondisi.
6. Catat log secara aman: catat kode error, waktu, nama fitur, dan correlation/request ID jika tersedia. Jangan mencatat kata sandi, token, OTP, koordinat presisi, atau isi pribadi pengguna tanpa kebutuhan yang sah.
7. Jangan melakukan retry tanpa batas: gunakan batas percobaan, jeda bertahap (exponential backoff) dengan jitter untuk permintaan yang aman diulang, serta timeout yang sesuai.
8. Jaga aksesibilitas: pesan error harus terbaca oleh pembaca layar, tidak hanya dibedakan melalui warna, dan tidak menghilang sebelum sempat dibaca jika membutuhkan tindakan pengguna.
11. Standar Tampilan Status
Status	Perilaku aplikasi
Loading	Tampilkan indikator proses; cegah pengiriman ganda untuk aksi yang sama.
Success	Tampilkan konfirmasi setelah server/perangkat benar-benar menyelesaikan aksi.
Empty state	Jelaskan bahwa belum ada data dan sediakan tindakan relevan, misalnya ubah filter atau mulai pencarian.
Error	Jelaskan masalah secara singkat, tindakan pemulihan, dan opsi mencoba kembali jika aman.
Offline	Tampilkan status koneksi; gunakan cache yang masih tersedia dan tandai data yang mungkin sudah lama.
Pending sync	Tandai data sebagai “Menunggu sinkronisasi”, bukan “Terverifikasi” atau “Berhasil”.
Session expired	Minta pengguna masuk kembali; pertahankan draf non-sensitif yang aman bila memungkinkan.
Permission denied	Jelaskan manfaat izin dan cara membuka pengaturan; jangan memaksa atau mengunci fitur yang tidak memerlukan izin tersebut.


12. Matriks Error Handling per Fitur
12.1 Aplikasi, navigasi, dan tampilan
- Tangani exception pada level fitur dan level aplikasi. Gunakan error boundary/widget fallback yang sesuai agar satu halaman yang gagal tidak selalu menutup seluruh aplikasi.
- Untuk halaman yang gagal dimuat, tampilkan pesan dan tombol Coba Lagi serta Kembali.
- Cegah tombol ditekan berkali-kali ketika permintaan masih berjalan.
- Tangani ukuran layar berbeda, keyboard yang menutupi form, teks panjang, gambar gagal dimuat, serta data kosong.
- Semua tombol dan kontrol harus memiliki aksi nyata, status aktif/nonaktif yang benar, dan umpan balik yang sesuai.
- Jangan menampilkan angka contoh dari desain seperti jumlah restoran, rating, poin, jarak, atau status buka sebagai data aktual kecuali memang berasal dari data yang tersedia dan terverifikasi. Data demonstrasi harus diberi label jelas.
12.2 Autentikasi, akun, dan sesi
Kondisi	Penanganan wajib
Email kosong/tidak valid atau kata sandi tidak memenuhi aturan	Validasi sebelum request; tampilkan kesalahan di field terkait.
Email atau kata sandi salah	Pesan umum yang aman; jangan mengungkap apakah sebuah email terdaftar jika kebijakan keamanan mengharuskan respons seragam.
Email belum diverifikasi	Beri instruksi verifikasi dan opsi kirim ulang dengan cooldown.
OTP salah/kedaluwarsa	Tolak kode, jelaskan bahwa kode tidak valid/kedaluwarsa, dan sediakan kirim ulang sesuai batas percobaan.
Terlalu banyak percobaan	Terapkan rate limit; tampilkan kapan pengguna dapat mencoba lagi jika informasi tersebut tersedia.
Tidak ada koneksi/server autentikasi bermasalah	Pertahankan input non-rahasia, jangan menganggap login berhasil, dan sediakan coba lagi.
Sesi kedaluwarsa/revoked	Bersihkan state autentikasi lokal yang tidak valid dan arahkan pengguna masuk kembali.
Biometrik tidak didukung, tidak disiapkan, dibatalkan, atau gagal	Sediakan fallback ke autentikasi akun/PIN perangkat sesuai kemampuan platform. Biometrik lokal tidak menggantikan validasi sesi server.
Google/Apple/passkey tidak dikonfigurasi	Jangan tampilkan opsi sebagai aktif. Aktifkan hanya setelah provider dan redirect/deep link benar-benar dikonfigurasi dan diuji.


- Jangan menyimpan kata sandi atau OTP dalam Hive maupun log.
- Token sesi harus disimpan menggunakan mekanisme penyimpanan aman yang sesuai platform dan rekomendasi SDK, bukan di penyimpanan biasa.
- “Ingat Saya” tidak boleh berarti menonaktifkan perlindungan sesi.
- Logout harus mengakhiri sesi Supabase dan membersihkan data privat dari state aplikasi. Data offline milik akun harus dipisahkan per pengguna agar tidak terlihat setelah akun berganti.
- Reset kata sandi, verifikasi email, redirect URL, dan deep link harus diuji pada build produksi.
12.3 Supabase, API, dan database
- Bedakan error jaringan, timeout, autentikasi, otorisasi, validasi, konflik data, rate limit, dan kesalahan server.
- Validasi input di aplikasi untuk kenyamanan pengguna, lalu ulangi validasi yang penting di backend/database. Validasi client saja tidak cukup untuk keamanan.
- Aktifkan dan uji Row Level Security (RLS) pada seluruh tabel yang berisi data pengguna. Uji akses sebagai pengguna anonim, pengguna A, dan pengguna B.
- Gunakan foreign key, unique constraint, check constraint, dan transaksi sesuai kebutuhan untuk menjaga konsistensi data.
- Jangan menaruh service_role key atau secret backend di kode Flutter, asset, file konfigurasi yang ikut dibundel, atau repository.
- Simpan secret di environment/backend secret manager. Gunakan konfigurasi terpisah untuk development, staging, dan production.
- Edge Functions wajib memvalidasi autentikasi, otorisasi, payload, ukuran request, dan rate limit untuk endpoint yang relevan.
- Operasi yang dapat menghasilkan duplikasi (misalnya klaim poin atau penukaran voucher) harus menggunakan idempotency key atau mekanisme transaksi/constraint yang setara.
- Jika backend mengembalikan data tidak sesuai skema, jangan membuat nilai penting secara diam-diam. Catat error dengan aman dan tampilkan fallback yang sesuai.
- Untuk perubahan skema, gunakan migration yang tersimpan di version control, uji pada staging, dan siapkan prosedur rollback.
12.4 Pencarian, filter, detail, dan data kuliner
- Jika hasil pencarian kosong, tampilkan empty state dan opsi menghapus filter atau mengganti kata kunci.
- Jika lokasi tidak ditemukan, minta pengguna memilih lokasi manual di DIY atau Jawa Tengah.
- Jika data restoran tidak tersedia, tampilkan status “Informasi belum tersedia”; jangan mengarang harga, jam buka, rating, menu, alamat, atau fasilitas.
- Jika foto gagal dimuat, tampilkan placeholder dan pertahankan informasi teks yang tersedia.
- Jika data sudah lama dari cache, beri label “Data tersimpan — mungkin belum diperbarui” bila kesegaran informasi berpengaruh, khususnya jam buka dan harga.
- Data restoran yang ditampilkan maupun direkomendasikan AI harus lolos batas geografis DIY/Jawa Tengah di backend, bukan hanya filter antarmuka.
- Filter harga, rating, kategori, jarak, dan status buka harus menggunakan nilai yang benar-benar tersedia. Jika suatu nilai tidak diketahui, jangan menganggapnya memenuhi filter.
- Perubahan urutan/filter harus mempertahankan konsistensi antara jumlah hasil, kartu, dan halaman detail.
12.5 GPS, peta, dan geofence check-in
Kondisi	Penanganan wajib
Izin lokasi ditolak	Jelaskan alasan izin diperlukan dan sediakan pencarian manual.
GPS mati/tidak tersedia	Tawarkan untuk mengaktifkan lokasi atau memilih lokasi manual.
Akurasi buruk	Jangan langsung mengesahkan check-in; minta pengguna mencoba di area terbuka atau mengulang pengukuran.
Lokasi pengguna di luar DIY/Jawa Tengah	Tampilkan pesan batas wilayah dan izinkan pemilihan lokasi pencarian manual di area layanan.
Restoran di luar batas layanan	Tolak dari hasil pencarian, rekomendasi AI, dan check-in.
Jarak check-in 50 meter atau lebih	Tolak verifikasi dan tampilkan jarak/status secara jelas.
GPS palsu, koordinat tidak konsisten, timestamp tidak wajar, atau request dimanipulasi	Tandai untuk ditolak atau pemeriksaan server; jangan memberikan poin sebelum validasi berhasil.
Peta/rute gagal dimuat	Tampilkan alamat yang tersedia dan opsi membuka aplikasi peta eksternal jika URL valid.
Check-in saat offline	Simpan sebagai menunggu validasi, bukan check-in sah. Validasi ulang di server setelah koneksi pulih; jangan menjanjikan anti-cheat sempurna hanya berdasarkan koordinat dari perangkat.
Sinkronisasi check-in gagal	Pertahankan item dalam antrean, tampilkan status pending, dan retry dengan batas yang wajar. Cegah pengiriman ganda.


Validasi radius 50 meter harus dilakukan di backend dengan koordinat restoran yang tersimpan dan metode perhitungan jarak yang konsisten. Koordinat dari perangkat tidak dapat sepenuhnya membuktikan lokasi fisik atau menghilangkan semua bentuk GPS spoofing; sistem harus menyatakan batasan tersebut secara jujur.
12.6 Hive dan sinkronisasi offline
- Hive hanya menyimpan data yang memang dibutuhkan untuk akses offline. Supabase tetap menjadi sumber data utama untuk data online.
- Setiap item antrean sinkronisasi perlu memiliki ID unik, pemilik akun, waktu pembuatan, tipe operasi, status, dan jumlah percobaan.
- Tangani konflik data menggunakan aturan eksplisit per jenis data; jangan sekadar menimpa data server dengan data lokal terbaru tanpa pemeriksaan.
- Gunakan versi skema Hive dan mekanisme migrasi agar pembaruan aplikasi tidak merusak data lokal.
- Jika cache rusak atau gagal dibaca, tangani exception, pulihkan box/cache yang terdampak bila aman, dan tampilkan keadaan kosong atau minta sinkronisasi ulang. Jangan menghapus seluruh data lokal tanpa alasan dan pemberitahuan.
- Sediakan batas ukuran cache, kebijakan pembersihan data lama, serta indikator waktu sinkronisasi terakhir.
- Jangan menyimpan secret, kata sandi, OTP, atau token sensitif di Hive biasa.
- Data check-in offline tidak boleh mendapatkan poin, lencana, atau status terverifikasi sebelum server menerima dan memvalidasinya.
- Jika akun berganti atau logout, pastikan cache privat akun sebelumnya tidak bocor ke akun berikutnya.
12.7 AI Assistant dan rekomendasi
- Panggilan LLM dilakukan melalui backend/Edge Function; API key model tidak boleh berada di aplikasi Flutter.
- Jika AI timeout, provider tidak tersedia, respons kosong, atau format respons tidak valid, tampilkan pesan gagal yang ramah dan tombol coba lagi.
- Sediakan fallback ke pencarian dan filter biasa ketika AI tidak tersedia.
- AI hanya boleh merekomendasikan restoran yang berasal dari kandidat data Supabase yang valid dan lolos filter wilayah. Nama restoran, alamat, harga, jam buka, rating, dan menu tidak boleh diciptakan oleh model.
- Validasi ID restoran hasil AI terhadap data backend sebelum menampilkan kartu atau mengizinkan navigasi ke detail.
- Jika tidak ada kandidat yang sesuai, katakan bahwa belum ada hasil yang cocok dan tawarkan perubahan kriteria.
- Batasi panjang input, ukuran respons, frekuensi request, dan biaya pemanggilan model. Jangan mengirim data pribadi yang tidak diperlukan ke penyedia model.
- Tampilkan bahwa rekomendasi merupakan bantuan pencarian, bukan jaminan kualitas atau kebenaran seluruh informasi restoran.
12.8 Sensor, notifikasi, konverter, dan mini game
- Accelerometer: jika sensor tidak tersedia atau stream error, nonaktifkan pemicu gerak dan sediakan tombol pilihan manual. Terapkan cooldown agar satu goyangan tidak memicu banyak request.
- Gyroscope/panorama: jika sensor atau konten panorama tidak tersedia, sediakan kontrol sentuh atau tampilan gambar biasa. Jangan menampilkan fitur seolah aktif bila belum diimplementasikan.
- Notifikasi: tangani izin ditolak, token perangkat tidak tersedia, dan notifikasi terjadwal yang gagal. Fitur inti tetap dapat digunakan tanpa izin notifikasi.
- Konverter mata uang: tampilkan sumber dan waktu pembaruan kurs. Jika kurs real-time tidak tersedia, gunakan kurs terakhir yang diberi timestamp atau minta pengguna mencoba lagi; jangan menyebut kurs simulasi sebagai kurs real-time.
- Zona waktu: gunakan ID zona waktu yang sesuai dan perhitungan tanggal yang benar, termasuk perubahan waktu musim panas London. Jangan hanya mengurangi jam tetap sepanjang tahun.
- Mini game: cegah jawaban atau klaim poin dikirim dua kali; tangani timer yang selesai, aplikasi berpindah ke background, dan koneksi terputus. Skor/poin yang bernilai akun harus divalidasi backend.
- Poin, lencana, dan voucher: lakukan perubahan secara atomik di backend; cek saldo, syarat, status voucher, dan duplikasi klaim. Jika proses gagal, saldo tidak boleh berubah sebagian.
- Hash ulasan: hash hanya membantu mendeteksi perubahan data sesuai desain implementasi; hash tidak membuktikan bahwa ulasan benar atau bahwa kunjungan sungguh terjadi. Kunci rahasia, bila diperlukan, hanya boleh berada di backend.
12.9 Formulir, ulasan, dan profil
- Validasi panjang teks, rating, tipe file, ukuran file, serta format input sebelum mengirim.
- Tampilkan kesalahan di field yang sesuai dan pertahankan draf ketika request gagal.
- Untuk upload foto/avatar, tangani file tidak didukung, ukuran berlebih, koneksi terputus, izin galeri ditolak, dan upload gagal.
- Terapkan aturan akses storage dan database agar pengguna hanya dapat mengubah data yang berhak mereka ubah.
- Tampilkan status pengiriman feedback/ulasan secara akurat: draf lokal, sedang dikirim, terkirim, atau gagal.
- Hindari mengirim ulang formulir yang sudah berhasil dikirim karena pengguna menekan tombol beberapa kali.
13. Keamanan dan Privasi untuk Rilis
1. Terapkan RLS dan uji kebijakan akses setiap tabel serta bucket Supabase Storage.
2. Jangan menyimpan secret backend di aplikasi. Kunci publik Supabase yang memang dirancang untuk client tetap harus dilindungi dengan RLS dan kebijakan akses yang benar.
3. Gunakan HTTPS untuk komunikasi jaringan; jangan menampilkan klaim “end-to-end encryption” kecuali arsitekturnya benar-benar menyediakan enkripsi end-to-end.
4. Minimalkan pengumpulan data pribadi dan lokasi. Minta izin lokasi hanya saat diperlukan, jelaskan tujuannya, dan hindari menyimpan koordinat presisi lebih lama daripada kebutuhan fitur.
5. Terapkan validasi dan sanitasi input di client serta backend, pembatasan ukuran request, rate limiting, dan penanganan error yang tidak membocorkan detail internal.
6. Sediakan kebijakan privasi, syarat penggunaan, kontak pengelola, penjelasan izin perangkat, dan informasi penghapusan akun/data sesuai kebutuhan distribusi.
7. Pastikan log produksi tidak memuat password, OTP, access/refresh token, secret, atau data pribadi yang tidak diperlukan.
8. Pastikan data setiap akun terisolasi. Uji akses silang akun secara eksplisit.
9. Jika menggunakan analytics/crash reporting, jelaskan data yang dikumpulkan, batasi informasi sensitif, dan patuhi kebijakan platform serta persetujuan yang diperlukan.
10. Fitur sosial, review, dan konten pengguna harus memiliki mekanisme pelaporan/moderasi yang sesuai dengan ruang lingkup aplikasi.
14. Observability dan Diagnostik
- Gunakan logging terstruktur dengan level debug, info, warning, dan error; level debug tidak aktif secara default pada rilis produksi.
- Untuk setiap error jaringan/backend, simpan kode error yang aman, nama operasi, waktu, dan request ID bila tersedia.
- Pantau crash, kegagalan request, waktu respons, kegagalan sinkronisasi, error autentikasi, dan kegagalan fitur penting.
- Sediakan halaman diagnostik internal atau prosedur dukungan yang tidak membocorkan data pengguna.
- Jangan mengirim log sensitif ke layanan pihak ketiga. Tentukan masa retensi log dan siapa yang dapat mengaksesnya.
- Error yang berulang harus dapat ditelusuri dari log tanpa mengandalkan pesan error yang terlihat oleh pengguna.
15. Strategi Pengujian Sebelum Rilis
15.1 Jenis pengujian
- Unit test: validasi form, filter, perhitungan jarak, konversi mata uang/waktu, aturan poin, dan pengolahan status.
- Widget test: loading, empty state, error state, validasi input, navigasi, dialog konfirmasi, dan fallback fitur.
- Integration test: autentikasi, query Supabase, upload avatar, sinkronisasi Hive, pencarian-detail, check-in, AI, dan klaim poin.
- Security test: RLS, akses silang akun, input tidak valid, secret dalam bundle, session expiry, dan endpoint tanpa otorisasi.
- Offline/network test: mode pesawat, koneksi lambat, timeout, koneksi putus saat request, reconnect, dan retry.
- Device test: beberapa ukuran layar, versi Android/iOS yang ditargetkan, izin ditolak, sensor tidak tersedia, serta lifecycle aplikasi.
- Release test: build release, instalasi bersih, upgrade dari versi sebelumnya, deep link auth, konfigurasi production, dan pemeriksaan log.
15.2 Skenario minimum yang harus lulus
ID	Skenario	Hasil yang diharapkan
EH-01	Perangkat offline saat membuka Explore	Cache ditampilkan jika tersedia; status offline terlihat; tidak crash.
EH-02	Pencarian menghasilkan nol data	Empty state tampil; pengguna dapat mengubah filter.
EH-03	Supabase timeout	Pesan ramah dan retry tersedia; tidak ada klaim berhasil palsu.
EH-04	Sesi kedaluwarsa	Pengguna diminta login kembali; data akun lain tidak muncul.
EH-05	Izin lokasi ditolak	Pencarian manual tetap tersedia.
EH-06	GPS akurasi buruk atau jarak ≥ 50 m	Check-in tidak diverifikasi dan poin tidak diberikan.
EH-07	Check-in offline lalu reconnect	Status tetap pending sampai server memvalidasi; tidak ada poin ganda.
EH-08	AI mengembalikan ID restoran tidak valid	Kartu ditolak; tidak ada data restoran yang dibuat-buat.
EH-09	Tombol klaim ditekan berkali-kali	Hanya satu transaksi/claim yang berhasil.
EH-10	Hive berisi skema lama atau cache rusak	Migrasi/pemulihan berjalan atau fallback tampil tanpa crash.
EH-11	Sensor tidak tersedia	Tombol manual berfungsi dan aplikasi tetap dapat dipakai.
EH-12	Kurs API gagal	Kurs terakhir ditandai timestamp atau pesan gagal tampil; tidak mengklaim real-time.
EH-13	Pengguna A mencoba membaca data privat pengguna B	Akses ditolak oleh kebijakan backend.
EH-14	Upload foto gagal di tengah proses	Status gagal terlihat; pengguna dapat mencoba lagi tanpa duplikasi.
EH-15	Pengguna logout lalu akun lain login	Data privat lokal akun pertama tidak tampil pada akun kedua.


16. Aturan Kualitas Kode dan Arsitektur
- Pisahkan UI, state management, model, repository, dan service agar logika bisnis tidak menumpuk di widget.
- Gunakan satu sumber kebenaran untuk state autentikasi, status jaringan, dan antrean sinkronisasi.
- Hindari duplikasi query dan aturan bisnis; letakkan aturan kritis pada repository/backend yang tepat.
- Gunakan model bertipe dan parsing defensif untuk respons API. Tangani field opsional dan perubahan skema secara eksplisit.
- Gunakan konfigurasi environment untuk URL dan key client yang berbeda antara development, staging, dan production. Secret server hanya berada di backend.
- Tetapkan standar format/lint dan jalankan dart format, flutter analyze, serta seluruh test sebelum merge/release.
- Hilangkan dead code, debug print, placeholder navigasi, data dummy yang tidak diberi label, dan tombol yang belum berfungsi.
- Setiap dependency harus memiliki alasan penggunaan, versi yang sesuai, dan diperiksa kompatibilitasnya sebelum rilis.
- Jangan menjadikan try/catch kosong sebagai solusi. Setiap exception harus ditangani, diteruskan, atau dicatat secara aman sesuai konteks.
17. Kriteria Release / Go-No-Go
Rilis hanya boleh dilakukan jika seluruh kriteria wajib berikut terpenuhi:
- [ ] Seluruh fitur P0 telah diimplementasikan dan diuji; fitur P1/P2 yang belum selesai disembunyikan atau diberi label belum tersedia, bukan dibuat seolah aktif.
- [ ] Tidak ada crash blocker, kehilangan data kritis, akses silang akun, atau bug yang menyebabkan transaksi/poin ganda.
- [ ] flutter analyze lulus tanpa error; seluruh unit test dan integration test kritis lulus.
- [ ] Build release Android berhasil dan telah diuji di perangkat nyata. Build iOS juga harus diuji jika iOS dinyatakan sebagai platform rilis.
- [ ] Supabase production memiliki schema/migration yang benar, RLS aktif dan teruji, storage policy aman, dan Edge Functions terpasang.
- [ ] Semua secret disimpan di lingkungan backend yang sesuai; tidak ada service-role key atau secret LLM dalam bundle aplikasi.
- [ ] Email OTP, reset password, redirect/deep link, session expiry, logout, dan biometrik telah diuji pada konfigurasi rilis.
- [ ] Penanganan izin lokasi, lokasi di luar area, GPS buruk, offline mode, dan sinkronisasi telah diuji.
- [ ] Kebijakan privasi, syarat penggunaan, deskripsi aplikasi, ikon, screenshot, dan metadata store sudah sesuai implementasi sebenarnya.
- [ ] Tidak ada klaim data yang belum dibuktikan, seperti jumlah restoran terverifikasi, rating nyata, kurs real-time, enkripsi end-to-end, atau check-in anti-cheat sempurna.
- [ ] Tersedia prosedur backup/migration database, pemantauan error, penanganan insiden, dan rencana rollback.
- [ ] Versi/build number, signing Android, konfigurasi iOS, izin platform, serta konfigurasi environment telah diverifikasi.
- [ ] Uji akhir dilakukan pada build release, bukan hanya debug, dan hasil pengujian dicatat.
18. Batasan Klaim “Siap Deploy”
Dokumen ini menetapkan standar yang harus dipenuhi agar FOODIE layak dirilis, tetapi tidak otomatis membuktikan bahwa implementasi sudah siap deploy. Status siap rilis hanya boleh diberikan setelah fitur benar-benar dibangun, konfigurasi produksi diperiksa, keamanan diuji, dan kriteria release di atas lulus. Fitur yang masih berupa rancangan, simulasi, data contoh, atau belum memiliki provider/layanan aktif harus ditandai secara jujur dan tidak boleh dipresentasikan sebagai fitur produksi.