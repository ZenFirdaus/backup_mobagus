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
  bool _isDailyKulinerdle = true;
  final List<String> _kulinerdleGuesses = [];
  String _kulinerdleCurrentInput = '';
  bool _kulinerdleGameOver = false;
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

  @override
  void initState() {
    super.initState();
    _initKulinerdleWord();
    _loadAllData();
  }

  @override
  void dispose() {
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

      // Detective Progress
      final unlockedDet = prefs.getInt('foodie_game_unlocked_level') ?? 1;
      final dStars = <int, int>{};
      for (int i = 1; i <= kDetectiveCases.length; i++) {
        dStars[i] = prefs.getInt('foodie_game_stars_$i') ?? 0;
      }

      // Kulinerdle Stats
      _kdPlayed = prefs.getInt('kulinerdle_played') ?? 0;
      _kdWon = prefs.getInt('kulinerdle_won') ?? 0;
      _kdCurrentStreak = prefs.getInt('kulinerdle_current_streak') ?? 0;
      _kdMaxStreak = prefs.getInt('kulinerdle_max_streak') ?? 0;
      for (int i = 1; i <= 6; i++) {
        _kdGuessDistribution[i] = prefs.getInt('kulinerdle_dist_$i') ?? 0;
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
  void _initKulinerdleWord({bool randomFreePlay = false}) {
    setState(() {
      _isDailyKulinerdle = !randomFreePlay;
      _kulinerdleTarget = randomFreePlay
          ? getRandomKulinerdleWord()
          : getDailyKulinerdleWord();
      _kulinerdleGuesses.clear();
      _kulinerdleCurrentInput = '';
      _kulinerdleGameOver = false;
      _kulinerdleKeyEvaluations.clear();
    });
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
                            '+$points Poin',
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
            'Poin detektif tidak cukup untuk pemulihan cepat (butuh 50 poin).',
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

    setState(() {
      _activeCase = c;
      _currentSceneIndex = 0;
      _detectiveLives = 3;
      _bossHp = c.scenes.isNotEmpty && c.scenes.last.isBossFight
          ? (c.scenes.last.boss?.maxHp ?? 100)
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
    final isBossDefeated = scene.isBossFight && _bossHp <= 0;
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
                          : (scene.isBossFight
                                ? 'Lanjutkan Konfrontasi ⚔️'
                                : 'Langkah Selanjutnya ➔')),
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
            _bossHp = nextScene.boss!.maxHp;
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
          _bossHp = nextScene.boss!.maxHp;
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
      final currentStars = _detectiveStars[level] ?? 0;
      if (stars > currentStars) {
        _detectiveStars[level] = stars;
        await prefs.setInt('foodie_game_stars_$level', stars);
      }

      if (level >= _unlockedDetectiveLevel && level < kDetectiveCases.length) {
        _unlockedDetectiveLevel = level + 1;
        await prefs.setInt(
          'foodie_game_unlocked_level',
          _unlockedDetectiveLevel,
        );
      }

      await _addScore(pointsEarned);
    } catch (_) {}
  }

  void _openClueNotebook() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.paprika,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text('Papan Bukti Investigasi', style: AppText.display(18)),
                  const Spacer(),
                  Text(
                    '${_gatheredClues.length} Bukti',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.paprika,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.line, height: 24),
              Expanded(
                child: _gatheredClues.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada bukti terkumpul.',
                          style: TextStyle(color: AppColors.slateBlue),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _gatheredClues.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final clue = _gatheredClues[idx];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  clue.icon,
                                  color: AppColors.paprika,
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        clue.title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.charcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        clue.description,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.slateBlue,
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
              child: const Text('Pulihkan (50 Poin)'),
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
          onTap: () => setState(() => _currentView = _GameView.kulinerdle),
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
                'Skor Didapat: +$_quizScoreInLevel Poin',
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: _isDailyKulinerdle
                                    ? AppColors.green.withValues(alpha: 0.15)
                                    : AppColors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _isDailyKulinerdle ? 'HARIAN' : 'BEBAS',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _isDailyKulinerdle
                                      ? AppColors.green
                                      : AppColors.orange,
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
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.orange,
                      size: 22,
                    ),
                    tooltip: 'Ronde Baru Bebas',
                    onPressed: () => _initKulinerdleWord(randomFreePlay: true),
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
                    'PILIH JALANMU: DETEKTIF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                  Text('Berkas Misteri Mataram', style: AppText.display(17)),
                ],
              ),
            ),
            Row(
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Icon(
                    i < _detectiveLives
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: i < _detectiveLives
                        ? AppColors.tomato
                        : AppColors.line,
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),

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
                const Text(
                  'Cooldown Investigasi Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  'Hati pulih dalam: $timeStr',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slateBlue,
                  ),
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
            child: const Text(
              'Pulihkan',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? AppColors.orange
                      : (isLocked ? AppColors.line : AppColors.charcoal),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9.5,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isUnlocked ? () => _startDetectiveCase(c) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.isCheckpoint
                            ? AppColors.saffron.withValues(alpha: 0.2)
                            : AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.isCheckpoint
                            ? 'CHECKPOINT LV ${c.level}'
                            : 'KASUS ${c.level}',
                        style: TextStyle(
                          fontSize: 9.5,
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
                        color: c.difficulty.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.difficulty.label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: c.difficulty.color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isUnlocked)
                      const Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: AppColors.slateBlue,
                      )
                    else if (stars > 0)
                      Row(
                        children: List.generate(
                          3,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: i < stars
                                ? AppColors.saffron
                                : AppColors.line,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          c.iconEmoji,
                          style: const TextStyle(fontSize: 18),
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
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoal,
                            ),
                          ),
                          Text(
                            c.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
              ],
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                child: Text(
                  'Kasus ${c.level}: ${c.title}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: _openClueNotebook,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
                        style: const TextStyle(
                          fontSize: 11,
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
            padding: const EdgeInsets.all(18),
            children: [
              if (scene.isBossFight && scene.boss != null) ...[
                _buildDetectiveBossFightCard(scene.boss!),
                const SizedBox(height: 14),
              ],

              // Dialogue Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surfaceSubtle,
                      child: Text(scene.speakerAvatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scene.speakerName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            scene.speakerRole,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.slateBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Narrative Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  scene.narrative,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'PILIH LANGKAH INVESTIGASI:',
                style: AppText.display(
                  11,
                  color: AppColors.slateBlue,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              ...scene.choices.asMap().entries.map((entry) {
                final idx = entry.key;
                final choice = entry.value;
                final isSelected = _selectedChoiceIndicesInScene.contains(idx);

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
                          color: isSelected
                              ? AppColors.line
                              : choice.type.color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            choice.type.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: choice.type.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            choice.text,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            choice.actionDetail,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.slateBlue,
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

  Widget _buildDetectiveBossFightCard(BossConfrontation boss) {
    final hpPct = (_bossHp / boss.maxHp).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tomato, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'KONFRONTASI DALANG',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tomato,
                ),
              ),
              const Spacer(),
              Text(
                'HP: $_bossHp/${boss.maxHp}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: hpPct,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation(AppColors.tomato),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(boss.avatar, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  boss.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectiveGoodEndingView() {
    final c = _activeCase;
    if (c == null) {
      return Center(
        child: PrimaryButton(
          label: 'Kembali',
          onPressed: () => setState(() => _currentView = _GameView.hub),
        ),
      );
    }

    final ending = c.goodEnding;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: Text('🏆', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 10),
        Center(child: Text('KASUS TERPECAHKAN!', style: AppText.display(20))),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: AppColors.line, height: 20),
              Text(
                ending.narrative,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Daftar Kasus Berikutnya ➔',
          onPressed: () =>
              setState(() => _currentView = _GameView.detectiveCaseSelect),
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
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: Text('💔', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'INVESTIGASI GAGAL!',
            style: AppText.display(20, color: AppColors.tomato),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ending.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: AppColors.line, height: 20),
              Text(
                ending.narrative,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Kembali ke Menu Kasus',
          onPressed: () =>
              setState(() => _currentView = _GameView.detectiveCaseSelect),
        ),
      ],
    );
  }
}
