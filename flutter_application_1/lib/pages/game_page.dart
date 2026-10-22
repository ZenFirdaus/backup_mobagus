import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

// Sesuaikan path import dengan struktur project Anda
import '../models/game_question.dart';
import '../models/quiz_data.dart'; // File data bank soal Anda
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';

// import '../screens/restaurant_detail_screen.dart'; // Uncomment ini nanti untuk navigasi ke restoran

/// Kelas helper internal untuk state soal
class _ActiveQuestion {
  final GameQuestion original;
  final List<String> shuffledOptions;
  final int correctIndex;

  _ActiveQuestion(this.original, this.shuffledOptions, this.correctIndex);

  factory _ActiveQuestion.from(GameQuestion q, Random random) {
    List<MapEntry<int, String>> indexedOptions = q.options
        .asMap()
        .entries
        .toList();
    indexedOptions.shuffle(random);
    int newCorrectIndex = indexedOptions.indexWhere(
      (e) => e.key == q.correctIndex,
    );
    List<String> newOptions = indexedOptions.map((e) => e.value).toList();
    return _ActiveQuestion(q, newOptions, newCorrectIndex);
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // --- STATE PROGRESSION & LEVEL ---
  int _currentLevel = 1;
  int _totalScore = 0;
  int _currentCombo = 1; // 🔥 FITUR BARU: Combo multiplier
  int _highestCombo = 1;

  List<_ActiveQuestion> _sessionQuestions = [];
  int _currentIndex = 0;
  int _correctAnswersInLevel = 0;

  bool _isCheckpoint = false;
  int _checkpointBonus = 0;

  int? _selectedIndex;
  bool _answered = false;
  int _secondsLeft = 15;
  Timer? _timer;
  bool _showSummary = false;
  bool _saving = false;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- LOGIKA PROGRESSION ---

  int _getQuestionsCount() {
    return min(5 + 2 * ((_currentLevel - 1) ~/ 5), 15);
  }

  int _getPointsForLevel() {
    return 20 + ((_currentLevel - 1) * 10);
  }

  /// 🎚️ FITUR BARU: Memfilter soal berdasarkan level
  List<GameQuestion> _getQuestionsPool() {
    List<GameQuestion> pool;
    if (_currentLevel == 1) {
      pool = kQuizQuestions
          .where((q) => q.difficulty == QuestionDifficulty.mudah)
          .toList();
    } else if (_currentLevel <= 5) {
      pool = kQuizQuestions
          .where(
            (q) =>
                q.difficulty == QuestionDifficulty.mudah ||
                q.difficulty == QuestionDifficulty.menengah,
          )
          .toList();
    } else if (_currentLevel <= 10) {
      pool = kQuizQuestions
          .where(
            (q) =>
                q.difficulty == QuestionDifficulty.menengah ||
                q.difficulty == QuestionDifficulty.sulit,
          )
          .toList();
    } else {
      pool = kQuizQuestions
          .where(
            (q) =>
                q.difficulty == QuestionDifficulty.sulit ||
                q.difficulty == QuestionDifficulty.sangatSulit,
          )
          .toList();
    }

    // Fallback jika soal di tingkat tersebut habis
    if (pool.length < 3) return List.from(kQuizQuestions);
    return pool;
  }

  void _startLevel() {
    int count = _getQuestionsCount();

    List<GameQuestion> pool = _getQuestionsPool();
    pool.shuffle(_random);

    // Fallback jika bank soal lebih sedikit dari kebutuhan level
    List<GameQuestion> selected = [];
    if (pool.length >= count) {
      selected = pool.sublist(0, count);
    } else {
      selected.addAll(pool);
      var fallback = List<GameQuestion>.from(kQuizQuestions)..shuffle(_random);
      for (var q in fallback) {
        if (selected.length >= count) break;
        if (!selected.contains(q)) selected.add(q);
      }
    }

    setState(() {
      _sessionQuestions = selected
          .map((q) => _ActiveQuestion.from(q, _random))
          .toList();
      _currentIndex = 0;
      _correctAnswersInLevel = 0;
      _showSummary = false;
      _isCheckpoint = false;
      _checkpointBonus = 0;
      _selectedIndex = null;
      _answered = false;
      // Jangan reset combo di sini agar combo bisa bersambung antar level!
    });

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (!_answered) {
          setState(() {
            _answered = true;
            _selectedIndex = -1;
            _currentCombo = 1; // 🔥 Reset combo karena kehabisan waktu
          });
          Future.delayed(const Duration(seconds: 2), _advance);
        }
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _selectOption(int index) {
    if (_answered) return;
    _timer?.cancel();

    final activeQ = _sessionQuestions[_currentIndex];
    final correct = index == activeQ.correctIndex;

    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (correct) {
        // 🔥 FITUR BARU: Kalkulasi poin dikalikan combo
        int pointsEarned = _getPointsForLevel() * _currentCombo;
        _totalScore += pointsEarned;
        _correctAnswersInLevel++;

        _currentCombo++; // Naikkan combo untuk soal berikutnya
        if (_currentCombo > _highestCombo) _highestCombo = _currentCombo;
      } else {
        _currentCombo = 1; // Reset combo jika salah
      }
    });
  }

  void _advance() {
    if (_currentIndex < _sessionQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _answered = false;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      _handleLevelComplete();
    }
  }

