# FOODIE — Product Requirements Document & Development Rules

**Product:** Smart Culinary & Food Discovery  
**Platform:** Android & iOS  
**Frontend:** Flutter / Dart  
**Online Database:** Supabase PostgreSQL  
**Authentication:** Supabase Auth  
**Local Storage:** Hive  
**Backend Services:** Supabase dan Supabase Edge Functions  
**Design Direction:** Culinary Editorial Futurism  
**Service Area:** Bandung, Jawa Barat

---

# PART 1 — PRODUCT REQUIREMENTS DOCUMENT (PRD)

## 1. Product Overview

### 1.1 Tentang FOODIE

FOODIE adalah aplikasi mobile untuk membantu pengguna menemukan, mengeksplorasi, dan menentukan pilihan kuliner berdasarkan lokasi, anggaran, preferensi makanan, rating, dan jarak.

Aplikasi menggabungkan pencarian kuliner, rekomendasi AI, asisten LLM, peta digital, pemilihan makanan menggunakan sensor, mini game, sistem achievement, konversi mata uang, dan konversi zona waktu.

FOODIE secara eksklusif menyediakan penemuan kuliner di wilayah layanan Bandung, Jawa Barat. Pengguna dapat mencari restoran, melihat informasi menu, menyimpan favorit, membaca rekomendasi, serta menemukan tempat makan yang sesuai dengan kebutuhan.

Contoh penggunaan:

"Aku mau makanan pedas, budget Rp30.000, dan jaraknya maksimal 2 km."

FOODIE mencari kandidat restoran yang memenuhi kriteria tersebut di dalam wilayah layanan, lalu menampilkan rekomendasi berdasarkan data yang tersedia.

### 1.2 Product Vision

Menjadi aplikasi eksplorasi kuliner lokal yang membantu pengguna menemukan makanan dengan pengalaman yang praktis, personal, menarik, dan didukung teknologi modern.

### 1.3 Product Principles

1. **Food First:** makanan menjadi fokus utama aplikasi.
2. **Personalized Discovery:** rekomendasi sesuai kebutuhan pengguna.
3. **Visual Appetite:** foto makanan harus menggugah selera.
4. **Simple Interaction:** fitur mudah dipahami dan digunakan.
5. **Trustworthy Information:** informasi berdasarkan data yang tersedia.
6. **Local Discovery:** pencarian kuliner dibatasi pada wilayah layanan Bandung.
7. **Smart Technology:** AI, sensor, dan blockchain harus memiliki fungsi yang jelas.
8. **Simple Engineering:** kode sederhana, modular, dan mudah dikembangkan.

### 1.4 Masalah yang Diselesaikan

- Pengguna bingung menentukan makanan.
- Sulit menemukan tempat makan sesuai budget.
- Informasi restoran tersebar di berbagai platform.
- Pengguna kesulitan menemukan kuliner terdekat.
- Rekomendasi umum kurang sesuai dengan preferensi pribadi.
- Pengguna membutuhkan cara praktis untuk menentukan pilihan makanan.

### 1.5 Target Users

| Pengguna | Kebutuhan |
|---|---|
| Mahasiswa | Kuliner terjangkau dan dekat |
| Pekerja | Tempat makan praktis |
| Wisatawan | Eksplorasi kuliner Bandung |
| Food Explorer | Menemukan makanan baru |
| Pengguna umum | Rekomendasi sesuai preferensi |

---

## 2. Project Requirements

FOODIE harus memenuhi seluruh kriteria proyek akhir mata kuliah Pemrograman Aplikasi Mobile.

| Kriteria | Implementasi |
|---|---|
| Konsep proyek akhir | Smart Culinary & Food Discovery |
| Login dengan enkripsi dan session | Supabase Auth |
| Tanpa Firebase | Seluruh autentikasi menggunakan Supabase |
| Login biometrik | Fingerprint atau Face ID melalui autentikasi perangkat |
| Database online | Supabase PostgreSQL |
| Penyimpanan lokal | Hive |
| Web service/API | Supabase API dan Edge Functions |
| LBS | Lokasi pengguna, kuliner terdekat, peta, dan rute |
| Bottom navigation | Home, Explore, Decide, AI, Profile |
| Profil dengan gambar | Foto profil atau avatar |
| Saran dan kesan | Form feedback mata kuliah |
| Logout | Sign-out dan pembersihan sesi lokal |
| Currency converter | IDR, USD, MYR |
| Timezone converter | WIB, WITA, WIT, London |
| Minimal dua sensor | Accelerometer dan gyroscope |
| AI | Rekomendasi kuliner |
| LLM | Asisten percakapan FOODIE |
| Mini game | Guess the Food |
| Pencarian dan pemilihan | Search, filter, sorting, Shake to Decide |
| Mobile notification | Reminder dan achievement |
| Blockchain sederhana | Verifikasi integritas data menggunakan hash |

Setiap fitur wajib benar-benar berfungsi. Tampilan tombol atau halaman tanpa implementasi tidak dianggap memenuhi persyaratan.

---

## 3. Scope & Feature Priority

### P0 — Core Features

- Registrasi, login, session, dan logout.
- Login biometrik.
- Home dashboard.
- Search dan Explore.
- Filter dan sorting.
- Restaurant Detail.
- LBS dan pembatasan wilayah Bandung.
- Supabase PostgreSQL.
- Hive local storage.
- Profile dan feedback.
- Currency Converter.
- Timezone Converter.
- Accelerometer dan gyroscope.
- Mobile notification.
- API dan validasi akses.

### P1 — Smart Features

- AI Food Recommendation.
- FOODIE AI Assistant berbasis LLM.
- Favorites dan search history.
- Check-in.
- Rating dan review.
- Foodie Points dan achievement.
- Mini Game: Guess the Food.

### P2 — Advanced Features

