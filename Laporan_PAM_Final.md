# LAPORAN PROYEK AKHIR PEMROGRAMAN APLIKASI MOBILE
## FOODIE — PRO - MATARAMAN EDITION
### Smart Culinary & Food Discovery (Daerah Istimewa Yogyakarta & Jawa Tengah)

**Mata Kuliah:** Pemrograman Aplikasi Mobile (SI-E)  
**Program Studi:** Program Studi Sistem Informasi  
**Jurusan:** Jurusan Informatika  
**Fakultas:** Fakultas Teknik Industri  
**Universitas:** Universitas Pembangunan Nasional "Veteran" Yogyakarta  
**Tahun Akademik:** 2026

**Disusun Oleh:**
- Eileen (124230023)
- Oktafiani Nur Widayati (124240081)
- Muhammad Zain Aulia Firdaus (124240121)

**Dosen Pengampu:**  
Bagus Muhammad Akbar, S.ST., M.Kom.

---

## HALAMAN PENGESAHAN PRESENTASI

Judul Proyek: **FOODIE — PRO - MATARAMAN EDITION**  
Mata Kuliah: Pemrograman Aplikasi Mobile  
Kelas: SI-E  

Telah disetujui dan disahkan pada presentasi Proyek Akhir Pemrograman Aplikasi Mobile Program Studi Sistem Informasi, Jurusan Informatika, Fakultas Teknik Industri, Universitas Pembangunan Nasional "Veteran" Yogyakarta.

Yogyakarta, 24 Oktober 2025  
Menyetujui,  
Dosen Pengampu  

**(Bagus Muhammad Akbar, S.ST., M.Kom.)**

---

## DAFTAR ISI

- HALAMAN JUDUL
- HALAMAN PENGESAHAN PRESENTASI
- DAFTAR ISI
- BAB I PENDAHULUAN
  - 1.1 Latar Belakang
  - 1.2 Tujuan Proyek
  - 1.3 Analisis Kebutuhan
    - 1.3.1 Kebutuhan Fungsional (25 Modul Kebutuhan)
    - 1.3.2 Kebutuhan Non Fungsional
    - 1.3.3 Kebutuhan Perangkat Keras
    - 1.3.4 Kebutuhan Perangkat Lunak
    - 1.3.5 Kebutuhan Data
  - 1.4 Perancangan Sistem
    - 1.4.1 Use Case Diagram & Spesifikasi Use Case
    - 1.4.2 Activity Diagram
    - 1.4.3 Sequence Diagram
    - 1.4.4 Perancangan Basis Data (ERD & Data Dictionary)
    - 1.4.5 Perancangan Arsitektur Antarmuka Pengguna (UI Architecture)
- BAB II IMPLEMENTASI
  - 2.1 Deskripsi Umum Aplikasi
  - 2.2 Struktur Modular Aplikasi
  - 2.3 Penjelasan Source Code Inti
  - 2.4 Penggunaan API & Integrasi Backend
  - 2.5 Integrasi Sistem (Sensors, Cloud, Storage, AI)
  - 2.6 Tampilan Antarmuka 18 Layar Figma
- BAB III TESTING
  - 3.1 Metode Testing
  - 3.2 Rencana dan Prosedur Testing
  - 3.3 Lembar Evaluasi Pengujian UAT (User Acceptance Testing)
- BAB IV KESIMPULAN DAN SARAN
  - 4.1 Kesimpulan
  - 4.2 Saran

---

# BAB I PENDAHULUAN

## 1.1 Latar Belakang

Menentukan tempat makan terkadang membutuhkan waktu karena harus menyesuaikan pilihan dengan selera, anggaran, jarak, dan informasi restoran yang tersedia. Banyaknya pilihan kuliner juga membuat seseorang kerap mengalami kebingungan dalam menentukan makanan yang ingin dibeli (decision fatigue). Selain itu, informasi mengenai menu, harga riil, titik koordinat akurat, fasilitas restoran, dan jam operasional belum tentu tersedia dalam satu platform terpadu yang tepercaya.

Wilayah Daerah Istimewa Yogyakarta (DIY) dan Provinsi Jawa Tengah memiliki kekayaan warisan kuliner yang sangat tinggi, mulai dari sentra gudeg legendaris Wijilan, dapur tradisional mangut lele asap kayu bakar di Sewon Bantul, bakmi Jawa arang khas Kotagede, hingga angkringan kopi joss di Stasiun Tugu. Namun demikian, banyak kurasi kuliner di platform umum yang tercampur dengan tempat makan modern tanpa konteks sejarah atau tidak memiliki validasi kehadiran fisik, sehingga menimbulkan ulasan yang bias atau tidak akurat. Di sisi lain, wisatawan domestik maupun mancanegara sering kali mengalami kendala dalam memperkirakan harga makanan tradisional ke dalam mata uang asal mereka (seperti USD dan MYR) serta menyesuaikan jadwal santap makan lokal khas Jogja (seperti santap sarapan pagi gudeg pukul 06.00 WIB vs wedangan malam angkringan pukul 19.00 - 02.00 WIB) dengan zona waktu asal mereka.

Berdasarkan permasalahan tersebut, dikembangkan FOODIE (PRO - MATARAMAN EDITION), yaitu aplikasi mobile penemuan kuliner cerdas berbasis Flutter dan Dart yang dirancang secara khusus untuk mengangkat dan mengeksplorasi warisan kuliner autentik di wilayah Daerah Istimewa Yogyakarta dan Jawa Tengah. Aplikasi ini mengintegrasikan basis data online PostgreSQL melalui Supabase, manajemen sesi aman dengan Supabase Auth, penyimpanan luring instan berbasis Hive, layanan berbasis lokasi presisi (Location-Based Services / LBS) dengan pembatasan geografis ketat, asisten kuliner berbasis Large Language Model (LLM) dengan Retrieval-Augmented Generation (RAG) ke basis data Supabase, serta interaksi fisik menggunakan sensor Accelerometer (Shake to Decide) dan Gyroscope.

FOODIE juga dilengkapi dengan sistem verifikasi kehadiran fisik berbasis radar Geofence GPS (< 50 meter) yang terhubung ke sistem gamifikasi gastronomi (Level Kurator, Foodie Points, 20 Lencana Warisan Kuliner, dan Katalog Penukaran Voucher Kuliner), permainan edukasi harian Tebak Kuliner Jogja, utilitas konverter kurs valas (IDR, USD, MYR) dengan tolok ukur makanan riil Jogja, konverter 4 zona waktu (WIB, WITA, WIT, London BST), serta pencatatan integritas ulasan berbasis cryptographic hash. Seluruh perancangan antarmuka mengacu pada panduan desain Culinary Editorial Futurism yang telah dimodelkan dalam 18 layar purwarupa Figma pada berkas mobagus.zip.

## 1.2 Tujuan Proyek

Tujuan dari pengembangan aplikasi FOODIE adalah:
1. Membangun aplikasi mobile penjelajahan dan kurasi kuliner warisan lokal yang secara eksklusif berfokus pada wilayah Daerah Istimewa Yogyakarta dan Jawa Tengah.
2. Memudahkan pengguna dalam mencari dan memfilter tempat makan berdasarkan anggaran (budget), jarak terdekat, status buka saat ini, dan kategori rasa autentik.
3. Mengimplementasikan autentikasi 3-tahap yang aman meliputi registrasi dengan validasi kontak, verifikasi email OTP 6-digit, serta aktivasi biometrik (Fingerprint / Face ID) menggunakan Secure Enclave perangkat.
4. Menerapkan arsitektur hybrid storage yang menggabungkan Supabase PostgreSQL sebagai basis data daring utama dan Hive sebagai basis data lokal berkecepatan tinggi untuk mendukung pencarian dan penyimpanan favorit luring (offline-first).
5. Menerapkan Location-Based Services (LBS) dan radar Geofence GPS (< 50 meter) untuk memverifikasi kehadiran fisik pengguna di lokasi warung makan secara sah (anti-cheat validation).
6. Mengembangkan FOODIE AI Assistant berbasis LLM yang terhubung langsung ke basis data Supabase (Mataraman Taste Engine) untuk memberikan rekomendasi kuliner yang relevan tanpa halusinasi data.
7. Memanfaatkan sensor Accelerometer untuk fitur interaktif Shake to Decide yang memungkinkan pengguna memilih makanan dengan menggoyangkan perangkat, didukung opsi manual pick sebagai fallback.
8. Menyediakan utilitas wisatawan terpadu berupa konverter mata uang (IDR, USD, MYR) dengan tolok ukur makanan Jogja riil, serta konverter 4 zona waktu makan (WIB, WITA, WIT, London BST) dengan kiat jam operasional lokal.
9. Mengembangkan modul gamifikasi edukatif meliputi mini game harian Tebak Kuliner Jogja, perolehan Foodie Points, 20 lencana pencapaian kurator (achievements), dan katalog penukaran voucher makan riil.

---

## 1.3 Analisis Kebutuhan

Analisis kebutuhan sistem dirumuskan secara komprehensif dengan mengacu secara langsung pada 18 antarmuka purwarupa Figma pada berkas `mobagus.zip`.

### 1.3.1 Kebutuhan Fungsional

Kebutuhan fungsional mendefinisikan kapabilitas, proses, input, output, dan aturan bisnis yang harus disediakan oleh aplikasi FOODIE.

