import 'package:flutter/material.dart';
import '../models/detective_case.dart';

final List<DetectiveCase> kDetectiveCases = [
  // =========================================================================
  // KASUS 1: WIJILAN
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
                'Salah langkah! Pelayan tersebut hanya panik karena kuali berasap. Sikap cerobohmu membuat dapur semakin kacau dan waktu terbuang sia-sia.',
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
            nextSceneId: 'scene_3',
          ),
          SceneChoice(
            text: 'Ancam akan menyegel kios Pak Darto tanpa menunjukkan bukti',
            actionDetail: 'Menggertak saksi secara agresif',
            feedback:
                'Gagal! Warga pasar berkerumun membelanya dan Pak Darto menutup mulut rapat-rapat. Kamu kehilangan wibawa dan fokus detektif.',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_3',
          ),
          SceneChoice(
            text: 'Periksa karung kluwek dan rempah kelapa di gudang',
            actionDetail: 'Memastikan stok bumbu pawon tidak terkontaminasi dari sumbernya',
            feedback:
                'Bumbu asli pasar terbukti murni. Ini membuktikan sabotase terjadi murni di dalam dapur pawon setelah bumbu tiba.',
            isCorrect: true,
            nextSceneId: 'scene_3',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_3',
        title: 'Penyusupan ke Restoran "Modern Taste"',
        location: 'Dapur Stainless Restoran Modern Taste - Pukul 11.30 WIB',
        narrative:
            'Dengan menyamar sebagai kurir bahan mentah, kamu menyelinap ke restoran megah milik Chef Hendra yang berada tepat di seberang gerbang Wijilan. Kamu mencium aroma krecek yang aneh dari ruang VIP.',
        speakerName: 'Detektif (Kamu)',
        speakerRole: 'Menyamar',
        speakerAvatar: '🕵️',
        choices: [
          SceneChoice(
            text: 'Geledah loker pribadi Chef Hendra di ruang koki utama',
            actionDetail: 'Mencari botol sisa cairan asam dan seragam berlumpur',
            feedback:
                'Berhasil gemilang! Di dalam loker, kamu menemukan sepasang boot berlumpur dengan tapak identik dan sebotol asam cuka berlabel laboratorium.',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_botol_loker',
              title: 'Botol Kimia & Boot Bersol Identik',
              description: 'Barang bukti fisik tak terbantahkan yang disimpan di loker sang Chef.',
              icon: Icons.inventory_2_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Cicipi langsung kuah krecek di meja prasmanan restoran',
            actionDetail: 'Mencicipi makanan yang diduga meniru resep Wijilan',
            feedback:
                'Uhuk! Krecek itu ternyata sengaja dibubuhi bubuk cabai sintetis ekstra pedas. Lidahmu mati rasa seketika dan konsentrasimu terganggu!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Rekam percakapan bisik-bisik Chef Hendra di telepon',
            actionDetail: 'Menggunakan mikrofon saku untuk mengumpulkan rekaman',
            feedback:
                'Terdengar jelas Chef Hendra berkata: "Biar saja gudeg mereka bau comberan sore ini, wartawan kuliner pasti lari ke tempatku!"',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_rekaman_telepon',
              title: 'Rekaman Suara Konspirasi',
              description: 'Suara Chef Hendra merencanakan kejatuhan warung Bu Djuminten.',
              icon: Icons.mic_external_on_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI AKHIR: Tuntaskan Chef Hendra',
        location: 'Ruang Tengah Restoran Modern Taste - Pukul 13.00 WIB',
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
          weakPoints: ['Faktur Toko Kimia', 'Boot Lumpur Identik', 'Rekaman Rencana'],
        ),
        choices: [
          SceneChoice(
            text: 'Banting Faktur Kimia & Hasil Uji Lakmus di atas mejanya!',
            actionDetail: 'Menunjukkan bukti transaksi asam cuka sintetis',
            feedback:
                'CRITICAL HIT! Wajah Chef Hendra memucat melihat namanya tertera jelas di faktur bahan kimia berbahaya!',
            isCorrect: true,
            bossDamage: 40,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Tuduh dia iri hati karena tidak pernah bisa membuat gudeg seenak Wijilan',
            actionDetail: 'Menyerang secara emosional tanpa bukti dokumen',
            feedback:
                'Chef Hendra tertawa terbahak-bahak: "Hanya hinaan murahan? Hukum butuh bukti hitam di atas putih, Detektif!" Kamu terpojok!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Tunjukkan foto sol boot berlumpur di dapur Bu Djuminten',
            actionDetail: 'Mencocokkan tanah liat di dapur kuno dengan sepatu Hendra',
            feedback:
                'SERANGAN TELAK! Hendra refleks menyembunyikan kakinya di bawah meja! Pertahanan mentalnya mulai runtuh!',
            isCorrect: true,
            bossDamage: 35,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'SKAKMAT: Pengakuan Chef Hendra',
        location: 'Ruang Tengah Restoran Modern Taste - Pukul 13.15 WIB',
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
          maxHp: 60,
          weakPoints: ['Rekaman Telepon Sabotase'],
        ),
        choices: [
          SceneChoice(
            text: 'Putar rekaman suara teleponnya di hadapan seluruh staf restoran!',
            actionDetail: 'Memperdengarkan bukti audio pengakuan niat jahatnya',
            feedback:
                'FATAL BLOW! Suara Hendra menggema di seluruh ruangan. Seluruh staf ternganga dan Hendra ambruk berlutut mengakui kejahatannya!',
            isCorrect: true,
            bossDamage: 70,
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
  // KASUS 2: KOPI JOSS TUGU
  // =========================================================================
  const DetectiveCase(
    level: 2,
    id: 'case_kopi_joss',
    title: 'Sabotase Bara Arang Kopi Joss Tugu',
    subtitle: 'Arang beracun yang meletup dan konspirasi monopoli angkringan Malioboro',
    location: 'Kawasan Stasiun Tugu & Lesehan Malioboro',
    targetRestaurant: 'Kopi Joss Lik Man',
    suspectName: 'Mbah Broto "Juragan Arang"',
    difficulty: CaseDifficulty.menengah,
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
                'Bau belerang tambang yang menyengat menusuk hidungmu! Ini jelas bukan arang kayu sengon alami yang biasa menyerap kafein.',
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
          SceneChoice(
            text: 'Periksa karung goni pasokan arang di gerobak Lik Man',
            actionDetail: 'Melihat cap stempel pada karung pengiriman arang',
            feedback:
                'Pada karung goni terdapat stempel merah pudar bertuliskan "Gudang Arang Broto - Pengok".',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_cap_gudang_broto',
              title: 'Cap Karung Gudang Broto',
              description: 'Identitas pemasok arang bermasalah yang berbasis di area stasiun barat.',
              icon: Icons.local_shipping_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penyelidikan di Bengkel Arang Stasiun',
        location: 'Gudang Kayu Pengok - Pukul 23.30 WIB',
        narrative:
            'Kamu berjalan di antara tumpukan kayu sengon dan tumpukan karung arang. Di sudut gelap, terdengar suara pekerja sedang mengaduk cairan kuning berbusa.',
        speakerName: 'Kuli Angkut',
        speakerRole: 'Saksi Kunci',
        speakerAvatar: '👷',
        choices: [
          SceneChoice(
            text: 'Ambil sampel cairan kuning dari ember sebelum pekerja kabur',
            actionDetail: 'Menyimpan cairan perekat belerang sebagai bukti lab',
            feedback:
                'Bahan terlarang! Itu adalah cairan limbah pabrik sulfur yang digunakan untuk merendam arang kualitas rendah agar tampak membara merah.',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_cairan_sulfur',
              title: 'Cairan Sulfur Perendam Briket',
              description: 'Zat kimia berbahaya yang dipakai Mbah Broto demi menghemat modal.',
              icon: Icons.liquor_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Berteriak menyuruh semua orang angkat tangan',
            actionDetail: 'Menggertak tanpa menutup jalur keluar',
            feedback:
                'Pekerja melempar ember abu ke arah matamu! Matamu perih terkena jelaga abu dan tersangka utama menyelinap pergi!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI BOS: Mbah Broto Juragan Arang',
        location: 'Kantor Rahasia Mbah Broto di Atas Gerbong Kereta Tua - Pukul 01.00 WIB',
        narrative:
            'Mbah Broto duduk bersila di atas tumpukan karung arang sambil menghisap rokok klobot. Dua anjing penjaga menggonggong liar di sampingnya.',
        speakerName: 'Mbah Broto',
        speakerRole: 'Juragan Monopoli Arang (Boss)',
        speakerAvatar: '🦹',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Mbah Broto "Si Juragan Bara"',
          role: 'Pemasok Arang Ilegal Malioboro',
          avatar: '🦹',
          quote:
              'Hahaha! Anak muda bau kencur mau mengajari aku soal arang? Kalau angkringan Lik Man tutup, semua pedagang terpaksa beli arang mahalku!',
          maxHp: 100,
          weakPoints: ['Sampel Sulfur', 'Cap Karung Pengok'],
        ),
        choices: [
          SceneChoice(
            text: 'Lempar sampel serbuk arang belerang dan cap karung gudangnya!',
            actionDetail: 'Menunjukkan kecocokan kimia antara gelas Lik Man dan gudang Broto',
            feedback:
                'TELAK! Mbah Broto tersentak: "Dari mana kamu dapat sampel itu?!" Pertahanan mentalnya goyah!',
            isCorrect: true,
            bossDamage: 50,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Klaim bahwa polisi sudah mengepung gerbong kereta',
            actionDetail: 'Melakukan gertakan bohong tanpa menunjukkan bukti',
            feedback:
                'Mbah Broto melirik ke luar jendela dan menyadari kamu hanya sendirian: "Bohong besar!" Dia melepaskan rantai anjingnya!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'BUNGKAM JURAGAN BARA',
        location: 'Pintu Gerbong Kereta Pengok',
        narrative:
            'Mbah Broto mencoba meraih obor minyak untuk membakar tumpukan karung dan memusnahkan bukti!',
        speakerName: 'Mbah Broto',
        speakerRole: 'Terpojok',
        speakerAvatar: '😡',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Mbah Broto',
          role: 'Boss',
          avatar: '😡',
          quote: 'Jangan mendekat atau kugosongkan tempat ini sekalian!',
          maxHp: 50,
          weakPoints: ['Cairan Sulfur'],
        ),
        choices: [
          SceneChoice(
            text: 'Siramkan air pasir ke obor dan pamerkan botol cairan sulfur pabrik!',
            actionDetail: 'Memadamkan ancaman api dan membuktikan kejahatan lingkungan',
            feedback:
                'SKAKMAT! Obor padam, aparat polisi stasiun menyerbu masuk dari pintu samping. Mbah Broto tertunduk lesu di atas abunya sendiri!',
            isCorrect: true,
            bossDamage: 60,
          ),
          SceneChoice(
            text: 'Maju menerjang obor api dengan tangan kosong',
            actionDetail: 'Tindakan gegabah tanpa perhitungan',
            feedback:
                'Bajumu terjilat api! Kamu bergulingan di tanah untuk memadamkan api dan menderita luka bakar ringan!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 10,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS TERPECAHKAN: Nyala Bara Murni Kopi Joss',
      narrative:
          'Gudang arang belerang disegel permanen. Lik Man kembali mendapatkan pasokan kayu sengon murni dari perbukitan Menoreh.\n\nMalam itu, cangkir kopi joss kembali berdesis syahdu diiringi petikan gitar pengamen Malioboro. Lik Man menyuguhkan kopi joss istimewa berkepul bara merah murni untuk sang Detektif.',
      epilogue: 'Kamu mengamankan sertifikat Arang Higienis Malioboro dan naik pangkat menjadi Detektif Madya!',
      badgeName: 'Penjaga Api Malioboro ☕',
      rewardPoints: 400,
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
  // KASUS 3: MERAPI COFFEE
  // =========================================================================
  const DetectiveCase(
    level: 3,
    id: 'case_merapi',
    title: 'Jeratan Kabut Kopi Arabika Merapi',
    subtitle: 'Pencurian biji kopi pusaka lereng gunung dan perburuan roastery bayangan',
    location: 'Perkebunan Kopi Vulkanik Kaliurang & Gua Jepang',
    targetRestaurant: 'Kopi Klothok Pakem',
    suspectName: 'Madam Vania "Ratu Kafe Bayangan"',
    difficulty: CaseDifficulty.menengah,
    baseReward: 450,
    iconEmoji: '🏔️',
    synopsis:
        'Kopi Yellow Caturra Merapi langka yang hanya dipanen 20 kg setahun mendadak raib dari lumbung petani tua Pakem. Beberapa hari kemudian, sebuah kafe mewah di pusat kota memamerkan menu kopi jutaan rupiah dengan klaim eksklusif palsu.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Misteri Lumbung Kopi Berkabut',
        location: 'Lumbung Kopi Tradisional Pakem - Pukul 05.30 WIB',
        narrative:
            'Hawa dingin menusuk tulang di kebun kopi lereng Merapi. Gembok lumbung terpotong rapi dengan cairan asam kimia. Karung biji kopi merah petik terpilih telah lenyap tak berbekas.',
        speakerName: 'Pak Karto',
        speakerRole: 'Petani Kopi Generasi Ketiga',
        speakerAvatar: '👴',
        choices: [
          SceneChoice(
            text: 'Periksa sisa kulit biji kopi di lantai lumbung dengan kaca pembesar',
            actionDetail: 'Mencari karakteristik biji kopi vulkanik yang tertinggal',
            feedback:
                'Petunjuk emas! Biji kopi Yellow Caturra memiliki guratan urat kuning cerah alami dengan aroma nangka matang yang tak bisa ditiru varietas biasa.',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_karakter_biji',
              title: 'Sampel Biji Yellow Caturra Murni',
              description: 'Ciri fisik biji kopi vulkanik dengan notes buah nangka dan keasaman sitrun segar.',
              icon: Icons.grain_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Tuduh monyet liar lereng Merapi yang mengambil karung kopi',
            actionDetail: 'Menyalahkan satwa liar tanpa memeriksa jejak gembok',
            feedback:
                'Monyet tidak membawa pemotong gembok dan mobil bak terbuka! Analisis ngawurmu membuat petani menggeleng kecewa.',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Lacak jejak ban mobil bak di tanah basah perkebunan',
            actionDetail: 'Mengukur cetakan ban kendaraan pelaku',
            feedback:
                'Jejak ban truk pendingin berstempel logo kafe elit "Vania Roastery Skyline" mengarah turun ke arah Kaliurang.',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_jejak_truk_vania',
              title: 'Cekungan Ban Truk Pendingin Vania',
              description: 'Jejak ban dengan serpihan abu vulkanik mengarah langsung ke kafe mewah tersangka.',
              icon: Icons.alt_route_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Blind Taste Test di Kafe Mewah Vania',
        location: 'Vania Luxury Coffee Lounge - Pukul 15.00 WIB',
        narrative:
            'Kamu menyamar sebagai pembeli kopi kaya raya dari luar negeri. Madam Vania dengan gaun sutra ungu menuangkan seduhan pour-over V60 di cangkir porselen seharga Rp500.000 per cangkir.',
        speakerName: 'Madam Vania',
        speakerRole: 'Kolektor Kafe Glamor',
        speakerAvatar: '💃',
        choices: [
          SceneChoice(
            text: 'Analisis aroma dan rasa kopi: Tebak aroma nangka & notes sulfur vulkanik',
            actionDetail: 'Melakukan cupping profesional untuk membuktikan asal biji kopi',
            feedback:
                'SKOR MAKSIMAL! Begitu kamu menyebut aroma nangka dan acidity vulkanik Pakem, cangkir di tangan Madam Vania bergetar hebat!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_blind_cupping',
              title: 'Bukti Rasa Cupping Identik',
              description: 'Profil rasa kopi yang disajikan 100% sama dengan biji yang dicuri dari Pak Karto.',
              icon: Icons.coffee_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Langsung siramkan kopi panas ke wajah Madam Vania',
            actionDetail: 'Tindakan kekerasan tanpa dasar hukum',
            feedback:
                'Pelanggaran etika berat! Satpam kafe membekukmu dan kamu terancam didepak dari kasus!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI BOS: Madam Vania',
        location: 'Ruang Roasting Rahasia Bawah Tanah Kafe Vania',
        narrative:
            'Di ruang mesin roasting modern buatan Jerman, karung-karung biji kopi Pak Karto sedang siap dikemas ulang dengan merek luar negeri.',
        speakerName: 'Madam Vania',
        speakerRole: 'Ratu Kafe Bayangan (Boss)',
        speakerAvatar: '💃',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Madam Vania "Ratu Kafe Bayangan"',
          role: 'Pencuri Hak Cipta Kopi Merapi',
          avatar: '💃',
          quote:
              'Petani tua itu tidak tahu cara menjual karyanya! Di tanganku, biji kopi ini jadi lambang gengsi para bangsawan! Mau apa kamu, Detektif?',
          maxHp: 100,
          weakPoints: ['Sampel Biji Asli', 'Cekungan Ban Truk', 'Bukti Blind Cupping'],
        ),
        choices: [
          SceneChoice(
            text: 'Sandingkan sampel biji mentah Pak Karto dengan karung di mesin roaster-nya!',
            actionDetail: 'Membuktikan nomor seri karung goni petani yang belum sempat diganti',
            feedback:
                'HANTAMAN DEDUKSI! Nomor seri karung jahitan tangan Pak Karto cocok sempurna! Madam Vania tak bisa berkutik!',
            isCorrect: true,
            bossDamage: 55,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Tawar untuk membeli seluruh kopi dengan uang saku detektif',
            actionDetail: 'Mencoba bernegosiasi dengan dana terbatas',
            feedback:
                'Madam Vania tertawa mencemooh: "Kamu kira aku butuh recehanmu?" Boss menyalakan alarm darurat!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'PENGAKUAN RATU BAYANGAN',
        location: 'Ruang Roasting Bawah Tanah',
        narrative:
            'Madam Vania terkunci di sudut mesin roasting. Satpamnya telah melarikan diri saat melihat tim patroli detektif tiba!',
        speakerName: 'Madam Vania',
        speakerRole: 'Tersangka Utama',
        speakerAvatar: '🥺',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Madam Vania',
          role: 'Boss',
          avatar: '🥺',
          quote: 'Tolong jangan hancurkan reputasiku... aku hanya ingin diakui di dunia barista internasional...',
          maxHp: 45,
          weakPoints: ['Cekungan Ban Truk'],
        ),
        choices: [
          SceneChoice(
            text: 'Tunjukkan surat penyitaan resmi atas nama Perlindungan Varietas Kopi Lereng Merapi!',
            actionDetail: 'Mengakhiri kasus secara bermartabat dan sah menurut hukum',
            feedback:
                'SEMPURNA! Madam Vania menyerahkan kunci brankas tempat sertifikat palsu disimpan. Kopi pusaka berhasil diselamatkan seutuhnya!',
            isCorrect: true,
            bossDamage: 60,
          ),
          SceneChoice(
            text: 'Rusak mesin roaster jutaan dolar miliknya sebagai balas dendam',
            actionDetail: 'Merusak barang bukti',
            feedback:
                'Tindakan itu mencoreng nama baik biro investigasi dan kamu mendapat peringatan keras!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 10,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS TERPECAHKAN: Kopi Pusaka Merapi Kembali ke Petani',
      narrative:
          'Seluruh karung biji kopi Yellow Caturra dikembalikan kepada Pak Karto. Kafe Vania didenda dan diwajibkan bermitra adil dengan petani lokal.\n\nDi serambi kayu Pakem yang teduh, Pak Karto menyeduhkan cangkir kopi pertama hasil panen yang selamat, ditemani pisang goreng hangat bertabur gula semut aren.',
      epilogue: 'Kamu dianugerahi Cangkir Keramik Merapi dan dipromosikan menjadi Detektif Rasa Utama!',
      badgeName: 'Penjaga Kopi Vulkanik 🏔️',
      rewardPoints: 500,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Monopoli Kafe Bayangan Berjaya',
      narrative:
          'Madam Vania berhasil mengekspor seluruh kopi ke luar negeri sebelum kamu sempat menyegelnya. Petani tua itu meratapi panen setahun yang hilang tanpa kompensasi.',
      epilogue: 'Rasa pahit ini bukan dari kafein, tapi dari kegagalan menyelamatkan keringat petani.',
      badgeName: 'Biji Tercecer 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // KASUS 4: SATE KLATHAK IMOGIRI
  // =========================================================================
  const DetectiveCase(
    level: 4,
    id: 'case_sate_klathak',
    title: 'Hilangnya Jeruji Pusaka Sate Klathak',
    subtitle: 'Konspirasi pencurian tusuk besi sepeda ontel kuno sebelum festival akbar sate Jejeran',
    location: 'Sentra Sate Klathak Jejeran, Imogiri, Bantul',
    targetRestaurant: 'Sate Klathak Pak Pong',
    suspectName: 'Ki Ageng Bismo "Kolektor Pusaka"',
    difficulty: CaseDifficulty.sulit,
    baseReward: 550,
    iconEmoji: '🍢',
    synopsis:
        'Jeruji besi sepeda ontel kuno peninggalan era kolonial milik juru bakar sate legendaris dicuri dari kotak brankas dapur. Tanpa jeruji besi berkonduksi panas tinggi ini, daging kambing muda tidak akan matang merata hingga ke bagian dalam.',
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
              description: 'Aroma minyak cendana pembersih pusaka menempel di engsel kotak.',
              icon: Icons.auto_fix_high_rounded,
            ),
            nextSceneId: 'scene_2',
          ),
          SceneChoice(
            text: 'Ganti semua tusuk dengan tusukan bambu biasa',
            actionDetail: 'Mencoba jalan pintas tanpa mencari pencuri',
            feedback:
                'Daging kambing bagian dalam tetap mentah berdarah saat dibakar! Pelanggan kecewa dan reputasi sate klathak tercoreng!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_2',
        title: 'Penggerebekan Padepokan Barang Antik Imogiri',
        location: 'Pendopo Antik Ki Ageng Bismo - Pukul 22.00 WIB',
        narrative:
            'Di lereng bukit Imogiri, sebuah pendopo dipenuhi gamelan tua dan keris kuno. Di tengah ruangan, jeruji sepeda ontel Jejeran diletakkan di atas kain beludru merah!',
        speakerName: 'Ki Ageng Bismo',
        speakerRole: 'Kolektor Pusaka Antik (Boss)',
        speakerAvatar: '🧙',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Ki Ageng Bismo',
          role: 'Kolektor Eksentrik',
          avatar: '🧙',
          quote:
              'Besi ini bukan sekadar alat membakar daging, Detektif! Besi sepeda ontel 1920 ini mengandung daya konduksi magis yang harus kujadikan pusaka pribadiku!',
          maxHp: 100,
          weakPoints: ['Minyak Keris', 'Filosofi Fisika Kuliner'],
        ),
        choices: [
          SceneChoice(
            text: 'Jelaskan bahwa keajaiban besi itu adalah ilmu fisika konduksi panas, bukan klenik pusaka!',
            actionDetail: 'Membongkar mitos dengan penjelasan sains kuliner yang logis',
            feedback:
                'ARGUMEN CERDAS! Ki Ageng terhenyak saat kamu mendemonstrasikan rumus distribusi panas besi pada serat daging!',
            isCorrect: true,
            bossDamage: 50,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Rebut kain beludru sambil menendang meja dupa',
            actionDetail: 'Menyerang tanpa strategi',
            feedback:
                'Ki Ageng melempar bubuk kemenyan ke matamu! Kamu terbatuk-batuk hebat di ruangan tertutup!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'PENGEMBALIAN BESI JEJERAN',
        location: 'Pendopo Imogiri',
        narrative:
            'Ki Ageng Bismo terpojok memegangi bilah jeruji besi yang mulai bergetar karena kamu menyalakan bara batok kelapa di sampingnya.',
        speakerName: 'Ki Ageng Bismo',
        speakerRole: 'Kolektor Terdesak',
        speakerAvatar: '🧙',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Ki Ageng Bismo',
          role: 'Boss',
          avatar: '🧙',
          quote: 'Jangan biarkan besi bersejarah ini hanya dipakai untuk menusuk sate...',
          maxHp: 50,
          weakPoints: ['Filosofi Rasa Rakyat'],
        ),
        choices: [
          SceneChoice(
            text: 'Katakan bahwa kehormatan tertinggi sebuah alat adalah memberi makan rakyat dengan nikmat!',
            actionDetail: 'Menyentuh nurani terdalam sang kolektor',
            feedback:
                'SKAKMAT TELAK! Air mata menetes di pipi Ki Ageng. Dia menyerahkan seluruh jeruji besi sambil membungkuk hormat.',
            isCorrect: true,
            bossDamage: 60,
          ),
          SceneChoice(
            text: 'Borgol dia dan seret ke pasar kambing',
            actionDetail: 'Tindakan kasar berlebihan',
            feedback:
                'Pengikut padepokan menahanmu dan situasi menjadi ricuh tak terkendali!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 10,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS TERPECAHKAN: Nyala Gurih Klathak Jejeran',
      narrative:
          'Seluruh 100 bilah jeruji besi sepeda ontel dikembalikan tepat saat festival dibuka. Asap putih harum rempah garam gurih membubung ke langit malam Imogiri.\n\nDaging kambing matang sempurna hingga ke urat terdalam berkat konduksi besi legendaris. Kamu dianugerahi porsi kehormatan Sate Klathak Juara!',
      epilogue: 'Kamu menguasai sains dan filosofi kuliner dan dinobatkan sebagai Detektif Senior!',
      badgeName: 'Penjaga Jeruji Jejeran 🍢',
      rewardPoints: 600,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Hilangnya Cita Rasa Otentik',
      narrative:
          'Ki Ageng menyembunyikan jeruji besi ke dalam gua karst Imogiri. Festival sate terpaksa menggunakan tusuk bambu biasa, dan sensasi matang sempurna sate klathak hilang ditelan zaman.',
      epilogue: 'Sebuah tradisi tak ternilai runtuh di bawah pengawasanmu.',
      badgeName: 'Besi Berkarat 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // KASUS 5: PERJAMUAN KERATON
  // =========================================================================
  const DetectiveCase(
    level: 5,
    id: 'case_keraton',
    title: 'Racun di Piring Perjamuan Ningrat',
    subtitle: 'Konspirasi meracuni hidangan Bistik Jawa Sri Sultan menjelang gala diplomatik',
    location: 'Bangsal Kencana Keraton & Resto Bale Raos',
    targetRestaurant: 'Bale Raos Keraton',
    suspectName: 'Gustave Laurent "Kritikus Angkuh"',
    difficulty: CaseDifficulty.sulit,
    baseReward: 700,
    iconEmoji: '👑',
    synopsis:
        'Beberapa jam sebelum jamuan makan malam bersama Duta Besar UNESCO, saus bistik kesukaan Sultan terindikasi dicemari zat kimia pewarna tekstil berbahaya. Seorang kritikus kuliner Eropa berambisi menghancurkan nominasi kuliner Nusantara.',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Inspeksi Meja Saji Bangsal Magangan',
        location: 'Dapur Ageng Keraton - Pukul 17.00 WIB',
        narrative:
            'Piring perak bertatah lambang Praja Cihna tersusun rapi. Saus bistik cokelat kemilau mengeluarkan bau kimia asam tembaga yang samar di bawah aroma pala dan cengkeh.',
        speakerName: 'Abdi Dalem Dapur',
        speakerRole: 'Penata Hidangan Keraton',
        speakerAvatar: '🧓',
        choices: [
          SceneChoice(
            text: 'Teteskan perasan jeruk nipis dan garam pada sampel saus bistik',
            actionDetail: 'Reaksi kimia alami untuk menguji pewarna tekstil sintetis',
            feedback:
                'Reaksi instan! Saus berubah warna menjadi hijau lumut neon! Terbukti ada zat pewarna tekstil beracun yang sengaja dicampurkan!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_uji_nipis',
              title: 'Reaksi Uji Asam Pewarna Tekstil',
              description: 'Bukti racun pewarna kimia berbahaya pada saus bistik kerajaan.',
              icon: Icons.colorize_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Sajikan saus tersebut ke tamu untuk melihat reaksinya',
            actionDetail: 'Tindakan membahayakan nyawa tamu negara',
            feedback:
                'BENCANA BESAR! Duta besar bisa keracunan dan memicu insiden diplomatik! Kehormatanmu sebagai detektif hancur seketika!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'KONFRONTASI BOS: Gustave Laurent',
        location: 'Bale Raos VIP Dining Room - Pukul 19.30 WIB',
        narrative:
            'Gustave Laurent duduk dengan setelan jas tuksedo sambil memegang pena emas. Dia siap menulis artikel penghancur reputasi kuliner keraton.',
        speakerName: 'Gustave Laurent',
        speakerRole: 'Kritikus Kuliner Internasional (Boss)',
        speakerAvatar: '🧐',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Gustave Laurent',
          role: 'Kritikus Arogan',
          avatar: '🧐',
          quote:
              'Hidangan kerajaan ini barbar dan berbahaya! Lihat saja sausnya, bahkan standar kebersihannya tidak layak untuk pakan ternak di Paris!',
          maxHp: 100,
          weakPoints: ['Reaksi Kimia Uji Nipis', 'Botol Pewarna di Saku Jas'],
        ),
        choices: [
          SceneChoice(
            text: 'Tunjukkan hasil uji kimia dan ungkap botol pewarna yang ia sembunyikan di saku jasnya!',
            actionDetail: 'Membongkar bukti sabotase langsung di depan dewan juri kehormatan',
            feedback:
                'HANTAMAN EMAS! Gustave terperanjat saat kamu mengeluarkan botol pewarna kimia dari tas laptop miliknya!',
            isCorrect: true,
            bossDamage: 60,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Kritik gaya berpakaian jas tuksedo miliknya yang kuno',
            actionDetail: 'Menyerang penampilan fisik tersangka',
            feedback:
                'Gustave tertawa dingin: "Debat murahan dari orang tanpa argumen." Dia terus menulis fitnah di catatannya!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'PEMBERSIHAN NAMA BESAR KERATON',
        location: 'Bale Raos',
        narrative:
            'Para duta besar mulai memasuki ruangan jamuan. Waktu tersisa tinggal 5 menit!',
        speakerName: 'Gustave Laurent',
        speakerRole: 'Boss Terdesak',
        speakerAvatar: '😨',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Gustave Laurent',
          role: 'Boss',
          avatar: '😨',
          quote: 'Jangan sentuh aku! Kalian tidak punya hak menggeledah kritikus ternama sepertiku!',
          maxHp: 40,
          weakPoints: ['Surat Tugas Dewan Kehormatan'],
        ),
        choices: [
          SceneChoice(
            text: 'Tunjukkan surat tugas Biro Investigasi dan rekaman CCTV ia memasuki dapur tanpa izin!',
            actionDetail: 'Bukti rekaman CCTV yang mengunci status tersangkanya',
            feedback:
                'KEMENANGAN MUTLAK! Gustave terduduk lemas di kursinya. Paspampres langsung mengamankannya keluar dari bangsal jamuan!',
            isCorrect: true,
            bossDamage: 50,
          ),
          SceneChoice(
            text: 'Batalkan seluruh jamuan makan malam secara sepihak',
            actionDetail: 'Menyerah pada kepanikan',
            feedback:
                'Keraton mengalami kerugian besar dan rasa malu internasional!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'KASUS TERPECAHKAN: Kejayaan Jamuan Rasa Ningrat',
      narrative:
          'Dapur Ageng berhasil menyiapkan bistik Jawa pengganti dengan kuah semur rempah pala asli dan kentang butter gurih. Seluruh duta besar memberikan tepuk tangan meriah dan memuji hidangan keraton sebagai puncak cita rasa harmoni Timur-Barat.\n\nSri Sultan menganugerahkan Samir Kehormatan Keraton dan mengangkatmu sebagai Inspektur Cita Rasa Kerajaan!',
      epilogue: 'Reputasi internasional kuliner Nusantara terselamatkan dengan gemilang!',
      badgeName: 'Bintang Jasa Keraton 👑',
      rewardPoints: 800,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Tragedi Diplomatik Meja Makan',
      narrative:
          'Zat pewarna tekstil terlanjur masuk ke hidangan utama. Acara makan malam dibatalkan di tengah skandal besar, dan delegasi asing melayangkan protes keras.',
      epilogue: 'Kamu diberhentikan dengan tidak hormat dari penugasan kerajaan.',
      badgeName: 'Mahkota Retak 💔',
      rewardPoints: 0,
    ),
  ),

  // =========================================================================
  // KASUS 6: GRAND FINALE - SINDIKAT TOPENG GARAM
  // =========================================================================
  const DetectiveCase(
    level: 6,
    id: 'case_topeng_garam',
    title: 'Konspirasi Sindikat Topeng Garam',
    subtitle: 'Penggerebekan markas rahasia pemalsu rempah pusaka Nusantara di Gua Bawah Tanah Pantai Selatan',
    location: 'Labirin Gua Bawah Tanah Parangtritis',
    targetRestaurant: 'Kawasan Kuliner Pesisir Pantai Selatan',
    suspectName: 'The Grand Mastermind "Si Topeng Garam"',
    difficulty: CaseDifficulty.master,
    baseReward: 1000,
    iconEmoji: '🎭',
    synopsis:
        'Sindikat rahasia pimpinan "Topeng Garam" telah menculik 5 koki legendaris DIY-Jateng untuk memeras resep pusaka dan memonopoli bumbu sintesis di ribuan gerai kuliner. Kamu memimpin operasi penggerebekan pamungkas!',
    scenes: [
      CaseScene(
        id: 'scene_1',
        title: 'Mengurai Kode Rahasia Bumbu 5 Elemen',
        location: 'Pintu Gerbang Gua Karst Parangtritis - Pukul 02.00 WIB',
        narrative:
            'Di depan gerbang batu gua tersembunyi, terdapat 5 mangkuk batu berisi bumbu uji coba: Asin, Manis, Pedas, Asam, dan Umami. Pintu gerbang hanya terbuka jika urutan keseimbangan rasa tradisional Jawa disusun benar.',
        speakerName: 'Detektif (Kamu)',
        speakerRole: 'Memecahkan Sandi',
        speakerAvatar: '🕵️',
        choices: [
          SceneChoice(
            text: 'Susun urutan harmoni: Manis (Gula Aren) -> Asin (Garam Kusamba) -> Gurih (Kemiri) -> Asam (Kluwek) -> Pedas (Cabai Jawa)',
            actionDetail: 'Menerapkan filosofi kuliner Panca Rasa Jawa kuno',
            feedback:
                'GERBANG TERBUKA! Suara mekanisme batu bergeser berat. Filosofi keseimbangan rasa membuka pintu rahasia sindikat!',
            isCorrect: true,
            foundClue: CaseClue(
              id: 'clue_panca_rasa',
              title: 'Harmoni Kunci Panca Rasa',
              description: 'Formula seimbang 5 rasa dasar yang mematahkan sistem keamanan sindikat.',
              icon: Icons.vpn_key_rounded,
            ),
            nextSceneId: 'scene_boss',
          ),
          SceneChoice(
            text: 'Ledakkan gerbang batu dengan granat asap',
            actionDetail: 'Tindakan gegabah merusak pintu gua',
            feedback:
                'Langit-langit gua runtuh menjatuhkan stalaktit tajam! Bahumu terluka tertimpa pecahan batu!',
            isCorrect: false,
            losesLife: true,
            nextSceneId: 'scene_boss',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss',
        title: 'FINAL CLIMAX: Pertarungan Kontra Topeng Garam',
        location: 'Aula Tengah Pabrik Rahasia Bawah Tanah - Pukul 03.00 WIB',
        narrative:
            'Di tengah aula raksasa beralaskan garam kristal, sosok berjubah hitam mengenakan Topeng Garam Keramik berdiri di atas podium tungku raksasa. Para koki legendaris terikat di belakangnya!',
        speakerName: 'Topeng Garam',
        speakerRole: 'The Mastermind (Final Boss)',
        speakerAvatar: '🎭',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'The Grand Mastermind "Topeng Garam"',
          role: 'Penguasa Pasar Gelap Kuliner',
          avatar: '🎭',
          quote:
              'Selamat datang, Detektif! Resep tradisional kalian terlalu lambat dan rumit. Dengan bumbu instan sintetisku, aku akan menguasai setiap lidah di Nusantara ini!',
          maxHp: 100,
          weakPoints: ['Kunci Panca Rasa', 'Kesaksian Para Maestro'],
        ),
        choices: [
          SceneChoice(
            text: 'Ungkap bahwa bumbu kimianya merusak saraf lidah dan buktikan dengan formula Panca Rasa!',
            actionDetail: 'Menyerang ideologi jahatnya dengan sains rasa autentik',
            feedback:
                'HANTAMAN CRITICAL! Topeng Garam mundur terhuyung saat formula kimianya kamu buktikan berbahaya bagi kesehatan generasi masa depan!',
            isCorrect: true,
            bossDamage: 50,
            nextSceneId: 'scene_boss_2',
          ),
          SceneChoice(
            text: 'Tawarkan kerja sama untuk membagi keuntungan 50:50',
            actionDetail: 'Mencoba berkompromi dengan penjahat',
            feedback:
                'Topeng Garam tertawa sinis dan menyemprotkan uap mercon ke arahmu! Detektif sejati tidak pernah menjual integritas!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
            nextSceneId: 'scene_boss_2',
          ),
        ],
      ),
      CaseScene(
        id: 'scene_boss_2',
        title: 'PECAHNYA TOPENG KEPALSUAN',
        location: 'Podium Tungku Bawah Tanah',
        narrative:
            'Topeng Garam meraih tuas peledak untuk menghancurkan seluruh gua beserta resep para maestro!',
        speakerName: 'Topeng Garam',
        speakerRole: 'Final Boss Terdesak',
        speakerAvatar: '🎭',
        isBossFight: true,
        boss: BossConfrontation(
          name: 'Topeng Garam',
          role: 'Final Boss',
          avatar: '🎭',
          quote: 'Jika aku tidak bisa memilikinya, tidak ada yang boleh mencicipi resep warisan ini selamanya!',
          maxHp: 50,
          weakPoints: ['Penyelamatan Maestro'],
        ),
        choices: [
          SceneChoice(
            text: 'Tebas tali pengikat para maestro dan lemparkan bumbu garam murni ke tuas peledak!',
            actionDetail: 'Menyelamatkan sandera dan melumpuhkan detonator',
            feedback:
                'FINISH HIM! Tuas korsleting, para maestro bersatu merebut kendali, dan topeng keramiknya pecah berkeping-keping mengungkap wajah aslinya!',
            isCorrect: true,
            bossDamage: 60,
          ),
          SceneChoice(
            text: 'Lari keluar gua sendirian menyelamatkan diri',
            actionDetail: 'Meninggalkan para koki yang disandera',
            feedback:
                'Tindakan pengecut! Gua meledak dan kamu menanggung rasa bersalah seumur hidup!',
            isCorrect: false,
            losesLife: true,
            bossDamage: 0,
          ),
        ],
      ),
    ],
    goodEnding: CaseEnding(
      title: 'TAMAT SEMPURNA: Kemenangan Cita Rasa Nusantara',
      narrative:
          'Sindikat Topeng Garam runtuh total! Seluruh pabrik rahasia disita oleh negara, dan para koki legendaris kembali dengan selamat ke pawon masing-masing.\n\nDi alun-alun Yogyakarta, diadakan Pesta Rakyat Kenduri Akbar 1.000 Rasa. Seluruh warga dan pelancong merayakan kebebasan cita rasa otentik Nusantara. Namamu diukir dengan tinta emas sebagai GRAND MASTER DETEKTIF KULINER SEPANJANG MASA!',
      epilogue: 'Kamu telah menamatkan seluruh buku misteri kuliner dengan kehormatan tertinggi!',
      badgeName: 'Grand Master Detektif Nusantara 🌟🏆',
      rewardPoints: 1200,
    ),
    badEnding: CaseEnding(
      title: 'PENYELIDIKAN GAGAL: Kegelapan Rasa Abadi',
      narrative:
          'Sindikat berhasil melarikan diri membawa formula rahasia dan menenggelamkan gua ke dasar samudra. Sejak hari itu, kuliner otentik perlahan punah digantikan makanan cepat saji tanpa jiwa.',
      epilogue: 'Biro Investigasi Rasa ditutup. Sejarah meratapi hilangnya deduksi terbaikmu.',
      badgeName: 'Bayangan Garam 💔',
      rewardPoints: 0,
    ),
  ),
];