- Blockchain verification.
- Panorama 360°.
- Leaderboard jika memungkinkan.

Seluruh fitur yang diwajibkan mata kuliah tetap harus diimplementasikan. Prioritas di atas menentukan urutan pengerjaan.

---

## 4. Geographic Scope — Bandung Only

### 4.1 Batas Wilayah

FOODIE hanya menyediakan layanan eksplorasi kuliner di wilayah Bandung.

Sebelum implementasi, tim harus menetapkan apakah cakupan wilayah berarti Kota Bandung saja atau Bandung Raya, termasuk wilayah sekitarnya seperti Kabupaten Bandung, Kabupaten Bandung Barat, dan Kota Cimahi.

Batas geografis harus ditentukan secara eksplisit dan digunakan secara konsisten oleh aplikasi, database, dan API.

### 4.2 Location Rules

- Restoran di luar wilayah layanan tidak boleh muncul dalam pencarian.
- Pengguna di luar Bandung tetap dapat membuka aplikasi.
- Pengguna di luar wilayah layanan dapat memilih lokasi pencarian secara manual di dalam Bandung.
- Izin GPS yang ditolak tidak boleh membuat fitur pencarian sepenuhnya tidak dapat digunakan.
- Backend harus memvalidasi batas geografis.
- Data kuliner yang tersimpan di Hive tetap mengikuti pembatasan wilayah.
- Lokasi perangkat dan lokasi pencarian manual harus dibedakan.

Pesan ketika pengguna berada di luar wilayah:

"FOODIE saat ini hanya menyediakan eksplorasi kuliner di Bandung. Pilih lokasi di Bandung untuk mulai menemukan makanan."

### 4.3 Location-Based Services

Fitur LBS meliputi:

- Mendeteksi lokasi pengguna setelah izin diberikan.
- Menampilkan restoran terdekat.
- Menghitung jarak dari lokasi pencarian.
- Menampilkan lokasi restoran pada peta.
- Membuka rute melalui layanan peta.
- Mendukung check-in sesuai aturan aplikasi.

### 4.4 Geographic Acceptance Criteria

| Kondisi | Hasil |
|---|---|
| Lokasi dalam wilayah layanan | Pencarian kuliner tersedia |
| Lokasi di luar wilayah | Tampilkan informasi pembatasan |
| GPS ditolak | Pengguna dapat memilih lokasi manual |
| Lokasi manual di luar area | Permintaan ditolak |
| API menerima koordinat di luar area | Hasil dibatasi oleh backend |
| AI diminta mencari kuliner kota lain | Jelaskan batas layanan dan tawarkan kuliner Bandung |

---

## 5. Application Navigation

### 5.1 Bottom Navigation

FOODIE menggunakan lima menu utama.

1. **Home:** rekomendasi dan kuliner pilihan.
2. **Explore:** pencarian, filter, dan peta.
3. **Decide:** pemilihan makanan menggunakan sensor.
4. **AI:** rekomendasi dan percakapan dengan LLM.
5. **Profile:** profil, tools, feedback, pengaturan, dan logout.

### 5.2 Profile Menu

Halaman Profile berisi:

- Foto profil atau avatar.
- Nama dan email.
- Favorites.
- Search history.
- Foodie Points dan achievement.
- Currency Converter.
- Timezone Converter.
- Saran dan Kesan mata kuliah Pemrograman Aplikasi Mobile.
- Pengaturan notifikasi.
- Logout.

### 5.3 Secondary Pages

- Restaurant Detail.
- Food Detail.
- Check-in.
- Mini Game.
- Feedback.
- Settings.
- Currency Converter.
- Timezone Converter.

Jangan menambahkan semua fitur ke bottom navigation karena dapat membuat navigasi terlalu ramai.

---

## 6. Functional Requirements

### 6.1 Authentication

**Fitur:**
- Registrasi.
- Login email dan password.
- Pengelolaan session.
- Logout.
- Login biometrik jika didukung perangkat.

**Rules:**
- Gunakan Supabase Auth.
- Tidak menggunakan Firebase Authentication.
- Password ditangani oleh mekanisme autentikasi Supabase.
- Password tidak boleh disimpan dalam bentuk plaintext.
- Gunakan HTTPS.
- Token dan session dikelola melalui mekanisme penyimpanan aman.
- Biometrik digunakan untuk membuka akses ke sesi atau kredensial lokal yang tersimpan secara aman.
- Data biometrik tidak dikirim ke server.
- Sediakan login biasa sebagai fallback.
- Logout harus mengakhiri sesi dan membersihkan kredensial lokal yang relevan.
- Endpoint privat wajib memvalidasi autentikasi dan otorisasi.

### 6.2 Home Dashboard

Konten:
- Greeting dan profil singkat.
- Lokasi pencarian.
- Search bar.
- Featured culinary.
- Nearby restaurants.
- Category chips.
- Personalized recommendations.
- Shortcut Shake to Decide.
- Favorites dan recent searches.

Rules:
- Search bar harus mudah ditemukan.
- Foto makanan menjadi fokus visual.
- Rekomendasi utama lebih menonjol daripada fitur pendukung.
- Semua data kuliner harus berasal dari wilayah layanan.
- Data dummy tidak boleh ditampilkan seolah-olah merupakan data aktual.

### 6.3 Search & Explore

Metode pencarian:
- Nama restoran.
- Nama makanan.
- Kategori kuliner.

Filter:
- Budget.
- Rating minimum.
- Jarak maksimum.
- Kategori.
- Halal atau vegetarian jika informasi tersedia dan dapat dipertanggungjawabkan.
- Open Now jika jam operasional tersedia.

Sorting:
- Nearest.
- Highest Rated.
- Most Relevant.