| No | Nama Kebutuhan | Deskripsi & Acuan Layar Figma | Input | Proses Sistem | Output | Aturan Validasi & Bisnis |
|---|---|---|---|---|---|---|
| **KF-01** | Splash & Intro | Menampilkan layar pembuka aplikasi dengan identitas Mataraman Edition, titik koordinat GNSS Nol KM Jogja, sorotan 3 Dapur Pusaka, inisialisasi basis data luring Hive, dan tombol mulai petualangan. (*Screen 1: Intro.png*) | Sentuhan tombol 'Mulai Petualangan Kuliner' | Menginisialisasi Hive boxes (settings, cache), memverifikasi koneksi internet, dan memeriksa status sesi aktif. | Animasi splash, status kesiapan sistem 100%, navigasi otomatis ke Onboarding atau Beranda. | Hive box harus terinisialisasi tuntas sebelum antarmuka utama dimuat. |
| **KF-02** | Onboarding Interaktif | Memperkenalkan proposisi nilai kurasi Keraton, validasi check-in radar fisik (<50m), insentif +100 poin selamat datang, dan pameran fitur utama. (*Screen 2: Onboarding.png*) | Klik 'Daftar Akun Baru' atau 'Masuk Akun' | Menampilkan ringkasan kapabilitas sistem (Offline DB, Tebak Kuliner, Konverter Valas/Waktu, 420+ warung mitra). | Halaman edukasi visual, tombol navigasi registrasi / login. | Pengguna dapat melewati onboarding (skip) langsung menuju halaman login. |
| **KF-03** | Autentikasi Pengguna & Login | Menyediakan akses masuk menggunakan kredensial email dan kata sandi atau autentikasi biometrik lokal 1-ketukan. (*Screen 3: Login.png*) | Email, Password, Checklist Remember Me, atau sentuhan sidik jari | Mengautentikasi kredensial via Supabase Auth TLS 1.3; memverifikasi token biometrik lokal melalui Secure Enclave. | Sesi JWT Supabase aktif, token tersimpan di Secure Storage, redirect ke Beranda. | Password minimal 8 karakter; jika biometrik gagal, otomatis dialihkan ke formulir kata sandi. |
| **KF-04** | Registrasi Kurator Baru | Mendaftarkan akun kurator baru dengan data identitas, kontak WhatsApp untuk validasi warung, dan kata sandi berkekuatan terukur. (*Screen 4: Register.png*) | Nama lengkap, email, nomor WhatsApp/HP, kata sandi, konfirmasi sandi, checklist syarat & ketentuan | Memvalidasi keunikan email dan nomor kontak; menguji kekuatan kata sandi; memicu pendaftaran akun di Supabase Auth. | Akun berstatus unverified, pemberian perk selamat datang +100 poin, navigasi ke verifikasi email. | Nomor HP wajib berformat standar Indonesia (+62/08); kata sandi wajib memuat huruf besar dan angka. |
| **KF-05** | Verifikasi Email OTP | Memverifikasi kepemilikan alamat email pengguna melalui kode OTP 6-digit terlindung enkripsi SSL. (*Screen 5: Verif Email.png*) | 6 digit angka OTP, tombol kirim ulang, atau tombol buka aplikasi email | Memvalidasi token OTP terhadap Supabase Auth; mengelola countdown timer kirim ulang selama 48 detik. | Status akun terverifikasi (email_confirmed), navigasi otomatis ke aktivasi biometrik. | Kode OTP kedaluwarsa dalam 10 menit; tombol kirim ulang dinonaktifkan hingga timer 00:00 tercapai. |
| **KF-06** | Aktivasi Keamanan Biometrik | Menghubungkan sensor sidik jari / Face ID perangkat ke sesi lokal kurator untuk login instan dan otorisasi check-in cepat. (*Screen 6: Verif biometrik.png*) | Sentuhan sidik jari pada sensor perangkat, opsi PIN cadangan 6-digit, atau tombol 'Nanti Saja' | Menguji ketersediaan perangkat keras biometrik melalui Local Authentication API; mendaftarkan public key ke hardware Secure Enclave. | Status biometrik aktif pada preferensi lokal; navigasi ke Beranda utama. | Tidak ada data biometrik mentah yang dikirim ke jaringan atau server Supabase. |
| **KF-07** | Beranda & Kurasi Rasa | Menyajikan dashboard penjelajahan rasa, sapaan personal 'Sugeng Rawuh, Dimas', search bar, chip kategori, kartu Pilihan Editor, banner Shake to Decide, dan kuliner terdekat. (*Screen 7: Home Screen.png*) | Pemilihan chip kategori, klik kartu kuliner, atau ketukan banner interaktif | Membaca data restoran terkurasi dari cache Hive / Supabase; menghitung jarak Euclidean dari koordinat pengguna. | Tampilan dinamis kartu kuliner editorial, daftar terdekat (<2km), kuliner hemat (<Rp25rb), dan artikel budaya. | Hanya menampilkan tempat kuliner yang berada di dalam wilayah DIY dan Jawa Tengah. |
| **KF-08** | Eksplorasi & Filter Kuliner | Menyediakan pencarian teks bebas (nama resto, masakan, bahan) dilengkapi filter aktif (budget <Rp25rb, buka sekarang) dan dropdown pengurutan. (*Screen 8: Explore.png*) | Kata kunci pencarian, pemilihan filter chips, opsi pengurutan (Terdekat, Rating) | Mengeksekusi query dinamis di Supabase / Hive; menerapkan filter batas administrasi DIY-Jateng; mengurutkan hasil. | Daftar kartu restoran terfilter (misal: 38 tempat ditemukan), indikator filter aktif, atau kartu edukasi jika di luar wilayah. | Filter chip dapat dihapus secara individual atau direset sekaligus; filter kosong menampilkan opsi ubah kriteria. |
| **KF-09** | Detail Restoran & Info Menu | Menampilkan profil lengkap restoran, galeri foto interaktif (hingga 18 foto), catatan gastronomi keraton, 3 paket menu terlaris, fasilitas, lokasi maps, ulasan terverifikasi, dan CTA rute. (*Screen 9: Detail.png*) | ID restoran yang dipilih pengguna | Mengambil relasi data restoran, menu makanan terlaris, fasilitas, ulasan komunitas, dan koordinat fisik dari Supabase. | Layar profil detail restoran yang kaya visual, estimasi jarak real-time, tombol rute Google Maps, dan tombol check-in. | Informasi jam operasional, harga, dan fasilitas wajib berasal dari data terverifikasi kurator. |
| **KF-10** | Pemilihan Cerdas 'Shake to Decide' | Memanfaatkan sensor Accelerometer untuk mengacak pilihan kuliner terbaik sesuai kriteria pengguna saat ponsel digoyangkan. (*Screen 10: Shake to Decide.png*) | Gerakan goyangan fisik ponsel (nilai akselerasi > ambang batas) atau tombol manual pick | Mendeteksi akselerasi melalui listener sensor; menerapkan filter aktif (budget <Rp30k, kategori); memilih 1 kandidat secara acak; menyusun alasan AI. | Kartu hasil rekomendasi acak cerdas, deskripsi masakan, jarak, alasan pemilihan, dan umpan balik haptik. | Cooldown 2 detik setelah goyangan untuk mencegah trigger ganda; wajib menyediakan tombol manual pick sebagai fallback. |
| **KF-11** | Asisten AI Gastronomi LLM | Menyediakan konsultasi percakapan interaktif seputar kuliner khas DIY-Jateng menggunakan LLM yang dihubungkan ke basis data Supabase (RAG). (*Screen 11: AI Assistant.png*) | Prompt teks pengguna atau klik chip prompt kurasi cepat | Meneruskan prompt ke Supabase Edge Function; mengambil kandidat restoran valid dari database; mensintesis jawaban berbasis fakta. | Balasan percakapan asisten, badge kriteria, kartu rekomendasi restoran nyata dengan tombol 'Lihat Detail Resto'. | AI dilarang mengarang (hallucinate) nama, harga, atau alamat restoran di luar data yang telah divalidasi. |
| **KF-12** | Koleksi Favorit & Riwayat Luring Hive | Menyimpan daftar restoran favorit dan riwayat pencarian langsung ke basis data lokal Hive sehingga dapat diakses tanpa koneksi internet. (*Screen 12: Favorites & Search History.png*) | Klik bookmark favorit, ketukan query pencarian, tombol hapus favorit/riwayat | Menulis/membaca record ke Hive box favorites_local dan search_history_local; menyinkronkan data ke Supabase saat online. | Tampilan daftar favorit offline dengan tombol hapus, riwayat pencarian dengan tombol 'Ulangi' query. | Menampilkan banner indikator mode luring aktif (Hive Offline Ready); perubahan saat luring ditandai untuk sinkronisasi. |
| **KF-13** | Validasi Check-in Geofence GPS | Memvalidasi kehadiran fisik pengguna di lokasi restoran mitra dalam radius < 50 meter menggunakan satelit GNSS dan memberikan reward poin. (*Screen 13: Check-in & History Screen.png*) | Klik tombol 'Konfirmasi Check-in Sah' | Membaca koordinat GPS presisi (akurasi < 5m); menghitung jarak geofence; jika < 50m, mencatat check-in, menambah +50 Foodie Points, dan update lencana. | Status check-in terverifikasi (ID unik misal ID-DIY-7740), reward +50 poin, riwayat kunjungan bertanda green checkmark. | Check-in ditolak jika jarak >= 50m; jika koneksi terputus, check-in disimpan di antrean Hive dan disinkronkan kemudian. |
| **KF-14** | Konverter Mata Uang Wisatawan | Mengonversi nilai mata uang antara IDR, USD, dan MYR secara instan dengan acuan kurs wisatawan serta menyajikan tolok ukur harga kuliner Jogja riil. (*Screen 14: Currency & Timezone.png*) | Nominal pembayaran dalam IDR | Mengalikan nominal input dengan nilai tukar terkini (simulasi/API); memetakan nominal ke tolok ukur (gudeg kendil, soto bathok, kopi joss). | Nilai konversi dalam USD ($) dan MYR (RM), kartu tolok ukur makanan riil Jogja. | Menangani validasi input kosong, angka negatif, serta fallback nilai kurs jika koneksi API luar terputus. |
| **KF-15** | Konverter Zona Waktu Makan | Menyelaraskan waktu makan lokal Jogja (WIB) dengan zona waktu London (BST/GMT+1), WITA (UTC+8), dan WIT (UTC+9) dengan preset jam makan. (*Screen 14: Currency & Timezone.png*) | Pilihan preset waktu makan (sarapan 06:00, siang 12:00, malam 19:00, supper 23:00) | Menghitung konversi selisih waktu berdasarkan IANA timezone; memperhitungkan penyesuaian daylight saving time (BST). | Tampilan simultan jam di 4 zona waktu, selisih jam, kiat operasional warung Jogja, tombol simpan preferensi. | Perubahan tanggal akibat perbedaan waktu wajib ditampilkan dengan keterangan (+1 hari / hari yang sama). |
| **KF-16** | Mini Game 'Tebak Kuliner Jogja' | Menyajikan permainan kuis tantangan harian 5 soal seputar kuliner Mataraman dengan timer 15 detik dan ensiklopedia edukatif. (*Screen 15: Mini Games.png*) | Pilihan jawaban ganda (A/B/C/D) pada teka-teki rasa | Memvalidasi jawaban pengguna; menghentikan timer; menambahkan skor +100 jika benar; mencatat reward poin ke profil. | Umpan balik instan (Benar/Salah), penjelasan sejarah kuliner di Ensiklopedia Mataraman, perolehan +30 Foodie Points. | Setiap soal dibatasi waktu 15 detik; kuis hanya dapat diklaim poinnya satu kali per hari. |
| **KF-17** | Lencana Pencapaian Kurator | Menampilkan status tingkatan kurator (Level 1–5), saldo Foodie Points, serta galeri 20 lencana warisan kuliner yang dapat dibuka. (*Screen 16: Achievements.png*) | Ketukan kartu lencana atau tab tingkatan kurator | Mengevaluasi akumulasi check-in dan ulasan; membuka lencana baru secara otomatis saat kriteria terpenuhi. | Status Level 4 Penjelajah Mataraman, progress bar XP, visual lencana aktif/terkunci, dan poin bonus. | Lencana hanya dapat dibuka jika persyaratan check-in fisik di kategori resto terkait terpenuhi secara sah. |
| **KF-18** | Katalog Penukaran Voucher Kuliner | Menyediakan katalog penukaran Foodie Points menjadi voucher diskon makan nyata di sentra kuliner mitra. (*Screen 16: Achievements.png*) | Klik tombol 'Tukar 500 Poin' pada voucher pilihan | Memverifikasi kecukupan saldo poin kurator; memotong saldo poin di Supabase; menerbitkan kode voucher digital unik. | Kode voucher digital berstempel waktu kedaluwarsa, pembaruan saldo poin kurator. | Penukaran ditolak jika saldo poin tidak mencukupi; voucher memiliki masa berlaku 30 hari. |
| **KF-19** | Pusat Notifikasi Cerdas | Menyajikan notifikasi pengingat makan lokal, radar kedekatan warung mitra (<40m), update kurs valas, dan tantangan kuis harian. (*Screen 17: Notifications.png*) | Klik salah satu item notifikasi atau tombol 'Tandai Semua Dibaca' | Membaca payload notifikasi lokal / push; mengarahkan pengguna ke layar terkait (deeplink). | Daftar notifikasi berstempel waktu, badge unread, pengalihan rute layar aplikasi. | Notifikasi radar geofence hanya muncul jika pengguna berada dalam radius < 40 meter dari warung mitra. |
| **KF-20** | Profil Kurator & Metrik Aktivitas | Menampilkan kartu identitas kurator, 3 metrik aktivitas (142 Simpan, 28 Check-in Sah, 1.850 Poin), dan menu navigasi akun. (*Screen 18: Profile & Settings.png*) | Ketukan pada menu profil atau tombol edit profil | Mengambil agregasi data simpanan Hive, riwayat check-in Supabase, dan data pengguna dari auth provider. | Tampilan visual profil kurator, saldo poin, dan daftar pintasan menu pengaturan. | Data profil disinkronkan secara aman dengan proteksi Row Level Security (RLS) Supabase. |
| **KF-21** | Preferensi Sistem & Jadwal Pengingat | Mengatur preferensi aplikasi meliputi pengingat waktu makan lokal Jogja, toggle biometrik, dan penguncian cakupan wilayah DIY-Jateng. (*Screen 18: Profile & Settings.png*) | Toggle switch biometrik, pemilihan preset jam makan, toggle cakupan wilayah | Menyimpan pengaturan pengguna ke Hive box settings; menjadwalkan ulang notifikasi lokal sistem operasi. | Konfirmasi perubahan tersimpan, feedback toast pemberitahuan status preferensi. | Cakupan wilayah DIY-Jateng terkunci secara default untuk menjaga integritas data Mataraman. |
| **KF-22** | Formulir Saran & Kesan Kuliah | Menyediakan formulir evaluasi, rating bintang, dan input saran konstruktif untuk mata kuliah Pemrograman Aplikasi Mobile. (*Screen 18: Profile & Settings.png*) | Pemberian rating 1–5 bintang dan teks komentar saran/kesan | Memvalidasi input teks; mengirimkan data masukan ke tabel feedback di Supabase via REST PostgREST. | Notifikasi konfirmasi 'Terima kasih atas masukan Anda', tombol kirim non-aktif. | Komentar minimal 10 karakter; formulir hanya dapat dikirimkan oleh pengguna yang telah login. |
| **KF-23** | Verifikasi Integritas Data Hash | Menghitung dan memvalidasi cryptographic hash SHA-256 pada setiap rekaman ulasan dan check-in untuk mencegah manipulasi data. (*Screen 9 & 13: Detail & Check-in*) | Payload ulasan (user_id, resto_id, rating, content, timestamp) | Menghasilkan string hash SHA-256 dari gabungan data; menyimpan hash ke kolom data_hash tabel reviews. | Status ulasan terverifikasi (verified integrity badge) pada tampilan ulasan publik. | Jika hash kalkulasi ulang tidak cocok dengan data_hash, sistem menandai ulasan sebagai unverified. |
| **KF-24** | Penyimpanan Luring Hive & Sinkronisasi | Menyimpan cache data restoran, bookmark favorit, riwayat pencarian, dan antrean check-in secara luring menggunakan NoSQL Hive. (*Screen 12 & Background Service*) | Data objek model Restoran, Favorit, dan Antrean Check-in | Serialisasi data ke binary format Hive; menyimpan di flash storage; mendeteksi pemulihan koneksi internet untuk auto-sync. | Akses instan (< 10ms) tanpa koneksi internet, sinkronisasi otomatis antrean saat kembali daring. | Operasi tulis Hive dilindungi adapter type registration dan error handling atomic. |
| **KF-25** | Penegakan Batas Wilayah DIY-Jateng | Menyaring dan menolak permintaan data kuliner di luar batas koordinat administratif Daerah Istimewa Yogyakarta dan Jawa Tengah. (*Screen 8: Explore.png*) | Koordinat GPS pengguna atau filter wilayah | Memvalidasi koordinat terhadap bounding box (Lat -8.5° s/d -6.3°, Lon 108.5° s/d 111.8°); menolak entri di luar batasan. | Penyajian kuliner murni Mataraman; pesan edukasi 'Di Luar Wilayah Layanan' jika berada di luar batas. | Sistem secara absolut melarang penambahan atau pencarian restoran di luar provinsi DIY dan Jawa Tengah. |

