import 'package:flutter/material.dart';
import '../models/detective_case.dart';

/// 15 Kasus Investigasi Kriminal Detektif Kuliner "Pilih Jalanmu"
/// Mencakup 16 Rumah Makan Otentik Yogyakarta & Sindikat Rahasia "Topeng Garam".
final List<DetectiveCase> kDetectiveCases = [
  // =========================================================================
  // LEVEL 1: WIJILAN (Gudeg Yu Djum) - PEMULA
  // =========================================================================
  const DetectiveCase(
    level: 1,
    id: 'case_wijilan',
    title: 'Misteri Racun Rasa Gudeg Wijilan',
    subtitle: 'Sabotase kuali pusaka berumur 40 tahun di sentra gudeg legendaris',
    location: 'Sentra Gudeg Wijilan, Kraton Yogyakarta',
    targetRestaurant: 'Gudeg Yu Djum Wijilan',
    suspectName: 'Chef Hendra "Si Lidah Emas"',
    difficulty: CaseDifficulty.pemula,
    baseReward: 250,
    iconEmoji: '🍲',
    synopsis:
        'Kuali gudeg legendaris milik Bu Djuminten mendadak terasa asam menyengat dan bau sangit kimia. Jika rahasia ini bocor, reputasi sentra Wijilan akan hancur lebur menjelang kunjungan menteri pariwisata.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Olah TKP Dapur Pawon Wijilan',
        location: 'Dapur Pawon Tungku Kayu Wijilan - Pukul 22.30 WIB',
        narrative:
            'Kamu tiba di dapur pawon yang dipenuhi asap tebal. Bu Djuminten terduduk lemas sambil memegangi sendok kayu pusaka. Kuali tembaga raksasa yang mendidih mengeluarkan buih keabu-abuan aneh dengan bau asam tajam.',
        speakerName: 'Bu Djuminten',
        speakerRole: 'Pemilik Resep Warisan',
        speakerAvatar: '👵',
        choices: [
          SceneChoice(
            text: 'Periksa endapan bumbu di dasar kuali tembaga',
            actionDetail: 'Menggunakan sendok sampel dan kertas lakmus detektif',
            feedback:
                'Analisis jitu! Kertas lakmus berubah merah pekat dan tercium asam cuka sintetis pekat yang sengaja dituang ke dalam santan aren.',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_asam_sintetis',
              title: 'Residu Asam Cuka Kimia',
              description: 'Zat asam sintetis non-organik ditemukan mengendap di dasar kuali santan.',
              icon: Icons.science_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Tuduh langsung pelayan cuci piring yang gemetar',
            actionDetail: 'Menginterogasi pelayan tanpa memeriksa bukti kuali',
            feedback:
                'Salah langkah! Pelayan tersebut hanya panik karena kuali berasap. Sikap cerobohmu membuat dapur semakin kacau dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Cek stok kayu bakar nangka di pojok pawon',
            actionDetail: 'Memeriksa keaslian kayu bakar penentu aroma gudeg',
            feedback:
                'Kayu nangka kering dalam kondisi normal, namun kamu melihat jejak sol sepatu boot beroda lumpur basah mengarah ke pintu belakang.',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_jejak_lumpur',
              title: 'Jejak Sepatu Boot Lumpur',
              description: 'Jejak sepatu khusus beraroma minyak restoran modern di dekat tungku.',
              icon: Icons.snowshoeing_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penelusuran Jejak Pemasok Beringharjo',
        location: 'Lorong Rempah Pasar Beringharjo - Pukul 06.00 WIB',
        narrative:
            'Jejak lumpur membawamu ke kios rempah langganan Wijilan. Penjual bumbu kluwek dan gula kelapa terlihat gelisah saat melihat lencana biro investigasimu.',
        speakerName: 'Pak Darto',
        speakerRole: 'Tengkulak Bumbu Tradisional',
        speakerAvatar: '🧔',
        choices: [
          SceneChoice(
            text: 'Tunjukkan sampel asam cuka dan minta buku faktur pesanan',
            actionDetail: 'Mencocokkan faktur pembelian bahan kimia kemarin sore',
            feedback:
                'Telak! Pak Darto mengakui bahwa asisten Chef Hendra dari restoran "Modern Taste" memesan 5 liter asam cuka pekat atas nama samaran.',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_faktur_palsu',
              title: 'Faktur Bahan Kimia Resto Modern',
              description: 'Bukti pembelian cairan perusak rasa yang diteken oleh bawahan Chef Hendra.',
              icon: Icons.receipt_long_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Ancam akan menyegel kios Pak Darto tanpa bukti dokumen',
            actionDetail: 'Menggertak saksi secara agresif',
            feedback:
                'Gagal! Warga pasar berkerumun membelanya dan Pak Darto menutup mulut rapat-rapat. Kamu kehilangan fokus detektif!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI AKHIR: Tuntaskan Chef Hendra',
        location: 'Ruang VIP Restoran Modern Taste - Pukul 13.00 WIB',
        narrative:
            'Kamu menendang pintu ruang VIP! Chef Hendra berdiri tegak dengan celemek sutra putih dan senyum sinis. Di depannya terhidang kuali replika gudeg curian.',
        speakerName: 'Chef Hendra',
        speakerRole: 'Si Lidah Emas (Mastermind)',
        speakerAvatar: '👨‍🍳',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Chef Hendra "Si Lidah Emas"',
          role: 'Rival Licik & Peniru Resep',
          avatar: '👨‍🍳',
          quote:
              'Detektif ingusan! Gudeg kuno itu memang sudah usang dan pantas punah digantikan franchise-ku! Kamu punya bukti apa menuduhku?!',
          maxHp: 100,
          weakPoints: ['Faktur Toko Kimia', 'Boot Lumpur Identik'],
          imageAsset: 'assets/images/boss_chapter_1.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Banting Faktur Kimia & Hasil Uji Lakmus di atas mejanya!',
            actionDetail: 'Menunjukkan bukti transaksi asam cuka sintetis tak terbantahkan',
            feedback:
                'CRITICAL HIT! Wajah Chef Hendra memucat melihat namanya tertera jelas di faktur bahan kimia berbahaya!',
            isCorrect: true,
            bossDamage: 55,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Tuduh dia iri hati karena masakannya kalah laris',
            actionDetail: 'Menyerang secara emosional tanpa dokumen pendukung',
            feedback:
                'Chef Hendra tertawa terbahak-bahak: "Hukum butuh bukti hitam di atas putih, bukan ocehan!" Seranganmu memantul!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'SKAKMAT: Pengakuan Chef Hendra',
        location: 'Ruang VIP Restoran Modern Taste - Pukul 13.15 WIB',
        narrative:
            'Chef Hendra terhuyung mundur. Dia panik dan mencoba meraih ponselnya untuk menghubungi pengacara!',
        speakerName: 'Chef Hendra',
        speakerRole: 'Tersangka Terpojok',
        speakerAvatar: '😰',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Chef Hendra',
          role: 'Tersangka Utama',
          avatar: '😰',
          quote: 'Semua itu fitnah! Aku ada di kamarku sepanjang malam tadi!',
          maxHp: 50,
          weakPoints: ['Sol Sepatu Lumpur'],
          imageAsset: 'assets/images/boss_chapter_1.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tunjukkan foto sol boot berlumpur yang cocok 100% dengan tanah pawon Wijilan!',
            actionDetail: 'Mencocokkan jejak fisika forensik sol sepatu dengan lantai kuali',
            feedback:
                'FATAL BLOW! Hendra ambruk berlutut dan mengakui bahwa dia menyelinap semalam untuk merusak kuali Bu Djuminten!',
            isCorrect: true,
            bossDamage: 60,
          ),
          SceneChoice(
            text: 'Ajak dia duel tanding masak gudeg sekarang juga',
            actionDetail: 'Menantang lomba masak alih-alih menegakkan hukum',
            feedback:
                'Tindakan konyol! Hendra memanfaatkan kebingungan ini untuk membuang botol kimia ke saluran wastafel!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS TERPECAHKAN: Kuali Emas Wijilan Terselamatkan',
      narrative:
          'Chef Hendra digiring ke kantor polisi dengan kepala tertunduk. Bu Djuminten membersihkan kuali pusaka dan menanak gudeg baru dengan bumbu nangka murni.\n\nSore harinya, rombongan menteri memuji kelezatan gudeg Wijilan sebagai mahakarya warisan dunia. Sebagai tanda kehormatan, Bu Djuminten menyematkan Sendok Tembaga Emas di jas detektifmu!',
      epilogue: 'Kamu dianugerahi lencana Detektif Rasa Pemula dan reputasimu mulai tersiar di seantero Yogyakarta.',
      badgeName: 'Penyelamat Pawon Wijilan 🎖️',
      rewardPoints: 300,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Warisan Legendaris Runtuh',
      narrative:
          'Kamu kehilangan petunjuk penting dan tersesat dalam alibi palsu Chef Hendra. Kuah gudeg yang asam terlanjur disajikan kepada para tamu negara.\n\nWarung Bu Djuminten ditutup sementara oleh dinas kesehatan, sementara Chef Hendra tersenyum puas membuka cabang baru di bekas tanah Wijilan.',
      epilogue: 'Lencana detektifmu dibekukan sementara. Kamu harus mempertajam insting rasa dan investigasimu!',
      badgeName: 'Detektif Tersungkur 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 2: KOPI JOSS (Lik Man Stasiun Tugu) - PEMULA
  // =========================================================================
  const DetectiveCase(
    level: 2,
    id: 'case_kopi_joss',
    title: 'Sabotase Bara Arang Kopi Joss Tugu',
    subtitle: 'Arang beracun yang meletup dan konspirasi monopoli angkringan Malioboro',
    location: 'Kawasan Stasiun Tugu & Lesehan Malioboro',
    targetRestaurant: 'Kopi Joss Lik Man',
    suspectName: 'Mbah Broto "Juragan Arang"',
    difficulty: CaseDifficulty.pemula,
    baseReward: 350,
    iconEmoji: '☕',
    synopsis:
        'Arang membara yang dicelupkan ke cangkir kopi joss mendadak meledak dan mengeluarkan bau belerang beracun. Beberapa turis asing pusing mual. Apakah ada yang sengaja menukar kayu sengon asli dengan limbah batu bara?',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Misteri Cangkir Retak di Pinggir Rel',
        location: 'Lesehan Angkringan Stasiun Tugu - Pukul 21.00 WIB',
        narrative:
            'Gelas kopi kaca pecah berserakan di tikar pandan. Lik Man memegang tangannya yang tersiram air kopi panas. Abu arang yang tersisa di tanah berwarna kuning kehijauan tidak wajar.',
        speakerName: 'Lik Man',
        speakerRole: 'Maestro Kopi Joss',
        speakerAvatar: '👴',
        choices: [
          SceneChoice(
            text: 'Cium dan kumpulkan residu serbuk arang di pecahan gelas',
            actionDetail: 'Menggunakan pinset forensik untuk menguji serbuk bara',
            feedback:
                'Bau belerang tambang yang menyengat menusuk hidungmu! Ini jelas bukan arang kayu sengon alami yang biasa menyerap racun lambung.',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_arang_belerang',
              title: 'Serpihan Arang Belerang Limbah',
              description: 'Briket arang beracun yang dicampur zat belerang agar meletup saat kena cairan.',
              icon: Icons.fireplace_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Minum sisa kopi di teko untuk mengecek racunnya',
            actionDetail: 'Mencicipi kopi yang diduga terkontaminasi',
            feedback:
                'Kecerobohan fatal! Lidah dan kerongkonganmu terbakar rasa pahit kimia! Kamu terbatuk-batuk hebat dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Gudang Pembakaran Arang Pinggir Rel',
        location: 'Gudang Briket Lempuyangan - Pukul 23.30 WIB',
        narrative:
            'Di gudang pembakaran gelap, kamu menemukan tumpukan karung goni bertuliskan "Limbah Tambang Belerang Merapi". Mbah Broto terlihat sedang menghitung gepokan uang kertas.',
        speakerName: 'Mbah Broto',
        speakerRole: 'Tengkulak Arang Oplosan',
        speakerAvatar: '🧙‍♂️',
        choices: [
          SceneChoice(
            text: 'Foto karung goni belerang dan cocokkan stempel karungnya',
            actionDetail: 'Mengabadikan barang bukti distribusi arang berbahaya',
            feedback:
                'Bukti kuat tercatat! Stempel karung beracun itu sama persis dengan karung yang diantar ke gerobak Lik Man tadi sore!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_stempel_karung',
              title: 'Stempel Karung Belerang',
              description: 'Nomor batch distribusi arang oplosan berbahaya milik gudang Mbah Broto.',
              icon: Icons.inventory_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Teriak menakuti Mbah Broto dari kejauhan',
            actionDetail: 'Membongkar posisi pengintaian',
            feedback:
                'Mbah Broto menyiramkan serbuk arang panas ke arahmu! Matamu perih luar biasa dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Membungkam Juragan Arang',
        location: 'Dermaga Lori Penggilingan Batu Bara - Pukul 00.30 WIB',
        narrative:
            'Mbah Broto terpojok di dekat lori pembakaran arang. Dia memegang linggis besi berkarat dengan tatapan mata buas.',
        speakerName: 'Mbah Broto',
        speakerRole: 'Juragan Arang Licik',
        speakerAvatar: '🧙‍♂️',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Mbah Broto "Juragan Arang"',
          role: 'Penyelundup Bahan Belerang',
          avatar: '🧙‍♂️',
          quote: 'Siapa peduli turis sakit perut?! Selama angkringan terpaksa beli arang briket buatanku, aku yang menguasai malam Jogja!',
          maxHp: 100,
          weakPoints: ['Stempel Karung Belerang', 'Serbuk Pecahan Gelas'],
          imageAsset: 'assets/images/boss_chapter_1.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tunjukkan sampel belerang menyala dan surat segel Dinas Lingkungan!',
            actionDetail: 'Membuktikan pelanggaran pidana distribusi bahan beracun berbahaya',
            feedback:
                'HANTAMAN TELAK! Mbah Broto menjatuhkan linggisnya saat sirine mobil biro hukum meraung di luar gudang!',
            isCorrect: true,
            bossDamage: 60,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Tantang dia adu kekuatan fisik dengan tangan kosong',
            actionDetail: 'Mengabaikan bahaya bara api di sekeliling panggung',
            feedback:
                'Mbah Broto mengayunkan sekop bara ke kakimu! Kamu terlempar dan terluka bakar!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'BONGKAR BUKTI TIKET SETORAN',
        location: 'Dermaga Lori Penggilingan Batu Bara - Pukul 00.45 WIB',
        narrative:
            'Mbah Broto berlutut di tanah, namun masih menyeringai licik mencoba menyembunyikan buku catatan di balik jaket kumalnya.',
        speakerName: 'Mbah Broto',
        speakerRole: 'Tersangka Tak Berkutik',
        speakerAvatar: '🧙‍♂️',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Mbah Broto',
          role: 'Tersangka Tersudut',
          avatar: '🧙‍♂️',
          quote: 'Kalian tidak akan pernah membuktikan uang ini hasil kejahatan!',
          maxHp: 40,
          weakPoints: ['Buku Catatan Hitam'],
          imageAsset: 'assets/images/boss_chapter_1.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Rampas buku catatan setoran hitam yang mencatat penerima suap suplai arang!',
            actionDetail: 'Mengamankan bukti pembukuan konspirasi angkringan',
            feedback:
                'KNOCKOUT! Seluruh alur distribusi ilegal terungkap terang benderang. Mbah Broto resmi dibekuk!',
            isCorrect: true,
            bossDamage: 50,
          ),
          SceneChoice(
            text: 'Biarkan dia menyimpan bukunya asalkan mau meminta maaf',
            actionDetail: 'Menunjukkan belas kasihan keliru pada penjahat',
            feedback:
                'Dia langsung menyobek halaman penting dan menelannya! Kesempatan bukti hilang!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS SELESAI: Bara Murni Kopi Joss Menyala Kembali',
      narrative:
          'Gudang arang belerang disegel permanen. Lik Man kembali menggunakan arang kayu sengon pilihan yang aman dan menyehatkan lambung.\n\nMalam di Stasiun Tugu kembali syahdu dengan kepulan asap kopi joss mendesis yang harum. Lik Man memberimu cangkir kopi kehormatan berukir lencana detektif!',
      epilogue: 'Kepercayaan pelancong pada angkringan legendaris Jogja pulih seutuhnya berkat analisismu.',
      badgeName: 'Penjaga Api Angkringan 🔥',
      rewardPoints: 350,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Kabut Beracun Menutup Angkringan',
      narrative:
          'Mbah Broto berhasil membakar gudang dan menghilangkan seluruh bukti. Isu racun kopi joss merebak di media sosial, membuat puluhan gerobak angkringan sepi pengunjung.',
      epilogue: 'Malam di Tugu terasa dingin dan hampa. Kamu harus belajar membaca jejak lebih cermat.',
      badgeName: 'Arang Padam 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 3: SOTO BATHOK (Mbah Katro Sambisari) - PEMULA
  // =========================================================================
  const DetectiveCase(
    level: 3,
    id: 'case_soto_bathok',
    title: 'Konspirasi Batok Keramat Candi Sambisari',
    subtitle: 'Pencemaran kuah kaldu sapi bening dan pencurian batok kelapa bertuah',
    location: 'Sawah Sambisari, Kalasan, Sleman',
    targetRestaurant: 'Soto Bathok Mbah Katro',
    suspectName: 'Ki Joyo "Pencuri Kaldu Bening"',
    difficulty: CaseDifficulty.pemula,
    baseReward: 400,
    iconEmoji: '🥥',
    synopsis:
        'Puluhan batok kelapa penyaji soto di warung Mbah Katro mendadak dilapisi cairan getah pahit yang merusak kaldu bening gurih. Di saat bersamaan, panci kaldu daging sapi rebusan 8 jam lenyap menjelang fajar.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Olah TKP Saung Tepi Sawah Sambisari',
        location: 'Gazebo Bambu Warung Mbah Katro - Pukul 05.00 WIB',
        narrative:
            'Angin pagi berhembus dingin di tepi Candi Sambisari. Mbah Katro menatap sedih deretan mangkuk batok kelapa yang permukaannya lengket kehijauan dan berbau getah pohon jarak.',
        speakerName: 'Mbah Katro',
        speakerRole: 'Sesepuh Soto Bathok',
        speakerAvatar: '👴',
        choices: [
          SceneChoice(
            text: 'Kerik lapisan getah pada mangkuk batok kelapa untuk uji laboratorium',
            actionDetail: 'Mengambil sampel getah pahit perusak rasa kaldu',
            feedback:
                'Tepat sekali! Getah ini berasal dari pohon jarak pagar beracun yang sengaja dioleskan agar batok kelapa mengeluarkan rasa pahit pekat!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_getah_jarak',
              title: 'Getah Jarak Pahit',
              description: 'Cairan racun alami yang dioleskan untuk merusak cita rasa gurih batok kelapa.',
              icon: Icons.eco_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Cuci mangkuk batok di selokan irigasi sawah',
            actionDetail: 'Membersihkan mangkuk dengan air kotor sawah',
            feedback:
                'Mangkuk malah makin terkontaminasi bakteri lumpur! Mbah Katro menegurmu keras dan kamu kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Jejak Kereta Sorong Menuju Tebing Candi',
        location: 'Parit Kuno Candi Sambisari - Pukul 06.30 WIB',
        narrative:
            'Di tanah basah tepi parit candi, terlihat bekas roda tunggal kereta dorong berat. Tercecer potongan daging tetelan sapi dan serpihan bawang putih goreng gurih.',
        speakerName: 'Warga Sekitar',
        speakerRole: 'Petani Pagi',
        speakerAvatar: '👨‍🌾',
        choices: [
          SceneChoice(
            text: 'Ikuti jejak tetesan kuah kaldu sapi ke arah gubuk pembakaran bata',
            actionDetail: 'Melacak jejak aroma gurih kaldu sapi rebusan',
            feedback:
                'Jejak akurat! Di dalam gubuk bata, kamu memergoki Ki Joyo sedang menuangkan kuah kaldu Mbah Katro ke dalam jeriken plastik komersial!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_jeriken_kaldu',
              title: 'Jeriken Kaldu Curian',
              description: 'Jeriken penampung kaldu sapi asli warung Mbah Katro yang hendak dijual ke warung fiktif.',
              icon: Icons.local_drink_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Cari panci kaldu dengan menerobos semak belukar berduri',
            actionDetail: 'Berlari tanpa memperhatikan arah jejak roda',
            feedback:
                'Kakimu terperosok ke lubang galian bata! Bajumu robek dan konsentrasi investigasimu buyar!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Gagalkan Ki Joyo di Tungku Bata',
        location: 'Gubuk Pembakaran Bata Kalasan - Pukul 07.15 WIB',
        narrative:
            'Ki Joyo berdiri menghadangmu di depan tungku bata panas dengan golok pemotong daging di tangannya. Dia berniat menjual formula kaldu Sambisari ke jaringan warung franchise.',
        speakerName: 'Ki Joyo',
        speakerRole: 'Pencuri Kaldu',
        speakerAvatar: '😠',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Ki Joyo "Pencuri Kaldu"',
          role: 'Pencuri Resep Sambisari',
          avatar: '😠',
          quote: 'Mbah Katro sudah terlalu tua! Kaldu bening ini bernilai miliaran jika kujual ke pabrik bumbu instan!',
          maxHp: 100,
          weakPoints: ['Jeriken Kaldu Curian', 'Getah Jarak'],
          imageAsset: 'assets/images/boss_chapter_1.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Konfrontasi dengan jeriken kaldu berlabel nomor panci Mbah Katro!',
            actionDetail: 'Menunjukkan bukti kepemilikan panci bernomor seri dapur Sambisari',
            feedback:
                'SERANGAN TELAK! Ki Joyo terperangah melihat bukti segel nomor seri panci yang tidak bisa ia sangkal!',
            isCorrect: true,
            bossDamage: 55,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Bujuk dia untuk mencicipi kuah soto bersama-sama',
            actionDetail: 'Mengajak berdamai di situasi bahaya',
            feedback:
                'Ki Joyo menyiramkan abu pembakaran bata panas ke arahmu! Kamu terluka dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'LUMPUHKAN KI JOYO DI TANAH LIAT',
        location: 'Halaman Gubuk Pembakaran Bata - Pukul 07.30 WIB',
        narrative:
            'Ki Joyo mencoba melarikan diri melompati parit bata membawa botol sampel getah jarak!',
        speakerName: 'Ki Joyo',
        speakerRole: 'Buronan Terdesak',
        speakerAvatar: '😰',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Ki Joyo',
          role: 'Pencuri Terpojok',
          avatar: '😰',
          quote: 'Jangan sentuh aku! Kaldu ini milikku sekarang!',
          maxHp: 50,
          weakPoints: ['Botol Getah Jarak'],
          imageAsset: 'assets/images/boss_chapter_1.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Rebut botol getah jarak dan kancingkan borgol detektif ke tangannya!',
            actionDetail: 'Menjegal langkah pelaku di parit tanah liat licin',
            feedback:
                'KNOCKOUT! Ki Joyo tersungkur di parit tanah liat, botol racun tersita, dan kaldu pusaka berhasil diselamatkan!',
            isCorrect: true,
            bossDamage: 60,
          ),
          SceneChoice(
            text: 'Lepaskan dia dan hanya amankan jeriken kaldunya saja',
            actionDetail: 'Membiarkan pelaku kriminal lolos',
            feedback:
                'Ki Joyo berhasil kabur ke jalan raya dan bisa mengulangi kejahatannya!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS TERPECAHKAN: Batok Kelapa Sambisari Bersemi Kembali',
      narrative:
          'Panci kaldu sapi bening dikembalikan utuh ke warung Mbah Katro. Batok kelapa dicuci menggunakan larutan asam kawak alami hingga bersih berkilau.\n\nPagi itu, ribuan pengunjung Candi Sambisari menikmati soto hangat dalam mangkuk batok dengan tempe garit renyah. Mbah Katro menghadiahkan Batok Kelapa Emas berukir namamu!',
      epilogue: 'Misteri terselesaikan dengan sempurna dan sarapan warga Sleman kembali damai.',
      badgeName: 'Pelindung Batok Sambisari 🥥',
      rewardPoints: 400,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Kaldu Mbah Katro Tercuri',
      narrative:
          'Ki Joyo berhasil membawa lari kaldu dan menjualnya ke pabrik bumbu instan palsu. Warung soto batok kehilangan ciri khas rasa bening segarnya selamanya.',
      epilogue: 'Penyelidikanmu di Kalasan berakhir dengan kegagalan pahit.',
      badgeName: 'Batok Pecah 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 4: MANGUT LELE (Mbah Marto Sewon Bantul) - PEMULA
  // =========================================================================
  const DetectiveCase(
    level: 4,
    id: 'case_mangut_lele',
    title: 'Hilangnya Kayu Asap Klampok Sewon',
    subtitle: 'Pencurian kayu bakar langka dan pemalsuan aroma asap mangut lele legendaris',
    location: 'Dusun Ngenep, Sewon, Bantul',
    targetRestaurant: 'Mangut Lele Mbah Marto',
    suspectName: 'Darmo "Tengkulak Asap Palsu"',
    difficulty: CaseDifficulty.pemula,
    baseReward: 450,
    iconEmoji: '🐟',
    synopsis:
        'Aroma asap lele pawon Mbah Marto yang legendaris berasal dari kayu bakar pohon klampok tua berumur puluhan tahun. Semalam, seluruh pasokan kayu klampok hilang dan diganti kayu pinus beraroma terpentin yang membuat lele berbau cat minyak.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Pemeriksaan Pawon Asap Bantul',
        location: 'Dapur Pawon Berasap Mbah Marto - Pukul 04.30 WIB',
        narrative:
            'Di dapur pawon tradisional berdinding gedek bambu, deretan lele asap yang digantung di atas tungku berbau sengak aneh. Asap yang mengepul berwarna putih pekat membuat mata perih tak tertahankan.',
        speakerName: 'Mbah Marto',
        speakerRole: 'Legenda Mangut Lele',
        speakerAvatar: '👵',
        choices: [
          SceneChoice(
            text: 'Periksa sisa pembakaran kayu di bawah tungku asap',
            actionDetail: 'Mengidentifikasi jenis kayu penentu aroma mangut',
            feedback:
                'Analisis tepat! Kayu di tungku ternyata kayu pinus bergetah damar tinggi yang sengaja dimasukkan agar lele tercemar aroma terpentin kimia!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_kayu_pinus',
              title: 'Gelondongan Kayu Pinus Kimia',
              description: 'Kayu beraroma terpentin yang sengaja ditukar dengan kayu klampok asli.',
              icon: Icons.forest_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Makan lele yang masih mengepul bau minyak cat',
            actionDetail: 'Mencicipi ikan yang terpapar asap damar',
            feedback:
                'Kamu mual parah karena uap getah pinus! Kamu terbatuk hebat dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penyergapan di Pinggir Sungai Opak',
        location: 'Pabrik Penggergajian Kayu Liar Sewon - Pukul 07.00 WIB',
        narrative:
            'Di tepi Sungai Opak, sebuah truk bak tertutup sedang memuat gelondongan kayu klampok tua berurat merah khas Bantul. Darmo terlihat sedang bernegosiasi dengan calo restoran modern.',
        speakerName: 'Darmo',
        speakerRole: 'Tengkulak Kayu Ilegal',
        speakerAvatar: '🤠',
        choices: [
          SceneChoice(
            text: 'Cocokkan tanda kapur nomor seri kayu klampok milik Mbah Marto',
            actionDetail: 'Membuktikan kepemilikan kayu tebangan sah Sewon',
            feedback:
                'Bukti mutlak! Tanda kapur Mbah Marto tertera jelas di ujung gelondongan kayu beraroma manis buah ini!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_tanda_kapur',
              title: 'Segel Kapur Kayu Klampok',
              description: 'Bukti fisik kepemilikan kayu asap asli Mbah Marto yang hendak diselundupkan.',
              icon: Icons.verified_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Lempar batu ke kaca truk untuk menghentikan sopir',
            actionDetail: 'Tindakan destruktif tanpa rencana',
            feedback:
                'Batu memantul mengenai kepalamu sendiri! Sopir panik dan kamu terluka 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Hentikan Truk Darmo',
        location: 'Jembatan Gantung Sewon Bantul - Pukul 08.00 WIB',
        narrative:
            'Truk Darmo terhenti di depan palang jembatan gantung. Darmo turun dengan kapak pemotong kayu di genggamannya.',
        speakerName: 'Darmo',
        speakerRole: 'Tengkulak Asap Palsu',
        speakerAvatar: '🤠',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Darmo "Tengkulak Asap Palsu"',
          role: 'Pencuri Kayu Klampok',
          avatar: '🤠',
          quote: 'Kayu klampok ini harganya sepuluh kali lipat di restoran kota! Orang tua di Ngenep itu tak pantas memakai kayu semahal ini!',
          maxHp: 100,
          weakPoints: ['Segel Kapur Kayu Klampok', 'Serat Pinus Kimia'],
          imageAsset: 'assets/images/boss_chapter_1.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tunjukkan sampel getah pinus beracun dan ancaman pidana perusakan pangan!',
            actionDetail: 'Membentangkan pasal pidana peracunan makanan tradisional',
            feedback:
                'CRITICAL DAMAGE! Darmo pucat pasi mendengar ancaman hukuman penjara 15 tahun atas pencemaran pangan!',
            isCorrect: true,
            bossDamage: 60,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Coba rebut kapak dari tangannya secara gegabah',
            actionDetail: 'Menyerang tangan pelaku bersenjata tajam',
            feedback:
                'Gagang kapak menghantam bahumu! Kamu terpental dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'REBUT KUNCI KONTAK TRUK PENCURI',
        location: 'Jembatan Gantung Sewon - Pukul 08.15 WIB',
        narrative:
            'Darmo mencoba melompat ke kursi kemudi untuk menabrak palang jembatan!',
        speakerName: 'Darmo',
        speakerRole: 'Tersangka Nekat',
        speakerAvatar: '🤠',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Darmo',
          role: 'Buronan Kabur',
          avatar: '🤠',
          quote: 'Minggir atau kutabrak kau detektif!',
          maxHp: 40,
          weakPoints: ['Kunci Kontak Truk'],
          imageAsset: 'assets/images/boss_chapter_1.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tarik rem tangan dari jendela kabin dan cabut kunci kontak truk!',
            actionDetail: 'Melumpuhkan armada pengangkut kayu curian',
            feedback:
                'KNOCKOUT! Truk mogok seketika, polisi Polsek Sewon datang mengepung, dan Darmo menyerah pasrah!',
            isCorrect: true,
            bossDamage: 50,
          ),
          SceneChoice(
            text: 'Berdiri mematung di depan bumper truk',
            actionDetail: 'Menahan truk berat dengan tubuh',
            feedback:
                'Kamu hampir tertabrak dan harus melompat ke semak-semak! Penuh luka!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS SELESAI: Wangi Asap Klampok Pawon Sewon Abadi',
      narrative:
          'Seluruh muatan kayu klampok dikembalikan ke pawon Mbah Marto. Tungku kembali membara dengan asap harum manis khas kayu buah langka.\n\nLele asap berkuah santan cabai rawit pedas medok kembali tersaji sempurna untuk para pemburu kuliner nusantara. Mbah Marto menyajikan sepiring mangut lele terlezat untuk sarapan sang Detektif!',
      epilogue: 'Warisan pawon tradisional Ngenep tetap terjaga berkat ketelitianmu.',
      badgeName: 'Penjaga Asap Sewon 🐟',
      rewardPoints: 450,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Padamnya Asap Mbah Marto',
      narrative:
          'Kayu klampok berhasil diselundupkan ke luar kota dan pawon Mbah Marto terpaksa ditutup karena tidak ada lagi kayu bakar beraroma khas.',
      epilogue: 'Salah satu pusaka rasa paling ikonik di Bantul terancam punah.',
      badgeName: 'Asap Hilang 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 5: SATE KLATHAK (Pak Pong Jejeran Imogiri) - MENENGAH [CHECKPOINT 1]
  // =========================================================================
  const DetectiveCase(
    level: 5,
    id: 'case_sate_klathak',
    title: 'Hilangnya Jeruji Pusaka Sate Klathak',
    subtitle: 'Konspirasi pencurian tusuk besi sepeda ontel kuno sebelum festival akbar sate Jejeran',
    location: 'Sentra Sate Klathak Jejeran, Imogiri, Bantul',
    targetRestaurant: 'Sate Klathak Pak Pong',
    suspectName: 'Ki Ageng Bismo "Kolektor Pusaka Logam"',
    difficulty: CaseDifficulty.menengah,
    baseReward: 550,
    iconEmoji: '🍢',
    synopsis:
        'Jeruji besi sepeda ontel kuno peninggalan era kolonial milik juru bakar sate legendaris dicuri dari brankas dapur. Tanpa jeruji besi berkonduksi panas tinggi ini, daging kambing muda tidak akan matang merata hingga ke bagian dalam.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Rekonstruksi Kotak Besi yang Dirusak',
        location: 'Dapur Jagal Sate Jejeran - Pukul 18.00 WIB',
        narrative:
            'Bau arang batok kelapa dan daging kambing segar menguar. Kotak kayu jati tempat menyimpan 100 bilah jeruji besi sepeda ontel tercongkel paksa.',
        speakerName: 'Pak Pong',
        speakerRole: 'Maestro Sate Klathak',
        speakerAvatar: '👳',
        choices: [
          SceneChoice(
            text: 'Periksa sisa goresan logam pada engsel kotak kayu',
            actionDetail: 'Menganalisis alat yang dipakai pencuri',
            feedback:
                'Ditemukan serbuk magnetik dan bau minyak keris pusaka! Pelaku kemungkinan seorang kolektor barang antik berbau mistis.',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_minyak_keris',
              title: 'Residu Minyak Keris Pusaka',
              description: 'Minyak cendana wangi yang biasa dipakai merawat tosan aji kuno.',
              icon: Icons.colorize_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Tuduh juru potong daging kambing mencuri jeruji besi',
            actionDetail: 'Menuduh pekerja setia tanpa bukti sidik jari',
            feedback:
                'Tuduhan keliru membuat juru potong mogok kerja dan suasana dapur ricuh! Kamu kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Pelacakan ke Pasar Antik Klithikan',
        location: 'Pasar Barang Antik Kasihan - Pukul 20.30 WIB',
        narrative:
            'Di antara tumpukan sepeda Gazelle dan lampu dokar tua, seorang pedagang tosan aji menunjuk ke arah padepokan Ki Ageng Bismo di bukit Imogiri.',
        speakerName: 'Pedagang Antik',
        speakerRole: 'Informan Pasar',
        speakerAvatar: '🧓',
        choices: [
          SceneChoice(
            text: 'Beli informasi dengan menunjukkan lencana detektif dan foto residu minyak keris',
            actionDetail: 'Mengonfirmasi pesanan jeruji besi sepeda kuno berkadar nikel tinggi',
            feedback:
                'Informasi sahih! Ki Bismo memesan jeruji besi ontel kuno untuk ditempa menjadi keris mistis pesanan konglomerat!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_nota_klithikan',
              title: 'Catatan Pesanan Penempa Keris',
              description: 'Bukti transaksi Ki Bismo yang membutuhkan jeruji besi era 1940-an milik Pak Pong.',
              icon: Icons.history_edu_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Menggeledah kios pedagang secara paksa',
            actionDetail: 'Tindakan kasar di pasar rakyat',
            feedback:
                'Warga pasar melemparimu dengan botol bekas! Kamu diusir dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Padepokan Besi Ki Bismo',
        location: 'Padepokan Tosan Aji Bukit Imogiri - Pukul 22.00 WIB',
        narrative:
            'Di ruang perapian tempa berhawa panas, Ki Ageng Bismo sedang bersiap memasukkan bilah-bilah jeruji sepeda milik Pak Pong ke dalam tungku peleburan logam!',
        speakerName: 'Ki Ageng Bismo',
        speakerRole: 'Kolektor Pusaka Ambisius',
        speakerAvatar: '🧙',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Ki Ageng Bismo',
          role: 'Pencuri Jeruji Pusaka',
          avatar: '🧙',
          quote: 'Jeruji besi tua ini mengandung nikel murni Belanda! Lebih berharga kujadikan pusaka daripada hanya menusuk daging kambing!',
          maxHp: 110,
          weakPoints: ['Catatan Pesanan Klithikan', 'Minyak Keris Cendana'],
          imageAsset: 'assets/images/boss_chapter_1.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Siram air suci ke arang tempa dan bentangkan surat perintah penyitaan cagar budaya!',
            actionDetail: 'Mencegah peleburan logam pusaka bersejarah',
            feedback:
                'SERANGAN CRITICAL! Tungku padam berasap dan Ki Bismo gemetar melihat pasal perusakan benda cagar budaya!',
            isCorrect: true,
            bossDamage: 60,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Pegang bilah jeruji besi yang baru dipanaskan dengan tangan telanjang',
            actionDetail: 'Menyentuh logam bersuhu ratusan derajat',
            feedback:
                'Telapak tanganmu melepuh terbakar! Sakit tak tertahankan dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'REBUT KANTONG JERUJI KUNO',
        location: 'Padepokan Tosan Aji - Pukul 22.20 WIB',
        narrative:
            'Ki Bismo meraih tongkat besi untuk memukulmu dan mempertahankan tas jeruji curiannya!',
        speakerName: 'Ki Ageng Bismo',
        speakerRole: 'Dalang Terdesak',
        speakerAvatar: '🧙',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Ki Ageng Bismo',
          role: 'Boss Terpojok',
          avatar: '🧙',
          quote: 'Koleksiku tidak boleh gagal diselesaikan!',
          maxHp: 50,
          weakPoints: ['Tongkat Besi'],
          imageAsset: 'assets/images/boss_chapter_1.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tangkis dengan perisai investigasi dan tendang tas jeruji ke tangan polisi!',
            actionDetail: 'Melumpuhkan serangan senjata tumpul Ki Bismo',
            feedback:
                'FINISH! Ki Bismo terjatuh ke lantai tempa, seluruh 100 bilah jeruji besi ontel terselamatkan!',
            isCorrect: true,
            bossDamage: 60,
          ),
          SceneChoice(
            text: 'Mundur menghindar keluar pintu tanpa menyelamatkan tas jeruji',
            actionDetail: 'Kabur meninggalkan barang bukti utama',
            feedback:
                'Ki Bismo sempat menendang tas itu ke sumur galian! Pencarian jadi makin sulit!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'CHECKPOINT 1 TERCAPAI: Jeruji Besi Jejeran Terselamatkan',
      narrative:
          '100 bilah jeruji ontel kuno kembali ke panggangan Pak Pong. Daging kambing muda dipanggang di atas bara batok kelapa dengan taburan garam gurih merata.\n\nFestival Sate Klathak Imogiri berlangsung meriah luar biasa. Pak Pong menyematkan Pin Kehormatan Jeruji Perak di dadamu! Kamu berhasil mencapai CHECKPOINT 1 KAMPANYE DETEKTIF!',
      epilogue: 'Progres permainanmu tersimpan aman di Checkpoint Level 5.',
      badgeName: 'Ksatria Jeruji Klathak 🍢 [CHECKPOINT 1]',
      rewardPoints: 600,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Jeruji Besi Melebur Menjadi Keris',
      narrative:
          'Kamu gagal mencegah peleburan logam. Jeruji legendaris Pak Pong lenyap menjadi lelehan besi, membuat sate klathak Jejeran kehilangan metode memasak otentiknya.',
      epilogue: 'Kamu harus memulai kembali penyelidikan dari awal kasus.',
      badgeName: 'Besi Hangus 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 6: BAKMI MBAH GITO (Kotagede) - MENENGAH
  // =========================================================================
  const DetectiveCase(
    level: 6,
    id: 'case_bakmi_mbah_gito',
    title: 'Teror Tungku Arang Anglo Kotagede',
    subtitle: 'Sabotase telur bebek busuk dan zat pemadam bara di kedai kayu legendaris',
    location: 'Kotagede, Yogyakarta',
    targetRestaurant: 'Bakmi Jawa Mbah Gito',
    suspectName: 'Mas Bowo "Si Lidah Instan"',
    difficulty: CaseDifficulty.menengah,
    baseReward: 600,
    iconEmoji: '🍜',
    synopsis:
        'Suasana kedai kayu etnik Mbah Gito mendadak ricuh saat puluhan porsi bakmi godhog mengeluarkan aroma belerang telur busuk. Padahal ratusan pelanggan sedang mengantre santap malam. Dalang di balik ini ingin memaksakan produk mie instan kemasan pabrik miliknya.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Investigasi Dapur Tungku Anglo Kotagede',
        location: 'Dapur Anglo Kayu Mbah Gito - Pukul 19.30 WIB',
        narrative:
            'Di tengah hiruk pikuk pesanan bakmi nyemek dan godhog, koki utama menghentikan wajan. Telur bebek yang baru dipecahkan ke dalam kaldu berbusa hijau dan berbau busuk menusuk hidung.',
        speakerName: 'Mbah Gito',
        speakerRole: 'Maestro Bakmi Jawa',
        speakerAvatar: '👴',
        choices: [
          SceneChoice(
            text: 'Periksa peti penyimpanan telur bebek di rak dapur belakang',
            actionDetail: 'Mengecek bekas suntikan bahan kimia pada cangkang telur',
            feedback:
                'Ditemukan lubang jarum suntik mikro pada cangkang telur bebek! Seseorang sengaja menyuntikkan larutan amonia pembusuk telur!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_suntikan_amonia',
              title: 'Cangkang Telur Bersuntik Amonia',
              description: 'Bukti sabotase kimia jarum mikro pada pasokan telur bebek Mbah Gito.',
              icon: Icons.egg_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Tuduh peternak bebek lokal membawa telur busuk secara sengaja',
            actionDetail: 'Menuduh mitra peternak tanpa memeriksa cangkang telur',
            feedback:
                'Peternak membuktikan telur yang dikirim pagi tadi bersertifikat segar! Kamu dipermalukan dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penggerebekan Mobil Distributor Mie Instan',
        location: 'Parkiran Lorong Perak Kotagede - Pukul 20.45 WIB',
        narrative:
            'Di dekat deretan bengkel kerajinan perak Kotagede, sebuah mobil van hitam terparkir. Mas Bowo, sales agresif perusahaan mie instan instan, sedang membagikan brosur "Ganti Bakmi Anglo dengan Mie Cepat Saji".',
        speakerName: 'Detektif (Kamu)',
        speakerRole: 'Mengintai',
        speakerAvatar: '🕵️',
        choices: [
          SceneChoice(
            text: 'Geledah bagian belakang mobil van Mas Bowo',
            actionDetail: 'Mencari jarum suntik dan botol larutan amonia cair',
            feedback:
                'Bukti tak terbantahkan! Ditemukan spuit jarum medis 50ml dan cairan amonia pekat berbau sama dengan telur busuk!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_jarum_medis',
              title: 'Spuit Jarum Medis Sabotase',
              description: 'Alat kejahatan yang digunakan Mas Bowo untuk merusak telur dapur Mbah Gito.',
              icon: Icons.medication_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Bakar brosur mie instan di depan wajah Mas Bowo',
            actionDetail: 'Melakukan provokasi kekanak-kanakan',
            feedback:
                'Api menyambar jas detektifmu sendiri! Kamu kalang kabut memadamkan api dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Hadapi Mas Bowo di Depan Pelanggan',
        location: 'Pintu Masuk Kedai Kayu Mbah Gito - Pukul 21.30 WIB',
        narrative:
            'Mas Bowo berdiri di depan ratusan pelanggan yang mengantre, berusaha menghasut mereka agar meninggalkan kedai Mbah Gito.',
        speakerName: 'Mas Bowo',
        speakerRole: 'Saboteur Mie Instan',
        speakerAvatar: '👨‍💼',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Mas Bowo "Si Lidah Instan"',
          role: 'Agen Sabotase Korporasi',
          avatar: '👨‍💼',
          quote: 'Lihat bapak ibu! Bakmi tradisional ini jorok dan bau busuk! Beralihlah ke mie kemasan kami yang steril dan cepat saji!',
          maxHp: 110,
          weakPoints: ['Spuit Jarum Medis', 'Cangkang Telur Amonia'],
          imageAsset: 'assets/images/boss_chapter_2.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Angkat spuit jarum medis dan cangkang telur bersuntik di depan para pelanggan!',
            actionDetail: 'Membongkar konspirasi busuk di depan publik secara terang benderang',
            feedback:
                'CRITICAL DAMAGE! Ratusan pelanggan menyoraki Mas Bowo dengan murka! Alibi palsunya hancur berkeping-keping!',
            isCorrect: true,
            bossDamage: 65,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Ajak Mas Bowo makan semangkuk bakmi bersantan busuk',
            actionDetail: 'Menantang makan racun sendiri tanpa bukti hukum',
            feedback:
                'Mas Bowo menepis mangkuk itu ke arah kemejamu! Kotor dan memalukan!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'BEKUK MAS BOWO DI LORONG KAYU',
        location: 'Lorong Kayu Kedai Mbah Gito - Pukul 21.45 WIB',
        narrative:
            'Mas Bowo berusaha melarikan diri ke arah motor matic-nya sambil melemparkan kardus mie instan!',
        speakerName: 'Mas Bowo',
        speakerRole: 'Pelaku Terpojok',
        speakerAvatar: '😰',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Mas Bowo',
          role: 'Tersangka Kabur',
          avatar: '😰',
          quote: 'Kalian tidak bisa menahanku! Perusahaanku punya pengacara hebat!',
          maxHp: 45,
          weakPoints: ['Kunci Motor'],
          imageAsset: 'assets/images/boss_chapter_2.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tendang standar motor matic-nya dan kunci pergelangan tangannya ke tiang kayu jati!',
            actionDetail: 'Melumpuhkan buronan di lorong etnik',
            feedback:
                'KNOCKOUT! Mas Bowo terbanting ke tumpukan kardus dan diserahkan ke Polsek Kotagede!',
            isCorrect: true,
            bossDamage: 55,
          ),
          SceneChoice(
            text: 'Lemparkan sendok bebek ke arah helmnya',
            actionDetail: 'Melempar alat makan secara sia-sia',
            feedback:
                'Sendok patah memantul dan Mas Bowo hampir lolos ke jalan raya!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS SELESAI: Gurih Wangi Anglo Kotagede Menyala Lagi',
      narrative:
          'Dapur Mbah Gito dibersihkan dan pasokan telur bebek organik murni diantarkan langsung oleh kelompok tani binaan. Suara spatula menari di atas wajan baja beralas bara arang kembali bergemerincing merdu.\n\nPelanggan menikmati bakmi godhog kaldu kental gurih dengan senyum puas. Mbah Gito menghadiahkan Sendok Anglo Tembaga Kuno sebagai kenang-kenangan!',
      epilogue: 'Keaslian rasa bakmi arang Kotagede terlindungi dari cengkeraman industri curang.',
      badgeName: 'Penyelamat Anglo Kotagede 🍜',
      rewardPoints: 600,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Padamnya Tungku Mbah Gito',
      narrative:
          'Berita telur busuk menjadi viral dan membuat kedai Mbah Gito sepi ditinggalkan pelanggan. Mas Bowo berhasil memonopoli pasokan mie di Kotagede.',
      epilogue: 'Kamu gagal melindungi tradisi kuliner berusia puluhan tahun.',
      badgeName: 'Mie Basi 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 7: OSENG MERCON (Bu Narti Kauman) - MENENGAH
  // =========================================================================
  const DetectiveCase(
    level: 7,
    id: 'case_oseng_mercon',
    title: 'Formula Cabai Sintetis Peledak Kauman',
    subtitle: 'Zat kimia kapsaisin murni ilegal yang melukai lidah pecinta kuliner malam',
    location: 'Jl. KH. Ahmad Dahlan, Kauman, Yogyakarta',
    targetRestaurant: 'Oseng Mercon Bu Narti',
    suspectName: 'Nyai Gandari "Ratu Kimia Pedas"',
    difficulty: CaseDifficulty.menengah,
    baseReward: 650,
    iconEmoji: '🌶️',
    synopsis:
        'Kelezatan oseng mercon koyor sapi Bu Narti mendadak disabotase dengan cairan ekstrak cabai kimia berbahaya berkekuatan 5 juta Scoville. Beberapa pelanggan mengalami luka lambung parah. Pelakunya ingin membuktikan bahwa kuliner pedas tradisional berbahaya.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Olah TKP Tenda Lesehan Bu Narti',
        location: 'Lesehan Tenda Merah Kauman - Pukul 22.00 WIB',
        narrative:
            'Uap cabai merah mengepul pekat dari wajan raksasa. Namun aroma yang keluar bukan gurih rempah bawang merah dan koyor, melainkan uap asam belerang kimia yang menyengat paru-paru.',
        speakerName: 'Bu Narti',
        speakerRole: 'Perintis Oseng Mercon',
        speakerAvatar: '👵',
        choices: [
          SceneChoice(
            text: 'Ambil sampel kuah minyak kemerahan dengan pipet kaca detektif',
            actionDetail: 'Menguji konsentrasi kapsaisin dan pelarut kimia sintetis',
            feedback:
                'Hasil uji spektrometri kimia positif! Ditemukan cairan pelarut etil alkohol dan bubuk ekstrak cabai murni non-pangan berkekuatan racun!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_kapsaisin_murni',
              title: 'Ekstrak Kapsaisin 5 Juta SHU',
              description: 'Bahan kimia pelarut ekstrak pedas mematikan yang tidak layak konsumsi.',
              icon: Icons.science_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Hirup uap wajan sedalam-dalamnya untuk memastikan jenis cabainya',
            actionDetail: 'Menghirup uap kimia konsentrasi tinggi',
            feedback:
                'Paru-parumu serasa terbakar! Kamu terbatuk darah dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penyelidikan Laboratorium Kosmetik Gelap',
        location: 'Ruko Kosmetik Ilegal Wirobrajan - Pukul 23.45 WIB',
        narrative:
            'Jejak botol pelarut membawamu ke lantai dua ruko kosmetik gelap milik Nyai Gandari. Di atas meja terlihat puluhan botol bertuliskan "Bahan Kimia Peledak Lambung Bu Narti".',
        speakerName: 'Detektif (Kamu)',
        speakerRole: 'Menerobos',
        speakerAvatar: '🕵️',
        choices: [
          SceneChoice(
            text: 'Amankan buku formula dan sisa jeriken kapsaisin sintetis',
            actionDetail: 'Mengumpulkan bukti materiil laboratorium ilegal',
            feedback:
                'Barang bukti sangat lengkap! Tertulis jelas rencana meracuni 5 warung mercon legendaris Jogja untuk menjual obat lambung buatannya sendiri!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_buku_formula',
              title: 'Buku Formula Konspirasi Obat',
              description: 'Rencana jahat meracuni warung mercon demi memonopoli penjualan obat maag racikan.',
              icon: Icons.menu_book_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Hancurkan semua botol kaca di laboratorium secara membabi buta',
            actionDetail: 'Merusak TKP tanpa mencatat barang bukti',
            feedback:
                'Pecahan kaca melukai tanganmu dan uap pedas menyebar di ruangan tertutup! Kamu terluka 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Bekuk Nyai Gandari di Ruko',
        location: 'Ruang Produksi Ruko Wirobrajan - Pukul 00.30 WIB',
        narrative:
            'Nyai Gandari keluar dari ruang brankas sambil memegang botol semprotan cairan kapsaisin pekat!',
        speakerName: 'Nyai Gandari',
        speakerRole: 'Ratu Kimia Pedas',
        speakerAvatar: '👩‍🔬',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Nyai Gandari "Ratu Kimia"',
          role: 'Dalang Racun Pedas',
          avatar: '👩‍🔬',
          quote: 'Orang-orang bodoh itu rela antre berjam-jam demi mercon pedas! Biar lambung mereka robek dan mereka harus sujud membeli obat mujarabku!',
          maxHp: 110,
          weakPoints: ['Buku Formula Obat', 'Uji Kapsaisin 5 Juta SHU'],
          imageAsset: 'assets/images/boss_femme_fatale.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Bantah dengan Buku Formula Konspirasi dan segel resmi BPOM!',
            actionDetail: 'Menunjukkan bukti konspirasi jahat penjualan obat palsu',
            feedback:
                'CRITICAL STRIKE! Nyai Gandari terkesiap melihat buku hariannya berada di tanganmu! Nyalinya ciut!',
            isCorrect: true,
            bossDamage: 60,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Maju menerjang tanpa mengenakan masker pelindung mata',
            actionDetail: 'Menghadapi semprotan kimia tanpa pelindung',
            feedback:
                'Semprotan cabai mengenai wajahmu! Matamu perih luar biasa dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'LUMPUHKAN SEMPROTAN RACUN',
        location: 'Ruang Produksi Ruko - Pukul 00.45 WIB',
        narrative:
            'Nyai Gandari panik dan bersiap melempar botol kapsaisin ke arah jendela agar menguap ke pemukiman warga!',
        speakerName: 'Nyai Gandari',
        speakerRole: 'Dalang Terdesak',
        speakerAvatar: '👩‍🔬',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Nyai Gandari',
          role: 'Boss Tersudut',
          avatar: '👩‍🔬',
          quote: 'Kalau aku hancur, satu kampung Kauman harus ikut terbakar matanya!',
          maxHp: 50,
          weakPoints: ['Botol Semprotan'],
          imageAsset: 'assets/images/boss_femme_fatale.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tembak botol itu dengan jaring detektif dan kunci kedua tangannya dengan borgol!',
            actionDetail: 'Menyelamatkan keselamatan warga pemukiman dari gas cabai',
            feedback:
                'KNOCKOUT! Botol berhasil diamankan utuh, Nyai Gandari terborgol rapat dan dijebloskan ke tahanan!',
            isCorrect: true,
            bossDamage: 60,
          ),
          SceneChoice(
            text: 'Tutup mata dan tiarap di lantai',
            actionDetail: 'Menyerah pasrah di hadapan ancaman',
            feedback:
                'Botol pecah di dalam ruangan dan membuatmu sesak napas parah!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS SELESAI: Ledakan Gurih Pedas Bu Narti Kembali Jaya',
      narrative:
          'Laboratorium ilegal disita negara. Bu Narti menanak kembali oseng mercon koyor sapi asli dengan cabai rawit merah segar pilihan dari petani lereng Merapi.\n\nTenda Kauman kembali dipadati ribuan pecinta kuliner dengan keringat nikmat dan senyum kepuasan. Bu Narti menghadiahkan Ulekan Batu Merapi Kehormatan untukmu!',
      epilogue: 'Sensasi pedas otentik Nusantara terlindungi dari racun kimia komersial.',
      badgeName: 'Penjinak Mercon Kauman 🌶️',
      rewardPoints: 650,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Kabut Racun Menghanguskan Kauman',
      narrative:
          'Cairan kapsaisin meledak dan mencemari udara Kauman. Puluhan warga dilarikan ke rumah sakit dan kawasan kuliner malam terpaksa ditutup berminggu-minggu.',
      epilogue: 'Kegagalan ini membekas luka bakar di reputasi biro investigasimu.',
      badgeName: 'Mercon Meledak 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 8: BAKMI PAK PALE (Alun-Alun Utara) - MENENGAH
  // =========================================================================
  const DetectiveCase(
    level: 8,
    id: 'case_bakmi_pak_pale',
    title: 'Sandera Juru Racik Nyemek Alun-Alun Utara',
    subtitle: 'Penculikan koki rahasia dan ancaman pemusnahan bumbu kaldu bebek keraton',
    location: 'Pelataran Alun-Alun Utara Kraton Yogyakarta',
    targetRestaurant: 'Bakmi Jawa Pak Pale',
    suspectName: 'Bos Viktor "Mafia Kuliner Malam"',
    difficulty: CaseDifficulty.menengah,
    baseReward: 700,
    iconEmoji: '🍲',
    synopsis:
        'Pak Pale, juru masak bakmi nyemek paling legendaris di pojok Alun-alun Utara, diculik bersama buku catatan takaran kaldu bebek pusaka saat fajar usai berbelanja di pasar. Sindikat mafia malam menuntut tebusan berupa pengalihan hak merk dagang.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Olah TKP Gerobak Kosong Alun-Alun',
        location: 'Sudut Alun-Alun Utara Kraton - Pukul 06.00 WIB',
        narrative:
            'Gerobak kayu hijau Pak Pale terparkir miring di bawah pohon beringin kembar. Bumbu kemiri ulek dan kecap asin tumpah di tanah berpasir alun-alun.',
        speakerName: 'Mas Danu',
        speakerRole: 'Asisten Gerobak',
        speakerAvatar: '👦',
        choices: [
          SceneChoice(
            text: 'Analisis jejak ban mobil van di pasir alun-alun dengan kompas geologi',
            actionDetail: 'Menentukan rute pelarian penculik ke arah barat kota',
            feedback:
                'Jejak ban teridentifikasi mengarah ke kawasan pergudangan tua eks Pabrik Gula Madukismo!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_jejak_madukismo',
              title: 'Jejak Pasir Pabrik Gula',
              description: 'Partikel tebu kering dan aspal tua mengindikasikan lokasi penyanderaan di Madukismo.',
              icon: Icons.tire_repair_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Tuduh pengamen jalanan yang tidur di dekat beringin',
            actionDetail: 'Menuduh saksi tuna wisma tanpa alibi masuk akal',
            feedback:
                'Saksi tersebut justru melihat mobil van hitam berlogo elang! Kamu membuang waktu dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penyusupan ke Gudang Karung Madukismo',
        location: 'Gudang Penggilingan Tebu Tua - Pukul 08.30 WIB',
        narrative:
            'Di dalam gudang berbau tetes tebu manis pekat, Pak Pale terikat di kursi kayu. Bos Viktor sedang memaksanya menandatangani akta penyerahan resep rahasia di bawah ancaman pisau.',
        speakerName: 'Pak Pale',
        speakerRole: 'Korban Sandera',
        speakerAvatar: '👴',
        choices: [
          SceneChoice(
            text: 'Lepaskan katup uap penggilingan tebu untuk membuat kabut pengalih perhatian',
            actionDetail: 'Memanfaatkan instalasi uap pabrik tua untuk infiltrasi',
            feedback:
                'Taktik brilian! Ruangan dipenuhi uap tebal seketika, anak buah Viktor panik dan kamu berhasil memotong tali pengikat Pak Pale!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_akta_palsu',
              title: 'Akta Perampasan Resep Fiktif',
              description: 'Dokumen perjanjian paksa yang hendak dipakai Bos Viktor untuk menguasai merk Pak Pale.',
              icon: Icons.description_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Langsung dobrak pintu depan sambil berteriak nama polisi',
            actionDetail: 'Menyerbu tanpa perlindungan di sarang bersenjata',
            feedback:
                'Anak buah Viktor melempar karung gula seberat 50kg ke arahmu! Kamu tertimpa dan terluka 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Hancurkan Bos Viktor',
        location: 'Ruang Mesin Pabrik Gula Tua - Pukul 09.15 WIB',
        narrative:
            'Bos Viktor mencabut pistol revolver dan mengarahkannya ke arahmu sambil menggenggam buku catatan resep kaldu bebek Pak Pale!',
        speakerName: 'Bos Viktor',
        speakerRole: 'Mafia Kuliner Malam',
        speakerAvatar: '🤵',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Bos Viktor "Mafia Malam"',
          role: 'Penculik Berdarah Dingin',
          avatar: '🤵',
          quote: 'Resep bakmi nyemek ini akan menjadi tambang uang bagi kelompokku! Kau tidak akan pernah keluar hidup-hidup dari pabrik ini!',
          maxHp: 120,
          weakPoints: ['Akta Perampasan Palsu', 'Buku Resep Kaldu Bebek'],
          imageAsset: 'assets/images/boss_chapter_2.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tembak tuas katrol rantai derek tepat di atas kepala Viktor!',
            actionDetail: 'Menjatuhkan rantai derek baja untuk melumpuhkan senjata api',
            feedback:
                'CRITICAL IMPACT! Rantai baja menghantam tangan Viktor, revolvernya terlempar jauh ke saluran tetes tebu!',
            isCorrect: true,
            bossDamage: 65,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Maju menghadang peluru pistol dengan tangan kosong',
            actionDetail: 'Tindakan bunuh diri melawan senjata api',
            feedback:
                'Peluru menyerempet lengan kirimu! Darah mengucur dan kamu kehilangan 1 nyawa berharga!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'REBUT KEMBALI BUKU RESEP PUSAKA',
        location: 'Ruang Mesin Madukismo - Pukul 09.30 WIB',
        narrative:
            'Viktor yang terluka mencoba membakar buku resep kaldu bebek dengan pemantik zippo!',
        speakerName: 'Bos Viktor',
        speakerRole: 'Mafia Nekat',
        speakerAvatar: '🤵',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Bos Viktor',
          role: 'Boss Terpojok',
          avatar: '🤵',
          quote: 'Kalau aku tidak dapat resep ini, kalian juga tidak boleh memilikinya!',
          maxHp: 55,
          weakPoints: ['Pemantik Api'],
          imageAsset: 'assets/images/boss_chapter_2.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Semprotkan tabung pemadam api busa tepat ke arah tangan dan pemantiknya!',
            actionDetail: 'Memadamkan api seketika dan mengamankan buku kuno',
            feedback:
                'PERFECT FINISH! Api padam total, buku resep terselamatkan utuh tanpa terbakar sedikitpun, dan Viktor diringkus tim Brimob!',
            isCorrect: true,
            bossDamage: 65,
          ),
          SceneChoice(
            text: 'Coba tiup api dari kejauhan',
            actionDetail: 'Tindakan konyol memadamkan api besar dengan tiupan mulut',
            feedback:
                'Halaman sampul buku sempat terbakar hangus dan jarimu melepuh!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS SELESAI: Aroma Nyemek Alun-Alun Utara Kembali Mengepul',
      narrative:
          'Pak Pale berhasil diselamatkan tanpa luka berarti. Seluruh sindikat mafia malam digulung tuntas ke meja hijau.\n\nMalam harinya di bawah langit beringin kembar Alun-alun Utara, wajan arang kembali mendidih dengan kuah nyemek telur bebek gurih keemasan. Pak Pale menyematkan Mangkuk Tembaga Kraton di sertifikat investigasimu!',
      epilogue: 'Malam di jantung kota Yogyakarta kembali aman dan penuh kenikmatan rasa.',
      badgeName: 'Penyelamat Maestro Alun-Alun 🍲',
      rewardPoints: 700,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Hilangnya Resep Warisan Selamanya',
      narrative:
          'Buku resep terbakar hangus dan Pak Pale trauma berat untuk memasak kembali. Gerobak legendaris di Alun-alun Utara tutup permanen.',
      epilogue: 'Satu lagi warisan kuliner tak ternilai hilang dari peradaban kota.',
      badgeName: 'Resep Hangus 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 9: NASI PECEL BU WIRYO (Agro UGM 1959) - SULIT
  // =========================================================================
  const DetectiveCase(
    level: 9,
    id: 'case_pecel_bu_wiryo',
    title: 'Racun Jamur Bumbu Kacang Agro UGM',
    subtitle: 'Kontaminasi aflatoksin sengaja pada stok kacang tanah sangrai legendaris',
    location: 'Kawasan Lembah Agro UGM, Bulaksumur, Sleman',
    targetRestaurant: 'Warung Nasi Pecel Bu Wiryo 1959',
    suspectName: 'Dr. Aris "Ahli Biokimia Pangan Ilegal"',
    difficulty: CaseDifficulty.sulit,
    baseReward: 750,
    iconEmoji: '🥜',
    synopsis:
        'Bumbu pecel kacang kental siraman hangat Bu Wiryo yang terkenal sejak 1959 mendadak terkontaminasi jamur beracun Aspergillus flavus penghasil aflatoksin mematikan. Seorang ilmuwan pangan yang dipecat kampus berusaha memfitnah warung legendaris tempat mahasiswa berkumpul.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Analisis Laboratorium Bumbu Kacang',
        location: 'Warung Pecel Bu Wiryo Bulaksumur - Pukul 07.30 WIB',
        narrative:
            'Di meja penyajian bumbu kacang encer hangat beraroma daun jeruk, beberapa piring pecel ditolak pengunjung karena terasa pahit metalik dan membuat pusing seketika.',
        speakerName: 'Bu Wiryo',
        speakerRole: 'Penerus Resep 1959',
        speakerAvatar: '👵',
        choices: [
          SceneChoice(
            text: 'Uji sampel kacang sangrai dengan lampu ultraviolet (UV Blacklight)',
            actionDetail: 'Mendeteksi pendaran fluoresensi racun aflatoksin jamur',
            feedback:
                'Fluoresensi hijau neon berpendar di bawah sinar UV! Ini membuktikan spora jamur aflatoksin murni sengaja disemprotkan ke karung kacang sangrai!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_pendaran_uv',
              title: 'Pendaran Jamur Aflatoksin UV',
              description: 'Bukti spora racun mikotoksin yang disemprotkan secara laboratoris pada kacang tanah.',
              icon: Icons.lightbulb_circle_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Makan sepiring nasi pecel komplit dengan empal untuk membuktikan racun',
            actionDetail: 'Mengkonsumsi makanan yang terindikasi racun aflatoksin',
            feedback:
                'Tubuhmu demam tinggi dan penglihatanmu mengabur! Kamu kehilangan 1 nyawa dan harus minum air kelapa netralisir!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Pengintaian Laboratorium Liar Sekitar Selokan Mataram',
        location: 'Gedung Inkubator Riset Terbengkalai - Pukul 10.00 WIB',
        narrative:
            'Di sebuah laboratorium sewa dekat Selokan Mataram, Dr. Aris sedang membiakkan kultur jamur beracun dalam botol-botol biakan agar-agar.',
        speakerName: 'Detektif (Kamu)',
        speakerRole: 'Menyusup',
        speakerAvatar: '🕵️',
        choices: [
          SceneChoice(
            text: 'Fotokopi catatan log inkubasi jamur dan botol semprot aerosil',
            actionDetail: 'Mengumpulkan bukti scientific tampering racun pangan',
            feedback:
                'Bukti laboratorium sangat telak! Tercantum tanggal penyemprotan karung kacang gudang Bu Wiryo!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_log_inkubasi',
              title: 'Log Biakan Jamur Dr. Aris',
              description: 'Catatan ilmiah sabotase biokimia pangan yang ditandatangani pelaku.',
              icon: Icons.biotech_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Sentuh cawan petri biakan jamur beracun tanpa sarung tangan lateks',
            actionDetail: 'Menyentuh agen biologi berbahaya secara langsung',
            feedback:
                'Spora masuk ke pori-pori kulitmu dan menyebabkan gatal membakar! Kamu kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Bungkam Dr. Aris di Laboratorium',
        location: 'Ruang Sterilisasi Inkubator - Pukul 11.00 WIB',
        narrative:
            'Dr. Aris memegang labu erlenmeyer berisi asam pekat dan mengancam akan menyiramkannya jika kamu berani melangkah maju!',
        speakerName: 'Dr. Aris',
        speakerRole: 'Ahli Biokimia Jahat',
        speakerAvatar: '👨‍🔬',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Dr. Aris "Si Ahli Kimia"',
          role: 'Pelaku Bioteror Pangan',
          avatar: '👨‍🔬',
          quote: 'Kampus ini menolak penelitianku! Maka akan kutunjukkan pada mereka bahwa kuliner kebanggaan mereka bisa kuhancurkan dalam semalam!',
          maxHp: 120,
          weakPoints: ['Log Biakan Jamur', 'Pendaran UV Aflatoksin'],
          imageAsset: 'assets/images/boss_chapter_2.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tunjukkan hasil uji UV fluoresensi dan surat penahanan dari Polda DIY!',
            actionDetail: 'Menghancurkan legitimasi akademisnya dengan bukti forensik',
            feedback:
                'CRITICAL DAMAGE! Dr. Aris terpaku gemetar saat tahu kejahatannya terbukti secara metodologi ilmiah tak terbantahkan!',
            isCorrect: true,
            bossDamage: 65,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Debat teori biologi tanpa menunjukkan bukti fisik',
            actionDetail: 'Berdebat omong kosong dengan profesor gila',
            feedback:
                'Dr. Aris menyiramkan cairan asam ke mejamu! Percikan asam mengenai bajumu dan melukaimu!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'AMANKAN LABU ASAM BERBAHAYA',
        location: 'Ruang Sterilisasi - Pukul 11.20 WIB',
        narrative:
            'Dr. Aris hendak membanting labu erlenmeyer berisi cairan asam ke saluran pembuangan agar bukti musnah!',
        speakerName: 'Dr. Aris',
        speakerRole: 'Tersangka Kalap',
        speakerAvatar: '👨‍🔬',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Dr. Aris',
          role: 'Boss Terpojok',
          avatar: '👨‍🔬',
          quote: 'Jangan sentuh cawan risetku!',
          maxHp: 55,
          weakPoints: ['Labu Erlenmeyer'],
          imageAsset: 'assets/images/boss_chapter_2.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Gunakan penjepit kimia isolasi untuk merebut labu erlenmeyer dan dorong Dr. Aris ke ruang dekontaminasi!',
            actionDetail: 'Prosedur pengamanan zat berbahaya standar laboratorium',
            feedback:
                'KNOCKOUT! Zat berbahaya terkunci aman di kotak isolasi, Dr. Aris terkunci di ruang dekontaminasi sampai polisi tiba!',
            isCorrect: true,
            bossDamage: 65,
          ),
          SceneChoice(
            text: 'Tangkap botol asam yang melayang dengan baju kaosmu',
            actionDetail: 'Menadah zat korosif dengan kain tipis',
            feedback:
                'Kain bajumu tembus terbakar asam dan kulitmu melepuh! Kecerobohan fatal!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS SELESAI: Gurih Manis Pecel Bu Wiryo Kembali Segar',
      narrative:
          'Seluruh karung kacang yang terkontaminasi dimusnahkan di insinerator limbah medis. Bu Wiryo mendatangkan kacang tanah tuban segar bersertifikat bebas racun.\n\nKawasan Agro UGM kembali dipenuhi gelak tawa mahasiswa dan dosen yang menikmati sarapan nasi pecel legendaris dengan kuah kacang gurih pedas manis yang sempurna. Bu Wiryo memberimu Cobek Kayu Jati 1959!',
      epilogue: 'Keamanan pangan ribuan mahasiswa dan akademisi Yogyakarta terselamatkan.',
      badgeName: 'Benteng Pangan Bulaksumur 🥜',
      rewardPoints: 750,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Keracunan Massal di Kampus',
      narrative:
          'Kamu gagal membuktikan sabotase tepat waktu. Puluhan mahasiswa dilarikan ke rumah sakit dan warung pecel bersejarah sejak 1959 itu disegel aparat.',
      epilogue: 'Nama baikmu di kalangan akademisi runtuh seketika.',
      badgeName: 'Kacang Beracun 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 10: TENGKLENG GAJAH (Kaliurang Km 9.3) - SULIT [CHECKPOINT 2]
  // =========================================================================
  const DetectiveCase(
    level: 10,
    id: 'case_tengkleng_gajah',
    title: 'Skandal Balungan Oplosan Kaliurang',
    subtitle: 'Penyelundupan balungan ternak bangkai berbahaya ke kuali jumbo tengkleng gajah',
    location: 'Jl. Kaliurang Km 9.3, Sleman, Yogyakarta',
    targetRestaurant: 'Tengkleng Gajah Bu Hj. Bejo',
    suspectName: 'Juragan Tejo "Raja Balungan Gelap"',
    difficulty: CaseDifficulty.sulit,
    baseReward: 850,
    iconEmoji: '🍖',
    synopsis:
        'Porsi jumbo balungan kambing tengkleng gajah yang terkenal dengan sumsum gurih melimpah disabotase dengan tulang ternak busuk yang mengandung bakteri antraks mati. Juragan Tejo ingin menjatuhkan warung agar rumah pemotongan hewan miliknya menguasai seluruh Bantul dan Sleman.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Pemeriksaan Kuali Balungan Raksasa',
        location: 'Pawon Kuali Baja Tengkleng Gajah - Pukul 11.00 WIB',
        narrative:
            'Di atas tungku api besar, kuah gulai tengkleng mendidih bergolak. Namun sumsum tulang yang disedot mengeluarkan bau anyir busuk dan cairan kehitaman.',
        speakerName: 'Bu Hj. Bejo',
        speakerRole: 'Pemilik Tengkleng Gajah',
        speakerAvatar: '🧕',
        choices: [
          SceneChoice(
            text: 'Gunakan bor tulang mikro untuk mengambil sampel sumsum kehitaman',
            actionDetail: 'Menguji keberadaan toksin dan bakteri patogen bangkai',
            feedback:
                'Analisis jitu! Sumsum tersebut berasal dari ternak mati kemarin yang sengaja dicampur ke pengiriman balungan segar pagi tadi!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_sumsum_busuk',
              title: 'Sampel Sumsum Tulang Gelap',
              description: 'Tulang kambing bangkai oplosan dengan kandungan bakteri berbahaya.',
              icon: Icons.coronavirus_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Sedot sumsum tulang itu dengan sedotan bambu',
            actionDetail: 'Mencoba menguji rasa sumsum busuk secara langsung',
            feedback:
                'Bakteri racun seketika membuatmu muntah hebat dan pingsan! Kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penggerebekan Cold Storage Ilegal Kaliurang',
        location: 'Gudang Es Tersembunyi Kaliurang Atas - Pukul 13.00 WIB',
        narrative:
            'Di gudang berpendingin gelap di kaki bukit, puluhan ton tulang ternak tak bersertifikat tersusun dalam karung bertuliskan "RPA Gelap Tejo". Juragan Tejo sedang mengawasi truk pengantar.',
        speakerName: 'Juragan Tejo',
        speakerRole: 'Tengkulak Daging Ilegal',
        speakerAvatar: '🧔',
        choices: [
          SceneChoice(
            text: 'Temukan buku manifes pengiriman palsu di kantor pos satpam gudang',
            actionDetail: 'Mencari catatan nomor polisi truk pengirim tulang bangkai ke resto',
            feedback:
                'Bukti nomor polisi truk pengantar tepat identik dengan rekaman CCTV dapur Tengkleng Gajah pagi tadi!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_manifes_truk',
              title: 'Buku Manifes Truk Oplosan',
              description: 'Catatan pengiriman tulang kambing tanpa surat karantina hewan ke resto-resto Sleman.',
              icon: Icons.local_shipping_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Matikan generator listrik cold storage tanpa persiapan',
            actionDetail: 'Mencoba membuat gudang mati lampu',
            feedback:
                'Korsleting listrik menyengat tanganmu! Kamu terkejut hebat dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Bekuk Juragan Tejo di Ruang Es',
        location: 'Ruang Beku Cold Storage - Pukul 14.00 WIB',
        narrative:
            'Di tengah balok es dan uap beku -15 derajat celcius, Juragan Tejo mencabut kapak jagal raksasa dan menantangmu!',
        speakerName: 'Juragan Tejo',
        speakerRole: 'Raja Balungan Gelap',
        speakerAvatar: '🧔',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Juragan Tejo "Raja Oplosan"',
          role: 'Mafia Daging & Tulang',
          avatar: '🧔',
          quote: 'Restoran itu menolak membeli balungan dariku! Sekarang lihat, reputasi mereka akan hancur dan mereka akan mengemis pasokan dari tanganku!',
          maxHp: 130,
          weakPoints: ['Manifes Truk Oplosan', 'Sampel Sumsum Bakteri'],
          imageAsset: 'assets/images/boss_chapter_2.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Banting bukti Manifes Pengiriman dan Hasil Uji Karantina Hewan ke depan mukanya!',
            actionDetail: 'Menunjukkan bukti pelanggaran undang-undang peternakan & karantina nasional',
            feedback:
                'CRITICAL DAMAGE! Juragan Tejo terhenyak melihat stempel resmi kepolisian dan karantina hewan!',
            isCorrect: true,
            bossDamage: 70,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Tantang dia adu kuat membongkar balok es besar',
            actionDetail: 'Tindakan sia-sia yang menghabiskan stamina',
            feedback:
                'Kapak jagal Tejo memecahkan balok es dan serpihannya melukai keningmu!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'KUNCI JURAGAN TEJO DI RUANG ISOLASI',
        location: 'Ruang Pembongkaran Daging - Pukul 14.20 WIB',
        narrative:
            'Tejo mengayunkan kapak jagalnya membabi buta mencoba menerobos pintu keluar darurat!',
        speakerName: 'Juragan Tejo',
        speakerRole: 'Tersangka Mengamuk',
        speakerAvatar: '🧔',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Juragan Tejo',
          role: 'Boss Terpojok',
          avatar: '🧔',
          quote: 'Jangan berani halangi jalanku!',
          maxHp: 60,
          weakPoints: ['Kapak Jagal'],
          imageAsset: 'assets/images/boss_chapter_2.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Gunakan tongkat kejut listrik detektif pada kapak logamnya dan gembok pintu keluar dari luar!',
            actionDetail: 'Melumpuhkan senjata logam dengan arus listrik',
            feedback:
                'KNOCKOUT! Arus listrik melumpuhkan otot lengannya, kapak terjatuh, dan Tejo terkurung di ruang isolasi sampai tim Reskrim tiba!',
            isCorrect: true,
            bossDamage: 70,
          ),
          SceneChoice(
            text: 'Lompat ke punggungnya untuk mencekiknya',
            actionDetail: 'Menyerang tersangka berbadan gempal dari belakang tanpa pelindung',
            feedback:
                'Tejo membantingmu ke lantai beku dengan keras! Punggungmu memar parah!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'CHECKPOINT 2 TERCAPAI: Sumsum Gurih Gajah Kembali Menggelegar',
      narrative:
          'Seluruh gudang oplosan disita dan dimusnahkan. Kuali raksasa Tengkleng Gajah dibersihkan total dan diisi kembali dengan balungan kambing muda segar bersertifikat sehat dari peternakan terpercaya.\n\nAroma rempah kuah gulai dan tengkleng goreng kembali semerbak memikat ratusan pelancong di jalan Kaliurang. Bu Hj. Bejo menyematkan Piagam Balungan Emas untukmu! SELAMAT, KAMU MENCAPAI CHECKPOINT 2 KAMPANYE DETEKTIF!',
      epilogue: 'Progres permainanmu tersimpan kokoh di Checkpoint Level 10.',
      badgeName: 'Penakluk Balungan Gajah 🍖 [CHECKPOINT 2]',
      rewardPoints: 850,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Skandal Daging Mengguncang Kaliurang',
      narrative:
          'Berita daging oplosan merebak liar tanpa penangkapan dalang. Restoran-restoran legendaris di sepanjang Kaliurang sepi pengunjung dan mengalami kerugian miliaran rupiah.',
      epilogue: 'Kamu gagal mengungkap mafia daging terbesar di lereng gunung.',
      badgeName: 'Tulang Busuk 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 11: ES DAWET (Ibu Titi Pasar Ngasem) - SULIT
  // =========================================================================
  const DetectiveCase(
    level: 11,
    id: 'case_es_dawet',
    title: 'Misteri Pewarna Tekstil Cendol Pandan Kraton',
    subtitle: 'Zat kimia hijau metanil beracun yang diselundupkan ke dalam juruh cendol segar',
    location: 'Pasar Burung Ngasem & Tamansari, Kraton Yogyakarta',
    targetRestaurant: 'Es Dawet Ibu Titi',
    suspectName: 'Madam Siska "Ratu Kosmetik Beracun"',
    difficulty: CaseDifficulty.sulit,
    baseReward: 900,
    iconEmoji: '🍧',
    synopsis:
        'Cendol hijau pandan suji yang kenyal segar di warung Es Dawet Ibu Titi mendadak berubah warna menjadi hijau menyala terang benderang dengan rasa pahit getir. Beberapa turis asing mengalami ruam kulit dan muntah darah setelah mencicipinya.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Olah TKP Gentong Tanah Liat Dawet',
        location: 'Kios Es Dawet Pasar Ngasem - Pukul 10.30 WIB',
        narrative:
            'Di dalam gentong tanah liat pendingin dawet, butiran cendol pandan mengapung dengan warna hijau neon tidak wajar. Juruh gula kelapa aren berbusa asam.',
        speakerName: 'Ibu Titi',
        speakerRole: 'Pembuat Dawet Alami',
        speakerAvatar: '👵',
        choices: [
          SceneChoice(
            text: 'Teteskan larutan klorin dan asam cuka ke butiran cendol',
            actionDetail: 'Reaksi kimia untuk menguji zat pewarna tekstil Fast Green / Malachite Green',
            feedback:
                'Reaksi positif instan! Warna hijau tidak memudar sama sekali, membuktikan ini pewarna cat kain tekstil sintetis berbahaya!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_pewarna_tekstil',
              title: 'Zat Hijau Metanil Tekstil',
              description: 'Pewarna kain sintetis non-pangan berkadar karsinogenik tinggi yang diselundupkan ke adonan cendol.',
              icon: Icons.colorize_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Teguk segelas es dawet hijau neon itu sampai habis',
            actionDetail: 'Menenggak racun pewarna tekstil',
            feedback:
                'Kerongkonganmu membengkak parah dan napasmu tersengal-sengal! Kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Pelacakan ke Toko Pewarna Tamansari',
        location: 'Lorong Bawah Tanah Tamansari - Pukul 12.00 WIB',
        narrative:
            'Di lorong sunyi dekat pemandian air Tamansari, Madam Siska terlihat sedang membuang botol-botol kaleng bekas pewarna kimia ke sumur tua.',
        speakerName: 'Madam Siska',
        speakerRole: 'Penyelundup Zat Kimia Tekstil',
        speakerAvatar: '💃',
        choices: [
          SceneChoice(
            text: 'Tangkap botol kaleng yang hendak dibuang dengan kait teleskopik',
            actionDetail: 'Menyelamatkan bukti fisik berlabel pabrik pewarna kain',
            feedback:
                'Bukti nomor batch pabrik tekstil berhasil diamankan utuh sebelum menyentuh dasar sumur!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_kaleng_pewarna',
              title: 'Kaleng Pewarna Tekstil Tamansari',
              description: 'Kaleng kimia beracun dengan sidik jari Madam Siska yang identik di gentong Ibu Titi.',
              icon: Icons.sanitizer_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Lompat langsung ke dalam sumur tua untuk mengambil botol',
            actionDetail: 'Melompat ke sumur berbahaya sedalam 10 meter',
            feedback:
                'Kamu terjebak di air sumur yang kotor dan dingin! Kakimu terkilir dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Hadapi Madam Siska di Pemandian',
        location: 'Pelataran Kolam Tamansari - Pukul 13.00 WIB',
        narrative:
            'Madam Siska berbalik dengan kipas bertatah duri racun beracun. Dia tersenyum angkuh di depan kolam peninggalan Sultan.',
        speakerName: 'Madam Siska',
        speakerRole: 'Ratu Kosmetik & Racun',
        speakerAvatar: '💃',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Madam Siska',
          role: 'Peracun Dawet Kraton',
          avatar: '💃',
          quote: 'Daun pandan dan suji itu merepotkan! Pewarna buatanku membuat cendol hijau berkilau abadi tanpa perlu memetik daun segar!',
          maxHp: 130,
          weakPoints: ['Kaleng Pewarna Tamansari', 'Zat Hijau Metanil Tekstil'],
          imageAsset: 'assets/images/boss_femme_fatale.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tunjukkan hasil uji Malachite Green dan botol kaleng berlabel sidik jarinya!',
            actionDetail: 'Membongkar alibi di hadapan petugas keamanan cagar budaya',
            feedback:
                'CRITICAL DAMAGE! Senyum sinis Madam Siska runtuh melihat bukti kaleng dengan sidik jari manisnya yang tercetak jelas!',
            isCorrect: true,
            bossDamage: 70,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Puji kecantikannya agar dia mau mengaku sukarela',
            actionDetail: 'Rayuan bodoh pada penjahat berbahaya',
            feedback:
                'Madam Siska menyabetkan kipas berdurinya ke lenganmu! Racun membuatmu lunglai 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'KUNCI MADAM SISKA DI GERBANG TAMANSARI',
        location: 'Gerbang Gapura Panggung Tamansari - Pukul 13.20 WIB',
        narrative:
            'Madam Siska berlari ke tangga panggung atas hendak menyebarkan bubuk racun ke kolam pemandian umum!',
        speakerName: 'Madam Siska',
        speakerRole: 'Dalang Terdesak',
        speakerAvatar: '💃',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Madam Siska',
          role: 'Boss Tersudut',
          avatar: '💃',
          quote: 'Jangan sentuh gaun sutraku!',
          maxHp: 60,
          weakPoints: ['Kipas Berduri'],
          imageAsset: 'assets/images/boss_femme_fatale.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Gunakan semprotan air pemadam untuk merontokkan bubuk racun di tangannya dan borgol kedua tangannya!',
            actionDetail: 'Melumpuhkan bubuk kimia sebelum menyebar ke kolam',
            feedback:
                'KNOCKOUT! Bubuk racun larut tak berbahaya di lantai batu, kipas berduri disita, dan Madam Siska digiring ke tahanan wanita!',
            isCorrect: true,
            bossDamage: 70,
          ),
          SceneChoice(
            text: 'Tarik gaun sutranya dari bawah tangga',
            actionDetail: 'Menarik kain licin secara ceroboh',
            feedback:
                'Gaun terlepas dan dia menendang wajahmu dengan sepatu hak tingginya!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS SELESAI: Segar Harum Pandan Dawet Ngasem Berseri',
      narrative:
          'Gentong tanah liat dibersihkan dengan air perasan daun jeruk purut. Ibu Titi memeras kembali daun pandan suji segar dari kebun sendiri, menghasilkan butiran cendol lembut beraroma harum alami yang tiada tanding.\n\nPelancong di Pasar Ngasem kembali menyeruput es dawet durian yang manis creamy dan menyegarkan tenggorokan. Ibu Titi memberimu Cangkir Tempurung Dawet bertatah ukiran bunga melati!',
      epilogue: 'Keaslian minuman tradisional kraton tetap suci dari racun tekstil.',
      badgeName: 'Penjaga Kesegaran Ngasem 🍧',
      rewardPoints: 900,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Racun Kimia Menodai Tamansari',
      narrative:
          'Air kolam Tamansari dan kios dawet tercemar zat pewarna tekstil permanen. Seluruh sentra wisata Pasar Ngasem ditutup untuk investigasi forensik berbulan-bulan.',
      epilogue: 'Kamu gagal melindungi kebersihan mata air bersejarah.',
      badgeName: 'Cendol Keruh 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 12: AYAM GORENG MBAH CEMPLUNG (Kasihan Bantul) - SULIT
  // =========================================================================
  const DetectiveCase(
    level: 12,
    id: 'case_mbah_cemplung',
    title: 'Pencurian Kuali Tanah Liat 70 Tahun Bantul',
    subtitle: 'Sabotase wajan keramat penghasil kulit ayam super renyah resep leluhur',
    location: 'Sembungan, Bangunjiwo, Kasihan, Bantul',
    targetRestaurant: 'Ayam Goreng Mbah Cemplung',
    suspectName: 'Ki Suro "Dukun Kuali Pusaka"',
    difficulty: CaseDifficulty.sulit,
    baseReward: 950,
    iconEmoji: '🍗',
    synopsis:
        'Kuali tanah liat tebal berusia 70 tahun milik Mbah Cemplung yang digunakan untuk teknik cemplung ayam kampung minyak kelapa mendadak dicuri dari pawon tungku kayu. Tanpa kuali tanah liat penahan panas stabil ini, ayam goreng akan gosong di luar dan mentah berdarah di dalam.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'TKP Pawon Tungku Api Kasihan',
        location: 'Pawon Tungku Tanah Liat Mbah Cemplung - Pukul 03.30 WIB',
        narrative:
            'Di tengah dinginnya fajar desa Kasihan, abu tungku masih hangat membara. Wajan kuali tanah liat hitam berdiameter satu meter telah raib dari dudukan batu bata pawon.',
        speakerName: 'Cucu Mbah Cemplung',
        speakerRole: 'Penerus Ayam Goreng',
        speakerAvatar: '👨',
        choices: [
          SceneChoice(
            text: 'Periksa serpihan tanah liat dan abu tapak gerobak dorong di pintu pawon',
            actionDetail: 'Menganalisis tanah liat khas Kasongan yang menempel di lantai',
            feedback:
                'Serpihan tanah liat menunjukkan jejak pembuat gerabah Kasongan! Pelaku membawa kuali menggunakan gerobak beroda kayu jati menuju sentra gerabah!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_tanah_kasongan',
              title: 'Serpihan Tanah Liat Kasongan',
              description: 'Debu tanah liat merah berkarakteristik khusus desa gerabah Kasongan.',
              icon: Icons.grain_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Goreng ayam kampung menggunakan wajan teflon tipis biasa',
            actionDetail: 'Mencoba menggoreng tanpa kuali tanah liat',
            feedback:
                'Minyak meletup membakar tanganmu dan ayam gosong pahit! Kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penelusuran ke Pabrik Pembakaran Gerabah Kasongan',
        location: 'Tungku Pembakaran Raksasa Kasongan - Pukul 06.00 WIB',
        narrative:
            'Di dalam bengkel pembakaran gerabah gelap, kuali pusaka Mbah Cemplung disembunyikan di bawah tumpukan guci terakota. Ki Suro sedang menyiapkan dupa mantra klenik.',
        speakerName: 'Ki Suro',
        speakerRole: 'Dukun Pengumpul Pusaka',
        speakerAvatar: '🧙‍♂️',
        choices: [
          SceneChoice(
            text: 'Cocokkan cap tanda tangan ukir Mbah Cemplung tahun 1954 di bibir kuali',
            actionDetail: 'Membuktikan kepemilikan kuali bersejarah',
            feedback:
                'Cap ukir 1954 terbaca jelas di bawah sorotan lampu senter detektif! Bukti tak terbantahkan!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_cap_kuali_1954',
              title: 'Cap Ukir Kuali 1954',
              description: 'Tanda ukiran tangan Mbah Cemplung asli pada bibir tanah liat kuali.',
              icon: Icons.history_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Tendang dupa mantra Ki Suro sampai berserakan',
            actionDetail: 'Tindakan kasar memicu konfrontasi tanpa persiapan',
            feedback:
                'Asap dupa beracun mengenai matamu! Penglihatanmu buram dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Gagalkan Ki Suro di Tungku Pembakaran',
        location: 'Halaman Tungku Kasongan - Pukul 07.00 WIB',
        narrative:
            'Ki Suro mencabut keris luk sembilan dan mengancam akan menghancurkan kuali pusaka berkeping-keping dengan palu godam jika kamu berani merebutnya!',
        speakerName: 'Ki Suro',
        speakerRole: 'Dukun Kuali Pusaka',
        speakerAvatar: '🧙‍♂️',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Ki Suro "Dukun Kuali"',
          role: 'Pencuri Berbahaya',
          avatar: '🧙‍♂️',
          quote: 'Kuali ini menyerap minyak keberuntungan selama 70 tahun! Dengan kuali ini, aku bisa membuka pesugihan warung makan terkaya di tanah Jawa!',
          maxHp: 135,
          weakPoints: ['Cap Ukir Kuali 1954', 'Palu Godam'],
          imageAsset: 'assets/images/boss_chapter_3.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tembak palu godam di tangannya dengan tali lasso pelumpuh detektif!',
            actionDetail: 'Mencegah kehancuran kuali tanah liat pusaka',
            feedback:
                'CRITICAL SHOT! Palu godam terlempar jauh dari jangkauannya, kuali keramat aman dari ancaman kehancuran!',
            isCorrect: true,
            bossDamage: 70,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Maju menangkis keris dengan papan kayu rapuh',
            actionDetail: 'Menahan senjata tajam dengan kayu lapuk',
            feedback:
                'Keris menembus papan dan melukai pundakmu! Kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'LUMPUHKAN KI SURO DI TUNGKU TERAKOTA',
        location: 'Ruang Pembakaran Gerabah - Pukul 07.20 WIB',
        narrative:
            'Ki Suro yang terdesak hendak menyalakan blower gas pembakaran untuk membakar seisi bengkel!',
        speakerName: 'Ki Suro',
        speakerRole: 'Pelaku Kalap',
        speakerAvatar: '🧙‍♂️',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Ki Suro',
          role: 'Boss Tersudut',
          avatar: '🧙‍♂️',
          quote: 'Semua akan hangus bersamaku!',
          maxHp: 65,
          weakPoints: ['Selang Gas Blower'],
          imageAsset: 'assets/images/boss_chapter_3.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Putus regulator selang gas blower dan gulingkan drum air pembasuh ke arah kakinya!',
            actionDetail: 'Mencegah ledakan gas dan menjatuhkan tersangka',
            feedback:
                'KNOCKOUT! Ki Suro terpeleset di lantai tanah liat basah dan terkunci rapat dalam borgol baja!',
            isCorrect: true,
            bossDamage: 70,
          ),
          SceneChoice(
            text: 'Tarik selang gas yang menyembur api dengan tangan',
            actionDetail: 'Menyentuh api gas bersuhu tinggi',
            feedback:
                'Tanganmu terbakar parah dan api membakar jas detektifmu!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS SELESAI: Gurih Renyah Ayam Cemplung Mengudara Lagi',
      narrative:
          'Kuali tanah liat 70 tahun dibawa pulang dengan selamat ke dapur Kasihan beralaskan jerami empuk. Minyak kelapa murni kembali dituang ke dalam kuali yang mendidih stabil dengan kayu bakar.\n\nAyam kampung utuh dicemplungkan ke dalam wajan menghasilkan kulit yang garing renyah keemasan dan daging gurih beraroma bawang ketumbar yang tiada duanya. Keluarga Mbah Cemplung menyematkan Lencana Kuali Emas Bantul untukmu!',
      epilogue: 'Teknik memasak tradisional paling unik di Bantul berhasil diselamatkan.',
      badgeName: 'Penjaga Kuali Cemplung 🍗',
      rewardPoints: 950,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Pecahnya Kuali Pusaka Leluhur',
      narrative:
          'Kuali tanah liat pecah berkeping-keping dalam insiden ledakan gas. Ayam goreng Mbah Cemplung kehilangan alat masak terpentingnya yang tidak bisa digantikan oleh wajan modern.',
      epilogue: 'Warisan kuliner 70 tahun hancur berkeping-keping.',
      badgeName: 'Kuali Pecah 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 13: OLIVE FRIED CHICKEN (Gejayan) - MASTER
  // =========================================================================
  const DetectiveCase(
    level: 13,
    id: 'case_olive_chicken',
    title: 'Spionase Formula 12 Rempah Tepung Krispi',
    subtitle: 'Pencurian formula rahasia ayam krispi legendaris oleh agen korporasi cepat saji multinasional',
    location: 'Jl. Affandi Gejayan, Sleman, Yogyakarta',
    targetRestaurant: 'Olive Fried Chicken Gejayan',
    suspectName: 'Agent X "Spionase Korporasi Fastfood"',
    difficulty: CaseDifficulty.master,
    baseReward: 1000,
    iconEmoji: '🍟',
    synopsis:
        'Formula rahasia 12 bumbu rempah tepung krispi Olive yang dicintai jutaan mahasiswa Jogja berhasil diretas dan dicuri dari brankas pusat bumbu Gejayan oleh seorang mata-mata korporasi cepat saji multinasional. Mereka berniat mematenkan resep ini di luar negeri dan menuntut penutupan seluruh outlet lokal.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Olah TKP Brankas Pencampuran Bumbu',
        location: 'Ruang Rahasia Outlet Gejayan - Pukul 23.30 WIB',
        narrative:
            'Di ruang kedap udara tempat menakar tepung bumbu, pintu brankas titanium terbuka dengan teknik pembobolan digital canggih. Flashdisk master berisi takaran mikrogram 12 rempah telah lenyap.',
        speakerName: 'Kepala Racik Olive',
        speakerRole: 'Penjaga Resep Tepung',
        speakerAvatar: '👨‍🍳',
        choices: [
          SceneChoice(
            text: 'Periksa port USB brankas dengan pemindai cyber forensik detektif',
            actionDetail: 'Mengekstrak data log perangkat peretas yang tertinggal',
            feedback:
                'Alamat MAC perangkat peretas berhasil dilacak! Sinyal transmisi mengarah ke kamar hotel bintang lima di Jalan Kaliurang!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_log_hacker',
              title: 'Log Transmisi Data Agent X',
              description: 'Jejak digital transfer file formula tepung bumbu ke server bayangan di luar negeri.',
              icon: Icons.computer_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Tuduh kasir kasir yang masih menghitung uang setoran',
            actionDetail: 'Menuduh staf tanpa memahami teknologi peretasan digital',
            feedback:
                'Kasir tidak memiliki akses ke sistem digital brankas! Kamu membuang waktu dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penyusupan ke Kamar Suite Hotel Mewah',
        location: 'Penthouse Hotel Bintang Lima Sleman - Pukul 01.00 WIB',
        narrative:
            'Di kamar mewah yang remang-remang, kamu menemukan koper berpelindung sinyal EMP. Di layar laptop, progress bar upload file "Secret_Olive_Formula.enc" sudah mencapai 85%!',
        speakerName: 'Detektif (Kamu)',
        speakerRole: 'Mencegat',
        speakerAvatar: '🕵️',
        choices: [
          SceneChoice(
            text: 'Tancapkan USB pemutus sinyal jammer dan gagalkan upload data rahasia',
            actionDetail: 'Menghentikan transmisi formula ke server luar negeri',
            feedback:
                'Berhasil gemilang! Upload terputus seketika pada angka 99%, dan hard disk penyimpan data berhasil disita!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_harddisk_enkripsi',
              title: 'Harddisk Enkripsi Formula Olive',
              description: 'Harddisk militer milik Agent X yang berisi bukti kontrak pencurian resep senilai 2 juta dolar.',
              icon: Icons.memory_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Cabut kabel stopkontak listrik dinding secara kasar',
            actionDetail: 'Mengabaikan sistem baterai cadangan laptop militer',
            feedback:
                'Laptop menggunakan baterai internal anti-padam dan alarm keamanan kamar meraung! Kamu kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Hadapi Agent X di Helipad Atap Hotel',
        location: 'Helipad Rooftop Hotel Gejayan - Pukul 01.30 WIB',
        narrative:
            'Di atap gedung di bawah deru baling-baling helikopter pelarian, Agent X mengenakan setelan taktis hitam dan mencabut pistol stun gun tegangan tinggi!',
        speakerName: 'Agent X',
        speakerRole: 'Spionase Korporasi Asing',
        speakerAvatar: '🕴️',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Agent X "The Phantom Spion"',
          role: 'Agen Bayaran Korporasi',
          avatar: '🕴️',
          quote: 'Formula 12 rempah ini bernilai triliunan rupiah di pasar global! Restoran ayam lokal murah seperti ini tidak pantas memilikinya!',
          maxHp: 140,
          weakPoints: ['Harddisk Enkripsi', 'Log Transmisi Data'],
          imageAsset: 'assets/images/boss_chapter_3.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tembakkan EMP Disrupter ke arah helikopter dan paparkan bukti kontrak intelijen!',
            actionDetail: 'Melumpuhkan instrumen elektronik helikopter dan menyudutkan pelaku',
            feedback:
                'CRITICAL STRIKE! Helikopter terpaksa mendarat darurat di landasan dan Agent X kehilangan sarana pelariannya!',
            isCorrect: true,
            bossDamage: 75,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Coba rebut koper dengan melompat ke bilah baling-baling helikopter',
            actionDetail: 'Manuver bodoh mendekati baling-baling berputar',
            feedback:
                'Hembusan angin helikopter melemparmu ke lantai beton! Tulang rusukmu nyeri dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'LUMPUHKAN AGENT X DI TEPI ATAP GEDUNG',
        location: 'Helipad Rooftop - Pukul 01.45 WIB',
        narrative:
            'Agent X menodongkan senjata ke arah harddisk berniat menembaknya agar hancur bersama!',
        speakerName: 'Agent X',
        speakerRole: 'Agen Terdesak',
        speakerAvatar: '🕴️',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Agent X',
          role: 'Boss Terpojok',
          avatar: '🕴️',
          quote: 'Kalau aku tidak membawanya, tidak ada yang boleh memilikinya!',
          maxHp: 65,
          weakPoints: ['Stun Gun'],
          imageAsset: 'assets/images/boss_chapter_3.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Lakukan bantingan judo taktis dan borgol Agent X ke tiang lampu landasan!',
            actionDetail: 'Teknik bela diri jarak dekat melumpuhkan agen rahasia',
            feedback:
                'KNOCKOUT! Senjata terlempar ke jaring pengaman, Agent X terkapar tak berdaya, dan flashdisk formula kembali aman!',
            isCorrect: true,
            bossDamage: 75,
          ),
          SceneChoice(
            text: 'Bernegosiasi minta royalti 10%',
            actionDetail: 'Tindakan pengkhianatan integritas detektif',
            feedback:
                'Agent X menyetrum dadamu dengan pistol tegangan tinggi! Tubuhmu kejang!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS SELESAI: Ayam Krispi Kebanggaan Rakyat Terselamatkan',
      narrative:
          'Formula 12 rempah dikembalikan utuh ke brankas pusat bumbu Gejayan dengan pengamanan enkripsi ganda tingkat militer. Agent X dan jaringannya dituntut di pengadilan internasional atas spionase ekonomi.\n\nKeesokan paginya, seluruh cabang Olive kembali menyajikan ayam goreng tepung super renyah gurih dengan harga terjangkau bagi jutaan pelajar dan warga. Manajemen Olive menghadiahkan Kartu Makan Emas Seumur Hidup untuk sang Detektif!',
      epilogue: 'Kuliner penyelamat kantong mahasiswa Jogja tetap berdiri teguh.',
      badgeName: 'Pahlawan Krispi Gejayan 🍟',
      rewardPoints: 1000,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Formula Dipatenkan Asing',
      narrative:
          'Data formula terupload sempurna ke server luar negeri. Korporasi asing mendaftarkan hak paten dan menuntut jaringan ayam goreng lokal ditutup total.',
      epilogue: 'Salah satu simbol kuliner rakyat Jogja terampas oleh keserakahan korporasi.',
      badgeName: 'Resep Terampas 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 14: KLINIK KOPI (Kaliurang) - MASTER
  // =========================================================================
  const DetectiveCase(
    level: 14,
    id: 'case_klinik_kopi',
    title: 'Manipulasi Biji Kopi Langka Wamena Papua',
    subtitle: 'Penyelundupan sianida organik pada biji kopi micro-lot fermentasi anaerobik',
    location: 'Jl. Kaliurang Km 7.8, Ngaglik, Sleman',
    targetRestaurant: 'Klinik Kopi Kaliurang',
    suspectName: 'Mr. Black "Smuggler Kopi Ilegal"',
    difficulty: CaseDifficulty.master,
    baseReward: 1100,
    iconEmoji: '☕',
    synopsis:
        'Klinik Kopi yang terkenal dengan edukasi narasi kopi nusantara mendadak diancam teror mematikan. Biji kopi single origin Wamena Papua hasil kurasi langsung dari petani pedalaman dicemari senyawa glikosida sianida organik yang aktif saat diekstraksi suhu 93 derajat celcius. Target pembunuhan adalah juri festival kopi dunia.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Olah TKP Bar Seduh Manual V60',
        location: 'Meja Seduh Kayu Klinik Kopi - Pukul 15.00 WIB',
        narrative:
            'Aroma kopi arabika yang baru digiling mengeluarkan aroma bunga melati yang manis, namun setelah disiram air panas mendidih, tercium bau samar almond pahit yang sangat berbahaya.',
        speakerName: 'Mas Pepeng',
        speakerRole: 'Storyteller & Roaster',
        speakerAvatar: '🧔',
        choices: [
          SceneChoice(
            text: 'Gunakan kertas deteksi ion sianida pada tetesan filter pertama',
            actionDetail: 'Mengidentifikasi senyawa glikosida sianida mematikan',
            feedback:
                'Kertas uji langsung berubah menjadi biru prusia pekat! Terbukti ada zat sianida yang sengaja dilapisi pada kulit tanduk biji kopi sebelum disangrai!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_sianida_kopi',
              title: 'Tetesan Filter Sianida Prusia',
              description: 'Senyawa racun sianida organik yang dirancang membunuh penikmat kopi saat cangkir pertama diteguk.',
              icon: Icons.dangerous_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Cicipi hasil seduhan kopi dengan teknik slurping kencang',
            actionDetail: 'Menyeruput kopi yang terindikasi racun sianida',
            feedback:
                'Racun sianida langsung memblokir oksigen di darahmu! Kamu kejang hebat dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Pengintaian Roastery Gelap Selokan Mataram',
        location: 'Gudang Mesin Roasting Ilegal - Pukul 17.30 WIB',
        narrative:
            'Di gudang berisik mesin pemanggang kopi, Mr. Black sedang mengawasi proses penyemprotan larutan racun pada 50 toples kopi bertuliskan nama-nama juri festival internasional.',
        speakerName: 'Detektif (Kamu)',
        speakerRole: 'Menyusup',
        speakerAvatar: '🕵️',
        choices: [
          SceneChoice(
            text: 'Amankan daftar nama target pembunuhan dan tabung semprotan kimia',
            actionDetail: 'Menyita bukti konspirasi pembunuhan berencana',
            feedback:
                'Bukti sangat mengerikan! Mr. Black dibayar oleh sindikat pasar gelap untuk menyingkirkan juri agar biji kopi oplosannya memenangkan tender ekspor jutaan dolar!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_daftar_target',
              title: 'Daftar Target Juri Festival',
              description: 'Dokumen berdarah yang mencatat nama-nama ahli kopi dunia yang hendak diracuni.',
              icon: Icons.list_alt_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Buka pintu tungku pemanggang kopi yang sedang membara 220 derajat',
            actionDetail: 'Membuka tungku panas tanpa sarung tangan pemadam',
            feedback:
                'Semburan bara panas menyambar wajahmu! Kamu terluka bakar dan kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI: Hentikan Mr. Black di Atas Tumpukan Karung',
        location: 'Gudang Ekspedisi Kargo Kopi - Pukul 19.00 WIB',
        narrative:
            'Mr. Black berdiri di atas tumpukan karung goni sambil memegang detonator bom uap beracun!',
        speakerName: 'Mr. Black',
        speakerRole: 'Smuggler Kopi Sianida',
        speakerAvatar: '🕶️',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Mr. Black "The Poison Roaster"',
          role: 'Penyelundup & Pembunuh Bayaran',
          avatar: '🕶️',
          quote: 'Industri specialty coffee adalah ladang uang raksasa! Siapapun yang menghalangi kopi oplosanku harus mati dalam cangkir terakhir mereka!',
          maxHp: 145,
          weakPoints: ['Daftar Target Juri', 'Kertas Uji Sianida'],
          imageAsset: 'assets/images/boss_chapter_3.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Tunjukkan bukti Daftar Target Juri dan rekaman suara transaksinya dengan sindikat!',
            actionDetail: 'Membongkar jaringan konspirasi pasar gelap kopi',
            feedback:
                'CRITICAL DAMAGE! Mr. Black panik menyadari seluruh jaringan kargo gelapnya telah disergap Bea Cukai di pelabuhan!',
            isCorrect: true,
            bossDamage: 75,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Tawarkan uang tebusan agar dia membatalkan niatnya',
            actionDetail: 'Bernegosiasi finansial dengan pembunuh berdarah dingin',
            feedback:
                'Mr. Black tertawa sinis dan menembakkan peluru gas beracun ke arahmu!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'LUMPUHKAN DETONATOR RACUN',
        location: 'Gudang Kargo - Pukul 19.20 WIB',
        narrative:
            'Mr. Black hendak menekan tombol detonator untuk meledakkan tabung gas sianida!',
        speakerName: 'Mr. Black',
        speakerRole: 'Boss Terpojok',
        speakerAvatar: '🕶️',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Mr. Black',
          role: 'Buronan Internasional',
          avatar: '🕶️',
          quote: 'Semua harus mencium aroma kematian bersamaku!',
          maxHp: 70,
          weakPoints: ['Detonator'],
          imageAsset: 'assets/images/boss_chapter_3.jpg',
        ),
        choices: [
          SceneChoice(
            text: 'Lemparkan pisau pemotong karung tepat memutus kabel detonator dan terjang Mr. Black ke tumpukan karung kopi!',
            actionDetail: 'Memutus sambungan picu ledak secara presisi milimeter',
            feedback:
                'KNOCKOUT! Kabel detonator putus, bom gagal meledak, dan Mr. Black dilumpuhkan seketika oleh tim Gegana!',
            isCorrect: true,
            bossDamage: 80,
          ),
          SceneChoice(
            text: 'Lari keluar gudang meninggalkan bom',
            actionDetail: 'Meninggalkan area berpenduduk tanpa perlindungan',
            feedback:
                'Ledakan gas sempat bocor dan uap beracun meracuni dadamu!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS SELESAI: Kejujuran Rasa Kopi Nusantara Berjaya',
      narrative:
          'Seluruh toples beracun diamankan dan dimusnahkan oleh tim gegana biokimia. Mas Pepeng kembali menyangrai biji kopi Wamena Papua asli dengan profil seduh sempurna bernuansa floral aroma jeruk nipis dan madu hutan.\n\nFestival kopi internasional berlangsung sukses gilang gemilang dan kopi Indonesia dinobatkan sebagai biji kopi terbaik di dunia. Mas Pepeng memberimu Dripper Keramik V60 bertanda tangan seluruh petani kopi Wamena!',
      epilogue: 'Integritas dan nyawa para ahli rasa dunia terselamatkan oleh tangan dinginmu.',
      badgeName: 'Penjaga Jiwa Kopi Nusantara ☕',
      rewardPoints: 1100,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Tragedi Hitam Festival Kopi',
      narrative:
          'Bom gas meledak dan mencemari ribuan ton biji kopi Indonesia. Nama baik kopi nusantara hancur di mata dunia internasional selama beberapa dekade.',
      epilogue: 'Dunia kopi berkabung atas kegagalan analisismu.',
      badgeName: 'Cangkir Kematian 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // LEVEL 15: BALE RAOS KERATON & FINALE - MASTER [CHECKPOINT 3 / GRAND FINALE]
  // =========================================================================
  const DetectiveCase(
    level: 15,
    id: 'case_bale_raos_finale',
    title: 'Konspirasi Perjamuan Agung Sri Sultan & Runtuhnya Topeng Garam',
    subtitle: 'Kudeta rasa perjamuan diplomatik keraton dan penangkapan sang dalang utama sindikat kriminal',
    location: 'Bangsal Kencana Keraton & Resto Bale Raos Kraton Yogyakarta',
    targetRestaurant: 'Bale Raos Keraton',
    suspectName: 'Mastermind "Topeng Garam"',
    difficulty: CaseDifficulty.master,
    baseReward: 1500,
    iconEmoji: '👑',
    synopsis:
        'Puncak dari seluruh kejahatan di 14 level sebelumnya bermuara malam ini! Sang dalang misterius bergelar "Topeng Garam" merencanakan sabotase besar pada hidangan Bistik Jawa dan Bebek Suwar-Suwir kesukaan Sri Sultan di Bale Raos menjelang jamuan diplomatik Duta Besar Dunia. Seluruh biro investigasi mengandalkan intuisimu untuk membongkar identitas asli dan meruntuhkan sindikat ini selamanya!',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Inspeksi Meja Saji Bangsal Kencana',
        location: 'Dapur Ageng Bale Raos Keraton - Pukul 18.00 WIB',
        narrative:
            'Di bawah kemegahan ukiran emas Bangsal Kencana, piring-piring perak pusaka bertatah lambang Praja Cihna telah tersusun. Di dalam saus bistik pala Sri Sultan dan saus kedondong bebek, tercium desis kimiawi halus yang hampir tak terdeteksi.',
        speakerName: 'Abdi Dalem Wedana',
        speakerRole: 'Kepala Dapur Keraton',
        speakerAvatar: '🧓',
        choices: [
          SceneChoice(
            text: 'Teteskan reagen kristal garam murni peninggalan 14 kasus sebelumnya',
            actionDetail: 'Reagen gabungan seluruh barang bukti yang telah kamu kumpulkan',
            feedback:
                'REAKSI REVELASI EMAS! Saus bistik bereaksi mengeluarkan buih hitam keperakan bertanda lambang rahasia "Topeng Garam"! Seluruh jejak 14 kasus terhubung ke satu sosok!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_reagen_sindikat',
              title: 'Residu Kristal Sindikat Topeng Garam',
              description: 'Bukti pamungkas zat perusak rasa yang menghubungkan seluruh 15 kejahatan kuliner.',
              icon: Icons.auto_awesome_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Cicipi langsung sesendok saus bistik Sultan',
            actionDetail: 'Mencicipi hidangan perjamuan agung beracun',
            feedback:
                'Zat pelumpuh saraf langsung membuat tenggorokanmu kaku dan detak jantungmu melonjak! Kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penerobosan ke Menara Lonceng Rahasia Tamansari',
        location: 'Bawah Tanah Gerbang Gedhong Panggung - Pukul 19.30 WIB',
        narrative:
            'Jejak reagen membawamu ke ruang kubah bawah tanah kedap suara. Di sana, seorang sosok bertopeng porselen putih bertatahkan butiran kristal garam sedang memegang detonator pemusnah arsip resep keraton.',
        speakerName: 'Topeng Garam',
        speakerRole: 'Pemimpin Tertinggi Sindikat',
        speakerAvatar: '🎭',
        choices: [
          SceneChoice(
            text: 'Tembak kamera drone perekam dan sambungkan siaran langsung ke hadapan Sri Sultan & Kapolda!',
            actionDetail: 'Membuka tabir kejahatan langsung ke pengadilan tertinggi keraton',
            feedback:
                'Layar raksasa di ruang sidang keraton menyala menampilkan wajah dan suara Topeng Garam yang sedang mempersiapkan kudeta kuliner!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_siaran_langsung',
              title: 'Bukti Siaran Langsung Konspirasi',
              description: 'Rekaman pengakuan Topeng Garam yang disaksikan seluruh pembesar istana.',
              icon: Icons.videocam_rounded,
            ),
            nextSceneId: 'scene_boss_1',
          ),
          SceneChoice(
            text: 'Minta dia bernegosiasi secara empat mata tanpa saksi',
            actionDetail: 'Mencoba bernegosiasi dengan psikopat narsistik',
            feedback:
                'Topeng Garam menembakkan gas air mata kristal garam ke matamu! Kamu terhuyung kehilangan 1 nyawa!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: null,
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_1',
        title: 'KONFRONTASI TAHAP 1: Runtuhkan Doktrin & Gas Altar',
        location: 'Kubah Bawah Tanah Tamansari - Pukul 20.00 WIB',
        narrative:
            'Topeng Garam berdiri tegak di podium altar kristal garam sambil menyebarkan gas beracun ke seluruh ruangan, meremehkan warisan rasa Keraton.',
        speakerName: 'Topeng Garam',
        speakerRole: 'Tahap 1: Penguasa Sindikat',
        speakerAvatar: '🎭',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Topeng Garam',
          role: 'Tahap 1: Dalang Utama Sindikat',
          avatar: '🎭',
          quote:
              'Aku telah merusak gudeg Wijilan, mencemari kopi joss, memalsukan mangut lele, dan merampas jeruji klathak! Malam ini kuliner keraton akan tamat dan duniaku yang akan berkuasa!',
          maxHp: 100,
          weakPoints: ['Residu Kristal Sindikat', 'Bukti Siaran Langsung'],
          imageAsset: 'assets/images/boss_final_tamansari.jpg',
        ),
        choices: [
          SceneChoice(
            text:
                'Hantamkan Lencana Master Detektif dan sebarkan bubuk penawar resep murni ke udara altar!',
            actionDetail:
                'Menetralisir gas beracun menggunakan reagen kristal gabungan 14 kasus',
            feedback:
                'Deduksi tepat! Reagen murni menetralisir kabut racun seketika! Topeng Garam terbatuk kaget dan keangkuhan pertamanya runtuh!',
            isCorrect: true,
            bossDamage: 35,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Tantang adu pedang dengan tangan kosong tanpa menetralisir kabut gas',
            actionDetail: 'Maju menyerang secara fisik tanpa strategi deduksi',
            feedback:
                'Kabut racun membuat matamu perih dan sabetan pedang rapier dalang melukaimu! Kamu kehilangan 1 hati!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: null,
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'KONFRONTASI TAHAP 2: Lucuti Pedang Perak & Patahkan Serangan',
        location: 'Altar Bawah Tanah Tamansari - Pukul 20.15 WIB',
        narrative:
            'Melihat kabut racunnya gagal, Topeng Garam menggeram murka. Ia melompat dari altar dan menghunus pedang rapier perak beracun langsung ke arahmu!',
        speakerName: 'Topeng Garam',
        speakerRole: 'Tahap 2: Dalang Terdesak',
        speakerAvatar: '🎭',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Topeng Garam',
          role: 'Tahap 2: Dalang Terdesak',
          avatar: '🎭',
          quote:
              'Lancang sekali! Jangan kira kamu menang hanya karena kabut racunku netral! Pedang perak ini yang akan menguburmu di Tamansari!',
          maxHp: 100,
          weakPoints: ['Jeruji Klathak', 'Siaran Langsung'],
          imageAsset: 'assets/images/boss_final_tamansari.jpg',
        ),
        choices: [
          SceneChoice(
            text:
                'Tangkis ayunan pedang dengan jeruji sate klathak pusaka dan putar bukti siaran langsung ke hadapan pengawalnya!',
            actionDetail:
                'Mematahkan senjata fisik sekaligus meruntuhkan loyalitas para pengawal sindikat',
            feedback:
                'Dentang keras bergema! Pedang rapier perak patah terbelah dua dan para pengawal sindikat lari kocar-kacir melihat siaran langsung!',
            isCorrect: true,
            bossDamage: 35,
            nextSceneId: 'scene_boss_3',
          ),
          SceneChoice(
            text: 'Coba bujuk dia menyerahkan diri dengan tawaran negosiasi damai',
            actionDetail: 'Mencoba bernegosiasi dengan dalang yang sedang kalap',
            feedback:
                'Topeng Garam menepis ajakanmu dengan tendangan keras yang membenturkanmu ke pilar! Kamu kehilangan 1 hati!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: null,
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_3',
        title: 'KONFRONTASI TAHAP 3: Skakmat Pamungkas & Buka Topeng Kepalsuan',
        location: 'Altar Bawah Tanah Tamansari - Pukul 20.30 WIB',
        narrative:
            'Pedang patah dan pengawal kabur, Topeng Garam tersungkur di lantai altar. Dengan tangan gemetar penuh keputusasaan, ia meraih saklar detonator peledak untuk memusnahkan seluruh resep keraton!',
        speakerName: 'Topeng Garam',
        speakerRole: 'Tahap 3: Skakmat Terakhir',
        speakerAvatar: '🎭',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Topeng Garam',
          role: 'Tahap 3: Skakmat Terakhir',
          avatar: '🎭',
          quote:
              'Tidak... Rencanaku selama dua puluh tahun tidak boleh hancur di tanganmu! Jika aku binasa, seluruh warisan resep keraton ini harus musnah bersamaku!',
          maxHp: 100,
          weakPoints: ['Topeng Porselen', 'Detonator'],
          imageAsset: 'assets/images/boss_final_tamansari.jpg',
        ),
        choices: [
          SceneChoice(
            text:
                'Lepaskan tendangan sapuan presisi untuk merebut detonator dan remukkan topeng porselennya berkeping-keping!',
            actionDetail:
                'Melucuti ancaman peledak terakhir dan membuka identitas asli sang dalang di hadapan hukum',
            feedback:
                'SKAKMAT MUTLAK! Detonator berhasil diamankan! Topeng porselen hancur berkeping-keping, menyingkap wajah aslinya saat pasukan pengawal Keraton menyergapnya!',
            isCorrect: true,
            bossDamage: 60,
            nextSceneId: null,
          ),
          SceneChoice(
            text: 'Terpaku ragu mendengarkan ancaman gertakan terakhirnya',
            actionDetail: 'Ragu melangkah di detik-detik penentuan',
            feedback:
                'Percikan api pemicu sempat menyambar jasmu sebelum kamu sempat mundur! Kamu kehilangan 1 hati!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: null,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'TAMAT SEMPURNA: Kemenangan Agung Cita Rasa Mataraman',
      narrative:
          'Identitas Topeng Garam terbongkar tuntas! Dia adalah mantan juru masak istana yang dipecat puluhan tahun lalu karena keserakahan bisnis hitam. Seluruh sindikat dari Wijilan hingga Kaliurang dibongkar hingga ke akar-akarnya.\n\nDi Bangsal Kencana Bale Raos, Perjamuan Agung Diplomatik Keraton berlangsung dengan keagungan tiada tara. Sri Sultan Hamengku Buwono sendiri menyematkan Bintang Jasa Mahaputera Kuliner Nusantara di dadamu.\n\nNamamu tercatat abadi dalam lembaran babad sejarah Yogyakarta sebagai DETEKTIF KULINER LEGENDA SEPANJANG MASA!',
      epilogue: 'SELAMAT! KAMU TELAH MENAMATKAN SELURUH 15 KASUS DENGAN KEMENANGAN MUTLAK!',
      badgeName: 'Bintang Mahaputera Kuliner Nusantara 🏆👑🌟',
      rewardPoints: 2000,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Runtuhnya Martabat Jamuan Keraton',
      narrative:
          'Ledakan menghancurkan altar bawah tanah dan racun merusak seluruh jamuan diplomatik. Topeng Garam lolos ke laut selatan dan sejarah mencatat kegagalan terbesar detektif di tanah Jawa.',
      epilogue: 'Kamu gagal di langkah paling akhir. Bangkit dan ulangi dari Checkpoint 3!',
      badgeName: 'Mahkota Retak 💔',
      rewardPoints: 0,
    ),
  ),
];
