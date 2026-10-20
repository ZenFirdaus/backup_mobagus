class GameQuestion {
  final String id;
  final String hint;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? relatedRestaurantId;
  final int points;

  const GameQuestion({
    required this.id,
    required this.hint,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.relatedRestaurantId,
    this.points = 100,
  });
}

const kQuizQuestions = <GameQuestion>[
  GameQuestion(
    id: 'q1',
    hint: 'Sentra Wijilan, Kraton, Kota Yogyakarta',
    question:
        'Hidangan khas Yogyakarta berbahan dasar nangka muda yang dimasak '
        'dengan santan dan gula Jawa selama berjam-jam hingga berwarna '
        'cokelat kemerahan ini disebut...',
    options: ['Gudeg', 'Brongkos', 'Mangut Lele', 'Tongseng Kambing'],
    correctIndex: 0,
    explanation:
        'Gudeg adalah ikon kuliner Yogyakarta yang dimasak dengan proses '
        'slow-cooking menggunakan kayu bakar pohon asam selama 12-24 jam. '
        'Sentra gudeg paling terkenal berada di Jalan Wijilan, Kraton.',
    points: 100,
  ),
  GameQuestion(
    id: 'q2',
    hint: 'Pawon Dusun Tiwir, Sewon, Bantul',
    question:
        'Hidangan berbahan dasar lele asap dengan kuah santan cabai rawit '
        'pedas gurih yang dimasak di pawon arang khas Sewon ini adalah...',
    options: [
      'Mangut Lele Asap',
      'Brongkos Daging Koyor',
      'Gudeg Manggar Bantul',
      'Tongseng Kambing Pak Kribo',
    ],
    correctIndex: 0,
    explanation:
        'Mangut Lele Asap adalah hidangan tradisional Bantul yang menggunakan '
        'lele yang diasap dengan kayu klampok selama berjam-jam, lalu dimasak '
        'dengan kuah santan cabai rawit yang pedas dan gurih.',
    points: 100,
  ),
  GameQuestion(
    id: 'q3',
    hint: 'Stasiun Tugu, Malioboro, Yogyakarta',
    question:
        'Minuman kopi angkringan yang terkenal karena dicelupkan arang bara '
        'api langsung ke dalam gelas kopi ini disebut...',
    options: ['Kopi Joss', 'Kopi Luwak', 'Kopi Tubruk', 'Wedang Jahe'],
    correctIndex: 0,
    explanation:
        'Kopi Joss adalah kopi khas angkringan Yogyakarta yang unik karena '
        'arang bara dicelupkan langsung ke dalam gelas kopi, menghasilkan '
        'rasa yang khas dan mengurangi keasaman kopi.',
    points: 100,
  ),
  GameQuestion(
    id: 'q4',
    hint: 'Pasar Gede, Kota Surakarta',
    question:
        'Hidangan berkuah santan berwarna cokelat kehitaman berbahan kluwek, '
        'daging sapi, dan kacang tolo yang merupakan masakan khas keraton '
        'Surakarta ini disebut...',
    options: ['Brongkos', 'Rawon', 'Soto Kudus', 'Tengkleng'],
    correctIndex: 0,
    explanation:
        'Brongkos adalah masakan khas keraton Surakarta yang menggunakan '
        'kluwek sebagai bumbu utama, menghasilkan kuah berwarna cokelat '
        'kehitaman yang kaya rasa.',
    points: 100,
  ),
  GameQuestion(
    id: 'q5',
    hint: 'Kalasan, Sleman, DIY',
    question:
        'Soto khas Yogyakarta yang disajikan di dalam batok kelapa (tempurung) '
        'dengan suasana persawahan ini populer disebut...',
    options: [
      'Soto Bathok',
      'Soto Banjar',
      'Soto Lamongan',
      'Soto Kudus',
    ],
    correctIndex: 0,
    explanation:
        'Soto Bathok disajikan di dalam batok (tempurung) kelapa yang memberikan '
        'aroma khas alami. Warung soto bathok paling terkenal berada di kawasan '
        'Kalasan, Sleman dengan pemandangan sawah.',
    points: 100,
  ),
];