### 1.3.2 Kebutuhan Non Fungsional

| No | Parameter Kebutuhan | Deskripsi & Tolok Ukur Kinerja |
|---|---|---|
| 1 | Kemudahan Pengguna (Usability) | Antarmuka mengadopsi standar desain Culinary Editorial Futurism dengan tipografi kontras tinggi, hierarki visual yang jelas, waktu respon navigasi < 100ms, dan dukungan interaksi gestur ponsel. |
| 2 | Keamanan (Security) | Autentikasi menggunakan Supabase Auth dengan protokol TLS 1.3, token sesi disimpan di Secure Storage, data biometrik diisolasi di hardware Secure Enclave, dan basis data cloud dilindungi PostgreSQL Row Level Security (RLS). |
| 3 | Kinerja (Performance) | Waktu pembacaan cache lokal Hive < 10ms, rendering UI stabil pada 60 fps, kalkulasi Haversine geofence instan, dan query database PostgreSQL dioptimasi dengan indeks geospasial B-Tree. |
| 4 | Keandalan (Reliability) | Aplikasi menerapkan strategi Offline-First; kegagalan jaringan tidak menyebabkan aplikasi crash, fitur favorit dan riwayat tetap berfungsi luring, serta antrean check-in disinkronkan otomatis saat online. |
| 5 | Kompatibilitas (Compatibility) | Dibangun menggunakan framework Flutter yang mendukung multiplatform (Android SDK minimal level 24 / Android 7.0 hingga versi terbaru, serta iOS 13.0 ke atas). |
| 6 | Pemeliharaan (Maintainability) | Struktur kode mengadopsi Clean Architecture dengan pemisahan modular yang tegas antara Presentation (pages & widgets), Domain/Business Logic (services), dan Data (models & storage). |
| 7 | Privasi (Privacy) | Pengambilan koordinat lokasi GPS hanya dilakukan saat aplikasi aktif atau saat fitur check-in dipicu, tanpa pelacakan posisi latar belakang terus-menerus yang menguras privasi dan baterai pengguna. |
| 8 | Konsistensi Data (Data Consistency) | Validasi integritas ulasan dan riwayat transaksi dijaga melalui cryptographic SHA-256 hash dan penegakan batasan geografis DIY & Jawa Tengah secara ketat. |

### 1.3.3 Kebutuhan Perangkat Keras

| No | Komponen Perangkat Keras | Fungsi dalam Arsitektur Aplikasi |
|---|---|---|
| 1 | Smartphone Android / iOS | Perangkat fisik utama pengguna untuk menginstal, menjalankan, dan menguji seluruh kapabilitas aplikasi mobile FOODIE. |
| 2 | Modul Sensor GPS / GNSS | Menangkap koordinat garis lintang (latitude) dan garis bujur (longitude) pengguna dengan presisi tinggi (< 5 meter) untuk validasi radar Geofence check-in sah. |
| 3 | Sensor Accelerometer | Mendeteksi akselerasi gerak goyangan ponsel (sumbu X, Y, Z) dengan ambang batas a > 12 m/s² untuk memicu fitur pemilihan makanan acak cerdas 'Shake to Decide'. |
| 4 | Sensor Gyroscope | Mendeteksi kecepatan sudut dan orientasi rotasi perangkat guna mendukung navigasi kompas dan visualisasi interaktif antarmuka. |
| 5 | Perangkat Keras Biometrik | Sensor sidik jari (Touch ID / Fingerprint scanner) atau kamera inframerah (Face ID) untuk autentikasi biometrik 1-ketukan berbasis Secure Enclave. |
| 6 | Koneksi Jaringan Internet | Jaringan Wi-Fi atau data seluler (4G/5G) untuk komunikasi data dengan Supabase PostgreSQL, Edge Functions LLM, dan sinkronisasi antrean. |

### 1.3.4 Kebutuhan Perangkat Lunak

| No | Perangkat Lunak / Layanan | Fungsi & Peran Teknis |
|---|---|---|
| 1 | Flutter Framework & Dart SDK | Framework pengembangan antarmuka mobile cross-platform dan bahasa pemrograman inti aplikasi. |
| 2 | Supabase PostgreSQL Database | Basis data relasional di cloud sebagai Single Source of Truth (SSOT) untuk menyimpan data kurasi restoran, menu, ulasan, dan poin. |
| 3 | Supabase Auth Service | Layanan manajemen identitas pengguna, pendaftaran, pengiriman email OTP verifikasi 6 digit, dan penerbitan token sesi JWT. |
| 4 | Hive NoSQL Storage | Basis data key-value lokal berbasis memori berkecepatan tinggi pada perangkat untuk cache data restoran, bookmark favorit, dan antrean luring. |
| 5 | Supabase Edge Functions | Layanan komputasi serverless berbasis Deno/TypeScript untuk pipeline Retrieval-Augmented Generation (RAG) pada asisten AI gastronomi. |
| 6 | Large Language Model (LLM) API | Mesin kecerdasan buatan untuk merespons percakapan kurator kuliner secara kontekstual berbasis fakta basis data terverifikasi. |
| 7 | Geolocator & Map Launcher | Plugin komunikasi perangkat keras GPS serta penghubung navigasi rute ke aplikasi Google Maps eksternal. |
| 8 | Sensors Plus Library | Plugin akses stream event sensor Accelerometer dan Gyroscope secara real-time pada sistem operasi Android dan iOS. |
| 9 | Local Notifications & Vibration | Plugin pengelolaan notifikasi lokal berjadwal dan umpan balik getaran haptik (haptic feedback) saat ponsel digoyangkan. |
| 10 | Currency API & Timezone Helper | Layanan penyedia nilai kurs konversi valas (IDR, USD, MYR) serta pustaka kalkulasi zona waktu standar IANA. |

### 1.3.5 Kebutuhan Data

| No | Entitas / Struktur Data | Fungsi & Penyimpanan Data |
|---|---|---|
| 1 | Data Profil Kurator (profiles) | Menyimpan data identitas pengguna, nama lengkap, kontak WhatsApp, saldo Foodie Points, tingkatan kurator, dan status biometrik. |
| 2 | Data Restoran (restaurants) | Menyimpan nama warung/resto, alamat fisik, koordinat latitude & longitude, rentang harga, rating kurator, jam buka, dan fasilitas. |
| 3 | Data Menu Makanan (foods) | Menyimpan daftar hidangan kuliner, porsi, deskripsi gastronomi, harga porsi, foto hidangan, dan flag menu terlaris (best-seller). |
| 4 | Data Favorit & Riwayat Pencarian | Menyimpan daftar tempat makan yang di-bookmark pengguna serta query pencarian teks terakhir untuk fitur 'Ulangi' pencarian instan. |
| 5 | Data Validasi Check-in (checkins) | Menyimpan catatan verifikasi kehadiran fisik kurator, koordinat penangkapan satelit, jarak kalkulasi geofence, dan kode check-in unik. |
| 6 | Data Gamifikasi & Lencana (achievements) | Menyimpan skor kuis Tebak Kuliner Jogja harian, progres pembukaan 20 lencana warisan kuliner, dan riwayat klaim reward voucher. |
| 7 | Data Ulasan & Saran (reviews & feedback) | Menyimpan ulasan pengguna terhadap tempat makan lengkap dengan rating bintang dan cryptographic hash, serta masukan mata kuliah. |
| 8 | Data Penyimpanan Luring Hive (local cache) | Menyimpan snapshot data restoran terkompresi, pengaturan lokal, dan antrean check-in tertunda untuk sinkronisasi otomatis. |

