# FOODIE — PRD ADDENDUM & CODING RULES
**Project:** Smart Culinary & Food Discovery  
**Platform:** Android dan iOS  
**Frontend:** Flutter / Dart  
**Backend:** PHP REST API  
**Database:** Supabase + SQLite  
**Authentication:** Backend authentication dengan session/token, tanpa Firebase

---

# 1. PROJECT REQUIREMENTS CHECKLIST

Semua persyaratan berikut berstatus **wajib diimplementasikan dan diuji**.

| No. | Persyaratan | Implementasi FOODIE |
|---|---|---|
| 1 | Konsep proyek akhir | Smart Culinary & Food Discovery |
| 2 | Login dengan enkripsi, tanpa Firebase | Laravel API, password hashing, HTTPS, dan token/session |
| 3 | Biometric login | Fingerprint atau Face ID melalui fitur keamanan perangkat |
| 4 | Penyimpanan online dan lokal | MySQL untuk data utama, SQLite untuk cache dan data lokal |
| 5 | Web service/API | Laravel REST API dan integrasi API eksternal |
| 6 | LBS | Nearby restaurants, jarak, peta, rute, dan check-in |
| 7 | Bottom navigation | Home, Explore, Decide, AI, Profile |
| 8 | Profil dengan gambar | Foto profil, nama, email, dan pengaturan akun |
| 9 | Saran dan kesan | Form khusus untuk mata kuliah Pemrograman Aplikasi Mobile |
| 10 | Logout | Logout melalui menu Profile dengan penghapusan sesi lokal |
| 11 | Currency converter | Minimal IDR, USD, dan MYR |
| 12 | Timezone converter | WIB, WITA, WIT, dan London |
| 13 | Minimal dua sensor | Accelerometer dan gyroscope |
| 14 | AI | Rekomendasi kuliner berdasarkan kebutuhan pengguna |
| 15 | LLM | FOODIE AI Assistant berbasis percakapan |
| 16 | Mini game | Guess the Food dengan skor |
| 17 | Search dan selection | Pencarian, filter, sorting, dan pemilihan makanan |
| 18 | Mobile notification | Reminder, challenge, dan notifikasi aktivitas |
| 19 | Blockchain sederhana | Pencatatan hash review atau achievement |

## 1.1 Definisi Keberhasilan

Proyek tidak dianggap memenuhi persyaratan hanya karena seluruh menu sudah tampil. Setiap fitur harus memiliki alur yang dapat dijalankan, penanganan error, serta pengujian yang sesuai.

API eksternal yang membutuhkan konfigurasi harus menggunakan layanan yang benar-benar tersedia. Jika fitur tertentu masih berupa simulasi, statusnya wajib dinyatakan secara transparan.

---

# 2. DETAIL FITUR WAJIB

## 2.1 Authentication dan Biometric

**Flow login:**

1. Pengguna memasukkan email dan password.
2. Flutter mengirim kredensial ke Laravel melalui HTTPS.
3. Laravel memvalidasi kredensial dan memeriksa password hash.
4. Server menerbitkan token atau session.
5. Token disimpan menggunakan secure storage.
6. Pengguna dapat mengaktifkan biometric login.
7. Logout mencabut token di server dan membersihkan data autentikasi lokal.

**Rules:**
- Tidak menggunakan Firebase Authentication.
- Password tidak boleh disimpan dalam bentuk plaintext.
- Gunakan mekanisme hashing password Laravel.
- Jangan menyimpan password untuk keperluan login biometrik.
- Biometrik digunakan untuk membuka akses ke kredensial atau sesi yang disimpan secara aman.
- Biometrik harus memiliki fallback login dengan email dan password.
- Token tidak boleh ditulis ke log atau disimpan dalam SharedPreferences biasa.
- Endpoint privat harus memvalidasi autentikasi dan otorisasi.

## 2.2 Online dan Local Storage

**MySQL:** menyimpan akun, restoran, menu, review, feedback, skor, dan data yang perlu disinkronkan.

**SQLite:** menyimpan cache restoran, preferensi lokal, favorit offline, riwayat pencarian, dan draft feedback.

