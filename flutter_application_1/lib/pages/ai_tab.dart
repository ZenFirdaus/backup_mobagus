import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/ai_recommendation_service.dart';
import '../services/food_ai.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';

class _Msg {
  const _Msg.user(this.text)
    : fromUser = true,
      cards = const [],
      chips = const [];

  _Msg.bot(BotReply r)
    : text = r.text,
      fromUser = false,
      cards = r.cards,
      chips = r.chips;

  final String text;
  final bool fromUser;
  final List<Restaurant> cards;
  final List<QuickReply> chips;
}

/// FOODIE AI: asisten rekomendasi yang mencari langsung di data Supabase.
/// Logika percakapan ada di services/food_ai.dart; file ini hanya tampilan.
class AiTab extends StatefulWidget {
  const AiTab({super.key, this.onOpenRestaurant, this.onOpenExplore});

  /// Dipanggil saat kartu tempat di-tap. Kalau null, kartu tidak bisa di-tap.
  final ValueChanged<Restaurant>? onOpenRestaurant;

  /// Alternatif: pindah ke tab Explore saat kartu di-tap.
  final VoidCallback? onOpenExplore;

  @override
  State<AiTab> createState() => _AiTabState();
}

class _AiTabState extends State<AiTab> {
  final _svc = SupabaseService.instance;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  late final FoodAi _ai = FoodAi(
    fetch: ({String? search, int? maxPrice, String? sortBy}) =>
        _svc.getRestaurants(search: search, maxPrice: maxPrice, sortBy: sortBy),
  );

  late final List<_Msg> _messages = [_Msg.bot(_ai.welcome())];

  bool _typing = false;
  int _session = 0; // naik tiap "percakapan baru" agar balasan lama dibuang

  @override
  void initState() {
    super.initState();
    _initPersonalizedWelcome();
  }