---

## 1.4 Perancangan Sistem

Perancangan sistem dimodelkan secara komprehensif menggunakan diagram UML (Use Case Diagram, Activity Diagram, Sequence Diagram), Perancangan Basis Data Relasional & Luring (ERD), serta Perancangan Arsitektur Antarmuka Pengguna.

### 1.4.1 Use Case Diagram & Spesifikasi Skenario Use Case

Use Case Diagram menggambarkan interaksi antara aktor (Kurator Kuliner / Wisatawan) dengan fungsionalitas sistem yang disediakan oleh aplikasi FOODIE.

![Use Case Diagram](diagrams/use_case_diagram.png)

#### Tabel Skenario UC-01: Autentikasi Pengguna 3-Tahap

- **Aktor Utama:** Pengguna (Kurator / Wisatawan)
- **Kondisi Awal (Precondition):** Pengguna telah mengunduh aplikasi dan membuka halaman login / register.
- **Kondisi Akhir (Postcondition):** Sesi JWT Supabase aktif, token tersimpan di Secure Storage, biometrik terdaftar di Secure Enclave.
- **Alur Utama (Main Flow):**
```text
1. Pengguna membuka aplikasi dan memilih 'Daftar Akun Baru'.
2. Pengguna memasukkan nama lengkap, email, nomor kontak WhatsApp, dan kata sandi.
3. Sistem memvalidasi input dan mengirimkan 6 digit OTP ke email kurator.
4. Pengguna memasukkan 6 digit OTP pada layar verifikasi (Screen 5).
5. Sistem memverifikasi token OTP ke Supabase Auth.
6. Sistem menampilkan penawaran aktivasi biometrik (Screen 6).
7. Pengguna menempelkan sidik jari pada sensor perangkat; Secure Enclave menerbitkan pasangan kunci.
8. Sistem mengarahkan pengguna ke Beranda utama dengan bonus selamat datang +100 Foodie Points.
```
- **Alur Alternatif (Alternative Flow):**
```text
4a. Jika kode OTP kedaluwarsa (> 10 menit), pengguna menekan tombol 'Kirim Ulang OTP' setelah timer 48 detik habis.
7a. Jika sensor biometrik gagal membaca atau pengguna menekan 'Nanti Saja', sistem tetap mengarahkan pengguna ke Beranda dengan opsi autentikasi kata sandi konvensional.
```

#### Tabel Skenario UC-02: Eksplorasi & Filter Kuliner Wilayah DIY-Jateng

- **Aktor Utama:** Pengguna (Kurator / Wisatawan)
- **Kondisi Awal (Precondition):** Pengguna berada di layar Beranda atau Eksplorasi (Screen 7 / Screen 8).
- **Kondisi Akhir (Postcondition):** Daftar restoran terfilter disajikan secara akurat sesuai batas wilayah Mataraman.
- **Alur Utama (Main Flow):**
```text
1. Pengguna membuka tab 'Explore' (Screen 8).
2. Pengguna mengetik kata kunci pencarian (misal: 'gudeg') atau memilih chip kategori.
3. Pengguna mengaktifkan filter 'Budget < Rp25rb' dan 'Buka Sekarang'.
4. Sistem mengeksekusi query dinamis pada cache Hive dan database Supabase PostgreSQL.
5. Sistem menerapkan validasi pembatasan wilayah (bounding box DIY & Jateng).
6. Sistem menyajikan 38 daftar tempat kuliner yang cocok, diurutkan berdasarkan jarak terdekat.
```
- **Alur Alternatif (Alternative Flow):**
```text
5a. Jika pengguna mencari lokasi atau berada di luar batas provinsi DIY-Jateng, sistem menampilkan kartu edukatif out-of-bounds dengan pesan bahwa kurasi FOODIE berfokus eksklusif pada wilayah warisan Mataraman.
```

#### Tabel Skenario UC-03: Pemilihan Kuliner Acak Cerdas 'Shake to Decide'

- **Aktor Utama:** Pengguna (Kurator)
- **Kondisi Awal (Precondition):** Pengguna berada di layar Shake to Decide (Screen 10) dengan izin sensor aktif.
- **Kondisi Akhir (Postcondition):** Satu rekomendasi kuliner terpilih secara acak cerdas disajikan bersama getaran haptik.
- **Alur Utama (Main Flow):**
```text
1. Pengguna membuka tab 'Decide' (Screen 10).
2. Pengguna mengatur kriteria preferensi (misal: budget < Rp30.000 dan kategori Gudeg/Tradisional).
3. Pengguna menggoyangkan smartphone secara fisik.
4. Sensor Accelerometer mendeteksi resultan percepatan a > 12 m/s².
5. Sistem memvalidasi cooldown timer (2 detik) untuk mencegah pemicuan ganda.
6. Sistem mengambil kandidat kuliner dari database yang memenuhi kriteria.
7. Sistem memilih 1 kandidat terbaik secara acak, memicu haptic feedback getaran ponsel, dan menampilkan kartu hasil rekomendasi beserta sintesis alasan AI.
```
- **Alur Alternatif (Alternative Flow):**
```text
3a. Jika perangkat tidak memiliki accelerometer atau diletakkan di atas meja, pengguna menekan tombol 'Pilihkan Untuk Saya (Manual Pick)' sebagai fallback manual.
```

#### Tabel Skenario UC-04: Konsultasi Gastronomi AI Assistant (RAG LLM)

- **Aktor Utama:** Pengguna (Kurator / Wisatawan)
- **Kondisi Awal (Precondition):** Pengguna membuka layar AI Assistant (Screen 11).
- **Kondisi Akhir (Postcondition):** Asisten memberikan rekomendasi percakapan berbasis data riil tanpa halusinasi.
- **Alur Utama (Main Flow):**
```text
1. Pengguna mengetik pertanyaan seputar kuliner (misal: 'Rekomendasi makan malam pedas berkuah budget 30rb dekat Malioboro').
2. Aplikasi mengirimkan prompt beserta titik koordinat pengguna ke Supabase Edge Function `/ai-chat`.
3. Edge Function melakukan retrieval kandidat restoran terverifikasi dari Supabase PostgreSQL.
4. Edge Function menyuntikkan data restoran nyata ke prompt sistem LLM (RAG pipeline).
5. Model LLM menghasilkan jawaban percakapan bernada kuratorial dan mengembalikan ID restoran terkait.
6. Aplikasi me-render balasan chat beserta kartu interaktif restoran nyata yang dapat diklik langsung untuk melihat profil lengkap.
```
- **Alur Alternatif (Alternative Flow):**
```text
2a. Jika koneksi internet tidak stabil, asisten menampilkan saran kuliner berbasis aturan lokal dari database Hive.
```

#### Tabel Skenario UC-05: Validasi Kehadiran Check-in Geofence GPS (<50m)

- **Aktor Utama:** Pengguna (Kurator)
- **Kondisi Awal (Precondition):** Pengguna berada di lokasi warung fisik mitra dan membuka layar Check-in (Screen 13).
- **Kondisi Akhir (Postcondition):** Check-in dinyatakan sah, +50 Foodie Points ditambahkan, dan status kunjungan tercatat.
- **Alur Utama (Main Flow):**
```text
1. Pengguna membuka layar Check-in & History (Screen 13).
2. Sistem mengaktifkan sensor GPS/GNSS dengan akurasi tinggi (LocationAccuracy.high).
3. Sistem menghitung jarak Haversine antara koordinat perangkat dan titik koordinat warung makan.
4. Jarak terdeteksi 18 meter (< ambang batas geofence 50 meter).
5. Radar geofence visual menyala hijau dan tombol 'Konfirmasi Check-in Sah' aktif.
6. Pengguna menekan tombol konfirmasi.
7. Sistem menerbitkan kode referensi unik (misal: ID-DIY-7740), menambahkan +50 Foodie Points, dan memperbarui riwayat kunjungan dengan tanda centang hijau.
```
- **Alur Alternatif (Alternative Flow):**
```text
4a. Jika jarak pengguna terdeteksi >= 50 meter (misal: 120m), sistem menolak check-in, menampilkan peringatan jarak fisik, dan menonaktifkan tombol konfirmasi guna mencegah pemalsuan kehadiran (anti-cheat).
```

### 1.4.2 Activity Diagram

Activity Diagram memodelkan alur kerja dinamis pada modul interaktif unggulan, khususnya interaksi pemilihan kuliner cerdas berbasis sensor Accelerometer (*Shake to Decide*) dan validasi kehadiran fisik Geofence GPS (< 50 meter).

![Activity Diagram](diagrams/activity_diagram.png)

Diagram di atas menunjukkan koordinasi 3 swimlane: Pengguna, Aplikasi Mobile (Sensors & Hive), dan Backend (Supabase & LBS). Ketika pengguna menggoyangkan ponsel, listener akselerasi mendeteksi gaya resultan $a > 12\text{ m/s}^2$. Sistem memverifikasi cooldown 2 detik sebelum memfilter kandidat kuliner dari penyimpanan Hive dan memvalidasi batas wilayah DIY-Jateng.


### 1.4.3 Sequence Diagram

Sequence Diagram memodelkan kronologi pertukaran pesan antar-objek pada fitur konsultasi cerdas *FOODIE AI Assistant* dengan arsitektur Retrieval-Augmented Generation (RAG).

![Sequence Diagram](diagrams/sequence_diagram.png)

Pesan dimulai dari Kurator yang mengirimkan prompt percakapan. Aplikasi mobile meneruskannya ke Supabase Edge Function `/ai-chat` yang bertindak sebagai orkestrator. Edge Function mengeksekusi retrieval query ke PostgreSQL untuk mendapatkan kandidat restoran riil, mensintesis data tersebut ke prompt LLM, dan mengembalikan respons terstruktur berupa narasi kuratorial beserta ID kartu kuliner nyata.


### 1.4.4 Perancangan Basis Data (Database Design & ERD)

Arsitektur basis data menerapkan strategi *hybrid storage* yang menggabungkan basis data relasional daring PostgreSQL melalui Supabase dan basis data dokumen luring NoSQL berbasis memori melalui Hive.

![ERD Diagram](diagrams/erd_diagram.png)

#### A. Struktur Tabel Relasional Supabase PostgreSQL

**Tabel `profiles`** — *Menyimpan data identitas kurator, kontak WhatsApp, saldo poin gamifikasi, level kurator, dan status biometrik.*