**Rules:**
- MySQL menjadi sumber utama untuk data yang disinkronkan.
- SQLite tidak menggantikan backend.
- Data lokal yang belum tersinkron harus diberi status.
- Data cache dapat digunakan saat offline jika tersedia.
- Sinkronisasi tidak boleh menghasilkan review atau reward ganda.
- Data pribadi tidak boleh disimpan tanpa kebutuhan.

## 2.3 Bottom Navigation dan Profile

Gunakan lima menu utama:

- **Home:** rekomendasi dan kategori kuliner.
- **Explore:** pencarian, filter, dan peta.
- **Decide:** Shake to Decide.
- **AI:** rekomendasi dan percakapan LLM.
- **Profile:** akun, favorit, tools, feedback, pengaturan, dan logout.

Pada halaman Profile wajib terdapat:
- Foto profil atau avatar.
- Nama dan email.
- Favorites dan riwayat.
- Achievement dan Foodie Points.
- Currency Converter.
- Timezone Converter.
- Saran & Kesan Mata Kuliah Pemrograman Aplikasi Mobile.
- Pengaturan.
- Logout.

Feedback harus memiliki rating, kolom saran, validasi, serta konfirmasi setelah pengiriman berhasil.

## 2.4 Currency Converter

Mata uang wajib:
- IDR — Rupiah.
- USD — Dolar Amerika Serikat.
- MYR — Ringgit Malaysia.

Fitur:
- Pilih mata uang asal dan tujuan.
- Masukkan nominal.
- Tukar arah konversi.
- Tampilkan hasil konversi.
- Tampilkan waktu pembaruan kurs jika tersedia.

Konversi harus menggunakan kurs dari sumber yang dikonfigurasi, bukan angka acak atau kurs tetap yang diklaim sebagai real-time.

## 2.5 Timezone Converter

Zona waktu wajib:
- WIB — `Asia/Jakarta`.
- WITA — `Asia/Makassar`.
- WIT — `Asia/Jayapura`.
- London — `Europe/London`.

Fitur:
- Memilih zona waktu asal dan tujuan.
- Memasukkan tanggal dan waktu.
- Menampilkan hasil konversi.
- Menampilkan perubahan tanggal jika terjadi.
- Menangani daylight saving time London secara benar.

Gunakan database zona waktu IANA atau library yang mendukungnya, bukan sekadar menambahkan atau mengurangi jam secara manual.

## 2.6 Sensor

### Accelerometer — Shake to Decide

- Mendeteksi gerakan menggoyangkan perangkat.
- Memilih makanan secara acak dari kandidat yang sesuai filter.
- Menampilkan hasil beserta foto dan informasi yang tersedia.
- Menyediakan tombol pilih manual.
- Memiliki cooldown untuk mencegah pemilihan berulang.

### Gyroscope — Food Orientation Preview

- Menggerakkan tampilan panorama mengikuti orientasi perangkat.
- Menggunakan konten panorama yang benar-benar tersedia.
- Menyediakan kontrol manual sebagai fallback.
- Menghentikan listener sensor saat halaman ditutup.

Jika panorama 360° belum dapat direalisasikan, gunakan preview orientasi sederhana dan jelaskan batas implementasinya.

## 2.7 AI dan LLM

### AI Food Recommendation

Input: preferensi makanan, budget, lokasi, kategori, dan jarak.

Output: kandidat kuliner, alasan rekomendasi, estimasi harga, serta jarak berdasarkan data yang tersedia.

### FOODIE AI Assistant

Asisten percakapan untuk membantu pengguna menemukan ide makanan, kuliner lokal, dan rekomendasi berdasarkan kebutuhan.

**Rules:**
- LLM tidak boleh menjadi sumber utama fakta restoran.
- Backend mengambil kandidat dari database/API.
- LLM membantu memahami kebutuhan dan menjelaskan hasil.
- Jangan mengarang harga, alamat, rating, atau jam buka.
- Pertahankan batas budget dan jarak pengguna.
- Jika tidak ada hasil yang sesuai, jelaskan alasannya.
- Simpan API key LLM di backend, bukan di aplikasi Flutter.

## 2.8 Mini Game — Guess the Food

Gameplay:
1. Sistem menampilkan foto makanan.
2. Pengguna memilih jawaban dari beberapa opsi.
3. Sistem memeriksa jawaban.
4. Skor bertambah sesuai aturan.
5. Hasil permainan ditampilkan.
6. Reward diberikan jika memenuhi ketentuan.