Rules:
- Hasil harus berada dalam batas Bandung.
- Filter aktif harus terlihat.
- Pengguna dapat menghapus filter.
- Sediakan Reset Filters.
- Jangan menghapus kriteria pengguna secara diam-diam.
- Empty state harus memberikan opsi mengubah filter.

### 6.4 Restaurant Detail

Informasi sesuai ketersediaan:
- Nama restoran.
- Foto.
- Kategori.
- Rating dan jumlah review.
- Kisaran harga.
- Jarak.
- Jam operasional.
- Menu.
- Fasilitas.
- Alamat.
- Peta dan rute.

Actions:
- Add/Remove Favorite.
- Open Directions.
- Check-in.
- Write Review.

Jangan mengarang informasi restoran yang tidak tersedia.

### 6.5 AI Food Recommendation

AI memberikan rekomendasi berdasarkan:
- Budget.
- Preferensi rasa.
- Kategori makanan.
- Jarak.
- Lokasi pencarian.
- Rating dan jam operasional jika tersedia.

Workflow:
1. Pengguna memasukkan kebutuhan.
2. Sistem memproses kriteria.
3. Backend mengambil kandidat kuliner dari Supabase.
4. Sistem memvalidasi wilayah dan filter.
5. Kandidat yang valid disusun menjadi rekomendasi.
6. Pengguna dapat membuka detail restoran.

AI tidak boleh menambahkan restoran di luar kandidat yang sudah divalidasi.

### 6.6 FOODIE AI Assistant — LLM

Contoh pertanyaan:
- "Makanan khas Bandung apa yang cocok untukku?"
- "Cari makanan pedas di bawah Rp30.000."
- "Aku ingin jajanan yang dekat dari lokasi pencarianku."

Rules:
- Fakta restoran berasal dari database atau API.
- LLM membantu memahami permintaan dan menjelaskan rekomendasi.
- Jangan mengarang harga, alamat, rating, menu, atau jam buka.
- API key LLM disimpan di backend.
- Batasi request untuk mengendalikan biaya.
- Jika AI gagal, fitur pencarian biasa tetap dapat digunakan.
- Permintaan kuliner di luar wilayah layanan harus ditangani sesuai aturan Bandung-only.

### 6.7 Accelerometer — Shake to Decide

Workflow:
1. Pengguna membuka menu Decide.
2. Sistem mengambil kandidat yang memenuhi filter.
3. Pengguna menggoyangkan perangkat.
4. Accelerometer mendeteksi gerakan.
5. Sistem memilih satu kandidat secara acak.
6. Hasil ditampilkan.
7. Pengguna dapat membuka detail atau mencoba lagi.

Rules:
- Hanya kandidat yang valid yang boleh dipilih.
- Satu gerakan menghasilkan satu pemilihan.
- Gunakan cooldown untuk mencegah pemilihan berulang.
- Sensor hanya aktif ketika halaman digunakan.
- Sediakan tombol manual sebagai fallback.

### 6.8 Gyroscope — Orientation Interaction

Gyroscope digunakan untuk interaksi berbasis orientasi perangkat, seperti preview panorama jika aset dan implementasinya tersedia.

Rules:
- Jangan mengklaim panorama 360° jika hanya menampilkan gambar biasa.
- Sediakan kontrol manual.
- Hentikan sensor listener ketika halaman ditutup.
- Tangani perangkat yang tidak mendukung fitur terkait.

### 6.9 Currency Converter

Mata uang wajib:
- IDR.
- USD.
- MYR.

Fitur:
- Memilih mata uang asal dan tujuan.
- Input nominal.
- Menukar arah konversi.
- Menampilkan hasil konversi.
- Menampilkan sumber dan waktu pembaruan kurs jika tersedia.

Rules:
- Jangan mengklaim kurs real-time tanpa sumber yang mendukungnya.
- Tangani input kosong, negatif, dan kegagalan API.
- Gunakan kurs yang valid.
- Konversi dapat diakses dari Profile atau halaman tools.

### 6.10 Timezone Converter

Zona waktu wajib:

| Label | IANA Time Zone |
|---|---|
| WIB | `Asia/Jakarta` |
| WITA | `Asia/Makassar` |
| WIT | `Asia/Jayapura` |
| London | `Europe/London` |

Fitur:
- Memilih zona asal dan tujuan.
- Memasukkan tanggal dan waktu.
- Menampilkan hasil konversi.
- Menangani perubahan tanggal.
- Mendukung perubahan daylight saving di London.

### 6.11 Mini Game — Guess the Food

Workflow:
1. Menampilkan gambar makanan.
2. Pengguna memilih jawaban.
3. Sistem memeriksa jawaban.
4. Skor diperbarui.
5. Hasil permainan ditampilkan.
6. Achievement atau reward diberikan jika syarat terpenuhi.

Rules:
- Gambar harus sesuai pertanyaan.
- Skor harus mengikuti aturan konsisten.
- Reward online harus divalidasi backend.
- Cegah pengiriman skor ganda.
- Pertanyaan harus dapat diperbarui tanpa mengubah seluruh UI.

### 6.12 Mobile Notification

Jenis notifikasi:
- Reminder waktu makan.
- Challenge kuliner.
- Achievement.
- Reward.
- Pengingat yang dipilih pengguna.

Rules:
- Minta izin secara kontekstual.
- Sediakan pengaturan notifikasi.
- Hindari notifikasi duplikat.
- Gunakan local notification untuk pengingat lokal.
- Gunakan layanan push yang sesuai jika membutuhkan notifikasi dari server.
- Kegagalan notifikasi tidak boleh merusak fitur inti.

### 6.13 Blockchain Verification

Use case: integritas review atau achievement.

Workflow:
1. Pengguna mengirim review atau menyelesaikan achievement.
2. Backend memvalidasi data.
3. Sistem menghasilkan hash payload.
4. Hash dicatat melalui mekanisme blockchain yang dipilih.
5. Hash dan transaction reference disimpan.
6. Pengguna dapat melihat status verifikasi.