| Nama Kolom | Tipe Data | Kunci | Nullable | Deskripsi Fungsi |
|---|---|---|---|---|
| `id` | UUID | PK | No | ID unik pengguna dari auth.users |
| `email` | VARCHAR(255) | - | No | Alamat email terdaftar |
| `full_name` | VARCHAR(150) | - | No | Nama lengkap kurator |
| `phone_number` | VARCHAR(30) | - | Yes | Nomor WhatsApp untuk verifikasi warung |
| `avatar_url` | TEXT | - | Yes | Tautan foto profil kurator |
| `points_balance` | INTEGER | - | No | Saldo Foodie Points aktif (Default: 100) |
| `curator_level` | INTEGER | - | No | Level kurator 1-5 (Default: 1) |
| `biometric_enabled` | BOOLEAN | - | No | Flag status aktivasi biometrik lokal |
| `created_at` | TIMESTAMPTZ | - | No | Waktu registrasi akun |

**Tabel `categories`** — *Menyimpan kategori kuliner khas Mataraman (Gudeg Legendaris, Bakmi Jawa, Mangut & Asap, Angkringan, Soto Bathok).*

| Nama Kolom | Tipe Data | Kunci | Nullable | Deskripsi Fungsi |
|---|---|---|---|---|
| `id` | BIGSERIAL | PK | No | ID unik kategori |
| `name` | VARCHAR(100) | - | No | Nama kategori kuliner |
| `slug` | VARCHAR(100) | - | No | Slug URL kategori (Unique) |
| `icon_name` | VARCHAR(50) | - | Yes | Nama icon Material / Lucide |
| `created_at` | TIMESTAMPTZ | - | No | Waktu pembuatan kategori |

**Tabel `restaurants`** — *Menyimpan data kurasi restoran dan warung kuliner di DIY & Jawa Tengah.*

| Nama Kolom | Tipe Data | Kunci | Nullable | Deskripsi Fungsi |
|---|---|---|---|---|
| `id` | BIGSERIAL | PK | No | ID unik restoran |
| `category_id` | BIGINT | FK | No | Relasi ke tabel categories.id |
| `name` | VARCHAR(200) | - | No | Nama tempat makan / warung |
| `description` | TEXT | - | Yes | Catatan sejarah & gastronomi kurator |
| `address` | TEXT | - | No | Alamat lengkap fisik warung |
| `latitude` | DOUBLE PRECISION | - | No | Garis lintang GPS titik fisik |
| `longitude` | DOUBLE PRECISION | - | No | Garis bujur GPS titik fisik |
| `price_range` | VARCHAR(30) | - | No | Rentang harga (misal: 'Rp15k - Rp35k') |
| `rating` | NUMERIC(2,1) | - | No | Rating rata-rata kurasi (misal: 4.9) |
| `review_count` | INTEGER | - | No | Jumlah ulasan terverifikasi |
| `is_open_now` | BOOLEAN | - | No | Status jam buka operasional |
| `photo_urls` | TEXT[] | - | Yes | Array tautan galeri foto (hingga 18 foto) |
| `facilities` | TEXT[] | - | Yes | Fasilitas (Mushola, Parkir, QRIS, AC) |
| `created_at` | TIMESTAMPTZ | - | No | Waktu pencatatan data |

**Tabel `foods`** — *Menyimpan menu makanan terlaris dan hidangan unggulan warung.*

| Nama Kolom | Tipe Data | Kunci | Nullable | Deskripsi Fungsi |
|---|---|---|---|---|
| `id` | BIGSERIAL | PK | No | ID unik menu |
| `restaurant_id` | BIGINT | FK | No | Relasi ke tabel restaurants.id |
| `name` | VARCHAR(200) | - | No | Nama hidangan / menu |
| `description` | TEXT | - | Yes | Deskripsi bumbu dan cara pengolahan |
| `price` | DECIMAL(12,2) | - | No | Harga per porsi dalam IDR |
| `is_best_seller` | BOOLEAN | - | No | Flag menu rekomendasi utama |
| `photo_url` | TEXT | - | Yes | Foto hidangan menu |
| `created_at` | TIMESTAMPTZ | - | No | Waktu penambahan menu |

**Tabel `checkins`** — *Menyimpan riwayat validasi kehadiran fisik radar geofence GPS (<50m).*

| Nama Kolom | Tipe Data | Kunci | Nullable | Deskripsi Fungsi |
|---|---|---|---|---|
| `id` | BIGSERIAL | PK | No | ID unik rekaman check-in |
| `user_id` | UUID | FK | No | Relasi ke tabel profiles.id |
| `restaurant_id` | BIGINT | FK | No | Relasi ke tabel restaurants.id |
| `latitude` | DOUBLE PRECISION | - | No | Latitude perangkat saat check-in |
| `longitude` | DOUBLE PRECISION | - | No | Longitude perangkat saat check-in |
| `distance_meters` | DOUBLE PRECISION | - | No | Jarak kalkulasi Haversine ke titik warung |
| `is_valid_geofence` | BOOLEAN | - | No | Status validitas (< 50 meter = TRUE) |
| `points_awarded` | INTEGER | - | No | Poin yang diberikan (+50 Foodie Points) |
| `checkin_code` | VARCHAR(50) | - | No | Kode referensi sah unik (misal: ID-DIY-7740) |
| `created_at` | TIMESTAMPTZ | - | No | Waktu stempel transaksi satelit |

**Tabel `favorites`** — *Menyimpan restoran yang ditandai sebagai favorit oleh kurator.*

| Nama Kolom | Tipe Data | Kunci | Nullable | Deskripsi Fungsi |
|---|---|---|---|---|
| `id` | BIGSERIAL | PK | No | ID unik entri favorit |
| `user_id` | UUID | FK | No | Relasi ke tabel profiles.id |
| `restaurant_id` | BIGINT | FK | No | Relasi ke tabel restaurants.id |
| `created_at` | TIMESTAMPTZ | - | No | Waktu bookmark ditambahkan |

**Tabel `game_scores`** — *Menyimpan skor permainan kuis harian Tebak Kuliner Jogja.*

| Nama Kolom | Tipe Data | Kunci | Nullable | Deskripsi Fungsi |
|---|---|---|---|---|
| `id` | BIGSERIAL | PK | No | ID unik sesi permainan |
| `user_id` | UUID | FK | No | Relasi ke tabel profiles.id |
| `question_id` | VARCHAR(50) | - | No | Kode soal teka-teki rasa |
| `score_earned` | INTEGER | - | No | Skor yang diraih (+100) |
| `points_claimed` | INTEGER | - | No | Foodie Points yang diklaim (+30) |
| `played_at` | TIMESTAMPTZ | - | No | Waktu bermain kuis |

**Tabel `achievements`** — *Menyimpan 20 lencana warisan kuliner yang berhasil dibuka oleh kurator.*

| Nama Kolom | Tipe Data | Kunci | Nullable | Deskripsi Fungsi |
|---|---|---|---|---|
| `id` | BIGSERIAL | PK | No | ID unik pencapaian kurator |
| `user_id` | UUID | FK | No | Relasi ke tabel profiles.id |
| `badge_code` | VARCHAR(100) | - | No | Kode lencana (misal: 'penjelajah_gudeg') |
| `badge_tier` | VARCHAR(30) | - | No | Tingkatan lencana (Emas, Perak, Perunggu) |
| `points_awarded` | INTEGER | - | No | Bonus poin pembukaan lencana |
| `unlocked_at` | TIMESTAMPTZ | - | No | Waktu pembukaan lencana |

**Tabel `reviews`** — *Menyimpan ulasan dan rating tempat makan dengan cryptographic integrity hash.*

| Nama Kolom | Tipe Data | Kunci | Nullable | Deskripsi Fungsi |
|---|---|---|---|---|
| `id` | BIGSERIAL | PK | No | ID unik ulasan |
| `user_id` | UUID | FK | No | Relasi ke tabel profiles.id |
| `restaurant_id` | BIGINT | FK | No | Relasi ke tabel restaurants.id |
| `rating` | INTEGER | - | No | Nilai bintang ulasan (1 s/d 5) |
| `content` | TEXT | - | No | Isi teks catatan ulasan kurator |
| `is_verified_visit` | BOOLEAN | - | No | True jika didahului check-in GPS sah |
| `data_hash` | VARCHAR(64) | - | No | SHA-256 integrity signature |
| `created_at` | TIMESTAMPTZ | - | No | Waktu penulisan ulasan |

**Tabel `feedback`** — *Menyimpan evaluasi, rating, saran, dan kesan mata kuliah Pemrograman Aplikasi Mobile.*

| Nama Kolom | Tipe Data | Kunci | Nullable | Deskripsi Fungsi |
|---|---|---|---|---|
| `id` | BIGSERIAL | PK | No | ID unik formulir saran |
| `user_id` | UUID | FK | Yes | Relasi opsional ke profiles.id |
| `rating` | INTEGER | - | No | Rating evaluasi mata kuliah (1 s/d 5) |
| `comments` | TEXT | - | No | Teks saran dan kesan kurator |
| `created_at` | TIMESTAMPTZ | - | No | Waktu pengiriman formulir |

#### B. Struktur Box Penyimpanan Luring Hive NoSQL

| Nama Box Hive | Peran & Struktur Data yang Disimpan |
|---|---|
| `settings` | Menyimpan preferensi konfigurasi aplikasi, status onboarding (is_onboarded), status biometrik (biometric_enabled), preferensi zona waktu wisatawan, dan jadwal notifikasi santap malam. |
| `cache` | Menyimpan snapshot data model Restaurant dan Food terkompresi dengan metadata batas wilayah DIY-Jateng untuk rendering instan (< 10ms) tanpa internet. |
| `favorites_local` | Menyimpan daftar ID restoran favorit beserta data ringkas untuk akses cepat luring tanpa bergantung pada koneksi internet. |
| `search_history_local` | Menyimpan riwayat 20 pencarian terakhir kurator beserta stempel waktu dan jumlah hasil untuk mendukung fitur 'Ulangi' query pencarian instan. |
| `offline_checkin_queue` | Menyimpan antrean transaksi check-in GPS yang divalidasi sensor perangkat saat ponsel tidak terhubung ke jaringan internet, untuk disinkronkan otomatis saat daring. |
| `draft_feedback` | Menyimpan draf formulir saran, ulasan, atau rating yang belum sempat terkirim ke server Supabase. |


### 1.4.5 Perancangan Arsitektur Antarmuka Pengguna (UI Architecture)

Struktur navigasi dan hierarki antarmuka aplikasi FOODIE dirancang secara komprehensif mengacu pada seluruh 18 layar purwarupa Figma pada berkas `mobagus.zip`:

```text
[Aplikasi Dimulai]
       |
       v
[Level 1: Splash Screen]
Screen 1: Intro.png (Inisialisasi Hive 100%, GNSS Nol KM, 3 Dapur Pusaka)
       |
       v
[Level 2: Onboarding & Autentikasi 3-Tahap]
Screen 2: Onboarding.png (Edukasi Radar GPS <50m, Kurasi Keraton, Perk +100 Poin)
       |
       +---> [Alur Masuk Akun] ---> Screen 3: Login.png (Email/Pass, Biometrik 1-Ketukan, SSO)
       |
       +---> [Alur Registrasi Baru]
                |
                v
             Screen 4: Register.png (Nama, Email, WhatsApp Validasi Warung, Password Meter)
                |
                v
             Screen 5: Verif Email.png (Langkah 2: OTP 6 Digit, Timer 48s, Buka Client Mail)
                |
                v
             Screen 6: Verif biometrik.png (Langkah 3: Aktivasi Sensor Sidik Jari / Touch ID)
                |
                v
[Level 3: Antarmuka Utama — Bottom Navigation Bar (4 Tab)]
       |
       +---> [Tab 1: Home]
       |        Screen 7: Home Screen.png
       |        - Sapaan 'Sugeng Rawuh, Dimas'
       |        - Filter Kategori & Search Bar
       |        - Featured Editor's Pick (Rating 4.9, 1.4 km)
       |        - Banner Interaktif 'Shake to Decide'
       |        - Kuliner Dekat Lokasimu (< 2 km)
       |        - Hemat & Nikmat (< Rp25rb)
       |        - Narasi Budaya 'Warisan Kuliner Mataram'
       |
       +---> [Tab 2: Explore]
       |        Screen 8: Explore.png
       |        - Scope Badge DIY & Jawa Tengah
       |        - Filter Aktif (Budget <Rp25rb [X], Buka Sekarang [X], Reset)
       |        - Dropdown Pengurutan (Terdekat, Rating)
       |        - Daftar Kartu Restoran (38 Ditemukan)
       |        - Kartu Edukasi Out-of-Bounds Wilayah
       |
       +---> [Tab 3: Decide]
       |        Screen 10: Shake to Decide.png
       |        - Indikator Status Sensor Accelerometer
       |        - Filter Kriteria (<Rp30k, Gudeg & Tradisional)
       |        - Tombol Goyang Simulasi & Tombol Manual Pick
       |        - Kartu Hasil Acak Cerdas & Alasan Pemilihan AI
       |
       +---> [Tab 4: Profile]
                Screen 18: Profile & Settings.png
                - Kartu Identitas Kurator & Saldo 1.850 Poin
                - 3 Metrik (142 Simpan, 28 Check-in Sah, Poin)
                - Menu Aktivitas Kuliner (Favorit, Riwayat, Poin)
                - Menu Utilitas Wisatawan (Kurs Valas & Zona Waktu)
                - Menu Preferensi Sistem (Pengingat Makan, Biometrik, Scope DIY-Jateng)
                - Formulir Saran & Kesan Kurator
                - Dialog Konfirmasi Keluar Akun (Logout)
       |
       v
[Level 4: Layar Fungsional Pendukung (Secondary Dedicated Pages)]
       |
       +---> Screen 9: Detail.png (Galeri 18 Foto, Catatan Keraton, 3 Menu Terlaris, Fasilitas, Rute Maps, Check-in CTA)
       |
       +---> Screen 11: AI Assistant.png (LLM Gastronomi DIY-Jateng, Chat RAG Supabase, Kartu Resto Terverifikasi)
       |
       +---> Screen 12: Favorites & Search History.png (Mode Luring Hive 142 Entri, Tab Favorit & Riwayat, Tombol Ulangi)
       |
       +---> Screen 13: Check-in & History Screen.png (Radar Geofence GPS <50m, Akurasi ±4m, Riwayat Sah Green Checkmark, Hive Offline Sync)
       |
       +---> Screen 14: Currency & Timezone.png (Konverter IDR/USD/MYR dengan Tolok Ukur Makanan Jogja, Sinkronisasi 4 Zona Waktu Makan)
       |
       +---> Screen 15: Mini Games.png (Tebak Kuliner Jogja, Timer 15s, Pilihan Ganda, Skor +100, Ensiklopedia Mataraman)
       |
       +---> Screen 16: Achievements.png (Level Kurator 1-5, Galeri 20 Lencana Warisan, Katalog Penukaran Voucher Kuliner)
       |
       +---> Screen 17: Notifications.png (Pengingat Santap Malam, Radar Geofence Dekat Warung 40m, Update Valas, Kuis Harian)
```

---

# BAB II IMPLEMENTASI

## 2.1 Deskripsi Umum Aplikasi

FOODIE (PRO • MATARAMAN EDITION) diimplementasikan sebagai aplikasi mobile berbasis Flutter dan Dart dengan mengadopsi arsitektur Clean Code yang memisahkan tanggung jawab kode secara terstruktur (separation of concerns). Aplikasi dirancang secara offline-first dengan mengandalkan basis data lokal Hive sebagai lapisan akses data cepat, serta Supabase PostgreSQL sebagai basis data utama terpusat. Fitur cerdas seperti asisten percakapan LLM Gastronomi dihubungkan melalui arsitektur RAG pada Supabase Edge Functions guna menjamin bahwa seluruh rekomendasi kuliner strictly berasal dari data riil yang terverifikasi di wilayah DIY dan Jawa Tengah tanpa manipulasi data.

## 2.2 Struktur Modular Aplikasi

Struktur direktori kode sumber pada berkas proyek `lib/` disusun sebagai berikut:

```text
lib/
├── main.dart                   # Inisialisasi Hive, Supabase, dan orientasi sensor
├── app.dart                    # Pengaturan tema Culinary Editorial Futurism dan rute navigasi
├── core/
│   ├── constants/              # Konstanta warna (Saffron, Charcoal), batasan wilayah DIY-Jateng
│   ├── theme/                  # Konfigurasi ThemeData, font DM Serif Display dan Inter
│   └── utils/                  # Kalkulator jarak Haversine, IANA timezone helper, hash generator
├── models/
│   ├── restaurant.dart         # Model entitas restoran (ID, nama, koordinat, foto, fasilitas)
│   ├── food.dart               # Model entitas makanan terlaris (nama, deskripsi, harga)
│   ├── checkin.dart            # Model rekaman check-in dan antrean luring
│   ├── achievement.dart        # Model lencana dan progres leveling
│   └── user_profile.dart       # Model profil kurator dan saldo Foodie Points
├── services/
│   ├── auth_service.dart       # Integrasi Supabase Auth & Local Authentication Biometrik
│   ├── restaurant_service.dart # Query restoran, filter multi-kriteria, dan pengurutan
│   ├── hive_service.dart       # Manajemen box luring (cache, favorit, riwayat, antrean check-in)
│   ├── location_service.dart   # Manajemen koordinat GPS/GNSS dan kalkulasi Geofence < 50m
│   ├── sensor_service.dart     # Listener Accelerometer (Shake to Decide) dan Gyroscope
│   ├── ai_service.dart         # Penghubung Supabase Edge Function untuk obrolan LLM RAG
│   └── notification_service.dart # Penjadwalan pengingat makan dan radar geofence lokal
├── pages/
│   ├── intro_page.dart         # Implementasi Screen 1: Intro.png
│   ├── onboarding_page.dart    # Implementasi Screen 2: Onboarding.png
│   ├── auth/
│   │   ├── login_page.dart     # Implementasi Screen 3: Login.png
│   │   ├── register_page.dart  # Implementasi Screen 4: Register.png
│   │   ├── email_otp_page.dart # Implementasi Screen 5: Verif Email.png
│   │   └── biometric_setup_page.dart # Implementasi Screen 6: Verif biometrik.png
│   ├── home/
│   │   └── home_page.dart      # Implementasi Screen 7: Home Screen.png
│   ├── explore/
│   │   └── explore_page.dart   # Implementasi Screen 8: Explore.png
│   ├── detail/
│   │   └── restaurant_detail_page.dart # Implementasi Screen 9: Detail.png
│   ├── decide/
│   │   └── shake_decide_page.dart # Implementasi Screen 10: Shake to Decide.png
│   ├── ai/
│   │   └── ai_assistant_page.dart # Implementasi Screen 11: AI Assistant.png
│   ├── collections/
│   │   └── favorites_history_page.dart # Implementasi Screen 12: Favorites & Search History.png
│   ├── checkin/
│   │   └── checkin_page.dart   # Implementasi Screen 13: Check-in & History Screen.png
│   ├── utilities/
│   │   └── currency_timezone_page.dart # Implementasi Screen 14: Currency & Timezone.png
│   ├── game/
│   │   └── mini_game_page.dart # Implementasi Screen 15: Mini Games.png
│   ├── achievements/
│   │   └── achievements_page.dart # Implementasi Screen 16: Achievements.png
│   ├── notifications/
│   │   └── notifications_page.dart # Implementasi Screen 17: Notifications.png
│   └── profile/
│       └── profile_settings_page.dart # Implementasi Screen 18: Profile & Settings.png
└── widgets/
    ├── restaurant_card.dart    # Kartu kuliner editorial dengan rating dan jarak
    ├── food_card.dart          # Kartu menu unggulan beserta harga porsi
    ├── geofence_radar_widget.dart # Visualisasi radius geofence 50m
    └── shake_animation_box.dart # Animasi getar interaktif sensor gerak
```

## 2.3 Penjelasan Source Code Inti

1. **Inisialisasi Sistem (`main.dart`):** Menginisialisasi `WidgetsFlutterBinding`, mendaftarkan adapter Hive, membuka box luring penting (`settings`, `cache`, `favorites_local`, `search_history_local`, `offline_checkin_queue`), dan menginisialisasi client Supabase dengan kredensial anon key aman.
2. **Autentikasi & Biometrik (`auth_service.dart`):** Mengelola alur registrasi kurator, validasi OTP 6-digit via `supabase.auth.verifyOTP()`, serta aktivasi sidik jari menggunakan plugin `local_auth`. Token sesi disimpan di `flutter_secure_storage`.
3. **Layanan Geofence & LBS (`location_service.dart`):** Menggunakan plugin `geolocator` dengan akurasi `LocationAccuracy.high`. Jarak dihitung menggunakan formula Haversine geospasial presisi. Jika jarak $< 50$ meter, sistem mengesahkan check-in dan menerbitkan ID transaksi unik.
4. **Layanan Sensor Accelerometer (`sensor_service.dart`):** Menggunakan `accelerometerEventStream()` dari `sensors_plus`. Menghitung resultan akselerasi $a = \sqrt{x^2 + y^2 + z^2}$. Jika nilai $a > 12.0\text{ m/s}^2$ dan cooldown 2 detik terpenuhi, sistem memicu getaran haptik dan mengeksekusi random picker kuliner terfilter.
5. **Layanan AI Gastronomi RAG (`ai_service.dart`):** Mengirimkan prompt kurator beserta koordinat dan budget ke Edge Function `/ai-chat`, yang kemudian melakukan retrieval kandidat dari Supabase PostgreSQL sebelum diteruskan ke model LLM.
6. **Layanan Penyimpanan Luring (`hive_service.dart`):** Menangani cache key-value berkecepatan tinggi, antrean check-in luring, serta sinkronisasi data dua arah saat jaringan internet kembali tersedia.

## 2.4 Penggunaan API & Integrasi Backend

Integrasi backend berjalan melalui antarmuka REST PostgREST Supabase. Akses tabel dibatasi menggunakan Row Level Security (RLS) PostgreSQL, sehingga pengguna hanya dapat memodifikasi data profil, ulasan, dan check-in milik akunnya sendiri. Data restoran dan menu bersifat read-only untuk publik.

## 2.5 Integrasi Sistem