Gunakan dataset pertanyaan yang sederhana dan terstruktur. Skor atau reward yang disimpan online harus divalidasi backend.

## 2.9 Mobile Notification

Notifikasi dapat digunakan untuk:
- Reminder waktu makan.
- Challenge kuliner.
- Achievement dan reward.
- Pengingat aktivitas yang dipilih pengguna.

Gunakan local notification untuk pengingat yang dapat dijadwalkan di perangkat. Jika membutuhkan push notification dari server, integrasikan layanan push yang dipilih tanpa menjadikan Firebase Authentication sebagai ketergantungan.

Notifikasi harus mengikuti izin dan preferensi pengguna.

## 2.10 Blockchain Sederhana

Use case utama: **verifikasi integritas review atau achievement**.

Alur:
1. Pengguna mengirim review atau menyelesaikan achievement.
2. Backend memvalidasi data.
3. Sistem membentuk payload dan menghasilkan hash.
4. Hash dicatat melalui mekanisme blockchain yang dipilih.
5. Sistem menyimpan hash dan transaction ID.
6. Pengguna dapat melihat status pencatatan atau verifikasi.

Jangan menyimpan password atau data pribadi di blockchain. Hash hanya membantu memeriksa integritas data; hash tidak otomatis membuktikan bahwa isi review benar.

Jika menggunakan pencatatan hash lokal tanpa jaringan blockchain, sebut sebagai simulasi hash verification, bukan blockchain terdesentralisasi.

---

# 3. CODING RULES — SIMPLE & PROFESSIONAL

## 3.1 Prinsip Penulisan Kode

1. Kode harus mudah dibaca mahasiswa lain tanpa penjelasan panjang.
2. Setiap class dan file memiliki tanggung jawab yang jelas.
3. Hindari function terlalu panjang dan nested condition berlebihan.
4. Jangan mengulang logika yang sama di banyak file.
5. Gunakan nama variabel, class, dan function yang menjelaskan tujuannya.
6. Pisahkan UI dari API, database, autentikasi, dan sensor.
7. Gunakan package hanya jika benar-benar dibutuhkan.
8. Jangan membuat abstraksi atau design pattern yang tidak diperlukan.
9. Tangani error secara eksplisit.
10. Jangan meninggalkan tombol dummy atau fitur yang terlihat aktif tetapi tidak berfungsi.

## 3.2 Struktur Folder Flutter

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── network/
│   └── utils/
├── models/
│   ├── restaurant.dart
│   ├── food.dart
│   └── user.dart
├── services/
│   ├── auth_service.dart
│   ├── restaurant_service.dart
│   ├── location_service.dart
│   ├── ai_service.dart
│   ├── sensor_service.dart
│   └── storage_service.dart
├── pages/
│   ├── auth/
│   ├── home/
│   ├── explore/
│   ├── decide/
│   ├── ai/
│   ├── profile/
│   ├── converters/
│   ├── mini_game/
│   └── feedback/
└── widgets/
    ├── food_card.dart
    ├── restaurant_card.dart
    ├── search_bar.dart
    └── loading_view.dart