Rules:
- Jangan menyimpan data pribadi dalam bentuk terbuka di blockchain.
- Hash tidak membuktikan kebenaran isi review.
- Simulasi lokal tidak boleh disebut blockchain terdesentralisasi.
- Fitur blockchain tidak boleh menghambat pencarian kuliner.

### 6.14 Favorites & Check-in

**Favorites**
- Menambah dan menghapus favorit.
- Menampilkan daftar favorit.
- Menyimpan cache lokal di Hive.
- Menyinkronkan data ke Supabase.

**Check-in**
- Memeriksa restoran dan lokasi yang dipilih.
- Menyimpan waktu check-in.
- Menampilkan riwayat.
- Memberikan reward hanya jika syarat terpenuhi.

Jangan mengklaim check-in terverifikasi tanpa validasi lokasi yang sesuai.

### 6.15 Saran & Kesan

Form untuk mata kuliah Pemrograman Aplikasi Mobile.

Fields:
- Rating.
- Saran atau komentar.
- Tombol kirim.

Rules:
- Validasi input.
- Tampilkan konfirmasi setelah server menyatakan berhasil.
- Jika offline, simpan draft di Hive.
- Draft tidak boleh dianggap sudah terkirim.
- Feedback yang terkirim disimpan di Supabase.

---

# PART 2 — UI/UX DESIGN SYSTEM

## 7. Design Direction

### Culinary Editorial Futurism

Desain menggabungkan fotografi makanan editorial dengan antarmuka digital modern yang minimalis.

Karakter visual:
- Foto makanan berukuran besar.
- Tekstur natural seperti slate, batu, dan permukaan meja.
- Komposisi editorial yang teratur.
- Tipografi berkarakter.
- Grid dan navigasi modern.
- Animasi singkat dan fungsional.

Futuristik diwujudkan melalui kualitas interface dan interaksi, bukan efek neon berlebihan.

## 7.1 Color Palette

| Color | Hex | Usage |
|---|---|---|
| Roasted Charcoal | `#252D30` | Dark background |
| Slate Blue | `#607783` | Secondary surface |
| Saffron Yellow | `#F5BD50` | Primary CTA |
| Paprika Orange | `#EF8235` | Culinary accent |
| Tomato Red | `#A92F27` | Highlight terbatas |
| Cream | `#FFF7E8` | Light background |
| Warm White | `#FFFFFF` | Card dan teks |
| Muted Gray | `#8A9398` | Secondary text |

Rules:
- Saffron Yellow menjadi aksen utama.
- Paprika Orange digunakan untuk eksplorasi.
- Tomato Red digunakan secara terbatas.
- Hindari menggunakan seluruh aksen pada setiap layar.
- Pastikan kontras teks memadai.
- Hindari warna neon yang tidak relevan.

## 7.2 Typography

Gunakan maksimal dua keluarga font:
- **Display:** DM Serif Display atau Playfair Display.
- **Interface:** Inter atau Manrope.

Serif digunakan sebagai aksen editorial. Sans-serif digunakan untuk navigasi, form, label, harga, dan informasi penting.

## 7.3 Layout & Spacing

- Grid dasar 4/8 px.
- Padding halaman 20–24 px.
- Spacing komponen 12–20 px.
- Radius kartu 16–20 px.
- Radius tombol 12–16 px.
- Shadow minimal.
- Grid konsisten.
- Layout asimetris digunakan secukupnya.

## 7.4 Photography Direction

Gunakan foto makanan dengan:
- Pencahayaan hangat.
- Close-up yang menggugah selera.
- Tekstur makanan yang jelas.
- Background natural.
- Warna realistis.
- Crop yang mempertahankan objek utama.

Jangan menggunakan foto yang tidak sesuai dengan nama menu. Gunakan placeholder jika gambar gagal dimuat.

## 7.5 Component Rules

**Search Bar**
- Placeholder: "Cari makanan, restoran, atau rasa..."
- Ikon pencarian jelas.
- Tombol clear ketika ada input.

**Category Chips**
- Contoh: Indonesian, Noodles, Street Food, Dessert, Coffee.
- State aktif mudah dikenali.

**Restaurant Card**
- Foto.
- Nama restoran.
- Kategori.
- Harga jika tersedia.
- Rating jika tersedia.
- Jarak jika tersedia.
- Status buka jika datanya valid.
- Tombol favorit.

**Food Card**
- Foto makanan.
- Nama menu.
- Harga jika tersedia.
- Kategori.
- Restoran terkait jika diketahui.

**Buttons**
- Primary: Saffron Yellow dengan teks gelap.
- Secondary: outline atau surface sekunder.
- Label harus jelas dan menunjukkan tindakan.
- Setiap tombol harus memberikan feedback.

## 7.6 Screen Layout

**Home**
1. Header dan lokasi.
2. Search bar.
3. Featured culinary.
4. Nearby restaurants.
5. Category exploration.
6. Personalized recommendations.
7. Favorites atau recent searches.

**Explore**
- Search bar.
- Filter chips.
- Map/List switch.
- Daftar restoran.
- Empty dan error state.

**Restaurant Detail**
- Foto utama.
- Nama dan kategori.
- Harga, rating, jarak, dan jam buka.
- Menu dan fasilitas.
- Alamat dan peta.
- CTA rute dan favorit.

**Decide**
- Instruksi singkat.
- Interaksi shake.
- Tombol manual.
- Hasil pilihan.
- Coba lagi.

**AI Assistant**
- Percakapan yang bersih.
- Prompt contoh.
- Kartu rekomendasi kuliner.
- Pemisahan fakta dan penjelasan AI.

**Profile**
- Identitas pengguna.
- Favorites dan history.
- Points dan achievement.
- Tools.
- Feedback.
- Settings dan logout.