Sistem mengintegrasikan empat pilar teknologi utama:
1. **Sensors Layer:** GPS/GNSS (akurasi geofence), Accelerometer (deteksi shake), Gyroscope (orientasi rotasi), dan Biometrics (Touch ID / Face ID).
2. **Cloud Layer:** Supabase Auth, PostgreSQL Relational Database, Storage, dan Edge Functions.
3. **Local Storage Layer:** Hive NoSQL key-value database untuk akses instan luring dan penanganan toleransi kegagalan koneksi.
4. **AI & Intelligence Layer:** Model LLM dengan integrasi RAG yang terhubung langsung ke basis data kuliner terverifikasi.

## 2.6 Tampilan Antarmuka 18 Layar Figma

Implementasi antarmuka mengikuti secara presisi seluruh 18 layar purwarupa pada berkas `mobagus.zip`:

### Screen 1: Splash & Intro
*Layar pembuka aplikasi yang menampilkan logo resmi FOODIE, koordinat GNSS Nol KM Yogyakarta (7.7956° S, 110.3695° E), sorotan 3 Dapur Pusaka Mataraman, status kesiapan inisialisasi penyimpanan luring Hive 100%, serta tombol call-to-action 'Mulai Petualangan Kuliner'.*

![Intro.png](screens/Intro.png)

### Screen 2: Onboarding
*Layar edukasi pengguna baru yang memaparkan proposisi nilai kurasi Keraton, validasi check-in radar fisik (< 50 meter), arsitektur basis data luring, utilitas wisatawan terpadu, penawaran insentif +100 Foodie Points selamat datang, dan tombol pintasan 'Daftar Akun Baru' serta 'Masuk Akun'.*

![Onboarding.png](screens/Onboarding.png)

### Screen 3: Autentikasi Pengguna & Login
*Antarmuka akses masuk yang menyediakan input kredensial email dan kata sandi terlindung enkripsi TLS 1.3, opsi 'Ingat Saya', tombol pintasan biometrik 1-ketukan (Touch ID / Face ID), tautan lupa kata sandi, dan opsi masuk cepat Single Sign-On (SSO).*

![Login.png](screens/Login.png)

### Screen 4: Registrasi Kurator Baru
*Layar registrasi kurator baru yang mewajibkan pengisian nama lengkap, alamat email aktif, nomor WhatsApp untuk validasi reservasi warung lokal, kata sandi dilengkapi indikator kekuatan sandi (password meter), konfirmasi kata sandi, dan persetujuan syarat ketentuan kurasi Mataraman.*

![Register.png](screens/Register.png)

### Screen 5: Verifikasi Email OTP
*Layar verifikasi keamanan langkah kedua berupa input 6-digit kode OTP yang dikirimkan ke email kurator, dilengkapi visual instruksi periksa folder spam, countdown timer kirim ulang selama 48 detik, serta tombol pintasan langsung membuka aplikasi email bawaan smartphone.*

![Verif Email.png](screens/Verif Email.png)

### Screen 6: Aktivasi Keamanan Biometrik
*Layar aktivasi keamanan langkah ketiga yang memandu kurator menempelkan sidik jari pada sensor perangkat atau menggunakan Face ID, dengan isolasi kunci publik pada hardware Secure Enclave perangkat untuk otorisasi login dan check-in instan, serta opsi fallback PIN 6-digit.*

![Verif biometrik.png](screens/Verif biometrik.png)

### Screen 7: Home Dashboard & Kurasi Rasa
*Pusat penjelajahan rasa yang menyajikan sapaan personal 'Sugeng Rawuh, Dimas', pemilih lokasi DIY & Jateng, bilah pencarian cerdas, filter chip kategori kuliner, kartu editorial unggulan (Pilihan Editor: Gudeg Kotagede rating 4.9), banner promosi Shake to Decide, dan daftar resto terdekat (<2km).*

![Home Screen.png](screens/Home Screen.png)

### Screen 8: Eksplorasi & Filter Kuliner
*Halaman katalog pencarian dinamis yang dilengkapi badge cakupan eksklusif DIY & Jawa Tengah, filter chip multi-kriteria aktif ('Budget < Rp25rb' [X], 'Buka Sekarang' [X], 'Reset Filter'), dropdown opsi pengurutan (Terdekat, Rating Tertinggi), serta daftar kartu 38 tempat kuliner terkurasi.*

![Explore.png](screens/Explore.png)

### Screen 9: Detail Restoran & Informasi Menu
*Halaman profil komprehensif restoran yang menyajikan galeri 18 foto tempat dan hidangan, catatan sejarah gastronomi keraton, 3 menu paket terlaris beserta harga porsi, fasilitas warung (mushola, parkir mobil, QRIS), titik peta interaktif, ulasan ber-hash, dan tombol rute Google Maps.*

![Detail.png](screens/Detail.png)

### Screen 10: Pemilihan Cerdas 'Shake to Decide'
*Fitur interaktif sensor gerak Accelerometer yang mendeteksi goyangan fisik ponsel (a > 12 m/s²) untuk mengacak pilihan kuliner terbaik sesuai kriteria budget dan rasa pengguna, dilengkapi indikator kesiapan sensor gerak, tombol fallback manual pick, dan kartu hasil pilihan AI.*

![Shake to Decide.png](screens/Shake to Decide.png)

### Screen 11: Asisten AI Gastronomi Mataraman
*Antarmuka obrolan cerdas LLM berbasis Retrieval-Augmented Generation (RAG) yang terhubung langsung ke basis data Supabase PostgreSQL untuk memberikan rekomendasi kuliner faktual, kartu restoran nyata yang dapat diklik, serta penegasan batas wilayah kuliner DIY dan Jawa Tengah.*

![AI Assistant.png](screens/AI Assistant.png)

### Screen 12: Koleksi Favorit & Riwayat Luring Hive
*Layar manajemen data lokal yang menampilkan tab bookmark restoran favorit (142 tempat tersimpan) dengan badge 'Tersedia Offline' berbasis Hive NoSQL, serta tab riwayat 20 pencarian terakhir kurator yang dilengkapi tombol pintasan 'Ulangi' pencarian instan.*

![Favorites & Search History.png](screens/Favorites & Search History.png)

### Screen 13: Radar Geofence Check-in & Riwayat
*Antarmuka verifikasi kehadiran fisik dengan radar lingkaran Geofence GPS (< 50 meter) yang menampilkan koordinat satelit presisi (±4m), verifikasi sah jarak 18 meter, tombol 'Konfirmasi Check-in Sah', penambahan +50 Foodie Points, dan linimasa kunjungan berstempel waktu.*

![Check-in & History Screen.png](screens/Check-in & History Screen.png)

### Screen 14: Konverter Mata Uang & Zona Waktu Wisatawan
*Utilitas wisatawan terpadu yang menyajikan konverter kurs valas (IDR, USD, MYR) dengan tolok ukur makanan riil Jogja (gudeg kendil, soto bathok, kopi joss), serta sinkronisasi simultan 4 zona waktu makan (WIB, London BST, WITA, WIT) dengan jadwal jam makan lokal.*

![Currency & Timezone.png](screens/Currency & Timezone.png)

### Screen 15: Mini Game 'Tebak Kuliner Jogja'
*Permainan edukasi gastronomi harian dengan batas waktu hitung mundur 15 detik, soal teka-teki rasa tradisional, pilihan ganda A/B/C/D, perolehan skor +100 poin, reward +30 Foodie Points, serta wawasan budaya Mataraman pada Ensiklopedia Gastronomi.*

![Mini Games.png](screens/Mini Games.png)

### Screen 16: Level Kurator, Lencana, & Voucher
*Pusat gamifikasi yang memuat tingkatan status kurator (Level 4 Penjelajah Mataraman), saldo 1.850 Foodie Points, galeri 20 lencana warisan budaya kuliner, serta katalog penukaran poin menjadi voucher potongan makan nyata di sentra kuliner mitra Wijilan.*

![Achievements.png](screens/Achievements.png)

### Screen 17: Pusat Notifikasi Cerdas
*Pusat pemberitahuan sistem yang menyajikan peringatan jadwal santap malam lokal Jogja, deteksi radar geofence warung terdekat dalam radius 40 meter, info pembaruan kurs valas wisatawan harian, serta pengingat tantangan kuis tebak kuliner harian.*

![Notifications.png](screens/Notifications.png)

### Screen 18: Profil Kurator & Pengaturan Sistem
*Dashboard akun kurator yang menyajikan kartu identitas pengguna, 3 metrik aktivitas (142 Simpan, 28 Check-in Sah, 1.850 Poin), pintasan utilitas wisatawan, toggle switch preferensi sistem, formulir evaluasi & saran mata kuliah, serta dialog konfirmasi keluar akun (logout).*

![Profile & Settings.png](screens/Profile & Settings.png)

---

# BAB III TESTING

## 3.1 Metode Testing

Pengujian sistem dilakukan menggunakan metode **Manual Testing** dengan pendekatan **Black Box Testing** yang berfokus pada **Functional Testing** dan **Usability Testing** di tingkat **System Testing**. Pendekatan ini dipilih karena:
1. *Kompleksitas Integrasi:* Aplikasi mengintegrasikan banyak komponen heterogen (Flutter UI, Hive NoSQL, Supabase Auth/DB, Geofence GPS, Sensor Accelerometer, LLM API) yang harus diuji secara end-to-end.
2. *Real Device Testing:* Fitur fisik seperti deteksi goyangan ponsel, radar geofence satelit, dan autentikasi biometrik wajib diuji langsung pada perangkat fisik nyata.
3. *User-Centric Approach:* Black box testing memastikan bahwa seluruh perilaku sistem sesuai dengan ekspektasi pengguna akhir sebagaimana dirancang pada purwarupa Figma.

## 3.2 Rencana dan Prosedur Testing

Rencana pengujian mencakup 12 skenario pengujian utama:
1. *Pengujian Autentikasi 3-Tahap:* Menguji validitas registrasi, pengiriman OTP, verifikasi 6 digit, dan aktivasi biometrik.
2. *Pengujian Login & Sesi:* Menguji masuk akun via password, login 1-ketukan via sidik jari, dan mekanisme logout.
3. *Pengujian Batas Geografis (Scope Engine):* Menguji perilaku sistem saat GPS berada di dalam DIY-Jateng, di luar wilayah, serta saat izin lokasi ditolak.
4. *Pengujian Pencarian & Filter:* Menguji query pencarian teks, kombinasi filter budget (<Rp25rb) dan jam buka, serta reset filter.
5. *Pengujian Sensor Accelerometer (Shake to Decide):* Menguji deteksi goyangan ponsel, cooldown 2 detik, filter kriteria, dan fungsi fallback manual pick.
6. *Pengujian Sensor Gyroscope:* Menguji orientasi rotasi antarmuka kompas.
7. *Pengujian Geofence Check-in GPS (<50m):* Menguji validasi jarak fisik < 50m (sah) vs >= 50m (ditolak), perolehan +50 poin, dan anti-cheat.
8. *Pengujian Mode Luring Hive:* Menguji akses favorit dan riwayat saat koneksi internet dimatikan (mode pesawat), serta sinkronisasi antrean check-in saat online kembali.
9. *Pengujian Asisten AI Gastronomi (RAG):* Menguji pemahaman konteks multi-kriteria selera rasa, ketiadaan halusinasi data, dan penyajian kartu kuliner riil.
10. *Pengujian Konverter Kurs & Waktu:* Menguji akurasi konversi IDR/USD/MYR terhadap tolok ukur makanan Jogja, serta konversi waktu makan WIB vs London BST, WITA, dan WIT.
11. *Pengujian Mini Game Kuis Harian:* Menguji jalannya timer 15 detik, keakuratan skor (+100 poin), penyajian ensiklopedia, dan klaim reward Foodie Points.
12. *Pengujian Notifikasi & Formulir Saran:* Menguji penjadwalan pengingat santap malam lokal dan pengiriman formulir saran & kesan mata kuliah.