```

Struktur ini cukup untuk proyek skala mahasiswa. Jangan menambahkan banyak layer seperti repository, use case, dan dependency injection apabila belum dibutuhkan.

## 3.3 Aturan Dart

- Gunakan `PascalCase` untuk class dan enum.
- Gunakan `camelCase` untuk variabel dan function.
- Gunakan `snake_case.dart` untuk nama file.
- Gunakan `const` untuk widget yang nilainya tetap.
- Hindari `dynamic` jika tipe data dapat ditentukan.
- Hindari penggunaan `!` untuk memaksa nilai non-null tanpa pemeriksaan.
- Gunakan `async/await` untuk operasi asynchronous.
- Jangan memanggil API langsung di dalam `build()`.
- Jangan menempatkan seluruh aplikasi dalam satu file.
- Jalankan formatter dan analyzer sebelum commit.

## 3.4 Aturan Backend Laravel

- Gunakan migration untuk perubahan database.
- Gunakan Eloquent Model untuk akses data.
- Gunakan Form Request atau validasi Laravel.
- Gunakan controller untuk mengatur alur request.
- Gunakan service untuk logika bisnis yang digunakan ulang atau cukup kompleks.
- Gunakan middleware untuk autentikasi.
- Gunakan API Resource jika perlu menstandarkan respons.
- Jangan menempatkan seluruh logika di controller.
- Jangan mengembalikan stack trace kepada client.
- Gunakan environment variables untuk secret.
- Gunakan rate limiting untuk endpoint sensitif dan layanan AI.

## 3.5 Standar API

Gunakan prefix `/api/v1`.

| Method | Endpoint | Fungsi |
|---|---|---|
| POST | `/api/v1/auth/register` | Registrasi |
| POST | `/api/v1/auth/login` | Login |
| POST | `/api/v1/auth/logout` | Logout |
| GET | `/api/v1/me` | Profil pengguna |
| GET | `/api/v1/restaurants` | Daftar restoran |
| GET | `/api/v1/restaurants/{id}` | Detail restoran |
| GET | `/api/v1/foods` | Pencarian makanan |
| GET | `/api/v1/favorites` | Daftar favorit |
| POST | `/api/v1/favorites` | Tambah favorit |
| POST | `/api/v1/reviews` | Kirim review |
| POST | `/api/v1/feedback` | Kirim saran dan kesan |
| POST | `/api/v1/ai/recommendations` | Rekomendasi AI |
| POST | `/api/v1/ai/chat` | Percakapan LLM |
| POST | `/api/v1/checkins` | Check-in |
| POST | `/api/v1/game/scores` | Kirim skor permainan |
| GET | `/api/v1/converters/currency` | Kurs mata uang |
| POST | `/api/v1/blockchain/records` | Catat hash |

Endpoint tersebut merupakan rancangan awal dan harus disesuaikan dengan implementasi aktual. Tambahkan autentikasi pada endpoint privat dan validasi setiap input di server.

## 3.6 Standar Respons API

Gunakan format respons yang konsisten.

Respons berhasil:

```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": []
}
```

Respons gagal:

```json
{
  "success": false,
  "message": "Permintaan gagal diproses",
  "errors": {}
}
```

Status HTTP harus sesuai dengan kondisi sebenarnya, misalnya `200`, `201`, `401`, `403`, `422`, atau `500`.

## 3.7 Contoh Model Flutter

```dart
class Restaurant {
  final int id;
  final String name;
  final String category;
  final double? rating;
  final int? priceMin;
  final String? imageUrl;

  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    this.rating,
    this.priceMin,
    this.imageUrl,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      rating: (json['rating'] as num?)?.toDouble(),
      priceMin: json['price_min'] as int?,
      imageUrl: json['image_url'] as String?,
    );
  }
}
```

Model bertanggung jawab untuk merepresentasikan data restoran. Request HTTP tetap ditempatkan di service.

## 3.8 Contoh Service Flutter

```dart
class RestaurantService {
  final http.Client client;
  final String baseUrl;

  RestaurantService({
    required this.client,
    required this.baseUrl,
  });

