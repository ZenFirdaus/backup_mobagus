import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_question.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/buttons.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int _currentIndex = 0;
  int _totalScore = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _secondsLeft = 15;
  Timer? _timer;
  bool _showSummary = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
    final q = kQuizQuestions[_currentIndex];
    final correct = index == q.correctIndex;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (correct) _totalScore += q.points;
    });
  }

  void _advance() {
    if (_currentIndex < kQuizQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _answered = false;
      });
      _startTimer();
    } else {
      _timer?.cancel();
      setState(() => _showSummary = true);
      _saveScore();
    }
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
    final q = kQuizQuestions[_currentIndex];
    final progress = (_currentIndex + 1) / kQuizQuestions.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tebak Kuliner Jogja',
                style: AppText.display(18),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Pertanyaan ${_currentIndex + 1} dari ${kQuizQuestions.length}',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.tint(AppColors.yellow, 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.tint(AppColors.orange, 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.orange,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  q.hint,
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            q.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.6,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(q.options.length, (i) => _optionTile(q, i)),
        if (_answered && _selectedIndex != -1) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tint(
                _selectedIndex == q.correctIndex
                    ? AppColors.green
                    : AppColors.red,
                0.1,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.tint(
                  _selectedIndex == q.correctIndex
                      ? AppColors.green
                      : AppColors.red,
                  0.3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedIndex == q.correctIndex
                      ? 'Jawaban Benar! +${q.points} poin'
                      : 'Jawaban Salah',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _selectedIndex == q.correctIndex
                        ? AppColors.greenDark
                        : AppColors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  q.explanation,
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
            label: _currentIndex < kQuizQuestions.length - 1
                ? 'Lanjut ke Pertanyaan Berikutnya'
                : 'Lihat Hasil',
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
            Icons.timer_outlined,
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

  Widget _optionTile(GameQuestion q, int i) {
    Color bg = Colors.white;
    Color border = AppColors.line;
    Color textColor = AppColors.textDark;

    if (_answered) {
      if (i == q.correctIndex) {
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
                    color: _answered && i == q.correctIndex
                        ? AppColors.green
                        : _answered && i == _selectedIndex
                            ? AppColors.red
                            : AppColors.tint(AppColors.orange, 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: _answered && i == q.correctIndex
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
                    q.options[i],
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
    final pct = (_totalScore / (kQuizQuestions.length * 100) * 100).round();
    final perfect = pct == 100;
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
              border: Border.all(color: AppColors.line, width: 1),
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
                    color: perfect
                        ? AppColors.tint(AppColors.orange, 0.2)
                        : AppColors.tint(AppColors.green, 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    perfect ? Icons.emoji_events : Icons.quiz_outlined,
                    size: 36,
                    color: perfect ? AppColors.orange : AppColors.greenDark,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  perfect ? 'Sempurna!' : 'Permainan Selesai!',
                  style: AppText.display(22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Skor Akhir',
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
                const SizedBox(height: 4),
                Text(
                  'dari ${kQuizQuestions.length * 100} poin ($pct%)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statBubble(
                      Icons.check_circle_outline,
                      '${(_totalScore / 100).round()}',
                      'Benar',
                      AppColors.green,
                    ),
                    const SizedBox(width: 16),
                    _statBubble(
                      Icons.cancel_outlined,
                      '${kQuizQuestions.length - (_totalScore / 100).round()}',
                      'Salah',
                      AppColors.red,
                    ),
                  ],
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
            label: 'Kembali',
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
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