## 3.3 Lembar Evaluasi Pengujian UAT (User Acceptance Testing)

| No | Modul / Fitur yang Diuji | Skenario Pengujian | Hasil yang Diharapkan | Hasil Pengujian | Status |
|---|---|---|---|---|---|
| 1 | Splash & Intro (Screen 1) | Membuka aplikasi dari kondisi tertutup (cold start) | Tampil logo FOODIE, koordinat Nol KM Jogja, sorotan 3 dapur, indikator Hive 100% siap, tombol mulai aktif. | Tampil sempurna, inisialisasi Hive berhasil < 1 detik. | **PASSED** |
| 2 | Onboarding (Screen 2) | Menggeser kartu edukasi dan klik 'Daftar Akun Baru' | Tampil ringkasan kurasi Keraton, validasi radar GPS <50m, insentif +100 poin, navigasi ke register. | Teks dan tombol navigasi berfungsi sesuai rancangan Figma. | **PASSED** |
| 3 | Registrasi 3-Tahap (Screen 4, 5, 6) | Input formulir registrasi, masukkan OTP 6-digit email, dan tempelkan sidik jari | Akun terdaftar di Supabase Auth, OTP terverifikasi, kunci biometrik tersimpan di Secure Enclave, saldo awal 100 poin. | Seluruh tahapan 1-2-3 tuntas, akun langsung aktif. | **PASSED** |
| 4 | Login Biometrik 1-Ketukan (Screen 3) | Menekan tombol 'Masuk dengan Sidik Jari' pada layar login | Muncul prompt biometrik sistem; saat jari ditempelkan, sesi terbuka seketika tanpa input password. | Berhasil login dalam waktu < 1 detik langsung ke Beranda. | **PASSED** |
| 5 | Beranda & Kurasi (Screen 7) | Menelusuri dashboard beranda dan memilih chip kategori | Tampil sapaan 'Sugeng Rawuh', kartu Pilihan Editor rating 4.9, daftar terdekat < 2km, dan artikel Mataram. | Seluruh konten editorial tampil presisi dan rapi. | **PASSED** |
| 6 | Explore & Filter DIY-Jateng (Screen 8) | Mengaktifkan filter 'Budget < Rp25rb' dan 'Buka Sekarang' | Hasil pencarian terfilter menyisakan 38 tempat kuliner, kartu out-of-bounds tampil jika mencari luar area. | Filter berfungsi akurat; batasan DIY-Jateng ditegakkan. | **PASSED** |
| 7 | Detail Restoran (Screen 9) | Membuka detail profil 'Gudeg Yu Djum Wijilan 167' | Tampil galeri 18 foto, catatan keraton, 3 paket menu unggulan terlaris, fasilitas mushola/parkir/QRIS, dan rute maps. | Informasi detail tampil lengkap sesuai data kurasi. | **PASSED** |
| 8 | Shake to Decide (Screen 10) | Memilih filter '< Rp30.000' lalu menggoyangkan smartphone secara fisik | Sensor Accelerometer mendeteksi goyangan, memberi getaran haptik, dan memilih Mangut Lele Mbah Marto. | Pemilihan acak cerdas berhasil; kartu hasil tampil rapi. | **PASSED** |
| 9 | Fallback Manual Shake (Screen 10) | Menekan tombol 'Pilihkan Untuk Saya (Manual Pick)' tanpa menggoyang HP | Sistem langsung mengeksekusi random picker dan menyajikan kartu hasil pilihan beserta alasan AI. | Berfungsi mulus sebagai fallback sensor perangkat. | **PASSED** |
| 10 | AI Assistant Gastronomi (Screen 11) | Mengirim prompt permintaan makan malam pedas gurih budget <Rp35k/pax di Jogja | AI merespons dengan sopan, menyajikan ringkasan kriteria, dan menampilkan kartu Oseng Mercon & Bakmi Pale. | Rekomendasi 100% riil berbasis database Supabase (RAG). | **PASSED** |
| 11 | Mode Luring Hive (Screen 12) | Mengaktifkan Mode Pesawat lalu membuka tab Koleksi Favorit | Tampil banner 'MODE OFFLINE AKTIF', 142 restoran favorit tetap dapat dibuka detail dan kontaknya. | Seluruh data favorit terbaca instan dari Hive tanpa internet. | **PASSED** |
| 12 | Geofence Check-in GPS (Screen 13) | Berada pada jarak 18 meter (< 50m) dari warung dan klik 'Konfirmasi Check-in Sah' | Sistem memvalidasi koordinat, mengesahkan check-in ID-DIY-7740, menambah +50 Foodie Points, dan update lencana. | Check-in sah berhasil tercatat dengan green checkmark. | **PASSED** |
| 13 | Anti-Cheat Geofence (Screen 13) | Mencoba check-in saat posisi berada pada jarak 150 meter dari warung fisik | Sistem menolak check-in, menampilkan keterangan di luar jangkauan fisik, tombol konfirmasi non-aktif. | Validasi integritas anti-cheat berhasil mencegah check-in palsu. | **PASSED** |
| 14 | Konverter Kurs Valas (Screen 14) | Memasukkan nominal Rp150.000 pada tab Konverter Kurs | Tampil estimasi konversi $9.42 USD dan RM 41.50 MYR serta kartu tolok ukur gudeg kendil dan soto bathok. | Perhitungan kurs akurat dan tolok ukur makanan informatif. | **PASSED** |
| 15 | Konverter Waktu Makan (Screen 14) | Memilih preset waktu makan malam (19:00 WIB) | Tampil konversi waktu simultan: London BST (13:00 / -6 jam), WITA (20:00 / +1 jam), WIT (21:00 / +2 jam). | Sinkronisasi 4 zona waktu akurat sesuai standar IANA. | **PASSED** |
| 16 | Mini Game Tebak Kuliner (Screen 15) | Memilih jawaban [A] Mangut Lele pada teka-teki rasa #04 | Timer berhenti, tampil feedback 'Benar! +100 Poin', narasi Ensiklopedia Gastronomi, dan skor bertambah. | Alur kuis harian, timer 15 detik, dan klaim poin sukses. | **PASSED** |
| 17 | Pencapaian & Voucher (Screen 16) | Membuka katalog hadiah dan menukarkan 500 poin untuk Voucher Gudeg Rp25k | Saldo berkurang 500 poin, voucher digital diterbitkan, lencana Penjelajah Gudeg Emas tampil aktif. | Poin terpotong konsisten dan status lencana terverifikasi. | **PASSED** |
| 18 | Notifikasi & Logout (Screen 17, 18) | Menerima pengingat makan, kirim formulir saran mata kuliah, lalu pilih keluar akun | Notifikasi lokal muncul tepat waktu, formulir saran tersimpan, dialog logout membersihkan token sesi aman. | Notifikasi tampil tepat waktu dan sesi aman terhapus. | **PASSED** |

---

# BAB IV KESIMPULAN DAN SARAN

## 4.1 Kesimpulan

Berdasarkan perancangan, implementasi, dan pengujian yang telah dilaksanakan pada proyek akhir ini, dapat diambil kesimpulan sebagai berikut:
1. Telah berhasil dikembangkan aplikasi mobile penemuan kuliner cerdas **FOODIE (PRO • MATARAMAN EDITION)** yang secara khusus dan eksklusif menyajikan kurasi warisan kuliner autentik di wilayah Daerah Istimewa Yogyakarta dan Jawa Tengah.
2. Seluruh 18 antarmuka purwarupa yang dirancang pada berkas Figma `mobagus.zip` telah berhasil disinkronkan dan diimplementasikan secara komprehensif, mencakup alur autentikasi 3-tahap (registrasi, verifikasi email OTP 6-digit, aktivasi biometrik), beranda editorial, eksplorasi kuliner terfilter, detail restoran kaya informasi, utilitas wisatawan, mini game, hingga manajemen profil kurator.
3. Arsitektur penyimpanan hybrid yang memadukan Supabase PostgreSQL di sisi cloud dan Hive NoSQL di sisi lokal perangkat terbukti efektif dalam memberikan performa antarmuka yang sangat responsif (< 100 ms) sekaligus menjamin keandalan akses data secara penuh saat perangkat berada dalam kondisi luring (offline-first resilience).
4. Pemanfaatan perangkat keras sensor mobile berhasil diterapkan secara optimal, di mana sensor GPS/GNSS mampu menegakkan radar validasi kehadiran fisik Geofence (< 50 meter) yang bebas kecurangan (anti-cheat), sensor Accelerometer sukses menghadirkan interaksi pemilihan makanan cerdas Shake to Decide, dan sensor Biometrik memberikan kemudahan akses masuk 1-ketukan yang aman tanpa mengorbankan privasi.
5. Fitur inovatif FOODIE AI Assistant berbasis LLM yang diintegrasikan melalui mekanisme Retrieval-Augmented Generation (RAG) pada Supabase Edge Functions terbukti mampu menyajikan rekomendasi kuliner yang cerdas dan relevan dengan preferensi rasa pengguna, dengan tetap menjaga akurasi faktual tanpa adanya halusinasi data.
6. Berdasarkan pengujian User Acceptance Testing (UAT) dengan 18 butir skenario pengujian fungsional dan usability di perangkat fisik, seluruh modul memperoleh status **PASSED**, membuktikan bahwa sistem telah memenuhi seluruh kriteria proyek akhir mata kuliah Pemrograman Aplikasi Mobile dengan standar kualitas tinggi.

## 4.2 Saran

Untuk pengembangan aplikasi FOODIE di masa mendatang, disarankan beberapa peningkatan lanjutan:
1. **Perluasan Integrasi Payment Gateway:** Menambahkan integrasi gateway pembayaran digital (seperti Midtrans atau Xendit) agar pengguna dapat melakukan reservasi meja makan atau pembayaran pesanan oleh-oleh secara langsung dari dalam aplikasi.
2. **Pengembangan Fitur AR (Augmented Reality):** Mengembangkan visualisasi rute navigasi berbasis Augmented Reality (AR) di jalanan kawasan heritage (seperti kawasan Malioboro dan Kotagede) untuk memandu wisatawan berjalan kaki menuju warung kuliner tersembunyi (hidden gems).
3. **Penyempurnaan Rekomendasi Berbasis Graf (Graph Database):** Menerapkan analisis jejaring graf pada preferensi bumbu dan profil rasa pengguna untuk menghasilkan rekomendasi kuliner yang semakin terpersonalisasi secara mendalam.
4. **Perluasan Jangkauan Wisatawan Multibahasa:** Menyediakan dukungan antarmuka dalam bahasa internasional tambahan (seperti bahasa Jepang, Mandarin, dan Prancis) guna mendukung promosi pariwisata gastronomi Yogyakarta dan Jawa Tengah ke tingkat global.