  Future<List<Restaurant>> getRestaurants() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/v1/restaurants'),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data restoran');
    }

    final body = jsonDecode(response.body)
        as Map<String, dynamic>;

    final items = body['data'] as List<dynamic>;

    return items
        .map(
          (item) => Restaurant.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
```

Contoh ini membutuhkan import `dart:convert`, `package:http/http.dart`, serta model `Restaurant`. Autentikasi, timeout, dan penanganan error produksi ditambahkan melalui konfigurasi service.

## 3.9 Code Quality Rules

Sebelum fitur dinyatakan selesai:

- `dart format .`
- `flutter analyze`
- Jalankan unit test yang relevan.
- Uji request API sukses dan gagal.
- Periksa tidak ada secret yang masuk repository.
- Periksa listener sensor sudah dihentikan.
- Periksa loading, error, empty, dan offline state.
- Pastikan fungsi utama tetap dapat digunakan ketika layanan opsional gagal.

# ADDENDUM PRD — BANDUNG-ONLY SERVICE AREA

## 1. Product Scope: Geographic Restriction

FOODIE merupakan aplikasi eksplorasi kuliner yang secara eksklusif melayani wilayah Bandung, Jawa Barat. Seluruh fitur pencarian, rekomendasi, pemetaan, dan informasi tempat kuliner dibatasi pada wilayah layanan yang telah ditentukan.

Aplikasi tidak ditujukan untuk pencarian kuliner secara nasional atau internasional. Pengguna hanya dapat menemukan dan memperoleh rekomendasi tempat makan yang berada di dalam area layanan FOODIE di Bandung.

### Aturan Wilayah

- Wilayah layanan utama adalah Bandung, Jawa Barat.
- Batas geografis harus ditentukan secara eksplisit dalam konfigurasi aplikasi, bukan hanya berdasarkan nama kota.
- Tempat kuliner di luar area layanan tidak boleh muncul sebagai hasil pencarian atau rekomendasi.
- Pengguna di luar Bandung tetap dapat membuka aplikasi, tetapi tidak dapat menggunakan fitur penemuan kuliner untuk wilayah di luar area layanan.
- Pengguna dapat memilih lokasi Bandung secara manual apabila izin lokasi ditolak atau GPS tidak tersedia.
- Fitur konversi mata uang, konversi waktu, profil, dan pengaturan tetap dapat digunakan tanpa bergantung pada lokasi pengguna.

**Catatan batas wilayah:** sebelum implementasi, tim harus menetapkan apakah cakupan yang dimaksud adalah Kota Bandung saja atau Bandung Raya, termasuk wilayah Kabupaten Bandung, Kabupaten Bandung Barat, Kota Cimahi, dan wilayah terkait lainnya. Batas ini harus konsisten di frontend, backend, database, dan API.

## 2. Location-Based Service (LBS)

LBS digunakan untuk menemukan tempat kuliner berdasarkan posisi pengguna di dalam area layanan FOODIE.

### Functional Requirements

1. Aplikasi meminta izin lokasi ketika pengguna mengakses fitur kuliner berbasis lokasi.
2. Sistem memeriksa apakah koordinat pengguna berada di dalam wilayah layanan.
3. Jika berada di dalam wilayah, aplikasi menampilkan tempat makan terdekat.
4. Jika berada di luar wilayah, aplikasi menampilkan informasi bahwa layanan kuliner hanya tersedia di Bandung.
5. Pengguna di luar Bandung dapat memilih lokasi pencarian secara manual di dalam wilayah layanan.
6. Peta hanya menampilkan restoran yang memenuhi batas geografis FOODIE.
7. Rute menuju restoran dapat dibuka menggunakan layanan peta yang tersedia.

### User Messages

**Pengguna berada di dalam wilayah layanan:**

"Temukan kuliner terbaik di sekitarmu."

**Pengguna berada di luar wilayah layanan:**

"FOODIE saat ini hanya tersedia untuk eksplorasi kuliner di Bandung. Pilih lokasi di Bandung untuk mulai menemukan makanan."

**Lokasi tidak tersedia:**

"Kami belum dapat menentukan lokasimu. Pilih lokasi di Bandung secara manual untuk melanjutkan."

## 3. Search & Explore Rules

- Seluruh hasil pencarian harus berada dalam batas geografis yang ditentukan.
- Filter jarak dihitung dari lokasi pencarian yang dipilih pengguna.
- Filter harga, rating, kategori, dan jam operasional hanya diterapkan pada kandidat di dalam wilayah layanan.
- Pencarian nama restoran tidak boleh melewati batas geografis.
- Jika tidak ada hasil, tampilkan empty state dan opsi mengubah filter.
- Sistem tidak boleh otomatis mengalihkan pencarian ke kota lain.
- Lokasi manual di luar area layanan harus ditolak dengan pesan yang jelas.

## 4. AI Food Recommendation Rules

AI hanya boleh merekomendasikan restoran dan tempat kuliner yang berada di dalam wilayah layanan FOODIE.

Contoh permintaan:

"Aku mau makan pedas, budget Rp30.000, dan jaraknya maksimal 2 km."

Sistem harus:
1. Mengambil kandidat restoran dari database atau API kuliner Bandung.
2. Menerapkan batas wilayah sebelum menghasilkan rekomendasi.
3. Memeriksa budget, kategori, jarak, dan preferensi pengguna.
4. Mengirimkan kandidat yang valid kepada LLM untuk penyusunan rekomendasi.
5. Menampilkan alasan rekomendasi berdasarkan informasi yang tersedia.

LLM tidak boleh menambahkan restoran di luar daftar kandidat yang telah divalidasi.

Jika pengguna meminta rekomendasi di Jakarta, Yogyakarta, atau kota lain di luar area layanan, aplikasi harus menjelaskan batas wilayah dan menawarkan pencarian kuliner Bandung.

## 5. Backend & Database Rules

- Setiap restoran harus memiliki koordinat geografis yang valid atau referensi lokasi yang dapat diverifikasi.
- Backend menjadi sumber utama penentuan cakupan wilayah.
- Batas geografis disimpan dalam konfigurasi terpusat.
- Endpoint restoran, makanan, rekomendasi, pencarian, dan check-in wajib menerapkan pembatasan wilayah.
- Validasi wilayah tidak boleh hanya dilakukan di frontend.
- Data restoran di luar area layanan tidak boleh dikembalikan oleh endpoint publik FOODIE.
- Lokasi pengguna dan lokasi restoran harus dibedakan.
- Perubahan cakupan wilayah harus dilakukan melalui konfigurasi yang terkontrol.

## 6. Acceptance Criteria

| Skenario | Hasil yang Diharapkan |
|---|---|
| Pengguna berada di Bandung | Dapat menemukan kuliner di wilayah layanan. |
| Pengguna berada di luar Bandung | Mendapat pemberitahuan pembatasan wilayah. |
| Pengguna di luar Bandung memilih lokasi Bandung | Dapat melakukan pencarian pada lokasi yang valid. |
| Pengguna mencari restoran di kota lain | Tidak mendapatkan hasil dari luar area layanan. |
| AI diminta merekomendasikan kuliner luar wilayah | AI menjelaskan batas layanan dan menawarkan alternatif di Bandung. |
| Pengguna menolak izin GPS | Pencarian manual tetap tersedia. |
| API menerima koordinat di luar batas | Backend menolak permintaan atau mengembalikan hasil kosong sesuai kontrak API. |
| Tidak ada restoran yang sesuai filter | Sistem menampilkan empty state tanpa menghapus batas wilayah. |

## 7. Design & Branding Adjustment

Identitas visual FOODIE tetap menggunakan konsep Culinary Editorial Futurism dengan foto makanan yang menggugah selera, warna slate, cream, saffron yellow, paprika orange, dan tomato red.

Konten Home disesuaikan menjadi eksplorasi kuliner Bandung, seperti:

- Kuliner dekat lokasi pengguna.
- Makanan khas Bandung.
- Rekomendasi jajanan dan street food.
- Tempat makan sesuai budget.
- Kuliner populer di sekitar area pencarian.

Konten lokal hanya boleh ditampilkan jika didukung data yang relevan. Jangan mengklaim suatu makanan sebagai khas Bandung tanpa dasar informasi yang memadai.

**Product Rule:** seluruh fitur penemuan kuliner FOODIE harus konsisten menggunakan satu batas wilayah layanan yang sama. Pembatasan berlaku di frontend dan backend, bukan hanya sebagai label atau informasi pada halaman Home.
---

# 4. FINAL PRIORITY

Urutan pengerjaan yang disarankan:

**Tahap 1:** struktur aplikasi, tema, navigasi, login, dan session.

**Tahap 2:** MySQL, REST API, SQLite, pencarian, filter, dan detail restoran.

**Tahap 3:** LBS, biometric, accelerometer, gyroscope, dan notifikasi.

**Tahap 4:** AI Recommendation, LLM Assistant, currency converter, dan timezone converter.

**Tahap 5:** mini game, feedback, blockchain sederhana, pengujian, dan penyempurnaan UI.

Seluruh persyaratan tugas tetap wajib ditangani. Pembagian tahap hanya untuk menjaga pengerjaan tetap terarah dan mengurangi risiko fitur inti belum selesai ketika tenggat tiba.

**Prinsip implementasi:** pilih solusi paling sederhana yang benar-benar memenuhi kebutuhan, mudah dijelaskan saat presentasi, dapat diuji, dan tidak mengorbankan keamanan maupun pengalaman pengguna.