## 7.7 Motion & Accessibility

- Transisi sekitar 150–250 ms.
- Animasi harus mendukung interaksi.
- Hindari animasi dekoratif yang terus berjalan.
- Gunakan target sentuh sekitar 44–48 dp.
- Hormati safe area.
- Sediakan label aksesibilitas.
- Pastikan teks tetap terbaca saat diperbesar.
- Sediakan fallback manual untuk sensor.

---

# PART 3 — DATABASE & SYSTEM ARCHITECTURE

## 8. Technology Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter / Dart |
| Online Database | Supabase PostgreSQL |
| Authentication | Supabase Auth |
| Local Storage | Hive |
| API | Supabase API / Edge Functions |
| AI / LLM | LLM API melalui backend aman |
| Location | GPS dan Maps API |
| Sensors | Accelerometer dan gyroscope |
| Notification | Local notification / push notification |
| Blockchain | Hash verification dan integrasi sesuai kebutuhan |

**Tidak menggunakan Laravel, MySQL, SQLite, atau Firebase sebagai komponen arsitektur FOODIE.**

## 8.1 Supabase — Online Database

Supabase PostgreSQL menjadi sumber utama data yang perlu diakses lintas perangkat.

| Table | Function |
|---|---|
| `profiles` | Profil pengguna |
| `restaurants` | Data restoran Bandung |
| `foods` | Data menu |
| `categories` | Kategori kuliner |
| `favorites` | Favorit pengguna |
| `reviews` | Rating dan review |
| `search_history` | Riwayat pencarian tersinkron |
| `checkins` | Riwayat check-in |
| `game_scores` | Skor mini game |
| `achievements` | Pencapaian pengguna |
| `feedback` | Saran dan kesan |
| `blockchain_records` | Hash dan referensi transaksi |

Setiap tabel harus memiliki struktur, primary key, foreign key, constraint, dan indeks yang sesuai.

Supabase Auth mengelola identitas dan sesi. Tabel `profiles` menyimpan informasi profil aplikasi yang berkaitan dengan user ID Supabase.

## 8.2 Hive — Local Storage

Hive digunakan untuk penyimpanan lokal ringan di perangkat.

Data yang dapat disimpan:
- Cache restoran dan makanan.
- Riwayat pencarian lokal.
- Preferensi aplikasi.
- Favorites cache.
- Draft feedback.
- Data antrean sinkronisasi.
- Status onboarding.
- Pengaturan lokal.

Hive tidak menggantikan Supabase sebagai database online. Hive digunakan agar aplikasi tetap responsif dan memiliki data lokal saat koneksi tidak tersedia.

### Hive Rules

- Inisialisasi Hive sebelum box digunakan.
- Gunakan nama box yang konsisten.
- Tentukan model atau format data yang stabil.
- Gunakan adapter untuk model kompleks bila diperlukan.
- Jangan menyimpan password plaintext.
- Jangan menyimpan secret API.
- Data sensitif seperti token harus menggunakan mekanisme secure storage yang sesuai, bukan Hive biasa tanpa perlindungan.
- Beri versi pada data lokal yang memerlukan migrasi.
- Tangani data rusak atau box gagal dibuka.
- Jangan menyimpan data yang tidak diperlukan.

## 8.3 Supabase Security

- Aktifkan RLS pada tabel yang membutuhkan pembatasan akses.
- Pengguna hanya boleh mengakses data yang diizinkan.
- Operasi sensitif harus melalui fungsi backend atau mekanisme yang sesuai.
- Jangan mengekspos service-role key di aplikasi Flutter.
- Jangan mengandalkan filter UI sebagai mekanisme keamanan.
- Validasi input di server.
- Batasi request jika diperlukan.
- Bedakan data publik dan privat.

## 8.4 Offline & Synchronization

1. Supabase menjadi sumber utama data online.
2. Hive menyimpan cache dan draft lokal.
3. Data lokal diberi status jika perlu disinkronkan.
4. Ketika offline, aplikasi menampilkan cache yang tersedia.
5. Draft offline tidak boleh dianggap telah terkirim.
6. Saat online kembali, perubahan dikirim melalui proses sinkronisasi.
7. Cegah review, check-in, skor, dan reward terkirim ganda.
8. Konflik data harus memiliki aturan yang jelas.
9. Seluruh cache kuliner tetap mengikuti batas wilayah Bandung.

## 8.5 System Architecture

**Pencarian kuliner**

Flutter → Restaurant Service → Supabase API/Query → Validasi wilayah dan filter → Hasil restoran → UI.

**AI Recommendation**

Flutter → AI Service → Edge Function → Ambil kandidat valid dari Supabase → LLM menyusun rekomendasi → Validasi hasil → Flutter.

**Local Storage**

Flutter → Hive Service → Cache lokal → Sinkronisasi ke Supabase saat diperlukan.

**Authentication**

Flutter → Supabase Auth → Session/token → Secure Storage → Akses data sesuai RLS.

### Architecture Rules

- Flutter mengelola UI dan interaksi.
- Service layer menangani request dan integrasi.
- Supabase menjadi layanan online utama.
- Hive menangani penyimpanan lokal.
- Edge Functions digunakan untuk secret dan operasi sensitif yang sesuai.
- AI tidak menggantikan database restoran.
- LBS mengikuti satu batas geografis.
- Seed data dapat digunakan untuk demo jika sumber data eksternal belum tersedia.

---

# PART 4 — FLUTTER PROJECT STRUCTURE

## 9. Folder Structure

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── config/
│   └── utils/
├── models/
│   ├── restaurant.dart
│   ├── food.dart
│   └── user_profile.dart
├── services/
│   ├── auth_service.dart
│   ├── restaurant_service.dart
│   ├── hive_service.dart
│   ├── location_service.dart
│   ├── sensor_service.dart
│   ├── ai_service.dart
│   └── notification_service.dart
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