  Future<void> _initPersonalizedWelcome() async {
    final prof = await AiRecommendationService.instance.getProfile();
    if (!mounted) return;
    if (prof != null && prof.isCompleted) {
      final taste = prof.favoriteTastes.isNotEmpty
          ? prof.favoriteTastes.first
          : 'Kuliner';
      setState(() {
        _messages.clear();
        _messages.add(
          _Msg.bot(
            BotReply(
              'Halo! Sesuai preferensimu sebagai **${prof.occupation}** dengan selera **${prof.favoriteTastes.join(" & ")}**,\n\n'
              'Ada yang bisa kubantu carikan hari ini? Kamu juga bisa memilih rekomendasi di bawah:',
              chips: [
                QuickReply(
                  'Rasa $taste untuk ${prof.occupation?.split(" ").first ?? "aku"}',
                ),
                QuickReply('Kuliner dekat ${prof.housingType}'),
                QuickReply(
                  'Sesuai budget ${prof.mealBudget?.split(" ").first ?? "hemat"}',
                ),
                QuickReply('Rekomendasi terbaik'),
              ],
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send(String text, {String? display}) async {
    final t = text.trim();
    if (t.isEmpty || _typing) return;

    // Catatan: chat dengan AI sengaja TIDAK disimpan ke riwayat pencarian.
    // Riwayat hanya berisi pencarian dari search bar di tab Explore.
    final session = _session;
    setState(() {
      _messages.add(_Msg.user((display ?? t).trim()));
      _typing = true;
    });
    _controller.clear();
    _scrollDown();

    final started = DateTime.now();
    final reply = await _ai.reply(t);

    // Jeda kecil supaya terasa natural: lebih panjang jawaban, lebih lama.
    final wait = (450 + reply.text.length * 4).clamp(500, 1300).toInt();
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    if (elapsed < wait) {
      await Future.delayed(Duration(milliseconds: wait - elapsed));
    }

    if (!mounted || session != _session) return;
    setState(() {
      _messages.add(_Msg.bot(reply));
      _typing = false;
    });
    _scrollDown();
  }

  void _newChat() {
    _ai.reset();
    setState(() {
      _session++;
      _typing = false;
      _messages
        ..clear()
        ..add(_Msg.bot(_ai.welcome()));
    });
    _initPersonalizedWelcome();
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openRestaurant(Restaurant r) {
    final onOpen = widget.onOpenRestaurant;
    if (onOpen != null) {
      onOpen(r);
    } else {
      widget.onOpenExplore?.call();
    }
  }

  bool get _cardsTappable =>
      widget.onOpenRestaurant != null || widget.onOpenExplore != null;

  @override
  Widget build(BuildContext context) {
    return PageBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _messages.length + (_typing ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) return _typingBubble();
                  return _messageItem(i);
                },
              ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.greenDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              size: 22,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FOODIE AI', style: AppText.display(20)),
                Text(
                  _typing
                      ? 'Sedang mengetik...'
                      : 'Asisten kuliner DIY & Jawa Tengah',
                  style: TextStyle(
                    fontSize: 11,
                    color: _typing ? AppColors.orange : AppColors.textMuted,
                    fontWeight: _typing ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Percakapan baru',
            onPressed: _newChat,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.greenDark),
          ),
        ],
      ),
    );
  }

  /// Satu pesan + kartu hasil + chip (chip hanya untuk pesan bot terakhir).
  Widget _messageItem(int i) {
    final m = _messages[i];
    final isLast = i == _messages.length - 1;
    final showChips = !m.fromUser && isLast && !_typing && m.chips.isNotEmpty;

    return Column(
      crossAxisAlignment: m.fromUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        _bubble(m),
        for (final r in m.cards)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _RestaurantTile(
              restaurant: r,
              maxWidth: _maxBubbleWidth,
              onTap: _cardsTappable ? () => _openRestaurant(r) : null,
            ),
          ),
        if (showChips) _chipRow(m.chips),
      ],
    );
  }

  double get _maxBubbleWidth => MediaQuery.of(context).size.width * 0.78;

  Widget _bubble(_Msg m) {
    final user = m.fromUser;
    final base = TextStyle(
      fontSize: 12.5,
      height: 1.5,
      color: user ? AppColors.yellow : AppColors.greenDark,
    );
    final bold = base.copyWith(
      fontWeight: FontWeight.w800,
      color: user ? AppColors.yellow : AppColors.textDark,
    );

    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: _maxBubbleWidth),
        decoration: BoxDecoration(
          color: user ? AppColors.greenDark : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(user ? 18 : 4),
            bottomRight: Radius.circular(user ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: user ? 0.08 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text.rich(TextSpan(children: _spans(m.text, base, bold))),
      ),
    );
  }

  /// Teks di antara **tanda bintang ganda** ditampilkan tebal.
  List<InlineSpan> _spans(String text, TextStyle base, TextStyle bold) {
    final parts = text.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        TextSpan(text: parts[i], style: i.isOdd ? bold : base),
    ];
  }

  Widget _chipRow(List<QuickReply> chips) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in chips)
            GestureDetector(
              onTap: () => _send(c.send, display: c.label),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.yellow, 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  c.label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const _TypingDots(),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      onSubmitted: (v) {
                        _send(v);
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Tanya rekomendasi kuliner...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_focus.hasFocus || _controller.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Tutup Keyboard',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.keyboard_hide_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _send(_controller.text);
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _typing ? 0.5 : 1,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu satu tempat di bawah gelembung bot.
class _RestaurantTile extends StatelessWidget {
  const _RestaurantTile({
    required this.restaurant,
    required this.maxWidth,
    this.onTap,
  });

  final Restaurant restaurant;
  final double maxWidth;
  final VoidCallback? onTap;

  IconData get _icon {
    final c = restaurant.category.toLowerCase();
    if (c.contains('cafe') || c.contains('coffee')) {
      return Icons.local_cafe_rounded;
    }
    if (c.contains('fast')) return Icons.fastfood_rounded;
    if (c.contains('bakery')) return Icons.bakery_dining_rounded;
    if (c.contains('ice')) return Icons.icecream_rounded;
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final price = restaurant.priceMin;
    final priceText = price > 0
        ? 'mulai ${foodRp(price)}'
        : 'harga belum tercatat';

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.orange, 0.2),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_icon, size: 20, color: AppColors.red),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${prettyCategory(restaurant.category)} • $priceText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiga titik yang berdenyut saat bot "mengetik".
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_c.value - i * 0.18) % 1.0;
            final up = t < 0.5 ? t * 2 : (1 - t) * 2; // 0..1..0
            return Padding(
              padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
              child: Transform.translate(
                offset: Offset(0, -3 * up),
                child: Opacity(
                  opacity: 0.35 + 0.65 * up,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
