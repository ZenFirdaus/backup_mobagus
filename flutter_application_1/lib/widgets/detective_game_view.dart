import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/detective_cases_data.dart';
import '../models/detective_case.dart';
import '../models/restaurant.dart';
import '../pages/detail_page.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';

/// Game Detektif Kuliner "Pilih Jalanmu"
/// UI Elegan, Modern, Selaras dengan Tema Aplikasi Foodie & Game Kuis.
/// Fitur: 15 Kasus Investigasi Kuliner Jogja, 3 Hati & Cooldown Persisten, Checkpoint Tiap 5 Level,
/// Kantong Bukti, Konfrontasi Logika Dalang, dan Integrasi Restoran Asli.
class DetectiveGameView extends StatefulWidget {
  final VoidCallback onBackToMain;

  const DetectiveGameView({
    super.key,
    required this.onBackToMain,
  });

  @override
  State<DetectiveGameView> createState() => _DetectiveGameViewState();
}

enum _DetectiveScreen { levelMap, briefing, playing, ending }

class _DetectiveGameViewState extends State<DetectiveGameView> {
  _DetectiveScreen _screen = _DetectiveScreen.levelMap;

  // Progression & Save State
  int _unlockedLevel = 1;
  int _checkpointLevel = 1;
  final Set<String> _completedCaseIds = {};
  int _totalScore = 0;

  // Lives & Cooldown System
  int _lives = 3;
  int? _recoveryDeadline;
  int _cooldownSecondsRemaining = 0;
  Timer? _cooldownTimer;

  // Active Case Session
  DetectiveCase? _activeCase;
  CaseScene? _currentScene;
  final List<CaseClue> _collectedClues = [];
  int _bossCurrentHp = 100;
  int _bossMaxHp = 100;
  SceneChoice? _activeChoice;
  bool _showingFeedback = false;
  bool _isGoodEnding = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // =========================================================================
  // PERSISTENCE & COOLDOWN LOGIC
  // =========================================================================

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlocked = prefs.getInt('foodie_detective_unlocked') ?? 1;
      final checkpoint = prefs.getInt('foodie_detective_checkpoint') ?? 1;
      final completed = prefs.getStringList('foodie_detective_completed') ?? [];
      final score = prefs.getInt('foodie_detective_score') ?? 0;
      final savedLives = prefs.getInt('detective_lives') ?? 3;
      final deadline = prefs.getInt('detective_recovery_deadline');

      if (!mounted) return;

      setState(() {
        _unlockedLevel = unlocked.clamp(1, kDetectiveCases.length);
        _checkpointLevel = checkpoint.clamp(1, kDetectiveCases.length);
        _completedCaseIds.addAll(completed);
        _totalScore = score;
        _lives = savedLives.clamp(0, 3);
        _recoveryDeadline = deadline;
      });