  void _handleLevelComplete() {
    bool isCheckpoint = _currentLevel % 5 == 0;
    int bonus = 0;
    if (isCheckpoint) {
      bonus = _currentLevel * 100;
      _totalScore += bonus;
    }

    setState(() {
      _isCheckpoint = isCheckpoint;
      _checkpointBonus = bonus;
      _showSummary = true;
    });

    _saveScore();
  }

  Future<void> _saveScore() async {
    setState(() => _saving = true);
    try {
      await SupabaseService.instance.saveGameScore(_totalScore);
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBackground(
        child: _showSummary ? _buildSummary() : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    if (_sessionQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeQ = _sessionQuestions[_currentIndex];
    final originalQ = activeQ.original;
    final progress = (_currentIndex + 1) / _sessionQuestions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // --- HEADER ---
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tint(AppColors.orange, 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Level $_currentLevel', style: AppText.display(18)),
            ),

            // SKOR & COMBO BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.greenDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_totalScore',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  // Tampilkan badge Combo jika combo > 1
                  if (_currentCombo > 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x$_currentCombo',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- PROGRESS & TIMER ---
        Row(
          children: [
            Expanded(
              child: Text(
                'Pertanyaan ${_currentIndex + 1} dari ${_sessionQuestions.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            _timerChip(),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.tint(AppColors.green, 0.2),
            valueColor: const AlwaysStoppedAnimation(AppColors.green),
          ),
        ),
        const SizedBox(height: 24),

        // --- HINT ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.tint(AppColors.yellow, 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppColors.orange,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  originalQ.hint,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- QUESTION CARD ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            originalQ.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.6,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // --- OPTIONS ---
        ...List.generate(
          activeQ.shuffledOptions.length,
          (i) => _optionTile(activeQ, i),
        ),

        // --- FEEDBACK & EXPLANATION ---
        if (_answered && _selectedIndex != -1) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tint(
                _selectedIndex == activeQ.correctIndex
                    ? AppColors.green
                    : AppColors.red,
                0.1,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.tint(
                  _selectedIndex == activeQ.correctIndex
                      ? AppColors.green
                      : AppColors.red,
                  0.3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedIndex == activeQ.correctIndex
                          ? 'Jawaban Benar! +${_getPointsForLevel() * (_currentCombo - 1)} poin' // (_currentCombo - 1) karena sudah di-increment di _selectOption
                          : 'Jawaban Salah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _selectedIndex == activeQ.correctIndex
                            ? AppColors.greenDark
                            : AppColors.red,
                      ),
                    ),

                    // 🔗 FITUR BARU: Tautan ke Restoran jika ada relatedRestaurantId
                    if (originalQ.relatedRestaurantId != null)
                      InkWell(
                        onTap: () {
                          // TODO: Navigasi ke halaman detail restoran
                          // Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailScreen(id: originalQ.relatedRestaurantId!)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Menuju halaman resto...'),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.storefront,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Lihat Resto',
                                style: TextStyle(
                                  fontSize: 10,
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
                  originalQ.explanation,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _currentIndex < _sessionQuestions.length - 1
                ? 'Lanjut ke Pertanyaan Berikutnya'
                : 'Selesaikan Level',
            onPressed: _advance,
            trailingArrow: true,
          ),
        ],
      ],
    );
  }

  Widget _timerChip() {
    final urgent = _secondsLeft <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: urgent
            ? AppColors.tint(AppColors.red, 0.15)
            : AppColors.tint(AppColors.green, 0.15),
        borderRadius: BorderRadius.circular(20),
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
              fontWeight: FontWeight.w800,
              color: urgent ? AppColors.red : AppColors.greenDark,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _answered ? null : () => _selectOption(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _answered && i == activeQ.correctIndex
                        ? AppColors.green
                        : _answered && i == _selectedIndex
                        ? AppColors.red
                        : AppColors.tint(AppColors.orange, 0.15),
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
                              fontWeight: FontWeight.w800,
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
                      fontSize: 13,
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

  Widget _buildSummary() {
    int totalQuestions = _sessionQuestions.length;
    int incorrectAnswers = totalQuestions - _correctAnswersInLevel;

    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _isCheckpoint
                        ? AppColors.tint(AppColors.orange, 0.2)
                        : AppColors.tint(AppColors.green, 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isCheckpoint ? Icons.emoji_events : Icons.verified_rounded,
                    size: 36,
                    color: _isCheckpoint
                        ? AppColors.orange
                        : AppColors.greenDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isCheckpoint
                      ? 'CHECKPOINT!'
                      : 'Level $_currentLevel Selesai',
                  style: AppText.display(22),
                  textAlign: TextAlign.center,
                ),

                if (_isCheckpoint) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+$_checkpointBonus Poin Bonus!',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Text(
                  'Skor Total Anda',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalScore',
                  style: AppText.display(40, color: AppColors.greenDark),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statBubble(
                      Icons.check_circle_outline,
                      '$_correctAnswersInLevel',
                      'Benar',
                      AppColors.green,
                    ),
                    const SizedBox(width: 16),
                    _statBubble(
                      Icons.cancel_rounded,
                      '$incorrectAnswers',
                      'Salah',
                      AppColors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                // Menampilkan stat Combo Tertinggi
                Text(
                  'Combo Tertinggi: x$_highestCombo',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),

                if (_saving) ...[
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Lanjut Level ${_currentLevel + 1}',
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              setState(() {
                _currentLevel++;
                _startLevel();
              });
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Simpan & Keluar',
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

  Widget _statBubble(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tint(color, 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