Struktur dibuat modular, tetapi tidak memerlukan arsitektur yang terlalu kompleks.

---

# PART 5 — CODING RULES

## 10. General Coding Rules

1. Setiap file memiliki tanggung jawab yang jelas.
2. Jangan menempatkan seluruh aplikasi dalam satu file.
3. Pisahkan UI, model, service, dan storage.
4. Gunakan nama variabel dan fungsi yang deskriptif.
5. Hindari function terlalu panjang.
6. Hindari pengulangan logika.
7. Gunakan package yang benar-benar diperlukan.
8. Hindari abstraksi berlebihan.
9. Tangani error secara eksplisit.
10. Jangan membuat tombol dummy yang terlihat berfungsi.

## 10.1 Dart Naming

- Class: `PascalCase`.
- Variable dan function: `camelCase`.
- File: `snake_case.dart`.
- Gunakan `const` untuk nilai tetap.
- Hindari `dynamic` jika tipe data dapat ditentukan.
- Gunakan `async/await` untuk operasi asynchronous.
- Jangan memanggil API di dalam `build()`.
- Hindari null assertion tanpa pemeriksaan yang tepat.

## 10.2 Supabase Rules

- Inisialisasi Supabase satu kali saat aplikasi dimulai.
- Pisahkan autentikasi dan query melalui service.
- Gunakan RLS untuk pembatasan akses.
- Jangan menyimpan service-role key di aplikasi.
- Gunakan Edge Functions atau backend aman untuk secret LLM.
- Validasi input sebelum penyimpanan.
- Gunakan migration untuk perubahan schema.
- Uji akses menggunakan beberapa akun.
- Jangan mempercayai reward yang dikirim langsung oleh client.

## 10.3 Hive Rules

- Gunakan service khusus untuk akses Hive.
- Jangan memanggil operasi storage berulang di dalam `build()`.
- Gunakan key dan nama box yang konsisten.
- Tentukan data mana yang hanya cache dan mana yang menunggu sinkronisasi.
- Tangani error baca/tulis.
- Jangan menyimpan secret atau password.
- Jangan menganggap data Hive sebagai sumber utama data online.
- Jangan membuat mekanisme sinkronisasi kompleks sebelum kebutuhan dasar berfungsi.

## 10.4 Sensor Rules

- Listener hanya aktif ketika fitur digunakan.
- Listener dihentikan ketika halaman ditutup.
- Shake to Decide memiliki cooldown.
- Sediakan tombol manual.
- Tangani perangkat yang tidak mendukung sensor.

## 10.5 Code Quality

Sebelum fitur dianggap selesai:

- Jalankan `dart format .`.
- Jalankan `flutter analyze`.
- Jalankan unit test yang relevan.
- Uji API sukses dan gagal.
- Uji kondisi offline.
- Periksa penyimpanan session.
- Periksa izin lokasi dan sensor.
- Pastikan tidak ada secret di repository.
- Periksa semua tombol dan navigasi.

---

# PART 6 — API & DATA CONTRACTS

## 11. API Rules

Supabase menyediakan REST API melalui PostgREST. Edge Functions dapat digunakan untuk kebutuhan backend khusus.

Rancangan operasi:
- Authentication.
- Profiles.
- Restaurants.
- Foods.
- Favorites.
- Reviews.
- Feedback.
- AI Recommendations.
- AI Chat.
- Check-ins.
- Game Scores.
- Currency.
- Blockchain.

Path seperti `/functions/v1/ai-chat` hanya digunakan jika Edge Function tersebut memang dibuat. Jangan menganggap seluruh endpoint sudah tersedia secara otomatis.

Contoh format respons untuk fungsi custom:

```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": []
}
```

Contoh error:

```json
{
  "success": false,
  "message": "Permintaan gagal diproses",
  "errors": {}
}
```

Format ini merupakan kontrak untuk fungsi custom. Respons Supabase native dapat berbeda dan harus ditangani sesuai endpoint.

## 11.1 Supabase Initialization Example

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox('settings');
  await Hive.openBox('cache');

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const FoodieApp());
}

class FoodieApp extends StatelessWidget {
  const FoodieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FOODIE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF5BD50),
        ),
      ),
      home: const Scaffold(
        body: Center(child: Text('FOODIE')),
      ),
    );
  }
}
```

Contoh tersebut menunjukkan inisialisasi dasar. Model Hive yang menggunakan adapter harus didaftarkan sebelum box terkait dibuka. `FoodieApp` juga harus diganti dengan implementasi aplikasi sebenarnya.

`SUPABASE_URL` dan `SUPABASE_ANON_KEY` harus disediakan pada konfigurasi build. Publishable/anon key boleh digunakan di client jika RLS dikonfigurasi dengan benar. Service-role key tidak boleh dimasukkan ke Flutter.

## 11.2 Restaurant Model Example

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

  factory Restaurant.fromMap(Map<String, dynamic> data) {
    return Restaurant(
      id: data['id'] as int,
      name: data['name'] as String,
      category: data['category'] as String,
      rating: (data['rating'] as num?)?.toDouble(),
      priceMin: data['price_min'] as int?,
      imageUrl: data['image_url'] as String?,
    );
  }
}
```

