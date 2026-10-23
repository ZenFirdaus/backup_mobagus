import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_question.dart';
import '../models/quiz_data.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';
import 'detail_page.dart';

enum _GameView { levelSelect, playing, levelSummary, gameOver }

class LevelConfig {
  final int level;
  final String title;
  final String subtitle;
  final int questionCount;
  final int timePerQuestion;
  final int basePoints;
  final QuestionDifficulty targetDifficulty;
  final IconData icon;

  const LevelConfig({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.questionCount,
    required this.timePerQuestion,
    required this.basePoints,
    required this.targetDifficulty,
    required this.icon,
  });
}

const kLevelsConfig = <LevelConfig>[
  LevelConfig(
    level: 1,
    title: 'Warga Baru Malioboro',
    subtitle: 'Ikon kuliner populer, kopi joss, & jajanan legendaris',
    questionCount: 4,
    timePerQuestion: 15,
    basePoints: 50,
    targetDifficulty: QuestionDifficulty.mudah,
    icon: Icons.explore_rounded,
  ),
  LevelConfig(
    level: 2,
    title: 'Pemburu Kaki Lima',
    subtitle: 'Kekayaan jajanan pasar, sentra angkringan, & pawon',
    questionCount: 5,
    timePerQuestion: 13,
    basePoints: 75,
    targetDifficulty: QuestionDifficulty.menengah,
    icon: Icons.storefront_rounded,
  ),
  LevelConfig(
    level: 3,
    title: 'Penikmat Pawon Tradisional',
    subtitle: 'Resep lele asap, soto batok, & aroma tungku arang',
    questionCount: 5,
    timePerQuestion: 12,
    basePoints: 100,
    targetDifficulty: QuestionDifficulty.menengah,
    icon: Icons.outdoor_grill_rounded,
  ),
  LevelConfig(
    level: 4,
    title: 'Petualang Rasa Mataraman',
    subtitle: 'Olahan oseng mercon pedas, sate klathak, & rempah',
    questionCount: 6,
    timePerQuestion: 10,
    basePoints: 130,
    targetDifficulty: QuestionDifficulty.sulit,
    icon: Icons.whatshot_rounded,
  ),
  LevelConfig(
    level: 5,
    title: 'Abdi Dalem Kuliner Keraton',
    subtitle: 'Hidangan raja Sri Sultan, bistik ningrat, & filosofi',
    questionCount: 6,
    timePerQuestion: 9,
    basePoints: 160,
    targetDifficulty: QuestionDifficulty.sulit,
    icon: Icons.castle_rounded,
  ),
  LevelConfig(
    level: 6,
    title: 'Grand Master Foodie Nusantara',
    subtitle: 'Kuliner langka pelosok, manggar, & tantangan ekstrem',
    questionCount: 7,
    timePerQuestion: 8,
    basePoints: 200,
    targetDifficulty: QuestionDifficulty.sangatSulit,
    icon: Icons.military_tech_rounded,
  ),
];

class _ActiveQuestion {
  final GameQuestion original;
  final List<String> shuffledOptions;
  final int correctIndex;
  final Set<int> eliminatedIndices = {};

  _ActiveQuestion(this.original, this.shuffledOptions, this.correctIndex);

