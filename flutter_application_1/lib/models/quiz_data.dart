import 'game_question.dart'; // Sesuaikan path jika berbeda

const kQuizQuestions = <GameQuestion>[
  // --- SOAL MUDAH ---
  GameQuestion(
    id: 'q1',
    hint: 'Sentra Wijilan, Kraton, Kota Yogyakarta',
    question: 'Hidangan khas Yogyakarta berbahan dasar nangka muda yang dimasak dengan santan dan gula Jawa selama berjam-jam hingga berwarna cokelat kemerahan ini disebut...',
    options: ['Gudeg', 'Brongkos', 'Mangut Lele', 'Tongseng Kambing'],
    correctIndex: 0,
    explanation: 'Gudeg adalah ikon kuliner Yogyakarta yang dimasak dengan proses slow-cooking. Sentra gudeg paling terkenal berada di Jalan Wijilan, Kraton.',
    difficulty: QuestionDifficulty.mudah,
    // Contoh integrasi: Ganti string di bawah dengan ID Resto Gudeg Yu Djum di Supabase/Data Anda
    relatedRestaurantId: 'id_resto_gudeg_yu_djum',
  ),
  GameQuestion(
    id: 'q3',
    hint: 'Stasiun Tugu, Malioboro, Yogyakarta',
    question: 'Minuman kopi angkringan yang terkenal karena dicelupkan arang bara api langsung ke dalam gelas kopi ini disebut...',
    options: ['Kopi Joss', 'Kopi Luwak', 'Kopi Tubruk', 'Wedang Jahe'],
    correctIndex: 0,
    explanation: 'Kopi Joss adalah kopi khas angkringan Yogyakarta yang unik karena arang bara dicelupkan langsung ke dalam gelas kopi.',
    difficulty: QuestionDifficulty.mudah,
  ),
  GameQuestion(
    id: 'q6',
    hint: 'Pasar Beringharjo, Yogyakarta',
    question: 'Jajanan pasar khas Yogyakarta berbentuk silinder berongga, terbuat dari tepung beras, dicetak dalam bambu, dan disajikan dengan parutan kelapa serta gula merah cair adalah...',
    options: ['Putu', 'Klepon', 'Cenil', 'Lupis'],
    correctIndex: 0,
    explanation: 'Kue Putu dimasak dengan cara dikukus dalam cetakan bambu yang menghasilkan bunyi khas, disajikan dengan kelapa parut dan gula merah.',
    difficulty: QuestionDifficulty.mudah,
  ),

  // --- SOAL MENENGAH ---
  GameQuestion(
    id: 'q2',
    hint: 'Pawon Dusun Tiwir, Sewon, Bantul',
    question: 'Hidangan berbahan dasar lele asap dengan kuah santan cabai rawit pedas gurih yang dimasak di pawon arang khas Sewon ini adalah...',
    options: [
      'Mangut Lele Asap',
      'Brongkos Daging Koyor',
      'Gudeg Manggar Bantul',
      'Tongseng Kambing Pak Kribo',
    ],
    correctIndex: 0,
    explanation: 'Mangut Lele Asap adalah hidangan tradisional Bantul yang diasap dengan kayu klampok selama berjam-jam.',
    difficulty: QuestionDifficulty.menengah,
    relatedRestaurantId: 'id_resto_mangut_lele_mbah_marto',
  ),
  GameQuestion(
    id: 'q4',
    hint: 'Pasar Gede, Kota Surakarta',
    question: 'Hidangan berkuah santan berwarna cokelat kehitaman berbahan kluwek, daging sapi, dan kacang tolo yang merupakan masakan khas keraton Surakarta ini disebut...',
    options: ['Brongkos', 'Rawon', 'Soto Kudus', 'Tengkleng'],
    correctIndex: 0,
    explanation: 'Brongkos khas keraton Surakarta menggunakan kluwek sebagai bumbu utama, menghasilkan kuah berwarna cokelat kehitaman.',
    difficulty: QuestionDifficulty.menengah,
  ),
  GameQuestion(
    id: 'q7',
    hint: 'Jejak Mataram Islam, Kota Surakarta',
    question: 'Nasi gurih yang dimasak dengan santan, disajikan dengan sayur labu siam, suwiran ayam, dan areh (sari santan kental) merupakan karakteristik hidangan...',
    options: ['Nasi Liwet', 'Nasi Gudeg', 'Nasi Langgi', 'Nasi Jamblang'],
    correctIndex: 0,
    explanation: 'Nasi Liwet Solo dimasak dengan santan kaldu ayam sehingga gurih, selalu disajikan dengan sayur labu siam dan areh.',
    difficulty: QuestionDifficulty.menengah,
  ),

  // --- SOAL SULIT ---
  GameQuestion(
    id: 'q5',
    hint: 'Bantul, DIY',
    question: 'Mie khas Bantul yang terbuat dari tepung singkong (tapioka) dan gaplek, diolah menggunakan tenaga sapi untuk memutar penggilingannya adalah...',
    options: ['Mie Lethek', 'Mie Pentil', 'Mie Des', 'Mie Ketoprak'],
    correctIndex: 0,
    explanation: 'Mie Lethek memiliki warna kusam (lethek) karena terbuat dari singkong dan diproduksi secara tradisional menggunakan tenaga sapi di Bendo, Bantul.',
    difficulty: QuestionDifficulty.sulit,
    relatedRestaurantId: 'id_resto_mie_lethek_mbah_gendes',
  ),
  GameQuestion(
    id: 'q8',
    hint: 'Kuliner Ekstrem Gunungkidul',
    question: 'Makanan musiman khas Gunungkidul berprotein tinggi yang dimasak bacem atau digoreng kering, sering muncul pada awal musim penghujan di area pohon jati adalah...',
    options: [
      'Ungkep Ungker (Kepompong Daun Jati)',
      'Belalang Goreng (Walang)',
      'Laron Goreng',
      'Putul (Kumbang Tanah)',
    ],
    correctIndex: 0,
    explanation: 'Ungker atau kepompong ulat daun jati hanya bisa dipanen saat awal musim hujan di kawasan hutan jati Gunungkidul.',
    difficulty: QuestionDifficulty.sulit,
  ),

  // --- SOAL SANGAT SULIT ---
  GameQuestion(
    id: 'q9',
    hint: 'Variasi Gudeg, Kabupaten Bantul',
    question: 'Berbeda dengan gudeg nangka muda, Kabupaten Bantul memiliki varian gudeg langka khas yang bahan utamanya terbuat dari...',
    options: [
      'Bunga Kelapa (Manggar)',
      'Jantung Pisang (Ontong)',
      'Akar Teratai',
      'Rebung Bambu',
    ],
    correctIndex: 0,
    explanation: 'Gudeg Manggar menggunakan bunga kelapa yang belum mekar. Konon ini adalah menu istimewa keraton pada masa Sultan Hamengkubuwono I.',
    difficulty: QuestionDifficulty.sangatSulit,
  ),
  GameQuestion(
    id: 'q10',
    hint: 'Sate Khas Pleret, Bantul',
    question: 'Sate khas Pleret Bantul ini tidak ditusuk dengan bambu, melainkan dengan jeruji besi sepeda (ruji). Tujuannya agar daging matang merata dari dalam. Sate ini disebut...',
    options: ['Sate Klathak', 'Sate Ambal', 'Sate Buntel', 'Sate Kere'],
    correctIndex: 0,
    explanation: 'Sate Klathak menggunakan jeruji besi yang berfungsi sebagai konduktor panas, membuat daging kambing matang sempurna hingga ke bagian dalam.',
    difficulty: QuestionDifficulty.sangatSulit,
    relatedRestaurantId: 'id_resto_sate_klathak_pak_pong',
  ),
];