## 11.3 Restaurant Service Example

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantService {
  final SupabaseClient client;

  RestaurantService(this.client);

  Future<List<Restaurant>> getRestaurants() async {
    final data = await client
        .from('restaurants')
        .select()
        .order('name');

    return data
        .map((item) => Restaurant.fromMap(item))
        .toList();
  }
}
```

Ini adalah query dasar. Filter geografis, jarak, pagination, dan aturan akses harus ditambahkan sesuai schema dan backend. Jangan menjadikan query ini sebagai satu-satunya perlindungan Bandung-only.

## 11.4 Hive Cache Example

```dart
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  final Box cache = Hive.box('cache');

  Future<void> saveRestaurants(
    List<Map<String, dynamic>> restaurants,
  ) async {
    await cache.put('restaurants', restaurants);
  }

  List<Map<String, dynamic>> getRestaurants() {
    final data = cache.get('restaurants', defaultValue: []);

    return List<Map<String, dynamic>>.from(
      (data as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
  }
}
```

Contoh ini sesuai untuk data sederhana yang dapat disimpan sebagai map. Untuk model kompleks, gunakan Hive TypeAdapter agar struktur data lebih terkontrol.

---

# PART 7 — NON-FUNCTIONAL REQUIREMENTS

## 12. Security

- Password ditangani Supabase Auth.
- Session/token disimpan dengan aman.
- RLS diterapkan sesuai kebutuhan.
- Secret tidak disimpan di source code.
- Validasi dilakukan pada server.
- Endpoint sensitif memiliki kontrol akses.
- Biometrik tidak mengirimkan data biometrik ke server.

## 12.1 Privacy

- Izin lokasi diminta sesuai kebutuhan.
- Pengumpulan data dibatasi.
- Pengguna dapat mengelola notifikasi.
- Data sensitif tidak disimpan sembarangan.
- Integrasi pihak ketiga dijelaskan sesuai implementasi.

## 12.2 Reliability

- Tangani timeout dan kegagalan API.
- Aplikasi tidak crash saat offline.
- Cache memiliki status yang jelas.
- Retry tidak menghasilkan duplikasi.
- Fitur inti tetap berjalan ketika AI gagal.

## 12.3 Performance

- Optimalkan ukuran gambar.
- Gunakan pagination untuk data panjang.
- Hindari request berulang.
- Hentikan sensor ketika tidak digunakan.
- Hindari rebuild widget yang tidak diperlukan.
- Jangan membaca Hive secara berulang di setiap build tanpa kebutuhan.

## 12.4 Maintainability

- Pisahkan tanggung jawab kode.
- Dokumentasikan schema dan integrasi.
- Gunakan migration untuk database.
- Uji fungsi penting.
- Hindari overengineering.

---

# PART 8 — ERROR & STATE MANAGEMENT

## 13. UI States

Halaman yang mengambil data harus menangani state yang relevan:

- Initial.
- Loading.
- Success.
- Empty.
- Error.
- Offline.
- Stale cache.
- Permission denied.

## 13.1 Error Rules

- Jangan menampilkan stack trace kepada pengguna.
- Gunakan pesan yang mudah dipahami.
- Sediakan tombol Retry jika relevan.
- Pertahankan input pengguna ketika request gagal.
- Jangan menyatakan aksi berhasil sebelum ada konfirmasi.
- Sediakan alternatif manual jika memungkinkan.

---

# PART 9 — PRODUCT RULES

## 14. Core Product Rules

1. Seluruh penemuan kuliner mengikuti batas Bandung.
2. Search, filter, detail, dan rute merupakan fungsi inti.
3. Fitur tambahan tidak boleh menghambat fungsi utama.
4. Tidak boleh ada tombol yang berpura-pura aktif.
5. Data dummy harus dibedakan dari data aktual.
6. Budget dan jarak eksplisit harus dihormati.
7. Hasil kosong harus memberikan solusi berikutnya.

## 14.1 UI/UX Rules

8. Gunakan Culinary Editorial Futurism secara konsisten.
9. Foto makanan menjadi fokus visual.
10. Gunakan warna aksen secara terkontrol.
11. Pastikan hierarki informasi jelas.
12. Hindari CTA berlebihan.
13. Komponen dengan fungsi sama harus konsisten.
14. Tombol penting harus memberikan feedback.

## 14.2 AI & Data Rules

15. Database/API menjadi sumber fakta restoran.
16. AI tidak boleh mengarang fakta.
17. Filter geografis diterapkan sebelum kandidat dikirim ke LLM.
18. Kriteria pengguna tidak boleh diubah secara diam-diam.
19. Kegagalan AI tidak boleh mematikan pencarian.
20. Rekomendasi harus menggunakan kandidat kuliner yang telah divalidasi.

## 14.3 Security Rules

21. Jangan menyimpan password plaintext.
22. Jangan mengekspos service-role key.
23. Terapkan RLS.
24. Validasi data di server.
25. Jangan mempercayai reward dari client.
26. Jangan menulis token atau secret ke log.

## 14.4 Location & Sensor Rules

27. Izin lokasi harus kontekstual.
28. Lokasi manual harus tersedia.
29. Check-in membutuhkan validasi yang sesuai.
30. Sensor hanya aktif ketika diperlukan.
31. Shake to Decide memiliki cooldown.
32. Gyroscope memiliki fallback manual.

## 14.5 Storage Rules

33. Supabase menjadi sumber utama data online.
34. Hive digunakan untuk cache dan penyimpanan lokal.
35. Draft offline tidak boleh dianggap sudah terkirim.
36. Sinkronisasi harus mencegah duplikasi.
37. Cache kuliner harus mengikuti batas Bandung.
38. Data sensitif tidak disimpan di Hive biasa tanpa perlindungan.

## 14.6 Gamification & Blockchain Rules

39. Foodie Points memiliki aturan yang jelas.
40. Reward online divalidasi server.
41. Achievement diberikan sesuai syarat.
42. Hash tidak membuktikan kebenaran review.
43. Simulasi tidak boleh disebut blockchain terdesentralisasi.

## 14.7 Converter & Notification Rules

44. Currency mendukung IDR, USD, dan MYR.
45. Timezone mendukung WIB, WITA, WIT, dan London.
46. Perubahan tanggal dan daylight saving harus ditangani.
47. Notifikasi mengikuti izin dan preferensi pengguna.

## 14.8 Engineering Rules

48. Pisahkan UI, model, service, dan storage.
49. Gunakan penamaan yang konsisten.
50. Dokumentasikan konfigurasi.
51. Uji error dan kondisi offline.
52. Hindari dependency yang tidak diperlukan.
53. Semua integrasi harus memiliki penanganan error.
54. Setiap fitur harus dapat diuji.

---

# PART 10 — ACCEPTANCE CRITERIA

## 15. Feature Acceptance

| Feature | Kriteria Keberhasilan |
|---|---|
| Authentication | Register, login, session, dan logout berfungsi |
| Biometric | Tersedia pada perangkat yang mendukung |
| Supabase | Data online dibaca dan ditulis sesuai hak akses |
| Hive | Cache dan draft tersimpan secara lokal |
| Bandung-only | Hasil pencarian tidak melewati batas layanan |
| Search | Search, filter, sorting, dan reset berfungsi |
| LBS | Lokasi, jarak, dan rute berfungsi dengan fallback |
| AI | Rekomendasi mengikuti filter dan data valid |
| LLM | Percakapan tidak mengarang fakta restoran |
| Accelerometer | Shake memilih kandidat valid |
| Gyroscope | Interaksi sensor berfungsi atau menyediakan fallback |
| Currency | IDR, USD, dan MYR tersedia |
| Timezone | WIB, WITA, WIT, dan London tersedia |
| Notification | Izin dan preferensi dihormati |
| Mini Game | Jawaban dan skor dihitung konsisten |
| Blockchain | Hash atau status pencatatan dapat diperiksa |
| Feedback | Draft dan pengiriman ditangani dengan benar |
| UI | Seluruh layar mengikuti design system |

---

# PART 11 — TESTING STRATEGY

## 16. Testing Checklist

1. **Functional Testing:** navigasi, form, tombol, filter, dan state.
2. **Authentication Testing:** login, logout, session, dan biometrik.
3. **Database Testing:** Supabase, Hive, dan sinkronisasi.
4. **Security Testing:** RLS, akses data, dan penyimpanan secret.
5. **Location Testing:** lokasi Bandung, luar wilayah, izin ditolak, dan GPS mati.
6. **Sensor Testing:** shake, cooldown, gyroscope, dan fallback.
7. **AI Testing:** budget, jarak, hasil kosong, dan request luar wilayah.
8. **Converter Testing:** input tidak valid, kurs gagal, dan pergantian tanggal.
9. **Notification Testing:** izin, preferensi, dan duplikasi.
10. **Game Testing:** jawaban, skor, dan reward.
11. **Offline Testing:** cache Hive, draft, dan sinkronisasi.
12. **Usability Testing:** kemudahan menemukan makanan dan membuka rute.

---

# PART 12 — RISKS & DEVELOPMENT ROADMAP

## 17. Risks & Mitigation

| Risiko | Mitigasi |
|---|---|
| API eksternal gagal | Cache Hive dan seed data untuk demo |
| Data restoran tidak lengkap | Tandai informasi yang tidak tersedia |
| AI lambat atau mahal | Batasi request dan konteks |
| Sensor tidak konsisten | Sediakan tombol manual |
| Blockchain terlalu kompleks | Fokus pada satu use case |
| Scope terlalu besar | Kerjakan fondasi terlebih dahulu |
| UI terlalu ramai | Batasi warna dan elemen |
| Cache kedaluwarsa | Tampilkan status cache |
| Reward terduplikasi | Validasi server |
| Kebocoran secret | Simpan secret di backend |
| Wilayah tidak konsisten | Gunakan satu konfigurasi batas geografis |
| Konflik data lokal dan online | Tentukan aturan sinkronisasi |

## 17.1 Development Roadmap

### Phase 1 — Foundation
- Setup Flutter.
- Konfigurasi Supabase.
- Schema database dan RLS.
- Authentication dan biometric.
- Design system dan navigasi.
- Profile dan feedback.
- Hive initialization.

### Phase 2 — Culinary Discovery
- Data restoran Bandung.
- Search dan filter.
- Restaurant Detail.
- LBS dan peta.
- Favorites.
- Hive cache.

### Phase 3 — Mandatory Tools & Sensors
- Currency Converter.
- Timezone Converter.
- Accelerometer.
- Gyroscope.
- Mobile notification.

### Phase 4 — AI & Engagement
- AI Recommendation.
- LLM Assistant.
- Check-in.
- Mini Game.
- Foodie Points dan achievement.

### Phase 5 — Advanced Features
- Blockchain verification.
- Panorama 360°.
- Leaderboard jika memungkinkan.

### Phase 6 — Testing & Finalization
- Functional testing.
- Security testing.
- Offline testing.
- UI refinement.
- Bug fixing.
- Dokumentasi dan demo.

---

# PART 13 — DEFINITION OF DONE

## 18. Feature Completion Rules

Fitur dianggap selesai jika:

- Persyaratan sudah jelas.
- UI mengikuti design system.
- State relevan tersedia.
- Data divalidasi.
- Hak akses diterapkan.
- Error ditangani.
- Tidak ada secret di repository.
- Alur utama telah diuji.
- Offline state diuji jika relevan.
- Tidak ada tombol atau klaim palsu.
- Dokumentasi diperbarui.

## 18.1 Final Product Principles

**Crave-worthy:** makanan ditampilkan dengan visual yang menggugah selera.

**Effortless:** pengguna dapat menemukan dan menentukan pilihan dengan langkah sederhana.

**Trustworthy:** informasi berdasarkan data yang tersedia dan batas wilayah yang jelas.

**Maintainable:** kode sederhana, profesional, mudah dipahami, dan mudah diuji.

**FOODIE — Discover Your Next Craving.**