import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/detective_cases_data.dart';
import '../data/kulinerdle_data.dart';
import '../models/detective_case.dart';
import '../models/game_question.dart';
import '../models/profile.dart';
import '../models/quiz_data.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import '../services/reward_border_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';
import 'explore_tab.dart';

enum _GameView {
  hub,
  // Game 1: Kuis Kuliner Mataraman
  quizLevelSelect,
  quizPlaying,
  quizSummary,
  quizGameOver,
  // Game 2: Kulinerdle
  kulinerdle,
  // Game 3: Pilih Jalanmu (Detektif)
  detectiveCaseSelect,
  detectiveInvestigation,
  detectiveGoodEnding,
  detectiveBadEnding,
}

enum LetterEvaluation {
  empty,
  pending,
  correct, // Hijau: Huruf & posisi tepat
  present, // Kuning: Huruf ada, posisi keliru
  absent, // Netral: Huruf tidak ada
}

// ─────────────────────────────────────────────────────────────────────────────
// KUIS LEVEL CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────
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

const kQuizLevelsConfig = <LevelConfig>[
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
  _GameView _currentView = _GameView.hub;

  // Real Profile from App
  Profile? _realProfile;
  int _totalScore = 0;
  int _dailyStreak = 1;

  // ───────────────────────────────────────────────────────────────────────────
  // GAME 1: KUIS TRIVIA STATE
  // ───────────────────────────────────────────────────────────────────────────
  int _unlockedQuizLevel = 1;
  final Map<int, int> _quizStars = {}; // level -> stars (1-3)
  int _selectedQuizLevel = 1;
  List<_ActiveQuestion> _quizSessionQuestions = [];
  int _quizQuestionIndex = 0;
  int _quizCorrectAnswers = 0;
  int _quizScoreInLevel = 0;
  int _quizCombo = 1;
  int _quizHighestCombo = 1;
  int _quizLives = 3;
  bool _usedFiftyFifty = false;
  bool _usedFreezeTime = false;
  bool _usedClue = false;
  int? _quizSelectedIndex;
  bool _quizAnswered = false;
  int _quizSecondsLeft = 15;
  Timer? _quizTimer;
  final Random _random = Random();

  // ───────────────────────────────────────────────────────────────────────────
  // GAME 2: KULINERDLE STATE
  // ───────────────────────────────────────────────────────────────────────────
  late KulinerdleWord _kulinerdleTarget;
  bool _isDailyKulinerdle = false;
  final List<String> _kulinerdleGuesses = [];
  String _kulinerdleCurrentInput = '';
  bool _kulinerdleGameOver = false;
  final List<String> _recentKulinerdleWords = [];
  final Map<String, LetterEvaluation> _kulinerdleKeyEvaluations = {};
  int _kdPlayed = 0;
  int _kdWon = 0;
  int _kdCurrentStreak = 0;
  int _kdMaxStreak = 0;
  final Map<int, int> _kdGuessDistribution = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
  };

  // ───────────────────────────────────────────────────────────────────────────
  // GAME 3: DETEKTIF KASUS STATE
  // ───────────────────────────────────────────────────────────────────────────
  int _unlockedDetectiveLevel = 1;
  final Map<int, int> _detectiveStars = {};
  int _selectedChapter = 1;
  DetectiveCase? _activeCase;
  int _currentSceneIndex = 0;
  int _detectiveLives = 3;
  int _bossHp = 100;
  final Set<String> _gatheredClueIds = {};
  final List<CaseClue> _gatheredClues = [];
  final Set<int> _selectedChoiceIndicesInScene = {};
  static const int _cooldownDurationSeconds = 180;
  int _cooldownRemainingSeconds = 0;
  Timer? _cooldownTimer;
  StreamSubscription<void>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _initKulinerdleWord();
    _loadAllData();
    _profileSubscription = SupabaseService.instance.onProfileChanged.listen((_) {
      if (mounted) _loadAllData();
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _quizTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DATA LOADING & PROFILE SYNC
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = await SupabaseService.instance.getProfile();
      final totalScore = await SupabaseService.instance.getTotalGameScore();

      // Quiz Progress
      final unlockedQuiz = prefs.getInt('foodie_quiz_unlocked_level') ?? 1;
      final qStars = <int, int>{};
      for (int i = 1; i <= kQuizLevelsConfig.length; i++) {
        qStars[i] = prefs.getInt('foodie_quiz_stars_$i') ?? 0;
      }

      // ───────────────────────────────────────────────────────────────────────
      // DETECTIVE PROGRESS: Multi-Layer Resilient Checkpoint Persistence
      // (Layer 1: SharedPreferences, Layer 2: Hive NoSQL, Layer 3: Cloud Metadata,
      //  Layer 4: Star-derived reconstruction, Layer 5: Checkpoint Bab 1 Level 3 Guarantee)
      // ───────────────────────────────────────────────────────────────────────
      final uid = SupabaseService.instance.userId;
      final supaUser = SupabaseService.instance.currentUser;

      // Layer 1: SharedPreferences (Global & User-Scoped)
      final globalPrefsUnlocked = prefs.getInt('foodie_game_unlocked_level') ?? 1;
      final userPrefsUnlocked = (uid != null && uid.isNotEmpty)
          ? (prefs.getInt('foodie_game_unlocked_level_$uid') ?? 1)
          : 1;
      final hasCp3Pref = prefs.getBool('foodie_game_checkpoint_lv3_unlocked') == true ||
          (uid != null && uid.isNotEmpty && prefs.getBool('foodie_game_checkpoint_lv3_unlocked_$uid') == true);

      // Layer 2: Hive NoSQL Local Database (tahan logout & pembersihan cache)
      final hiveUnlocked = HiveService.instance.getDetectiveUnlockedLevel(uid);

      // Layer 3: Supabase Cloud User Metadata
      int cloudUnlocked = 1;
      Map<String, dynamic>? cloudStarsMap;
      if (supaUser != null && supaUser.userMetadata != null) {
        final meta = supaUser.userMetadata!;
        final rawCloudLv = meta['foodie_detective_unlocked_level'];
        if (rawCloudLv is int) {
          cloudUnlocked = rawCloudLv;
        } else if (rawCloudLv != null) {
          cloudUnlocked = int.tryParse(rawCloudLv.toString()) ?? 1;
        }
        if (meta['foodie_checkpoint_lv3'] == true && cloudUnlocked < 3) {
          cloudUnlocked = 3;
        }
        if (meta['foodie_detective_stars'] is Map) {
          cloudStarsMap = Map<String, dynamic>.from(meta['foodie_detective_stars'] as Map);
        }
      }

      // Layer 4: Load Stars across all sources & Star-Derived Checkpoint
      final hiveStars = HiveService.instance.getDetectiveStars(uid);
      final dStars = <int, int>{};
      int highestCompletedLevel = 0;

      for (int i = 1; i <= kDetectiveCases.length; i++) {
        final gPref = prefs.getInt('foodie_game_stars_$i') ?? 0;
        final uPref = (uid != null && uid.isNotEmpty)
            ? (prefs.getInt('foodie_game_stars_${i}_$uid') ?? 0)
            : 0;
        final hStar = hiveStars[i] ?? 0;
        int cStar = 0;
        if (cloudStarsMap != null && cloudStarsMap.containsKey(i.toString())) {
          cStar = int.tryParse(cloudStarsMap[i.toString()].toString()) ?? 0;
        }
        final bestStar = [gPref, uPref, hStar, cStar].reduce(max);
        dStars[i] = bestStar;
        if (bestStar > 0) {
          highestCompletedLevel = max(highestCompletedLevel, i);
        }
      }

      // Jika level k berhasil diselesaikan (bintang > 0), level k + 1 dipastikan terbuka
      final derivedFromStars = highestCompletedLevel > 0
          ? min(highestCompletedLevel + 1, kDetectiveCases.length)
          : 1;

      // Evaluasi Checkpoint Tertinggi
      int unlockedDet = [
        globalPrefsUnlocked,
        userPrefsUnlocked,
        hiveUnlocked,
        cloudUnlocked,
        derivedFromStars,
      ].reduce(max);

      // Layer 5: Garansi Checkpoint Bab 1 Level 3 (Klimaks Sambisari & Boss Ki Joyo)
      if ((hasCp3Pref || highestCompletedLevel >= 2) && unlockedDet < 3) {
        unlockedDet = 3;
      }
      unlockedDet = unlockedDet.clamp(1, kDetectiveCases.length);

      // Sinkronisasikan balik ke seluruh layer penyimpanan lokal agar tahan logout
      await prefs.setInt('foodie_game_unlocked_level', unlockedDet);
      if (uid != null && uid.isNotEmpty) {
        await prefs.setInt('foodie_game_unlocked_level_$uid', unlockedDet);
      }
      if (unlockedDet >= 3) {
        await prefs.setBool('foodie_game_checkpoint_lv3_unlocked', true);
        if (uid != null && uid.isNotEmpty) {
          await prefs.setBool('foodie_game_checkpoint_lv3_unlocked_$uid', true);
        }
      }
      await HiveService.instance.saveDetectiveUnlockedLevel(unlockedDet, uid);

      // Kulinerdle Stats
      _kdPlayed = prefs.getInt('kulinerdle_played') ?? 0;
      _kdWon = prefs.getInt('kulinerdle_won') ?? 0;
      _kdCurrentStreak = prefs.getInt('kulinerdle_current_streak') ?? 0;
      _kdMaxStreak = prefs.getInt('kulinerdle_max_streak') ?? 0;
      for (int i = 1; i <= 6; i++) {
        _kdGuessDistribution[i] = prefs.getInt('kulinerdle_dist_$i') ?? 0;
      }
      final recentWords = prefs.getStringList('foodie_recent_kulinerdle_words');
      if (recentWords != null && recentWords.isNotEmpty) {
        _recentKulinerdleWords.clear();
        _recentKulinerdleWords.addAll(recentWords);
      }

      // Streaks
      final streak = prefs.getInt('foodie_game_daily_streak') ?? 1;

      // Cooldown Check
      final cooldownEnd = prefs.getInt('foodie_game_cooldown_end') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      int remaining = 0;
      int initialLives = 3;

      if (cooldownEnd > now) {
        remaining = ((cooldownEnd - now) / 1000).ceil();
        initialLives = 0;
        _startCooldownTimer(remaining);
      } else if (cooldownEnd > 0) {
        await prefs.remove('foodie_game_cooldown_end');
        initialLives = 3;
      }

      if (mounted) {
        setState(() {
          _realProfile = p;
          _totalScore = (p?.points != null && p!.points > totalScore)
              ? p.points
              : totalScore;
          _unlockedQuizLevel = unlockedQuiz.clamp(1, kQuizLevelsConfig.length);
          _quizStars.addAll(qStars);
          _unlockedDetectiveLevel = unlockedDet.clamp(
            1,
            kDetectiveCases.length,
          );
          _detectiveStars.addAll(dStars);
          _dailyStreak = streak;
          _detectiveLives = initialLives;
          _cooldownRemainingSeconds = remaining;
          _selectedChapter = (((_unlockedDetectiveLevel - 1) ~/ 5) + 1).clamp(
            1,
            3,
          );
        });
      }

      _checkAndUpdateDailyStreak();
    } catch (_) {}
  }

  Future<void> _checkAndUpdateDailyStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastActive = prefs.getString('foodie_game_last_active_date') ?? '';

    if (lastActive == todayStr) return;

    int currentStreak = prefs.getInt('foodie_game_daily_streak') ?? 0;
    int maxStreak = prefs.getInt('foodie_game_max_streak') ?? 0;

    if (lastActive.isNotEmpty) {
      final lastDate = DateTime.tryParse(lastActive);
      if (lastDate != null) {
        final diff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;
        if (diff == 1) {
          currentStreak += 1;
        } else if (diff > 1) {
          currentStreak = 1;
        }
      } else {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }

    if (currentStreak > maxStreak) maxStreak = currentStreak;

    await prefs.setString('foodie_game_last_active_date', todayStr);
    await prefs.setInt('foodie_game_daily_streak', currentStreak);
    await prefs.setInt('foodie_game_max_streak', maxStreak);

    if (mounted) {
      setState(() {
        _dailyStreak = currentStreak;
      });
    }
  }

  Future<void> _addScore(int points) async {
    if (points <= 0) return;
    setState(() => _totalScore += points);
    try {
      await RewardBorderService.instance.awardGamePoints(
        gameType: 'kulinerdle',
        score: points,
      );
    } catch (_) {
      try {
        await SupabaseService.instance.saveGameScore(points);
      } catch (_) {}
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GAME 1: KUIS TRIVIA LOGIC
  // ───────────────────────────────────────────────────────────────────────────
  LevelConfig _getQuizLevelConfig(int level) {
    return kQuizLevelsConfig.firstWhere(
      (c) => c.level == level,
      orElse: () => kQuizLevelsConfig.first,
    );
  }

  void _startQuizLevel(int level) {
    final config = _getQuizLevelConfig(level);
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

    if (selected.length < config.questionCount) {
      final fallback = List<GameQuestion>.from(kQuizQuestions)
        ..shuffle(_random);
      for (final q in fallback) {
        if (selected.length >= config.questionCount) break;
        if (!selected.contains(q)) selected.add(q);
      }
    }

    setState(() {
      _selectedQuizLevel = level;
      _quizSessionQuestions = selected
          .map((q) => _ActiveQuestion.from(q, _random))
          .toList();
      _quizQuestionIndex = 0;
      _quizCorrectAnswers = 0;
      _quizScoreInLevel = 0;
      _quizCombo = 1;
      _quizHighestCombo = 1;
      _quizLives = 3;
      _usedFiftyFifty = false;
      _usedFreezeTime = false;
      _usedClue = false;
      _quizSelectedIndex = null;
      _quizAnswered = false;
      _currentView = _GameView.quizPlaying;
    });

    _startQuizTimer(config.timePerQuestion);
  }

  void _startQuizTimer(int totalSecs) {
    _quizTimer?.cancel();
    _quizSecondsLeft = totalSecs;
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_quizSecondsLeft <= 1) {
        t.cancel();
        if (!_quizAnswered) {
          _handleQuizTimeout();
        }
      } else {
        setState(() => _quizSecondsLeft--);
      }
    });
  }

  void _handleQuizTimeout() {
    setState(() {
      _quizAnswered = true;
      _quizSelectedIndex = -1;
      _quizCombo = 1;
      _quizLives--;
    });

    if (_quizLives <= 0) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _currentView = _GameView.quizGameOver);
      });
    } else {
      Future.delayed(const Duration(seconds: 2), _advanceQuizQuestion);
    }
  }

  void _selectQuizOption(int index) {
    if (_quizAnswered) return;
    _quizTimer?.cancel();

    final config = _getQuizLevelConfig(_selectedQuizLevel);
    final activeQ = _quizSessionQuestions[_quizQuestionIndex];
    final correct = index == activeQ.correctIndex;

    setState(() {
      _quizSelectedIndex = index;
      _quizAnswered = true;

      if (correct) {
        final earned = config.basePoints * _quizCombo;
        _quizScoreInLevel += earned;
        _quizCorrectAnswers++;
        _quizCombo++;
        if (_quizCombo > _quizHighestCombo) _quizHighestCombo = _quizCombo;
      } else {
        _quizCombo = 1;
        _quizLives--;
      }
    });

    if (_quizLives <= 0) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _currentView = _GameView.quizGameOver);
      });
    }
  }

  void _advanceQuizQuestion() {
    final config = _getQuizLevelConfig(_selectedQuizLevel);
    if (_quizQuestionIndex < _quizSessionQuestions.length - 1) {
      setState(() {
        _quizQuestionIndex++;
        _quizSelectedIndex = null;
        _quizAnswered = false;
      });
      _startQuizTimer(config.timePerQuestion);
    } else {
      _finishQuizLevel();
    }
  }

  Future<void> _finishQuizLevel() async {
    final totalQ = _quizSessionQuestions.length;
    final pct = totalQ > 0 ? (_quizCorrectAnswers / totalQ) : 0.0;
    int stars = 1;
    if (pct >= 0.9 && _quizLives == 3) {
      stars = 3;
    } else if (pct >= 0.7) {
      stars = 2;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentStars = _quizStars[_selectedQuizLevel] ?? 0;
      if (stars > currentStars) {
        _quizStars[_selectedQuizLevel] = stars;
        await prefs.setInt('foodie_quiz_stars_$_selectedQuizLevel', stars);
      }

      if (_selectedQuizLevel >= _unlockedQuizLevel &&
          _selectedQuizLevel < kQuizLevelsConfig.length) {
        _unlockedQuizLevel = _selectedQuizLevel + 1;
        await prefs.setInt('foodie_quiz_unlocked_level', _unlockedQuizLevel);
      }

      await _addScore(_quizScoreInLevel);
    } catch (_) {}

    if (mounted) setState(() => _currentView = _GameView.quizSummary);
  }

  void _useFiftyFifty() {
    if (_usedFiftyFifty || _quizAnswered) return;
    final activeQ = _quizSessionQuestions[_quizQuestionIndex];
    final wrongIndices = <int>[];
    for (int i = 0; i < activeQ.shuffledOptions.length; i++) {
      if (i != activeQ.correctIndex) wrongIndices.add(i);
    }
    wrongIndices.shuffle(_random);
    setState(() {
      _usedFiftyFifty = true;
      activeQ.eliminatedIndices.addAll(wrongIndices.take(2));
    });
  }

  void _useFreezeTime() {
    if (_usedFreezeTime || _quizAnswered) return;
    setState(() {
      _usedFreezeTime = true;
      _quizSecondsLeft += 10;
    });
  }

  void _useClue() {
    if (_usedClue || _quizAnswered) return;
    final activeQ = _quizSessionQuestions[_quizQuestionIndex];
    setState(() => _usedClue = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💡 Petunjuk: ${activeQ.original.hint}'),
        backgroundColor: AppColors.charcoal,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GAME 2: KULINERDLE LOGIC
  // ───────────────────────────────────────────────────────────────────────────
  void _initKulinerdleWord({
    bool randomFreePlay = true,
    bool showToast = false,
  }) {
    setState(() {
      _isDailyKulinerdle = !randomFreePlay;
      _kulinerdleTarget = randomFreePlay
          ? getRandomKulinerdleWord(null, _recentKulinerdleWords)
          : getDailyKulinerdleWord();
      _kulinerdleGuesses.clear();
      _kulinerdleCurrentInput = '';
      _kulinerdleGameOver = false;
      _kulinerdleKeyEvaluations.clear();
    });

    if (randomFreePlay) {
      if (!_recentKulinerdleWords.contains(_kulinerdleTarget.word)) {
        _recentKulinerdleWords.add(_kulinerdleTarget.word);
        if (_recentKulinerdleWords.length > 25) {
          _recentKulinerdleWords.removeAt(0);
        }
        SharedPreferences.getInstance().then((prefs) {
          prefs.setStringList(
            'foodie_recent_kulinerdle_words',
            _recentKulinerdleWords,
          );
        });
      }
    }

    if (showToast) {
      _showToast(
        randomFreePlay
            ? 'Kata baru diacak! Tebak masakannya 🍜'
            : 'Beralih ke Tantangan Harian 📅',
      );
    }
  }

  void _onVirtualKeyPress(String char) {
    if (_kulinerdleGameOver) return;
    if (_kulinerdleCurrentInput.length < 5) {
      setState(() => _kulinerdleCurrentInput += char.toUpperCase());
    }
  }

  void _onVirtualBackspace() {
    if (_kulinerdleGameOver || _kulinerdleCurrentInput.isEmpty) return;
    setState(() {
      _kulinerdleCurrentInput = _kulinerdleCurrentInput.substring(
        0,
        _kulinerdleCurrentInput.length - 1,
      );
    });
  }

  void _onVirtualEnter() {
    if (_kulinerdleGameOver) return;

    if (_kulinerdleCurrentInput.length < 5) {
      _showToast('Kata harus terdiri dari 5 huruf!');
      return;
    }

    final guess = _kulinerdleCurrentInput.toUpperCase();
    if (!kKulinerdleValidWords.contains(guess)) {
      _showToast('Kata "$guess" belum ada di kamus kuliner!');
      return;
    }

    setState(() {
      _kulinerdleGuesses.add(guess);
      _kulinerdleCurrentInput = '';
      _updateKeyEvaluations(guess);
    });

    final target = _kulinerdleTarget.word.toUpperCase();
    if (guess == target) {
      _handleKulinerdleWin();
    } else if (_kulinerdleGuesses.length >= 6) {
      _handleKulinerdleLoss();
    }
  }

  void _updateKeyEvaluations(String guess) {
    final evals = _evaluateGuess(guess, _kulinerdleTarget.word);
    for (int i = 0; i < guess.length; i++) {
      final char = guess[i];
      final current = _kulinerdleKeyEvaluations[char];
      final newEval = evals[i];

      if (current == LetterEvaluation.correct) continue;
      if (newEval == LetterEvaluation.correct) {
        _kulinerdleKeyEvaluations[char] = LetterEvaluation.correct;
      } else if (newEval == LetterEvaluation.present &&
          current != LetterEvaluation.correct) {
        _kulinerdleKeyEvaluations[char] = LetterEvaluation.present;
      } else if (current == null) {
        _kulinerdleKeyEvaluations[char] = LetterEvaluation.absent;
      }
    }
  }

  List<LetterEvaluation> _evaluateGuess(String guess, String target) {
    final result = List<LetterEvaluation>.filled(5, LetterEvaluation.absent);
    final targetChars = target.split('');
    final guessChars = guess.split('');

    for (int i = 0; i < 5; i++) {
      if (guessChars[i] == targetChars[i]) {
        result[i] = LetterEvaluation.correct;
        targetChars[i] = '#';
        guessChars[i] = '*';
      }
    }

    for (int i = 0; i < 5; i++) {
      if (guessChars[i] != '*') {
        final matchIdx = targetChars.indexOf(guessChars[i]);
        if (matchIdx != -1) {
          result[i] = LetterEvaluation.present;
          targetChars[matchIdx] = '#';
        }
      }
    }

    return result;
  }

  Future<void> _handleKulinerdleWin() async {
    setState(() => _kulinerdleGameOver = true);
    final attempt = _kulinerdleGuesses.length;
    final int pointsEarned = (160 - (attempt * 15)).clamp(50, 150);

    if (_kulinerdleTarget.word == 'GUDEG') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('foodie_game_achieve_gudeg', true);
    }

    _kdPlayed++;
    _kdWon++;
    _kdCurrentStreak++;
    if (_kdCurrentStreak > _kdMaxStreak) _kdMaxStreak = _kdCurrentStreak;
    _kdGuessDistribution[attempt] = (_kdGuessDistribution[attempt] ?? 0) + 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kulinerdle_played', _kdPlayed);
    await prefs.setInt('kulinerdle_won', _kdWon);
    await prefs.setInt('kulinerdle_current_streak', _kdCurrentStreak);
    await prefs.setInt('kulinerdle_max_streak', _kdMaxStreak);
    await prefs.setInt(
      'kulinerdle_dist_$attempt',
      _kdGuessDistribution[attempt] ?? 0,
    );

    await _addScore(pointsEarned);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showKulinerdleResultModal(won: true, points: pointsEarned);
    });
  }

  Future<void> _handleKulinerdleLoss() async {
    setState(() => _kulinerdleGameOver = true);
    _kdPlayed++;
    _kdCurrentStreak = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kulinerdle_played', _kdPlayed);
    await prefs.setInt('kulinerdle_current_streak', 0);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showKulinerdleResultModal(won: false, points: 0);
    });
  }

  void _showKulinerdleResultModal({required bool won, required int points}) {
    final wordObj = _kulinerdleTarget;
    final isGudeg = wordObj.word == 'GUDEG';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (won ? AppColors.green : AppColors.tomato).withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    won ? '🏆' : '💔',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                won ? 'KATA TERPECAHKAN!' : 'KESEMPATAN HABIS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: won ? AppColors.green : AppColors.tomato,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                wordObj.word,
                style: AppText.display(
                  24,
                  color: AppColors.charcoal,
                  letterSpacing: 3,
                ),
              ),
              Text(
                wordObj.category,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slateBlue,
                ),
              ),
              const SizedBox(height: 14),

              if (won) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            size: 16,
                            color: AppColors.saffron,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$points Poin Rasa',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tebakan ${_kulinerdleGuesses.length}/6',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.slateBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Fun Fact Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          size: 16,
                          color: AppColors.paprika,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isGudeg
                              ? 'FAKTA SPESIAL GUDEG JOGJA'
                              : 'FAKTA KULINER NUSANTARA',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.paprika,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      wordObj.funFact,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.charcoal,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Button: Temukan di Direktori Resto
              PrimaryButton(
                label: isGudeg
                    ? 'Temukan Gudeg di Direktori Resto'
                    : 'Temukan ${wordObj.searchQuery} di Resto Terdekat',
                icon: Icons.travel_explore_rounded,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _openDirectorySearch(wordObj.searchQuery);
                },
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.charcoal,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _initKulinerdleWord(randomFreePlay: true);
                      },
                      child: const Text(
                        'Main Kata Lain 🔄',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.charcoal,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() => _currentView = _GameView.hub);
                      },
                      child: const Text(
                        'Beranda Game 🏠',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDirectorySearch(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          body: ExploreTab(initialQuery: query),
        ),
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.charcoal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GAME 3: DETEKTIF KASUS LOGIC
  // ───────────────────────────────────────────────────────────────────────────
  void _startCooldownTimer(int seconds) {
    _cooldownTimer?.cancel();
    _cooldownRemainingSeconds = seconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      if (_cooldownRemainingSeconds <= 1) {
        timer.cancel();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('foodie_game_cooldown_end');
        setState(() {
          _cooldownRemainingSeconds = 0;
          _detectiveLives = 3;
        });
      } else {
        setState(() => _cooldownRemainingSeconds--);
      }
    });
  }

  Future<void> _triggerCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final cooldownEnd =
        DateTime.now().millisecondsSinceEpoch +
        (_cooldownDurationSeconds * 1000);
    await prefs.setInt('foodie_game_cooldown_end', cooldownEnd);
    _startCooldownTimer(_cooldownDurationSeconds);
  }

  Future<void> _instantRestoreDetectiveLives() async {
    const cost = 50;
    if (_totalScore < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Poin Rasa tidak cukup untuk pemulihan cepat (butuh 50 Poin Rasa).',
          ),
          backgroundColor: AppColors.tomato,
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('foodie_game_cooldown_end');
      _cooldownTimer?.cancel();
      await SupabaseService.instance.saveGameScore(-cost);

      if (mounted) {
        setState(() {
          _totalScore = (_totalScore - cost).clamp(0, 999999);
          _detectiveLives = 3;
          _cooldownRemainingSeconds = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ 3 Hati berhasil dipulihkan secara instan!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (_) {}
  }

  void _startDetectiveCase(DetectiveCase c) {
    if (_detectiveLives <= 0 && _cooldownRemainingSeconds > 0) {
      _showCooldownDialog();
      return;
    }

    // Checkpoint Pengaman: Begitu kasus dibuka atau dimainkan, pastikan level ini
    // tercatat sebagai checkpoint permanen (tahan logout & pembersihan cache).
    if (c.level > _unlockedDetectiveLevel) {
      _unlockedDetectiveLevel = c.level;
    }
    _persistDetectiveCheckpoint(_unlockedDetectiveLevel);

    setState(() {
      _activeCase = c;
      _currentSceneIndex = 0;
      _detectiveLives = 3;
      final firstScene = c.scenes.isNotEmpty ? c.scenes.first : null;
      _bossHp =
          (firstScene != null &&
              firstScene.isBossFight &&
              firstScene.boss != null)
          ? firstScene.boss!.maxHp
          : 100;
      _gatheredClueIds.clear();
      _gatheredClues.clear();
      _selectedChoiceIndicesInScene.clear();
      _currentView = _GameView.detectiveInvestigation;
    });
  }

  CaseScene? get _currentScene {
    if (_activeCase == null || _activeCase!.scenes.isEmpty) return null;
    if (_currentSceneIndex < 0 ||
        _currentSceneIndex >= _activeCase!.scenes.length) {
      return null;
    }
    return _activeCase!.scenes[_currentSceneIndex];
  }

  void _handleDetectiveChoice(int choiceIndex, SceneChoice choice) {
    final scene = _currentScene;
    if (scene == null) return;

    setState(() {
      _selectedChoiceIndicesInScene.add(choiceIndex);

      if (choice.foundClue != null &&
          !_gatheredClueIds.contains(choice.foundClue!.id)) {
        _gatheredClueIds.add(choice.foundClue!.id);
        _gatheredClues.add(choice.foundClue!);
      }

      if (choice.losesLife) {
        _detectiveLives = (_detectiveLives - 1).clamp(0, 3).toInt();
      }

      if (scene.isBossFight && choice.bossDamage > 0) {
        _bossHp = (_bossHp - choice.bossDamage).clamp(0, 100).toInt();
      }
    });

    _showDetectiveChoiceFeedback(choice, scene);
  }

  void _showDetectiveChoiceFeedback(SceneChoice choice, CaseScene scene) {
    final hasNextScene = choice.nextSceneId != null;
    final isBossDefeated =
        scene.isBossFight &&
        (_bossHp <= 0 || choice.isCorrect) &&
        !hasNextScene;
    final isGameOver = _detectiveLives <= 0;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (choice.isCorrect
                                  ? AppColors.green
                                  : AppColors.tomato)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      choice.isCorrect
                          ? 'DEDUKSI TEPAT'
                          : 'KESALAHAN INVESTIGASI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: choice.isCorrect
                            ? AppColors.green
                            : AppColors.tomato,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Icon(
                          index < _detectiveLives
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: index < _detectiveLives
                              ? AppColors.tomato
                              : Colors.black12,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                choice.feedback,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 14),

              if (choice.foundClue != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.saffron.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        choice.foundClue!.icon,
                        size: 20,
                        color: AppColors.paprika,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              choice.foundClue!.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoal,
                              ),
                            ),
                            Text(
                              choice.foundClue!.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.slateBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              PrimaryButton(
                label: isGameOver
                    ? 'Investigasi Terhenti (Nyawa Habis)'
                    : (isBossDefeated
                          ? 'Kasus Selesai: Lihat Hasil 🏆'
                          : (hasNextScene
                                ? 'Lanjut ke Tahap Berikutnya ➔'
                                : (scene.isBossFight
                                      ? 'Lanjutkan Konfrontasi ⚔️'
                                      : 'Langkah Selanjutnya ➔'))),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _afterDetectiveFeedbackNavigation(
                    choice: choice,
                    scene: scene,
                    isBossDefeated: isBossDefeated,
                    isGameOver: isGameOver,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _afterDetectiveFeedbackNavigation({
    required SceneChoice choice,
    required CaseScene scene,
    required bool isBossDefeated,
    required bool isGameOver,
  }) {
    if (isGameOver) {
      _triggerCooldown();
      setState(() => _currentView = _GameView.detectiveBadEnding);
      return;
    }

    if (isBossDefeated) {
      final stars = _detectiveLives == 3 ? 3 : (_detectiveLives == 2 ? 2 : 1);
      final points = _activeCase?.baseReward ?? 250;
      _saveDetectiveCaseProgress(
        level: _activeCase!.level,
        stars: stars,
        pointsEarned: points,
      );
      setState(() => _currentView = _GameView.detectiveGoodEnding);
      return;
    }

    if (choice.nextSceneId != null) {
      final nextIdx = _activeCase!.scenes.indexWhere(
        (s) => s.id == choice.nextSceneId,
      );
      if (nextIdx != -1) {
        setState(() {
          _currentSceneIndex = nextIdx;
          _selectedChoiceIndicesInScene.clear();
          final nextScene = _activeCase!.scenes[nextIdx];
          if (nextScene.isBossFight && nextScene.boss != null) {
            // Reinitialize boss HP when entering a new boss fight scene or stage
            if (!scene.isBossFight || nextScene.id != scene.id) {
              _bossHp = nextScene.boss!.maxHp;
            }
          }
        });
        return;
      }
    }

    if (scene.isBossFight) return;

    if (_currentSceneIndex < _activeCase!.scenes.length - 1) {
      setState(() {
        _currentSceneIndex++;
        _selectedChoiceIndicesInScene.clear();
        final nextScene = _activeCase!.scenes[_currentSceneIndex];
        if (nextScene.isBossFight && nextScene.boss != null) {
          if (!scene.isBossFight) {
            _bossHp = nextScene.boss!.maxHp;
          }
        }
      });
    } else {
      final stars = _detectiveLives == 3 ? 3 : (_detectiveLives == 2 ? 2 : 1);
      final points = _activeCase?.baseReward ?? 250;
      _saveDetectiveCaseProgress(
        level: _activeCase!.level,
        stars: stars,
        pointsEarned: points,
      );
      setState(() => _currentView = _GameView.detectiveGoodEnding);
    }
  }

  Future<void> _saveDetectiveCaseProgress({
    required int level,
    required int stars,
    required int pointsEarned,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = SupabaseService.instance.userId;

      // 1. Simpan Bintang Kasus (SharedPreferences + Hive)
      final currentStars = _detectiveStars[level] ?? 0;
      final newStars = max(currentStars, stars);
      _detectiveStars[level] = newStars;

      await prefs.setInt('foodie_game_stars_$level', newStars);
      if (uid != null && uid.isNotEmpty) {
        await prefs.setInt('foodie_game_stars_${level}_$uid', newStars);
      }
      await HiveService.instance.saveDetectiveStars(level, newStars, uid);

      // 2. Majukan Checkpoint ke level berikutnya (Level + 1)
      final nextLevel = level + 1;
      final targetUnlocked = max(_unlockedDetectiveLevel, nextLevel).clamp(1, kDetectiveCases.length);
      _unlockedDetectiveLevel = targetUnlocked;

      await prefs.setInt('foodie_game_unlocked_level', targetUnlocked);
      if (uid != null && uid.isNotEmpty) {
        await prefs.setInt('foodie_game_unlocked_level_$uid', targetUnlocked);
      }

      // Checkpoint permanen jika mencapai level 3 atau lebih (Bab 1 Level 3 Guarantee)
      if (targetUnlocked >= 3) {
        await prefs.setBool('foodie_game_checkpoint_lv3_unlocked', true);
        if (uid != null && uid.isNotEmpty) {
          await prefs.setBool('foodie_game_checkpoint_lv3_unlocked_$uid', true);
        }
      }

      // Simpan ke database NoSQL lokal Hive
      await HiveService.instance.saveDetectiveUnlockedLevel(targetUnlocked, uid);

      // Sinkronisasi ke Supabase Cloud User Metadata
      _syncDetectiveProgressToCloud(targetUnlocked, _detectiveStars);

      await _addScore(pointsEarned);
    } catch (_) {}
  }

  /// Memperkuat checkpoint level agar tersimpan permanen di semua lapisan
  Future<void> _persistDetectiveCheckpoint(int level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = SupabaseService.instance.userId;
      final target = max(_unlockedDetectiveLevel, level).clamp(1, kDetectiveCases.length);
      _unlockedDetectiveLevel = target;

      await prefs.setInt('foodie_game_unlocked_level', target);
      if (uid != null && uid.isNotEmpty) {
        await prefs.setInt('foodie_game_unlocked_level_$uid', target);
      }
      if (target >= 3) {
        await prefs.setBool('foodie_game_checkpoint_lv3_unlocked', true);
        if (uid != null && uid.isNotEmpty) {
          await prefs.setBool('foodie_game_checkpoint_lv3_unlocked_$uid', true);
        }
      }
      await HiveService.instance.saveDetectiveUnlockedLevel(target, uid);
      _syncDetectiveProgressToCloud(target, _detectiveStars);
    } catch (_) {}
  }

  /// Menyinkronkan progres level & bintang ke Supabase Auth User Metadata (Cloud)
  Future<void> _syncDetectiveProgressToCloud(int unlockedLevel, Map<int, int> stars) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final existingData = user.userMetadata ?? {};
        final curCloudLv = existingData['foodie_detective_unlocked_level'] as int? ?? 1;
        if (unlockedLevel >= curCloudLv) {
          await client.auth.updateUser(
            UserAttributes(
              data: {
                ...existingData,
                'foodie_detective_unlocked_level': unlockedLevel,
                'foodie_checkpoint_lv3': unlockedLevel >= 3,
                'foodie_detective_stars': stars.map((k, v) => MapEntry(k.toString(), v)),
              },
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _openClueNotebook() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Mini Hero Header Banner
              Container(
                height: 90,
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/detective_board.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: AppColors.charcoal),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'PAPAN BUKTI INVESTIGASI',
                                    style: AppText.display(
                                      14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Arsip bukti otentik yang berhasil dikumpulkan',
                                    style: AppText.body(
                                      11,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                '${_gatheredClues.length} Bukti',
                                style: AppText.display(
                                  11,
                                  color: AppColors.saffron,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: AppColors.line, height: 1),
              ),
              Expanded(
                child: _gatheredClues.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: AppColors.slateBlue.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum Ada Bukti Terkumpul',
                                style: AppText.display(
                                  15,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pilih opsi investigasi dan interogasi saksi untuk mengamankan bukti kasus.',
                                textAlign: TextAlign.center,
                                style: AppText.body(
                                  12,
                                  color: AppColors.slateBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _gatheredClues.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final clue = _gatheredClues[idx];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    clue.icon,
                                    color: AppColors.paprika,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              clue.title,
                                              style: AppText.display(
                                                13.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.charcoal,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.saffron
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'BUKTI #${idx + 1}',
                                              style: AppText.display(
                                                9,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.paprika,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        clue.description,
                                        style: AppText.body(
                                          11.5,
                                          color: AppColors.slateBlue,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCooldownDialog() {
    final mins = _cooldownRemainingSeconds ~/ 60;
    final secs = _cooldownRemainingSeconds % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Penyelidikan Ditangguhkan',
            style: TextStyle(
              color: AppColors.charcoal,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hati detektif sedang dalam masa pemulihan.',
                style: TextStyle(color: AppColors.slateBlue, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Tunggu',
                style: TextStyle(color: AppColors.slateBlue),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _instantRestoreDetectiveLives();
              },
              child: const Text('Pulihkan (50 Poin Rasa)'),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MASTER BUILD METHOD (App PageBackground Aesthetic)
  // ───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageBackground(
        child: switch (_currentView) {
          _GameView.hub => _buildHubView(),
          // Quiz
          _GameView.quizLevelSelect => _buildQuizLevelSelectView(),
          _GameView.quizPlaying => _buildQuizPlayingView(),
          _GameView.quizSummary => _buildQuizSummaryView(),
          _GameView.quizGameOver => _buildQuizGameOverView(),
          // Kulinerdle
          _GameView.kulinerdle => _buildKulinerdleView(),
          // Detective
          _GameView.detectiveCaseSelect => _buildDetectiveCaseSelectView(),
          _GameView.detectiveInvestigation =>
            _buildDetectiveInvestigationView(),
          _GameView.detectiveGoodEnding => _buildDetectiveGoodEndingView(),
          _GameView.detectiveBadEnding => _buildDetectiveBadEndingView(),
        },
      ),
    );
  }

  // ===========================================================================
  // 1. GAME HUB (Matches Real App Profile & Palette)
  // ===========================================================================
  Widget _buildHubView() {
    final solvedCases = _detectiveStars.values.where((s) => s > 0).length;
    int totalQuizStars = 0;
    for (final s in _quizStars.values) {
      totalQuizStars += s;
    }

    final p = _realProfile;
    final displayName = p?.displayName.isNotEmpty == true
        ? p!.displayName
        : (SupabaseService.instance.currentUser?.userMetadata?['name']
                  as String?) ??
              'Kurator Rasa';
    final levelTitle = p?.levelTitle ?? 'Pemula Rasa';
    final curatorLevel = p?.curatorLevel ?? 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      children: [
        // App Bar
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
                  border: Border.all(color: AppColors.line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ARENA PERMAINAN FOODIE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text('Pusat Game Kuliner', style: AppText.display(18)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 16,
                    color: AppColors.saffron,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$_totalScore',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Real Profile Card (No overlapping elements)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Real Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.surfaceSubtle,
                    backgroundImage:
                        (p?.avatarUrl != null && p!.avatarUrl!.isNotEmpty)
                        ? NetworkImage(p.avatarUrl!)
                        : null,
                    child: (p?.avatarUrl == null || p!.avatarUrl!.isEmpty)
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'F',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: AppText.display(16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'LV $curatorLevel',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          levelTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slateBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Daily Streak Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🔥 $_dailyStreak',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                        const Text(
                          'Hari Streak',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.slateBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.line, height: 24),
              // Stats Overview Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    'Kuis Selesai',
                    '$_unlockedQuizLevel/6',
                    Icons.quiz_rounded,
                    AppColors.orange,
                  ),
                  Container(width: 1, height: 26, color: AppColors.line),
                  _buildStatColumn(
                    'Kulinerdle',
                    '$_kdWon Menang',
                    Icons.grid_on_rounded,
                    AppColors.green,
                  ),
                  Container(width: 1, height: 26, color: AppColors.line),
                  _buildStatColumn(
                    'Kasus Selesai',
                    '$solvedCases/15',
                    Icons.local_police_rounded,
                    AppColors.charcoal,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section Title: 3 Pilihan Game
        Text(
          'PILIH PERMAINAN KULINER',
          style: AppText.display(
            13,
            color: AppColors.slateBlue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        // GAME CARD 1: KUIS KULINER MATARAMAN
        _buildHubGameCard(
          title: 'Kuis Kuliner Mataraman',
          badge: '6 LEVEL • TRIVIA KLASIK • LIFELINES',
          badgeColor: AppColors.orange,
          icon: Icons.quiz_rounded,
          description: 'Uji wawasan rasa legendaris Jogja & Jawa Tengah dengan batas waktu, combo skor, dan bantuan 50:50.',
          stats:
              'Level Terbuka: $_unlockedQuizLevel/6 • Total Bintang: $totalQuizStars ⭐',
          ctaText: 'Mulai Kuis ➔',
          onTap: () => setState(() => _currentView = _GameView.quizLevelSelect),
        ),
        const SizedBox(height: 14),

        // GAME CARD 2: KULINERDLE NUSANTARA
        _buildHubGameCard(
          title: 'Kulinerdle Nusantara',
          badge: 'WORDLE 5 HURUF • TANTANGAN HARIAN',
          badgeColor: AppColors.green,
          icon: Icons.grid_on_rounded,
          description: 'Tebak kata masakan khas nusantara 5 huruf dalam 6 kesempatan dengan keyboard virtual dan rekomendasi direktori.',
          stats: 'Menang: $_kdWon/$_kdPlayed • Streak: 🔥 $_kdCurrentStreak',
          ctaText: 'Mainkan Kulinerdle ➔',
          onTap: () {
            if (_kulinerdleGameOver || _kulinerdleGuesses.isEmpty) {
              _initKulinerdleWord(randomFreePlay: true);
            }
            setState(() => _currentView = _GameView.kulinerdle);
          },
        ),
        const SizedBox(height: 14),

        // GAME CARD 3: PILIH JALANMU (DETEKTIF KASUS)
        _buildHubGameCard(
          title: 'Pilih Jalanmu: Detektif Kuliner',
          badge: '15 KASUS • 3 BABAK • BOSS FIGHT',
          badgeColor: AppColors.charcoal,
          icon: Icons.local_police_rounded,
          description: 'Investigasi misteri kriminal kuliner nusantara, kumpulkan bukti fisik, dan hadapi dalang utama.',
          stats: 'Kasus: $solvedCases/15 • Nyawa: ❤️ $_detectiveLives',
          ctaText: 'Buka Berkas Kasus ➔',
          onTap: () =>
              setState(() => _currentView = _GameView.detectiveCaseSelect),
        ),
      ],
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.slateBlue),
        ),
      ],
    );
  }

  Widget _buildHubGameCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required String description,
    required String stats,
    required String ctaText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(icon, color: badgeColor, size: 24),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title, style: AppText.display(16)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slateBlue,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        stats,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ctaText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. GAME 1: KUIS TRIVIA VIEWS
  // ===========================================================================
  Widget _buildQuizLevelSelectView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _currentView = _GameView.hub),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PILIH LEVEL KUIS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                  Text('Kuis Kuliner Mataraman', style: AppText.display(17)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...kQuizLevelsConfig.map((cfg) {
          final isUnlocked = cfg.level <= _unlockedQuizLevel;
          final stars = _quizStars[cfg.level] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: isUnlocked
                    ? AppColors.surfaceSubtle
                    : AppColors.line,
                child: Icon(
                  isUnlocked ? cfg.icon : Icons.lock_rounded,
                  color: isUnlocked ? AppColors.orange : AppColors.slateBlue,
                ),
              ),
              title: Text(
                'Level ${cfg.level}: ${cfg.title}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    cfg.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slateBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (isUnlocked && stars > 0)
                    Row(
                      children: List.generate(
                        3,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: i < stars ? AppColors.saffron : AppColors.line,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: isUnlocked
                  ? const Icon(
                      Icons.play_circle_fill_rounded,
                      color: AppColors.orange,
                      size: 32,
                    )
                  : const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.slateBlue,
                      size: 20,
                    ),
              onTap: isUnlocked ? () => _startQuizLevel(cfg.level) : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuizPlayingView() {
    if (_quizSessionQuestions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }

    final activeQ = _quizSessionQuestions[_quizQuestionIndex];
    final progress = (_quizQuestionIndex + 1) / _quizSessionQuestions.length;

    return Column(
      children: [
        // App Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.charcoal,
                ),
                onPressed: () =>
                    setState(() => _currentView = _GameView.quizLevelSelect),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Soal ${_quizQuestionIndex + 1} dari ${_quizSessionQuestions.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.slateBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.line,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.orange,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Timer Ticker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _quizSecondsLeft <= 3
                      ? AppColors.tomato.withValues(alpha: 0.15)
                      : AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_quizSecondsLeft}s',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _quizSecondsLeft <= 3
                        ? AppColors.tomato
                        : AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              // Question Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeQ.original.category ?? 'Kuliner Mataraman',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeQ.original.question,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Options
              ...activeQ.shuffledOptions.asMap().entries.map((entry) {
                final idx = entry.key;
                final opt = entry.value;
                final isEliminated = activeQ.eliminatedIndices.contains(idx);
                if (isEliminated) return const SizedBox.shrink();

                Color bg = Colors.white;
                Color border = AppColors.line;
                Color text = AppColors.charcoal;

                if (_quizAnswered) {
                  if (idx == activeQ.correctIndex) {
                    bg = AppColors.green.withValues(alpha: 0.15);
                    border = AppColors.green;
                    text = AppColors.green;
                  } else if (idx == _quizSelectedIndex) {
                    bg = AppColors.tomato.withValues(alpha: 0.15);
                    border = AppColors.tomato;
                    text = AppColors.tomato;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: _quizAnswered ? null : () => _selectQuizOption(idx),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: 1.5),
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: text,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 14),

              // Lifelines Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLifelineButton(
                    '50:50',
                    Icons.filter_2_rounded,
                    _usedFiftyFifty,
                    _useFiftyFifty,
                  ),
                  _buildLifelineButton(
                    '+10 Detik',
                    Icons.timer_rounded,
                    _usedFreezeTime,
                    _useFreezeTime,
                  ),
                  _buildLifelineButton(
                    'Petunjuk',
                    Icons.lightbulb_rounded,
                    _usedClue,
                    _useClue,
                  ),
                ],
              ),
            ],
          ),
        ),

        if (_quizAnswered && _quizLives > 0)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: PrimaryButton(
              label: 'Lanjut Soal Berikutnya ➔',
              onPressed: _advanceQuizQuestion,
            ),
          ),
      ],
    );
  }

  Widget _buildLifelineButton(
    String label,
    IconData icon,
    bool used,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: used ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: used ? AppColors.line : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: used
                ? Colors.transparent
                : AppColors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: used ? AppColors.slateBlue : AppColors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: used ? AppColors.slateBlue : AppColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSummaryView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: Text('🏆', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Level $_selectedQuizLevel Selesai!',
            style: AppText.display(20),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Text(
                'Skor Didapat: +$_quizScoreInLevel Poin Rasa',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Jawaban Benar: $_quizCorrectAnswers / ${_quizSessionQuestions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slateBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Kembali ke Level Kuis',
          onPressed: () =>
              setState(() => _currentView = _GameView.quizLevelSelect),
        ),
      ],
    );
  }

  Widget _buildQuizGameOverView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: Text('💔', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Nyawa Habis!',
            style: AppText.display(20, color: AppColors.tomato),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Jangan menyerah, coba lagi untuk skor sempurna!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.slateBlue),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Coba Lagi Level Ini',
          onPressed: () => _startQuizLevel(_selectedQuizLevel),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () =>
              setState(() => _currentView = _GameView.quizLevelSelect),
          child: const Text('Kembali ke Menu Kuis'),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. GAME 2: KULINERDLE (Wordle Nusantara 5x6 with Zero Overlap)
  // ===========================================================================
  Widget _buildKulinerdleView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive tile size to strictly prevent vertical overflow
        final availableHeight = constraints.maxHeight;
        // Tile size clamped between 34 and 46
        final tileSize = ((availableHeight - 270) / 6).clamp(34.0, 46.0);

        return Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _currentView = _GameView.hub),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('KULINERDLE', style: AppText.display(15)),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                if (_isDailyKulinerdle) {
                                  _initKulinerdleWord(
                                    randomFreePlay: true,
                                    showToast: true,
                                  );
                                } else {
                                  _initKulinerdleWord(
                                    randomFreePlay: false,
                                    showToast: true,
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _isDailyKulinerdle
                                      ? AppColors.green.withValues(alpha: 0.15)
                                      : AppColors.orange.withValues(
                                          alpha: 0.15,
                                        ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color:
                                        (_isDailyKulinerdle
                                                ? AppColors.green
                                                : AppColors.orange)
                                            .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isDailyKulinerdle
                                          ? Icons.calendar_today_rounded
                                          : Icons.shuffle_rounded,
                                      size: 10,
                                      color: _isDailyKulinerdle
                                          ? AppColors.green
                                          : AppColors.orange,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _isDailyKulinerdle ? 'HARIAN' : 'ACAK',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: _isDailyKulinerdle
                                            ? AppColors.green
                                            : AppColors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Tebak 5 huruf masakan Nusantara',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.slateBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _initKulinerdleWord(
                      randomFreePlay: true,
                      showToast: true,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.casino_rounded,
                            size: 15,
                            color: AppColors.orange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Acak Kata',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content area with Zero Overlap
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Wordle 5x6 Board
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(6, (rowIdx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: _buildWordleRow(rowIdx, tileSize),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),

                    // Virtual Keyboard
                    _buildVirtualKeyboard(constraints.maxWidth),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWordleRow(int rowIdx, double size) {
    final isSubmitted = rowIdx < _kulinerdleGuesses.length;
    final isCurrent = rowIdx == _kulinerdleGuesses.length;
    final guess = isSubmitted
        ? _kulinerdleGuesses[rowIdx]
        : (isCurrent ? _kulinerdleCurrentInput : '');

    List<LetterEvaluation> evaluations = List.filled(5, LetterEvaluation.empty);
    if (isSubmitted) {
      evaluations = _evaluateGuess(guess, _kulinerdleTarget.word);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (colIdx) {
        final char = colIdx < guess.length ? guess[colIdx] : '';
        final eval = isSubmitted
            ? evaluations[colIdx]
            : (char.isNotEmpty
                  ? LetterEvaluation.pending
                  : LetterEvaluation.empty);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: _buildWordleTile(char, eval, size),
        );
      }),
    );
  }

  Widget _buildWordleTile(String char, LetterEvaluation eval, double size) {
    Color bg = Colors.white;
    Color border = AppColors.line;
    Color text = AppColors.charcoal;

    switch (eval) {
      case LetterEvaluation.correct:
        bg = AppColors.green;
        border = AppColors.green;
        text = Colors.white;
        break;
      case LetterEvaluation.present:
        bg = AppColors.saffron;
        border = AppColors.saffron;
        text = Colors.black;
        break;
      case LetterEvaluation.absent:
        bg = const Color(0xFFE2DDD5);
        border = const Color(0xFFE2DDD5);
        text = AppColors.slateBlue;
        break;
      case LetterEvaluation.pending:
        border = AppColors.orange;
        break;
      case LetterEvaluation.empty:
        border = AppColors.line;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: (size * 0.45).clamp(16.0, 22.0),
            fontWeight: FontWeight.w900,
            color: text,
          ),
        ),
      ),
    );
  }

  Widget _buildVirtualKeyboard(double screenWidth) {
    const row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
    const row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
    const row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

    final keyWidth = ((screenWidth - 44) / 10).clamp(26.0, 34.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row1.map((c) => _buildCharKey(c, keyWidth)).toList(),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row2.map((c) => _buildCharKey(c, keyWidth)).toList(),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSpecialKey(
                'ENTER',
                width: keyWidth * 1.5,
                onTap: _onVirtualEnter,
              ),
              ...row3.map((c) => _buildCharKey(c, keyWidth)),
              _buildSpecialKey(
                '⌫',
                width: keyWidth * 1.3,
                onTap: _onVirtualBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharKey(String char, double width) {
    final eval = _kulinerdleKeyEvaluations[char];
    Color bg = Colors.white;
    Color border = AppColors.line;
    Color text = AppColors.charcoal;

    if (eval == LetterEvaluation.correct) {
      bg = AppColors.green;
      border = AppColors.green;
      text = Colors.white;
    } else if (eval == LetterEvaluation.present) {
      bg = AppColors.saffron;
      border = AppColors.saffron;
      text = Colors.black;
    } else if (eval == LetterEvaluation.absent) {
      bg = const Color(0xFFE8E4DD);
      border = const Color(0xFFE8E4DD);
      text = Colors.black38;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: InkWell(
        onTap: () => _onVirtualKeyPress(char),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: width,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              char,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(
    String label, {
    required double width,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: width,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.line),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. GAME 3: DETEKTIF KASUS (Clean Authentic Palette)
  // ===========================================================================
  Widget _buildDetectiveCaseSelectView() {
    final chapterCases = kDetectiveCases
        .where((c) => c.chapter == _selectedChapter)
        .toList();
    final totalSolved = _detectiveStars.values.where((s) => s > 0).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
      children: [
        // Top App Bar
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _currentView = _GameView.hub),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.charcoal,
                ),
              ),
            ),
            const SizedBox(width: 14),
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
                          color: AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PILIH JALANMU',
                          style: AppText.display(
                            9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• DETEKTIF KULINER',
                        style: AppText.display(
                          9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slateBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Berkas Misteri Mataram',
                    style: AppText.display(17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Life Counter Hearts
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Icon(
                      i < _detectiveLives
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: i < _detectiveLives
                          ? AppColors.tomato
                          : AppColors.line,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),

        // Hero Dossier Illustration Banner
        Container(
          height: 140,
          margin: const EdgeInsets.only(top: 14, bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.charcoal.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/detective_board.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: AppColors.charcoal),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'ARSIP RAHASIA MATARAM',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.display(
                                        8.5,
                                        letterSpacing: 1.1,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              '$totalSolved/15 Kasus Tuntas',
                              style: AppText.display(
                                9.5,
                                color: AppColors.saffron,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PAPAN INVESTIGASI KASUS',
                        style: AppText.display(
                          17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pecahkan misteri kuliner otentik Yogyakarta & hadapi dalang sindikat rasa.',
                        style: AppText.body(
                          11,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_detectiveLives <= 0 && _cooldownRemainingSeconds > 0) ...[
          _buildDetectiveCooldownBanner(),
          const SizedBox(height: 16),
        ],

        // Chapter Tabs
        Row(
          children: [
            _buildChapterTabItem(1, 'Bab I', 'Kota Pusaka'),
            const SizedBox(width: 8),
            _buildChapterTabItem(2, 'Bab II', 'Jalur Mataram'),
            const SizedBox(width: 8),
            _buildChapterTabItem(3, 'Bab III', 'Sindikat'),
          ],
        ),
        const SizedBox(height: 16),

        ...chapterCases.map((c) => _buildDetectiveCaseCard(c)),
      ],
    );
  }

  Widget _buildDetectiveCooldownBanner() {
    final mins = _cooldownRemainingSeconds ~/ 60;
    final secs = _cooldownRemainingSeconds % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.tomato.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.tomato, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cooldown Investigasi Aktif',
                  style: AppText.display(
                    12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  'Hati pulih dalam: $timeStr',
                  style: AppText.body(11, color: AppColors.slateBlue),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: _instantRestoreDetectiveLives,
            child: Text(
              'Pulihkan',
              style: AppText.display(11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterTabItem(int num, String title, String subtitle) {
    final isSelected = _selectedChapter == num;
    final isLocked = num > 1 && _unlockedDetectiveLevel < ((num - 1) * 5 + 1);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (isLocked) {
            _showToast('Selesaikan Bab ${num - 1} untuk membuka babak ini.');
            return;
          }
          setState(() => _selectedChapter = num);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceSubtle : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.orange : AppColors.line,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: AppText.display(
                  11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? AppColors.orange
                      : (isLocked ? AppColors.line : AppColors.charcoal),
                ),
              ),
              Text(
                subtitle,
                style: AppText.body(
                  9.5,
                  color: isSelected ? AppColors.charcoal : AppColors.slateBlue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectiveCaseCard(DetectiveCase c) {
    final isUnlocked = c.level <= _unlockedDetectiveLevel;
    final stars = _detectiveStars[c.level] ?? 0;

    final accentColor = c.isCheckpoint
        ? AppColors.saffron
        : (isUnlocked ? AppColors.orange : AppColors.line);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? AppColors.line
              : AppColors.line.withValues(alpha: 0.6),
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: AppColors.charcoal.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Stripe
              Container(width: 5, color: accentColor),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isUnlocked ? () => _startDetectiveCase(c) : null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header badges
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: c.isCheckpoint
                                      ? AppColors.saffron.withValues(
                                          alpha: 0.18,
                                        )
                                      : AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: c.isCheckpoint
                                        ? AppColors.saffron.withValues(
                                            alpha: 0.4,
                                          )
                                        : AppColors.line,
                                  ),
                                ),
                                child: Text(
                                  c.isCheckpoint
                                      ? '🎖️ CHECKPOINT LV ${c.level}'
                                      : 'KASUS #${c.level.toString().padLeft(2, '0')}',
                                  style: AppText.display(
                                    9,
                                    fontWeight: FontWeight.bold,
                                    color: c.isCheckpoint
                                        ? AppColors.paprika
                                        : AppColors.slateBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: c.difficulty.color.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  c.difficulty.label.toUpperCase(),
                                  style: AppText.display(
                                    8.5,
                                    fontWeight: FontWeight.bold,
                                    color: c.difficulty.color,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (!isUnlocked)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 15,
                                      color: AppColors.slateBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Terkunci',
                                      style: AppText.display(
                                        9.5,
                                        color: AppColors.slateBlue,
                                      ),
                                    ),
                                  ],
                                )
                              else if (stars > 0)
                                Row(
                                  children: List.generate(
                                    3,
                                    (i) => Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: i < stars
                                          ? AppColors.saffron
                                          : AppColors.line,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'BARU',
                                    style: AppText.display(
                                      8.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.orange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Content Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isUnlocked
                                      ? AppColors.surfaceSubtle
                                      : const Color(0xFFF0EFEA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Center(
                                  child: Text(
                                    c.iconEmoji,
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: isUnlocked ? null : Colors.black26,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.title,
                                      style: AppText.display(
                                        13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isUnlocked
                                            ? AppColors.charcoal
                                            : AppColors.slateBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body(
                                        11,
                                        color: AppColors.slateBlue,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Bottom tags metadata
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 12,
                                      color: isUnlocked
                                          ? AppColors.orange
                                          : AppColors.slateBlue,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        c.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.body(
                                          10.5,
                                          color: AppColors.slateBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 12,
                                      color: AppColors.slateBlue,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        c.suspectName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.body(
                                          10.5,
                                          color: AppColors.slateBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${c.baseReward} XP',
                                style: AppText.display(
                                  10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.paprika,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectiveInvestigationView() {
    final c = _activeCase;
    final scene = _currentScene;
    if (c == null || scene == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }

    return Column(
      children: [
        // App Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.charcoal,
                ),
                onPressed: () => setState(
                  () => _currentView = _GameView.detectiveCaseSelect,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KASUS ${c.level} • TAHAP ${_currentSceneIndex + 1}/${c.scenes.length}',
                      style: AppText.display(
                        9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                        color: scene.isBossFight
                            ? AppColors.tomato
                            : AppColors.orange,
                      ),
                    ),
                    Text(
                      c.title,
                      style: AppText.display(13, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Life Counter
              Row(
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      i < _detectiveLives
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 15,
                      color: i < _detectiveLives
                          ? AppColors.tomato
                          : AppColors.line,
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              // Papan Bukti Button
              InkWell(
                onTap: _openClueNotebook,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: AppColors.paprika,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_gatheredClues.length} Bukti',
                        style: AppText.display(
                          10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              if (scene.isBossFight && scene.boss != null) ...[
                _buildDetectiveBossFightCard(c, scene, scene.boss!),
                const SizedBox(height: 18),
              ] else ...[
                // Normal Investigation Scene Header Illustration
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.charcoal.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/detective_investigation.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: AppColors.charcoal),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.75),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          bottom: 12,
                          right: 14,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.place_rounded,
                                        size: 12,
                                        color: AppColors.saffron,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          scene.location.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppText.display(
                                            9.5,
                                            letterSpacing: 0.8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'TKP INVESTIGASI',
                                  style: AppText.display(
                                    8.5,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dialogue Card (Speaker)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.charcoal.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceSubtle,
                          border: Border.all(
                            color: AppColors.saffron,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            scene.speakerAvatar,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scene.speakerName,
                              style: AppText.display(
                                13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.saffron.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                scene.speakerRole.toUpperCase(),
                                style: AppText.display(
                                  8.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.paprika,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Narrative Card (Confidential Culinary Dossier report)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            color: AppColors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LAPORAN INVESTIGASI LAPANGAN',
                            style: AppText.display(
                              9,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.bold,
                              color: AppColors.paprika,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.line, height: 16),
                      Text(
                        scene.narrative,
                        style: AppText.body(
                          13.5,
                          height: 1.55,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              Text(
                scene.isBossFight
                    ? 'TAKTIK SERANGAN LOGIKA DALANG:'
                    : 'PILIH LANGKAH INVESTIGASI:',
                style: AppText.display(
                  11,
                  fontWeight: FontWeight.bold,
                  color: scene.isBossFight
                      ? AppColors.tomato
                      : AppColors.slateBlue,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              ...scene.choices.asMap().entries.map((entry) {
                final idx = entry.key;
                final choice = entry.value;
                final isSelected = _selectedChoiceIndicesInScene.contains(idx);

                final choiceBorderColor = scene.isBossFight
                    ? (isSelected
                          ? AppColors.line
                          : AppColors.tomato.withValues(alpha: 0.5))
                    : (isSelected
                          ? AppColors.line
                          : choice.type.color.withValues(alpha: 0.5));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: isSelected
                        ? null
                        : () => _handleDetectiveChoice(idx, choice),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.surfaceSubtle
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: choiceBorderColor,
                          width: scene.isBossFight && !isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: !isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.charcoal.withValues(
                                    alpha: 0.04,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
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
                                  color: choice.type.color.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      choice.type.icon,
                                      size: 11,
                                      color: choice.type.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      choice.type.label.toUpperCase(),
                                      style: AppText.display(
                                        8.5,
                                        fontWeight: FontWeight.bold,
                                        color: choice.type.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            choice.text,
                            style: AppText.display(
                              13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.slateBlue
                                  : AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            choice.actionDetail,
                            style: AppText.body(
                              11,
                              color: AppColors.slateBlue,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _getBossIllustrationAsset(
    DetectiveCase c,
    CaseScene scene,
    BossConfrontation boss,
  ) {
    if (boss.imageAsset != null && boss.imageAsset!.isNotEmpty) {
      return boss.imageAsset!;
    }

    if (c.level == 15 ||
        scene.id.contains('boss_1') ||
        scene.id.contains('boss_2') ||
        scene.id.contains('boss_3')) {
      return 'assets/images/boss_final_tamansari.jpg';
    }

    final lower = boss.name.toLowerCase();
    if (boss.avatar == '👩‍🔬' ||
        boss.avatar == '💃' ||
        lower.contains('nyai') ||
        lower.contains('madam') ||
        lower.contains('ratu') ||
        lower.contains('siska')) {
      return 'assets/images/boss_femme_fatale.jpg';
    }

    switch (c.chapter) {
      case 1:
        return 'assets/images/boss_chapter_1.jpg';
      case 2:
        return 'assets/images/boss_chapter_2.jpg';
      case 3:
      default:
        return 'assets/images/boss_chapter_3.jpg';
    }
  }

  Widget _buildDetectiveBossFightCard(
    DetectiveCase c,
    CaseScene scene,
    BossConfrontation boss,
  ) {
    final hpPct = (_bossHp / boss.maxHp).clamp(0.0, 1.0);
    final illustrationAsset = _getBossIllustrationAsset(c, scene, boss);

    // Determine stage info if this is a multi-stage boss (like Case 15)
    final isCase15 = c.id == 'case_bale_raos_finale';
    String stageBadgeText = 'KONFRONTASI DALANG';
    if (isCase15) {
      if (scene.id == 'scene_boss_1') {
        stageBadgeText = 'TAHAP 1/3: ALTAR TAMANSARI';
      } else if (scene.id == 'scene_boss_2') {
        stageBadgeText = 'TAHAP 2/3: TERDESAK';
      } else if (scene.id == 'scene_boss_3') {
        stageBadgeText = 'TAHAP 3/3: SKAKMAT AKHIR';
      }
    } else if (scene.id == 'scene_boss_2') {
      stageBadgeText = 'SKAKMAT AKHIR';
    }

    final String phaseNarration;
    if (hpPct > 0.6) {
      phaseNarration =
          'Dalang masih bertahan dengan alibi palsunya. Terus bongkar celah pada argumennya!';
    } else if (hpPct > 0.25) {
      phaseNarration =
          'Pertahanan mental dalang mulai goyah! Kontradiksi argumennya kian terbukti nyata.';
    } else {
      phaseNarration =
          'Dalang tersudut di ambang kekalahan total! Tuntaskan dengan deduksi pamungkas.';
    }

    final chapterBadge = c.chapterTitle.split('(').first.trim().toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image with boss atmosphere & tailored illustration
            Stack(
              children: [
                SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: Image.asset(
                    illustrationAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.charcoal,
                      child: const Center(
                        child: Icon(
                          Icons.theater_comedy_rounded,
                          size: 44,
                          color: AppColors.saffron,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.88),
                        ],
                        stops: const [0.0, 0.42, 1.0],
                      ),
                    ),
                  ),
                ),
                // Top Badges Row (Chapter & Boss Fight Stage)
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield_rounded,
                              size: 11,
                              color: AppColors.saffron,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              chapterBadge,
                              style: AppText.display(
                                8.5,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paprika,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.gavel_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              stageBadgeText,
                              style: AppText.display(
                                8.5,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Boss Profile (Avatar, Name, Role & Location) over banner
                Positioned(
                  left: 14,
                  bottom: 10,
                  right: 14,
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppColors.orange, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            boss.avatar,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              boss.name,
                              style: AppText.display(
                                15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Text(
                                  boss.role.toUpperCase(),
                                  style: AppText.display(
                                    9.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.saffron,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    scene.location.split('-').first.trim().toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(
                                      9,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Card Body: Situasi Konfrontasi, Ancaman Tersangka & Ketahanan Mental
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Situasi Konfrontasi (Narrative)
                  Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 13,
                        color: AppColors.tomato,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SITUASI KONFRONTASI TERAKHIR',
                        style: AppText.display(
                          9,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tomato,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scene.narrative,
                    style: AppText.body(
                      13,
                      height: 1.5,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Berkas Konfrontasi: Alibi & Titik Lemah Argumen (Padat, Informatif & Tidak Kosong)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9EE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.saffron.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.charcoal.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header bar: Speaker Quote Tag & Status Chip
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.record_voice_over_rounded,
                                size: 13,
                                color: AppColors.paprika,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'DALIH & PERNYATAAN ${boss.name.toUpperCase()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.display(
                                  8.5,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.paprika,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tomato.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TERDESAK',
                                style: AppText.display(
                                  8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.tomato,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Quote Text (Selalu terisi & terbaca jelas dengan teks tegas)
                        Text(
                          boss.quote.trim().isNotEmpty
                              ? '“${boss.quote}”'
                              : '“Aku tidak akan membiarkanmu membongkar rencanaku di sini!”',
                          style: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Tactical Clue / Focus Target
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.line,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_rounded,
                                size: 14,
                                color: AppColors.saffron,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  boss.weakPoints.isNotEmpty
                                      ? 'Fokus Bukti: ${boss.weakPoints.join(' • ')}'
                                      : 'Pilih argumen yang mematahkan alibi dalang untuk meruntuhkan pertahanannya.',
                                  style: AppText.body(
                                    10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.charcoal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Health Bar Section (Ketahanan Dalang)
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology_outlined,
                        size: 14,
                        color: AppColors.slateBlue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Ketahanan Mental Dalang',
                        style: AppText.display(
                          10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$_bossHp% / ${boss.maxHp}%',
                        style: AppText.display(
                          11,
                          fontWeight: FontWeight.bold,
                          color: hpPct <= 0.3
                              ? AppColors.tomato
                              : AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: hpPct,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: hpPct > 0.4
                                      ? [AppColors.orange, AppColors.saffron]
                                      : [AppColors.tomato, AppColors.orange],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dynamic Battle Phase Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      phaseNarration,
                      style: AppText.body(
                        10.5,
                        color: AppColors.slateBlue,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectiveGoodEndingView() {
    final c = _activeCase;
    if (c == null) {
      return Center(
        child: PrimaryButton(
          label: 'Kembali ke Menu',
          onPressed: () => setState(() => _currentView = _GameView.hub),
        ),
      );
    }

    final ending = c.goodEnding;
    final stars = _detectiveStars[c.level] ?? 3;
    final points = c.baseReward;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // Trophy Badge Icon
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.saffron.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.saffron, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.saffron.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 36)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'BERKAS RESMI DIARSIPKAN • TERPECAHKAN',
              style: AppText.display(
                9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.green,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'KASUS TERPECAHKAN!',
            style: AppText.display(20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            c.title,
            style: AppText.body(13, color: AppColors.slateBlue),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),

        // Stars & Rewards Pill
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'RATING INVESTIGASI',
                    style: AppText.display(8.5, color: AppColors.slateBlue),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      3,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: i < stars ? AppColors.saffron : AppColors.line,
                      ),
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 32, color: AppColors.line),
              Column(
                children: [
                  Text(
                    'POIN RASA',
                    style: AppText.display(8.5, color: AppColors.slateBlue),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+$points XP',
                    style: AppText.display(
                      15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Narrative Dossier
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ending.title,
                style: AppText.display(
                  15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
              const Divider(color: AppColors.line, height: 20),
              Text(
                ending.narrative,
                style: AppText.body(
                  13.5,
                  height: 1.55,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 14),
              // Epilogue
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.saffron.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CATATAN KERATON MATARAM:',
                      style: AppText.display(
                        8.5,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.paprika,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ending.epilogue,
                      style: AppText.body(
                        12,
                        height: 1.45,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
              if (ending.badgeName.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.military_tech_rounded,
                        size: 15,
                        color: AppColors.paprika,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'LENCANA DIBUKA: ${ending.badgeName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.display(
                            9.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.paprika,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        PrimaryButton(
          label: 'Daftar Kasus Berikutnya ➔',
          onPressed: () =>
              setState(() => _currentView = _GameView.detectiveCaseSelect),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => setState(() => _currentView = _GameView.hub),
          child: Text(
            'Kembali ke Menu Game',
            style: AppText.display(
              12,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectiveBadEndingView() {
    final c = _activeCase;
    if (c == null) {
      return Center(
        child: PrimaryButton(
          label: 'Kembali',
          onPressed: () => setState(() => _currentView = _GameView.hub),
        ),
      );
    }

    final ending = c.badEnding;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tomato.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.tomato, width: 2),
            ),
            child: const Center(
              child: Text('💔', style: TextStyle(fontSize: 34)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tomato.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'INVESTIGASI TERHENTI',
              style: AppText.display(
                9.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.tomato,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'DEDUKSI GAGAL!',
            style: AppText.display(
              20,
              fontWeight: FontWeight.bold,
              color: AppColors.tomato,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            c.title,
            style: AppText.body(13, color: AppColors.slateBlue),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ending.title,
                style: AppText.display(
                  15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
              const Divider(color: AppColors.line, height: 20),
              Text(
                ending.narrative,
                style: AppText.body(
                  13.5,
                  height: 1.55,
                  color: AppColors.charcoal,
                ),
              ),
              if (ending.epilogue.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  ending.epilogue,
                  style: AppText.body(
                    12,
                    color: AppColors.slateBlue,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        PrimaryButton(
          label: 'Kembali ke Menu Kasus',
          onPressed: () =>
              setState(() => _currentView = _GameView.detectiveCaseSelect),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => setState(() => _currentView = _GameView.hub),
          child: Text(
            'Kembali ke Menu Game',
            style: AppText.display(
              12,
              fontWeight: FontWeight.bold,
              color: AppColors.charcoal,
            ),
          ),
        ),
      ],
    );
  }
}