  factory _ActiveQuestion.from(GameQuestion q, Random random) {
    final indexed = q.options.asMap().entries.toList();
    indexed.shuffle(random);
    final newCorrect = indexed.indexWhere((e) => e.key == q.correctIndex);
    final newOpts = indexed.map((e) => e.value).toList();
    return _ActiveQuestion(q, newOpts, newCorrect);
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  _GameView _currentView = _GameView.levelSelect;

  // Level progression
  int _unlockedLevel = 1;
  final Map<int, int> _levelStars = {}; // level -> 1..3 stars
  int _selectedLevel = 1;

  // Active game session
  int _totalScore = 0;
  int _scoreInLevel = 0;
  int _currentCombo = 1;
  int _highestCombo = 1;
  int _lives = 3;

  // Lifelines (1x per level)
  bool _usedFiftyFifty = false;
  bool _usedFreezeTime = false;
  bool _usedClue = false;

  List<_ActiveQuestion> _sessionQuestions = [];
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _secondsLeft = 15;
  Timer? _timer;
  bool _saving = false;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalScore = await SupabaseService.instance.getTotalGameScore();
      final unlocked = prefs.getInt('foodie_game_unlocked_level') ?? 1;

      final starsMap = <int, int>{};
      for (int i = 1; i <= kLevelsConfig.length; i++) {
        starsMap[i] = prefs.getInt('foodie_game_stars_$i') ?? 0;
      }

      if (mounted) {
        setState(() {
          _totalScore = totalScore;
          _unlockedLevel = unlocked.clamp(1, kLevelsConfig.length);
          _levelStars.addAll(starsMap);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProgress(int level, int stars, int pointsEarned) async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update stars if higher
      final currentStars = _levelStars[level] ?? 0;
      if (stars > currentStars) {
        _levelStars[level] = stars;
        await prefs.setInt('foodie_game_stars_$level', stars);
      }

      // Unlock next level
      if (level >= _unlockedLevel && level < kLevelsConfig.length) {
        _unlockedLevel = level + 1;
        await prefs.setInt('foodie_game_unlocked_level', _unlockedLevel);
      }

      // Save points to user profile
      if (pointsEarned > 0) {
        await SupabaseService.instance.saveGameScore(pointsEarned);
      }
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  LevelConfig _getLevelConfig(int level) {
    return kLevelsConfig.firstWhere(
      (c) => c.level == level,
      orElse: () => kLevelsConfig.first,
    );
  }

  void _startLevel(int level) {
    final config = _getLevelConfig(level);

    // Pick questions matching difficulty or nearby
    final pool = kQuizQuestions.where((q) {
      if (config.level == 1) return q.difficulty == QuestionDifficulty.mudah;
      if (config.level <= 3) {
        return q.difficulty == QuestionDifficulty.mudah ||
            q.difficulty == QuestionDifficulty.menengah;
      }
      if (config.level <= 5) {
        return q.difficulty == QuestionDifficulty.menengah ||
            q.difficulty == QuestionDifficulty.sulit;
      }
      return q.difficulty == QuestionDifficulty.sulit ||
          q.difficulty == QuestionDifficulty.sangatSulit;
    }).toList();

    pool.shuffle(_random);

    final selected = <GameQuestion>[];
    selected.addAll(pool.take(config.questionCount));

    // Fill with fallback if pool is smaller than questionCount
    if (selected.length < config.questionCount) {
      final fallback = List<GameQuestion>.from(kQuizQuestions)..shuffle(_random);
      for (final q in fallback) {
        if (selected.length >= config.questionCount) break;
        if (!selected.contains(q)) selected.add(q);
      }
    }

    setState(() {
      _selectedLevel = level;
      _sessionQuestions =
          selected.map((q) => _ActiveQuestion.from(q, _random)).toList();
      _currentIndex = 0;
      _correctAnswers = 0;
      _scoreInLevel = 0;
      _currentCombo = 1;
      _highestCombo = 1;
      _lives = 3;
      _usedFiftyFifty = false;
      _usedFreezeTime = false;
      _usedClue = false;
      _selectedIndex = null;
      _answered = false;
      _currentView = _GameView.playing;
    });

    _startTimer(config.timePerQuestion);
  }

  void _startTimer(int totalSecs) {
    _timer?.cancel();
    _secondsLeft = totalSecs;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (!_answered) {
          _handleTimeout();
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _handleTimeout() {
    setState(() {
      _answered = true;
      _selectedIndex = -1; // timed out
      _currentCombo = 1;
      _lives--;
    });

    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _currentView = _GameView.gameOver);
      });
    } else {
      Future.delayed(const Duration(seconds: 2), _advanceQuestion);
    }
  }

  void _selectOption(int index) {
    if (_answered) return;
    _timer?.cancel();

    final config = _getLevelConfig(_selectedLevel);
    final activeQ = _sessionQuestions[_currentIndex];
    final correct = index == activeQ.correctIndex;

    setState(() {
      _selectedIndex = index;
      _answered = true;

      if (correct) {
        final earned = config.basePoints * _currentCombo;
        _scoreInLevel += earned;
        _totalScore += earned;
        _correctAnswers++;
        _currentCombo++;
        if (_currentCombo > _highestCombo) _highestCombo = _currentCombo;
      } else {
        _currentCombo = 1;
        _lives--;
      }
    });

    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _currentView = _GameView.gameOver);
      });
    }
  }

  void _advanceQuestion() {
    final config = _getLevelConfig(_selectedLevel);
    if (_currentIndex < _sessionQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _answered = false;
      });
      _startTimer(config.timePerQuestion);
    } else {
      _timer?.cancel();
      _handleLevelComplete();
    }
  }

  void _handleLevelComplete() {
    int stars = 1;
    if (_lives == 3) {
      stars = 3;
    } else if (_lives >= 2) {
      stars = 2;
    }

    _saveProgress(_selectedLevel, stars, _scoreInLevel);

    setState(() {
      _currentView = _GameView.levelSummary;
    });
  }

  // --- LIFELINES ---
  void _useFiftyFifty() {
    if (_usedFiftyFifty || _answered) return;
    final activeQ = _sessionQuestions[_currentIndex];
    final wrongIndices = <int>[];
    for (int i = 0; i < activeQ.shuffledOptions.length; i++) {
      if (i != activeQ.correctIndex) wrongIndices.add(i);
    }
    wrongIndices.shuffle(_random);
    final eliminated = wrongIndices.take(2).toSet();

    setState(() {
      _usedFiftyFifty = true;
      activeQ.eliminatedIndices.addAll(eliminated);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ 50:50 aktif! Dua jawaban salah telah dieliminasi.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _useFreezeTime() {
    if (_usedFreezeTime || _answered) return;
    setState(() {
      _usedFreezeTime = true;
      _secondsLeft += 10;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏱️ Waktu ditambah +10 detik! Tenang dan fokus.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _useClue() {
    if (_usedClue || _answered) return;
    final original = _sessionQuestions[_currentIndex].original;
    setState(() {
      _usedClue = true;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_rounded, color: AppColors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'Petunjuk Rahasia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (original.category != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.orange, 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  original.category!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ),
            Text(
              original.hint,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _openRelatedRestaurant(String restaurantId) async {
    try {
      final resto = await SupabaseService.instance.getRestaurant(restaurantId);
      if (resto != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailPage(restaurant: resto)),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data restoran sedang dimuat...')),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        child: switch (_currentView) {
          _GameView.levelSelect => _buildLevelSelect(),
          _GameView.playing => _buildPlaying(),
          _GameView.levelSummary => _buildLevelSummary(),
          _GameView.gameOver => _buildGameOver(),
        },
      ),
    );
  }

  // ==========================================
  // VIEW 1: LEVEL SELECTOR / STAGE MAP
  // ==========================================
  Widget _buildLevelSelect() {
    int totalStarsEarned = 0;
    for (final s in _levelStars.values) {
      totalStarsEarned += s;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      children: [
        // App bar row
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kuis Kuliner Mataraman', style: AppText.display(18)),
                  const SizedBox(height: 2),
                  const Text(
                    'Jelajahi rasa otentik Jogja & taklukkan levelnya!',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Total score & stars banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.greenDark, Color(0xFF234C37)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.greenDark.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL FOODIE SCORE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalScore Poin',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.yellow),
                        const SizedBox(width: 4),
                        Text(
                          '$totalStarsEarned / ${kLevelsConfig.length * 3} Bintang Terkumpul',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 32,
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const Text(
          'Pilih Tantangan Level',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),

        // List of Levels
        for (final config in kLevelsConfig) _buildLevelCard(config),
      ],
    );
  }

  Widget _buildLevelCard(LevelConfig config) {
    final isUnlocked = config.level <= _unlockedLevel;
    final stars = _levelStars[config.level] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? AppColors.tint(AppColors.greenDark, 0.15)
              : AppColors.line,
          width: isUnlocked ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isUnlocked ? () => _startLevel(config.level) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Level Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppColors.tint(AppColors.green, 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      isUnlocked ? config.icon : Icons.lock_rounded,
                      size: 24,
                      color: isUnlocked ? AppColors.greenDark : Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? AppColors.tint(AppColors.orange, 0.12)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LEVEL ${config.level}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isUnlocked ? AppColors.orange : Colors.grey,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Stars
                          if (isUnlocked)
                            Row(
                              children: List.generate(
                                3,
                                (i) => Icon(
                                  i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 16,
                                  color: i < stars ? AppColors.orange : Colors.grey.shade300,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked ? AppColors.charcoal : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        config.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isUnlocked ? AppColors.textMuted : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Meta tags
                      Row(
                        children: [
                          _smallBadge(
                            Icons.help_outline_rounded,
                            '${config.questionCount} Soal',
                            isUnlocked,
                          ),
                          const SizedBox(width: 8),
                          _smallBadge(
                            Icons.timer_outlined,
                            '${config.timePerQuestion}s / Soal',
                            isUnlocked,
                          ),
                          const SizedBox(width: 8),
                          _smallBadge(
                            Icons.stars_rounded,
                            '+${config.basePoints} Poin',
                            isUnlocked,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(
                  isUnlocked ? Icons.play_circle_fill_rounded : Icons.lock_outline_rounded,
                  color: isUnlocked ? AppColors.greenDark : Colors.grey.shade300,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallBadge(IconData icon, String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppColors.tint(AppColors.greenDark, 0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: active ? AppColors.greenDark : Colors.grey),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.greenDark : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 2: ACTIVE GAMEPLAY SCREEN
  // ==========================================
  Widget _buildPlaying() {
    if (_sessionQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final config = _getLevelConfig(_selectedLevel);
    final activeQ = _sessionQuestions[_currentIndex];
    final originalQ = activeQ.original;
    final progress = (_currentIndex + 1) / _sessionQuestions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
      children: [
        // Top Header
        Row(
          children: [
            InkWell(
              onTap: () {
                _timer?.cancel();
                setState(() => _currentView = _GameView.levelSelect);
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level $_selectedLevel: ${config.title}',
                      style: AppText.display(14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    'Soal ${_currentIndex + 1} dari ${_sessionQuestions.length}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // Hearts (Nyawa)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.tint(AppColors.red, 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Icon(
                      i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 16,
                      color: i < _lives ? AppColors.red : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Score & Combo Bar
        Row(
          children: [
            // Score chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.greenDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, size: 14, color: AppColors.yellow),
                  const SizedBox(width: 4),
                  Text(
                    '$_scoreInLevel pts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (_currentCombo > 1) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, Color(0xFFFF8A00)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      'COMBO x$_currentCombo',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            _timerWidget(),
          ],
        ),
        const SizedBox(height: 10),

        // Progress line
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.tint(AppColors.green, 0.15),
            valueColor: const AlwaysStoppedAnimation(AppColors.green),
          ),
        ),
        const SizedBox(height: 14),

        // Lifelines toolbar (Bantuan)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _lifelineButton(
                icon: Icons.electric_bolt_rounded,
                label: '50:50',
                used: _usedFiftyFifty,
                onTap: _useFiftyFifty,
              ),
              _dividerLifeline(),
              _lifelineButton(
                icon: Icons.more_time_rounded,
                label: '+10s Waktu',
                used: _usedFreezeTime,
                onTap: _useFreezeTime,
              ),
              _dividerLifeline(),
              _lifelineButton(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Petunjuk',
                used: _usedClue,
                onTap: _useClue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Question card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo if available
              if (originalQ.imageUrl != null && originalQ.imageUrl!.isNotEmpty)
                Stack(
                  children: [
                    Image.network(
                      originalQ.imageUrl!,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.camera_alt_rounded, size: 12, color: AppColors.yellow),
                            const SizedBox(width: 4),
                            Text(
                              originalQ.category ?? 'Tebak Foto Kuliner',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Hint
                    Row(
                      children: [
                        if (originalQ.category != null && originalQ.imageUrl == null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.tint(AppColors.orange, 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              originalQ.category!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Icon(Icons.location_on_rounded, size: 13, color: AppColors.orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            originalQ.hint,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Question text
                    Text(
                      originalQ.question,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Options
        for (int i = 0; i < activeQ.shuffledOptions.length; i++)
          if (!activeQ.eliminatedIndices.contains(i))
            _optionTile(activeQ, i),

        // Answer feedback & explanation
        if (_answered) ...[
          const SizedBox(height: 14),
          _buildAnswerFeedback(activeQ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _currentIndex < _sessionQuestions.length - 1
                ? 'Lanjut ke Soal Berikutnya'
                : 'Selesaikan Level $_selectedLevel',
            trailingArrow: true,
            onPressed: _advanceQuestion,
          ),
        ],
      ],
    );
  }

  Widget _timerWidget() {
    final urgent = _secondsLeft <= 4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: urgent
            ? AppColors.tint(AppColors.red, 0.15)
            : AppColors.tint(AppColors.green, 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: urgent ? AppColors.red : AppColors.green,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            size: 14,
            color: urgent ? AppColors.red : AppColors.greenDark,
          ),
          const SizedBox(width: 4),
          Text(
            '${_secondsLeft}s',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: urgent ? AppColors.red : AppColors.greenDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerLifeline() {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.line,
    );
  }

  Widget _lifelineButton({
    required IconData icon,
    required String label,
    required bool used,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: used || _answered ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: used ? Colors.grey.shade400 : AppColors.orange,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: used ? Colors.grey.shade400 : AppColors.charcoal,
                decoration: used ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(_ActiveQuestion activeQ, int i) {
    Color bg = Colors.white;
    Color border = AppColors.line;
    Color textColor = AppColors.textDark;

    if (_answered) {
      if (i == activeQ.correctIndex) {
        bg = AppColors.tint(AppColors.green, 0.15);
        border = AppColors.green;
        textColor = AppColors.greenDark;
      } else if (i == _selectedIndex) {
        bg = AppColors.tint(AppColors.red, 0.15);
        border = AppColors.red;
        textColor = AppColors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _answered ? null : () => _selectOption(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _answered && i == activeQ.correctIndex
                        ? AppColors.green
                        : _answered && i == _selectedIndex
                            ? AppColors.red
                            : AppColors.tint(AppColors.orange, 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: _answered && i == activeQ.correctIndex
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : _answered && i == _selectedIndex
                            ? const Icon(Icons.close, size: 16, color: Colors.white)
                            : Text(
                                String.fromCharCode(65 + i),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.orange,
                                ),
                              ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activeQ.shuffledOptions[i],
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerFeedback(_ActiveQuestion activeQ) {
    final original = activeQ.original;
    final isCorrect = _selectedIndex == activeQ.correctIndex;
    final timedOut = _selectedIndex == -1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.tint(AppColors.green, 0.1)
            : AppColors.tint(AppColors.red, 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? AppColors.tint(AppColors.green, 0.3)
              : AppColors.tint(AppColors.red, 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: isCorrect ? AppColors.greenDark : AppColors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCorrect
                      ? 'Jawaban Benar! (+${_getLevelConfig(_selectedLevel).basePoints * (_currentCombo - 1)} poin)'
                      : timedOut
                          ? 'Waktu Habis! (-1 Nyawa)'
                          : 'Jawaban Salah! (-1 Nyawa)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isCorrect ? AppColors.greenDark : AppColors.red,
                  ),
                ),
              ),
              // Restaurant navigation button
              if (original.relatedRestaurantId != null)
                InkWell(
                  onTap: () => _openRelatedRestaurant(original.relatedRestaurantId!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Lihat Resto',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            original.explanation,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 3: LEVEL SUMMARY (LEVEL CLEARED)
  // ==========================================
  Widget _buildLevelSummary() {
    final config = _getLevelConfig(_selectedLevel);
    int stars = 1;
    if (_lives == 3) {
      stars = 3;
    } else if (_lives >= 2) {
      stars = 2;
    }

    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Trophy or Star badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.orange, 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 40,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(height: 14),
                Text('Level $_selectedLevel Berhasil!', style: AppText.display(22)),
                const SizedBox(height: 4),
                Text(
                  config.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),

                // Star display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 36,
                        color: i < stars ? AppColors.orange : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Points earned
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.green, 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.greenDark, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '+$_scoreInLevel Poin Didapatkan',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statCard(Icons.check_circle_rounded, '$_correctAnswers', 'Benar', AppColors.green),
                    const SizedBox(width: 12),
                    _statCard(Icons.favorite_rounded, '$_lives', 'Sisa Nyawa', AppColors.red),
                    const SizedBox(width: 12),
                    _statCard(Icons.local_fire_department_rounded, 'x$_highestCombo', 'Max Combo', AppColors.orange),
                  ],
                ),

                if (_saving) ...[
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Next Level or Back button
          if (_selectedLevel < kLevelsConfig.length)
            PrimaryButton(
              label: 'Lanjut Level ${_selectedLevel + 1}',
              icon: Icons.play_arrow_rounded,
              onPressed: () => _startLevel(_selectedLevel + 1),
            )
          else
            PrimaryButton(
              label: 'Semua Level Selesai! Hebat!',
              icon: Icons.celebration_rounded,
              onPressed: () => setState(() => _currentView = _GameView.levelSelect),
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _currentView = _GameView.levelSelect),
            child: const Text(
              'Kembali ke Peta Level',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 4: GAME OVER (HABIS NYAWA)
  // ==========================================
  Widget _buildGameOver() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.red, 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.heart_broken_rounded,
                    size: 40,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Nyawa Habis!', style: AppText.display(22, color: AppColors.red)),
                const SizedBox(height: 6),
                const Text(
                  'Tantangan level ini belum berhasil dilewati.\nJangan menyerah, coba lagi untuk skor sempurna!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Skor Didapat: $_scoreInLevel',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoal,
                        ),
                      ),
                      Text(
                        'Benar: $_correctAnswers / ${_sessionQuestions.length}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          PrimaryButton(
            label: 'Coba Lagi Level Ini',
            icon: Icons.replay_rounded,
            onPressed: () => _startLevel(_selectedLevel),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _currentView = _GameView.levelSelect),
            child: const Text(
              'Kembali ke Peta Level',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tint(color, 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