      _evaluateCooldown();
    } catch (_) {}
  }

  void _evaluateCooldown() {
    if (_lives <= 0 && _recoveryDeadline != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now >= _recoveryDeadline!) {
        _restoreAllLives();
      } else {
        _cooldownSecondsRemaining = ((_recoveryDeadline! - now) / 1000).ceil();
        _startCooldownTimer();
      }
    } else if (_lives <= 0 && _recoveryDeadline == null) {
      _startNewCooldown();
    }
  }

  Future<void> _startNewCooldown() async {
    const cooldownDuration = Duration(minutes: 5);
    final deadline = DateTime.now().add(cooldownDuration).millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('detective_recovery_deadline', deadline);

    if (!mounted) return;
    setState(() {
      _recoveryDeadline = deadline;
      _cooldownSecondsRemaining = cooldownDuration.inSeconds;
    });

    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSecondsRemaining <= 1) {
        timer.cancel();
        _restoreAllLives();
      } else {
        setState(() {
          _cooldownSecondsRemaining--;
        });
      }
    });
  }

  Future<void> _restoreAllLives() async {
    _cooldownTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('detective_lives', 3);
    await prefs.remove('detective_recovery_deadline');

    if (!mounted) return;
    setState(() {
      _lives = 3;
      _recoveryDeadline = null;
      _cooldownSecondsRemaining = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❤️ Seluruh hati pulih! Kamu siap melanjutkan penyelidikan.'),
        duration: Duration(seconds: 3),
        backgroundColor: AppColors.green,
      ),
    );
  }

  Future<void> _consumeLife() async {
    final newLives = (_lives - 1).clamp(0, 3);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('detective_lives', newLives);

    if (!mounted) return;
    setState(() {
      _lives = newLives;
    });

    if (newLives == 0) {
      _startNewCooldown();
    }
  }

  Future<void> _saveCaseVictory(DetectiveCase c, int reward) async {
    final nextLevel = c.level + 1;
    final newUnlocked = nextLevel > _unlockedLevel ? nextLevel : _unlockedLevel;

    // Checkpoint rule: Level 5, 10, 15
    int newCheckpoint = _checkpointLevel;
    if (c.level >= 10 && _checkpointLevel < 10) {
      newCheckpoint = 10;
    } else if (c.level >= 5 && _checkpointLevel < 5) {
      newCheckpoint = 5;
    }

    final newScore = _totalScore + reward;
    final completedList = {..._completedCaseIds, c.id}.toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('foodie_detective_unlocked', newUnlocked);
    await prefs.setInt('foodie_detective_checkpoint', newCheckpoint);
    await prefs.setStringList('foodie_detective_completed', completedList);
    await prefs.setInt('foodie_detective_score', newScore);

    if (!mounted) return;
    setState(() {
      _unlockedLevel = newUnlocked;
      _checkpointLevel = newCheckpoint;
      _completedCaseIds.add(c.id);
      _totalScore = newScore;
    });

    // Cloud sync via Supabase
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('user_game_profiles').upsert({
          'user_id': user.id,
          'detective_unlocked_level': newUnlocked,
          'detective_checkpoint': newCheckpoint,
          'detective_score': newScore,
          'detective_cases_solved': completedList.length,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  String _formatCooldown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // =========================================================================
  // CASE NAVIGATION & ACTIONS
  // =========================================================================

  void _startCase(DetectiveCase c) {
    if (_lives <= 0) {
      _showNoLivesDialog();
      return;
    }
    setState(() {
      _activeCase = c;
      _screen = _DetectiveScreen.briefing;
      _collectedClues.clear();
    });
  }

  void _beginInvestigation() {
    final c = _activeCase;
    if (c == null || c.scenes.isEmpty) return;

    final firstScene = c.scenes.first;
    setState(() {
      _currentScene = firstScene;
      _screen = _DetectiveScreen.playing;
      _activeChoice = null;
      _showingFeedback = false;
      if (firstScene.boss != null) {
        _bossMaxHp = firstScene.boss!.maxHp;
        _bossCurrentHp = firstScene.boss!.maxHp;
      }
    });
  }

  void _showNoLivesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: AppColors.orange, size: 24),
            SizedBox(width: 8),
            Text('Stamina Habis', style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiga nyawa detektifmu telah habis akibat kesalahan deduksi. Mohon istirahat sejenak untuk memulihkan stamina.',
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.charcoal),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Waktu pulih: ${_formatCooldown(_cooldownSecondsRemaining)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleChoice(SceneChoice choice) {
    if (_showingFeedback) return;

    // Tambah clue jika ditemukan
    if (choice.foundClue != null && !_collectedClues.any((c) => c.id == choice.foundClue!.id)) {
      _collectedClues.add(choice.foundClue!);
    }

    // Apply boss damage
    if (choice.bossDamage > 0) {
      _bossCurrentHp = (_bossCurrentHp - choice.bossDamage).clamp(0, _bossMaxHp);
    }

    // Kurangi nyawa jika opsi salah/ceroboh
    if (choice.losesLife) {
      _consumeLife();
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _activeChoice = choice;
      _showingFeedback = true;
    });
  }

  void _continueAfterFeedback() {
    final choice = _activeChoice;
    setState(() {
      _showingFeedback = false;
    });

    if (_lives <= 0) {
      _finishCase(win: false);
      return;
    }

    if (choice?.nextSceneId != null) {
      final next = _activeCase?.scenes.firstWhere(
        (s) => s.id == choice!.nextSceneId,
        orElse: () => _activeCase!.scenes.last,
      );
      setState(() {
        _currentScene = next;
        _activeChoice = null;
        if (next?.boss != null) {
          _bossMaxHp = next!.boss!.maxHp;
          _bossCurrentHp = next.boss!.maxHp;
        }
      });
    } else {
      final win = _bossCurrentHp <= 0 || (choice?.isCorrect ?? false);
      _finishCase(win: win);
    }
  }

  void _finishCase({required bool win}) {
    final c = _activeCase;
    if (c == null) return;

    setState(() {
      _isGoodEnding = win;
      _screen = _DetectiveScreen.ending;
    });

    if (win) {
      final reward = c.baseReward + (_collectedClues.length * 40) + (_lives * 30);
      _saveCaseVictory(c, reward);
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _restartFromCheckpoint() {
    final targetCase = kDetectiveCases.firstWhere(
      (c) => c.level == _checkpointLevel,
      orElse: () => kDetectiveCases.first,
    );
    _startCase(targetCase);
  }

  void _openCluesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.folder_shared_rounded, color: AppColors.orange, size: 22),
                  const SizedBox(width: 8),
                  Text('Kantong Bukti Kasus #${_activeCase?.level ?? 1}', style: AppText.display(16)),
                  const Spacer(),
                  Text(
                    '${_collectedClues.length} Bukti',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_collectedClues.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada bukti terkumpul',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pilih opsi investigasi yang tepat di tempat kejadian untuk mengamankan bukti.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _collectedClues.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final clue = _collectedClues[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Icon(clue.icon, color: AppColors.orange, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clue.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    clue.description,
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
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
        ),
      ),
    );
  }

  Future<void> _openRelatedRestaurant(String restaurantName) async {
    try {
      final all = await SupabaseService.instance.getRestaurants();
      Restaurant? match;
      for (final r in all) {
        if (r.name.toLowerCase().contains(restaurantName.toLowerCase()) ||
            restaurantName.toLowerCase().contains(r.name.toLowerCase())) {
          match = r;
          break;
        }
      }
      match ??= all.isNotEmpty ? all.first : null;

      if (match != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailPage(restaurant: match!)),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Informasi restoran tersedia di menu Jelajah.')),
          );
        }
      }
    } catch (_) {}
  }

  // =========================================================================
  // MAIN BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: switch (_screen) {
          _DetectiveScreen.levelMap => _buildLevelMap(),
          _DetectiveScreen.briefing => _buildBriefing(),
          _DetectiveScreen.playing => _buildInvestigation(),
          _DetectiveScreen.ending => _buildEndingScreen(),
        },
      ),
    );
  }

  // =========================================================================
  // 1. MAP / DAFTAR KASUS
  // =========================================================================

  Widget _buildLevelMap() {
    return Column(
      children: [
        _buildCleanHeader(
          title: 'Detektif Rasa Jogja',
          subtitle: 'Investigasi 15 Kasus Rahasia Kuliner',
          onBack: widget.onBackToMain,
        ),
        _buildStatusBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            itemCount: kDetectiveCases.length,
            itemBuilder: (ctx, i) {
              final c = kDetectiveCases[i];
              return _buildCaseCard(c);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCleanHeader({
    required String title,
    required String subtitle,
    required VoidCallback onBack,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background,
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
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hearts status
          Row(
            children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(
                    i < _lives ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: i < _lives ? AppColors.tomato : AppColors.line,
                    size: 18,
                  ),
                ),
              if (_lives <= 0)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    'Pulih ${_formatCooldown(_cooldownSecondsRemaining)}',
                    style: const TextStyle(color: AppColors.tomato, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          // Checkpoint pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmark_rounded, color: AppColors.orange, size: 13),
                const SizedBox(width: 4),
                Text(
                  'Checkpoint: Lvl $_checkpointLevel',
                  style: const TextStyle(color: AppColors.charcoal, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Total Score
          Text(
            '$_totalScore Poin',
            style: const TextStyle(color: AppColors.charcoal, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(DetectiveCase c) {
    final isUnlocked = c.level <= _unlockedLevel;
    final isSolved = _completedCaseIds.contains(c.id);
    final isCheckpoint = c.level == 5 || c.level == 10 || c.level == 15;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSolved
              ? AppColors.green.withValues(alpha: 0.4)
              : (isUnlocked ? AppColors.line : AppColors.line.withValues(alpha: 0.5)),
          width: isSolved ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isUnlocked ? () => _startCase(c) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCheckpoint)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark_rounded, color: AppColors.orange, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          c.level == 15 ? 'POS CHECKPOINT TERAKHIR • LEVEL 15' : 'POS CHECKPOINT • LEVEL ${c.level}',
                          style: const TextStyle(color: AppColors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isUnlocked ? AppColors.surfaceSubtle : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isUnlocked ? c.iconEmoji : '🔒',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Kasus #${c.level}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? AppColors.orange : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: c.difficulty.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
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
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.title,
                            style: TextStyle(
                              color: isUnlocked ? AppColors.charcoal : AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.targetRestaurant,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isSolved)
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      )
                    else if (isUnlocked)
                      const Icon(Icons.chevron_right_rounded, color: AppColors.charcoal, size: 20)
                    else
                      const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. BRIEFING KASUS (BERKAS PERKARA)
  // =========================================================================

  Widget _buildBriefing() {
    final c = _activeCase;
    if (c == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildCleanHeader(
          title: 'Kasus #${c.level}',
          subtitle: c.targetRestaurant,
          onBack: () => setState(() => _screen = _DetectiveScreen.levelMap),
        ),
        _buildStatusBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'KASUS #${c.level} • ${c.difficulty.label.toUpperCase()}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.orange),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '+${c.baseReward} Poin',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${c.targetRestaurant} • ${c.location}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: AppColors.line, height: 1),
                  ),
                  const Text(
                    'Informasi Kasus',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.synopsis,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.charcoal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _beginInvestigation,
                      child: const Text(
                        'Mulai Investigasi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 3. INVESTIGASI & KEPUTUSAN BERCABANG
  // =========================================================================

  Widget _buildInvestigation() {
    final s = _currentScene;
    final c = _activeCase;
    if (s == null || c == null) return const SizedBox.shrink();

    final isBossScene = s.isBossFight && s.boss != null;

    return Column(
      children: [
        _buildCleanHeader(
          title: s.title,
          subtitle: s.location,
          onBack: () => setState(() => _screen = _DetectiveScreen.levelMap),
          trailing: InkWell(
            onTap: _openCluesSheet,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_shared_rounded, color: AppColors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Bukti (${_collectedClues.length})',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildStatusBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Boss Banner jika tahap boss fight
                if (isBossScene) ...[
                  _buildBossCard(s.boss!),
                  const SizedBox(height: 14),
                ],

                // Dialog Saksi / Situasi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.line),
                            ),
                            alignment: Alignment.center,
                            child: Text(s.speakerAvatar, style: const TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.speakerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                                ),
                                Text(
                                  s.speakerRole,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.narrative,
                        style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.charcoal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Pilihan Tindakan
                const Text(
                  'Tentukan Langkah Selanjutnya:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                ),
                const SizedBox(height: 10),

                if (_showingFeedback && _activeChoice != null)
                  _buildFeedbackView(_activeChoice!)
                else
                  for (int i = 0; i < s.choices.length; i++)
                    _buildChoiceTile(s.choices[i], isBossScene),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBossCard(BossConfrontation boss) {
    final hpPercent = (_bossCurrentHp / _bossMaxHp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tomato.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                alignment: Alignment.center,
                child: Text(boss.avatar, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boss.name,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                    ),
                    Text(
                      boss.role,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '$_bossCurrentHp / $_bossMaxHp HP',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.tomato),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hpPercent,
              minHeight: 6,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.tomato),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"${boss.quote}"',
            style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceTile(SceneChoice choice, bool isBossScene) {
    String tagLabel = 'Periksa Bukti';
    IconData tagIcon = Icons.search_rounded;

    if (isBossScene) {
      tagLabel = 'Konfrontasi Dalang';
      tagIcon = Icons.bolt_rounded;
    } else if (choice.text.toLowerCase().contains('tanya') ||
        choice.text.toLowerCase().contains('interogasi') ||
        choice.text.toLowerCase().contains('faktur') ||
        choice.text.toLowerCase().contains('rekam')) {
      tagLabel = 'Interogasi Saksi';
      tagIcon = Icons.forum_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleChoice(choice),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isBossScene ? AppColors.tomato.withValues(alpha: 0.1) : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tagIcon, size: 11, color: isBossScene ? AppColors.tomato : AppColors.orange),
                      const SizedBox(width: 4),
                      Text(
                        tagLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isBossScene ? AppColors.tomato : AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  choice.text,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                ),
                const SizedBox(height: 2),
                Text(
                  choice.actionDetail,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackView(SceneChoice choice) {
    final isGood = choice.isCorrect;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGood ? AppColors.green.withValues(alpha: 0.08) : AppColors.tomato.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGood ? AppColors.green.withValues(alpha: 0.3) : AppColors.tomato.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGood ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: isGood ? AppColors.green : AppColors.tomato,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isGood ? 'Langkah Tepat' : 'Kurang Tepat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isGood ? AppColors.green : AppColors.tomato,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            choice.feedback,
            style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.charcoal),
          ),
          if (choice.losesLife)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Stamina berkurang 1 hati. Sisa: $_lives ❤️',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.tomato),
              ),
            ),
          if (choice.foundClue != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Bukti tersimpan: ${choice.foundClue!.title}',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.green),
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.charcoal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _continueAfterFeedback,
              child: const Text('Lanjutkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. ENDING SCREEN (GOOD & BAD ENDING)
  // =========================================================================

  Widget _buildEndingScreen() {
    final c = _activeCase;
    if (c == null) return const SizedBox.shrink();

    final ending = _isGoodEnding ? c.goodEnding : c.badEnding;
    final isSuccess = _isGoodEnding;

    return Column(
      children: [
        _buildCleanHeader(
          title: isSuccess ? 'Kasus Terpecahkan' : 'Investigasi Gagal',
          subtitle: c.targetRestaurant,
          onBack: () => setState(() => _screen = _DetectiveScreen.levelMap),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isSuccess ? AppColors.green.withValues(alpha: 0.12) : AppColors.tomato.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.verified_rounded : Icons.highlight_off_rounded,
                    size: 38,
                    color: isSuccess ? AppColors.green : AppColors.tomato,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  ending.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  ending.narrative,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

                // Card Kesimpulan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan Akhir Perkara',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.charcoal),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ending.epilogue,
                        style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.charcoal),
                      ),
                      if (isSuccess) ...[
                        const Divider(color: AppColors.line, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Lencana: ${ending.badgeName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange)),
                            Text('+${ending.rewardPoints} Poin', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.green)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Aksi
                if (isSuccess) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.charcoal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _screen = _DetectiveScreen.levelMap;
                        });
                      },
                      child: const Text('Lanjut ke Kasus Berikutnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.charcoal,
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _openRelatedRestaurant(c.targetRestaurant),
                      child: Text('Lihat ${c.targetRestaurant} di Aplikasi', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tomato,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _restartFromCheckpoint,
                      child: Text('Ulangi dari Checkpoint Lvl $_checkpointLevel', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _screen = _DetectiveScreen.levelMap),
                    child: const Text('Kembali ke Peta Kasus', style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
