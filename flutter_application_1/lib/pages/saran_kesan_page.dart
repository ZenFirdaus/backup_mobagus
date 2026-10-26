import 'dart:async';
import 'package:flutter/material.dart';

import '../models/course_feedback.dart';
import '../models/profile.dart';
import '../models/reward_border.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../services/reward_border_service.dart';
import '../widgets/profile_border_avatar.dart';

class SaranKesanPage extends StatefulWidget {
  const SaranKesanPage({super.key});

  @override
  State<SaranKesanPage> createState() => _SaranKesanPageState();
}

class _SaranKesanPageState extends State<SaranKesanPage> {
  List<CourseFeedback> _feedbacks = [];
  bool _isLoading = true;
  StreamSubscription<CourseFeedback>? _subscription;
  StreamSubscription<void>? _borderSubscription;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
    _subscribeRealtime();
    _borderSubscription = RewardBorderService.instance.onChange.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _borderSubscription?.cancel();
    super.dispose();
  }

  void _subscribeRealtime() {
    _subscription =
        SupabaseService.instance.onCourseFeedbackAdded.listen((newFb) {
      if (!mounted) return;
      final currentUserId = SupabaseService.instance.userId ?? 'guest_mhs';
      final isMyFb = newFb.userId == currentUserId ||
          (currentUserId == 'guest_mhs' && newFb.userId.startsWith('guest'));

      var resolvedFb = newFb;
      final myBorder = RewardBorderService.instance.activeBorderId;
      if (isMyFb && myBorder != null && myBorder.isNotEmpty) {
        resolvedFb = resolvedFb.copyWith(userActiveBorder: myBorder);
      }

      setState(() {
        final existingIndex =
            _feedbacks.indexWhere((f) => f.id == resolvedFb.id);
        if (existingIndex >= 0) {
          if (resolvedFb.userActiveBorder == null &&
              _feedbacks[existingIndex].userActiveBorder != null) {
            resolvedFb = resolvedFb.copyWith(
                userActiveBorder: _feedbacks[existingIndex].userActiveBorder);
          }
          _feedbacks[existingIndex] = resolvedFb;
        } else {
          _feedbacks.insert(0, resolvedFb);
        }
      });
    });
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.instance.getCourseFeedbacks();
      list.removeWhere((f) => f.id.startsWith('sample_'));
      if (!mounted) return;
      setState(() {
        _feedbacks = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  double get _avgRating {
    if (_feedbacks.isEmpty) return 0.0;
    final total = _feedbacks.fold<int>(0, (sum, item) => sum + item.rating);
    return total / _feedbacks.length;
  }


  void _openFeedbackBottomSheet({CourseFeedback? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FeedbackFormSheet(
        existing: existing,
        onSubmit: (kesan, saran, rating) async {
          if (existing != null) {
            final updated =
                await SupabaseService.instance.updateCourseFeedback(
              id: existing.id,
              kesan: kesan,
              saran: saran,
              rating: rating,
            );
            if (mounted) {
              setState(() {
                final idx =
                    _feedbacks.indexWhere((f) => f.id == existing.id);
                if (idx != -1) {
                  _feedbacks[idx] = updated ??
                      CourseFeedback(
                        id: existing.id,
                        userId: existing.userId,
                        userName: existing.userName,
                        userAvatar: existing.userAvatar,
                        userActiveBorder: existing.userActiveBorder,
                        kesan: kesan,
                        saran: saran,
                        rating: rating,
                        createdAt: existing.createdAt,
                      );
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saran & kesan berhasil diperbarui.'),
                  backgroundColor: AppColors.charcoal,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            final res = await SupabaseService.instance.submitCourseFeedback(
              kesan: kesan,
              saran: saran,
              rating: rating,
            );
            if (res != null && mounted) {
              final myBorder = RewardBorderService.instance.activeBorderId;
              final resolved =
                  (res.userActiveBorder == null && myBorder != null)
                      ? res.copyWith(userActiveBorder: myBorder)
                      : res;
              setState(() {
                final idx =
                    _feedbacks.indexWhere((f) => f.id == resolved.id);
                if (idx >= 0) {
                  _feedbacks[idx] = resolved;
                } else {
                  _feedbacks.insert(0, resolved);
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Saran & kesan berhasil dibagikan.'),
                  backgroundColor: AppColors.charcoal,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteFeedback(CourseFeedback fb) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 22),
            SizedBox(width: 8),
            Text(
              'Hapus Ulasan?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus saran & kesan ini dari publik? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 12.5, color: AppColors.slateBlue),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.slateBlue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await SupabaseService.instance.deleteCourseFeedback(fb.id);
      setState(() {
        _feedbacks.removeWhere((item) => item.id == fb.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saran & kesan berhasil dihapus.'),
            backgroundColor: AppColors.charcoal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.charcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saran & Kesan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.charcoal,
              ),
            ),
            Text(
              'Pemrograman Aplikasi Mobile',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.slateBlue,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.charcoal),
            tooltip: 'Segarkan data',
            onPressed: _loadFeedbacks,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.line, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeedbacks,
        color: AppColors.orange,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _buildHeaderBanner(),
                  const SizedBox(height: 14),
                  _buildStatsCard(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pesan Pengguna (${_feedbacks.length})',
                        style: AppText.display(16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.paprika.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.public_rounded,
                                size: 12, color: AppColors.paprika),
                            SizedBox(width: 4),
                            Text(
                              'Global Feed',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.paprika,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_feedbacks.isEmpty)
                    _buildEmptyState()
                  else
                    ..._feedbacks.map((fb) => _buildFeedbackCard(fb)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.charcoal,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: _openFeedbackBottomSheet,
        icon: const Icon(Icons.rate_review_rounded, size: 20),
        label: const Text(
          'Tulis Kesan & Saran',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded,
                    color: AppColors.saffron, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mata Kuliah Pemrograman Mobile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Program Studi Sistem Informasi',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC7CED1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ruang berbagi kesan proses belajar dan saran konstruktif untuk pengembangan perkuliahan.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.forum_rounded,
                      color: AppColors.orange, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_feedbacks.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const Text(
                      'Total Ulasan',
                      style: TextStyle(fontSize: 10.5, color: AppColors.slateBlue),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: AppColors.line,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _feedbacks.isEmpty
                        ? AppColors.cream
                        : AppColors.saffron.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _feedbacks.isEmpty
                        ? Icons.star_outline_rounded
                        : Icons.star_rounded,
                    color: _feedbacks.isEmpty
                        ? AppColors.slateBlue
                        : AppColors.paprika,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _feedbacks.isEmpty ? '0.0' : _avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                      ),
                    ),
                    Text(
                      _feedbacks.isEmpty
                          ? 'Belum ada ulasan'
                          : 'Rata-rata Rating',
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.slateBlue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(CourseFeedback fb) {
    final currentUserId = SupabaseService.instance.userId ?? 'guest_mhs';
    final isMyFeedback = fb.userId == currentUserId ||
        (currentUserId == 'guest_mhs' && fb.userId.startsWith('guest'));

    final myBorder = RewardBorderService.instance.activeBorderId;
    final effectiveBorderId = (isMyFeedback && myBorder != null && myBorder.isNotEmpty)
        ? myBorder
        : fb.userActiveBorder;

    final border = (effectiveBorderId != null && effectiveBorderId.isNotEmpty)
        ? RewardBorder.defaultBorders
            .where((b) => b.id == effectiveBorderId)
            .firstOrNull
        : null;

    final avatarBgColor = border != null
        ? border.rarity.color.withValues(alpha: 0.85)
        : AppColors.paprika;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileBorderAvatar(
                avatarUrl: fb.userAvatar,
                borderId: effectiveBorderId,
                border: border,
                size: 38,
                backgroundColor: avatarBgColor,
                fallbackText: fb.userName.isNotEmpty ? fb.userName : 'M',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fb.userName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (isMyFeedback)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.paprika.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Ulasan Anda',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.paprika,
                              ),
                            ),
                          ),
                        if (border != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: border.rarity.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    border.rarity.color.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  border.rarity == BorderRarity.legendary
                                      ? Icons.workspace_premium_rounded
                                      : (border.rarity == BorderRarity.epic
                                          ? Icons.military_tech_rounded
                                          : Icons.auto_awesome_rounded),
                                  size: 10,
                                  color: border.rarity.color,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  border.name,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: border.rarity.color,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < fb.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: AppColors.saffron,
                      );
                    }),
                  ),
                  if (isMyFeedback)
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: AppColors.slateBlue,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _openFeedbackBottomSheet(existing: fb);
                        } else if (val == 'delete') {
                          _confirmDeleteFeedback(fb);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          height: 38,
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 16, color: AppColors.charcoal),
                              SizedBox(width: 8),
                              Text(
                                'Edit Ulasan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          height: 38,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 16, color: AppColors.red),
                              SizedBox(width: 8),
                              Text(
                                'Hapus Ulasan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // KESAN SECTION
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.saffron.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite_rounded,
                        size: 14, color: AppColors.paprika),
                    SizedBox(width: 6),
                    Text(
                      'Kesan Mata Kuliah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.paprika,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  fb.kesan.isNotEmpty ? fb.kesan : '-',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // SARAN SECTION
          if (fb.saran.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.slateBlue.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 14, color: AppColors.slateBlue),
                      SizedBox(width: 6),
                      Text(
                        'Saran',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slateBlue,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fb.saran,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.rate_review_rounded,
                size: 28, color: AppColors.paprika),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada ulasan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Jadilah mahasiswa pertama yang membagikan kesan dan saran untuk mata kuliah ini!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.slateBlue,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackFormSheet extends StatefulWidget {
  final CourseFeedback? existing;
  final Future<void> Function(String kesan, String saran, int rating) onSubmit;

  const _FeedbackFormSheet({
    this.existing,
    required this.onSubmit,
  });

  @override
  State<_FeedbackFormSheet> createState() => _FeedbackFormSheetState();
}

class _FeedbackFormSheetState extends State<_FeedbackFormSheet> {
  final _kesanController = TextEditingController();
  final _saranController = TextEditingController();
  String? _kesanError;
  String? _saranError;
  int _rating = 5;
  bool _submitting = false;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _kesanController.text = widget.existing!.kesan;
      _saranController.text = widget.existing!.saran;
      _rating = widget.existing!.rating;
    }
    final activeBorder = RewardBorderService.instance.activeBorderId;
    SupabaseService.instance.getProfile().then((p) {
      if (!mounted) return;
      final effectiveBorder = activeBorder ?? p?.activeBorderId;
      setState(() {
        _profile = p?.copyWith(activeBorderId: effectiveBorder) ??
            Profile(
              id: SupabaseService.instance.userId ?? 'guest',
              displayName: SupabaseService.instance.guestName,
              avatarUrl: null,
              activeBorderId: effectiveBorder,
              points: 0,
              createdAt: DateTime.now(),
            );
      });
    });
  }

  @override
  void dispose() {
    _kesanController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final kesan = _kesanController.text.trim();
    final saran = _saranController.text.trim();

    setState(() {
      _kesanError = kesan.isEmpty ? 'Kesan wajib diisi' : null;
      _saranError = saran.isEmpty ? 'Saran wajib diisi' : null;
    });

    if (kesan.isEmpty || saran.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kesan dan Saran wajib diisi sebelum mengirim!'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.onSubmit(kesan, saran, _rating);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  widget.existing != null
                      ? Icons.edit_note_rounded
                      : Icons.rate_review_rounded,
                  color: AppColors.paprika,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.existing != null
                      ? 'Edit Saran & Kesan'
                      : 'Tulis Saran & Kesan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ulasan Anda tentang Mata Kuliah Pemrograman Aplikasi Mobile',
              style: TextStyle(fontSize: 11.5, color: AppColors.slateBlue),
            ),
            if (_profile != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    ProfileBorderAvatar(
                      avatarUrl: _profile?.avatarUrl,
                      borderId: RewardBorderService.instance.activeBorderId ??
                          _profile?.activeBorderId,
                      size: 28,
                      backgroundColor: AppColors.paprika,
                      fallbackText: _profile?.displayName.isNotEmpty == true
                          ? _profile!.displayName
                          : 'M',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profile?.displayName ?? 'Mahasiswa',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                          ),
                          Text(
                            _profile?.activeBorderId != null
                                ? 'Border aktif: ${RewardBorder.defaultBorders.where((b) => b.id == _profile!.activeBorderId).firstOrNull?.name ?? "Koleksi"}'
                                : 'Border: Standar (Tanpa Border)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.slateBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Rating Stars
            const Text(
              'Penilaian Mata Kuliah',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starValue),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      starValue <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 32,
                      color: AppColors.saffron,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // KESAN INPUT
            const Text(
              'Kesan Mata Kuliah *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _kesanController,
              maxLines: 3,
              onChanged: (val) {
                if (_kesanError != null && val.trim().isNotEmpty) {
                  setState(() => _kesanError = null);
                }
              },
              style: const TextStyle(fontSize: 13, color: AppColors.charcoal),
              decoration: InputDecoration(
                hintText: 'Contoh: mata kuliah mobile asik',
                hintStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.slateBlue.withValues(alpha: 0.7)),
                errorText: _kesanError,
                filled: true,
                fillColor: AppColors.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.paprika),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SARAN INPUT
            const Text(
              'Saran *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _saranController,
              maxLines: 3,
              onChanged: (val) {
                if (_saranError != null && val.trim().isNotEmpty) {
                  setState(() => _saranError = null);
                }
              },
              style: const TextStyle(fontSize: 13, color: AppColors.charcoal),
              decoration: InputDecoration(
                hintText:
                    'Contoh: untuk tenggat tugas mungkin bisa di perpanjang sedikit',
                hintStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.slateBlue.withValues(alpha: 0.7)),
                errorText: _saranError,
                filled: true,
                fillColor: const Color(0xFFF7F8F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.paprika),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.slateBlue,
                      side: const BorderSide(color: AppColors.line),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.charcoal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitting ? null : _handleSave,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.existing != null
                                ? 'Simpan Perubahan'
                                : 'Kirimkan ke Publik',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
