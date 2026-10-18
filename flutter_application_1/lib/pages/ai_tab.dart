import 'package:flutter/material.dart';

import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../services/supabase_service.dart';
import '../widgets/auth_widgets.dart';
import 'detail_page.dart';

class _Msg {
  final String text;
  final bool fromUser;
  final List<Restaurant>? restaurants;
  const _Msg(this.text, {required this.fromUser, this.restaurants});
}

class AiTab extends StatefulWidget {
  const AiTab({super.key});

  @override
  State<AiTab> createState() => _AiTabState();
}

class _AiTabState extends State<AiTab> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;

  final List<_Msg> _messages = [
    const _Msg(
      'Sugeng rawuh! Saya asisten AI kuliner FOODIE.\n'
      'Beritahu saya preferensi rasa, budget, atau suasana yang kamu inginkan '
      'di seputar DIY dan Jawa Tengah.',
      fromUser: false,
    ),
  ];

  static const _suggestions = [
    'Gudeg enak budget 25rb',
    'Sarapan soto murah',
    'Kuliner pedas khas Jogja',
    'Angkringan malam',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _typing) return;
    setState(() {
      _messages.add(_Msg(t, fromUser: true));
      _typing = true;
    });
    _controller.clear();
    _scrollDown();

    final response = await _generateReply(t);
    if (!mounted) return;
    setState(() {
      _messages.add(response);
      _typing = false;
    });
    _scrollDown();
  }

  Future<_Msg> _generateReply(String prompt) async {
    final lower = prompt.toLowerCase();
    String? categoryFilter;
    int? maxPriceFilter;

    if (lower.contains('gudeg')) categoryFilter = 'gudeg';
    if (lower.contains('soto')) categoryFilter = 'soto';
    if (lower.contains('pedas') || lower.contains('mercon')) {
      categoryFilter = 'pedas';
    }
    if (lower.contains('angkringan') || lower.contains('kopi')) {
      categoryFilter = 'angkringan';
    }
    if (lower.contains('bakmi')) categoryFilter = 'bakmi';
    if (lower.contains('sate')) categoryFilter = 'sate';

    if (lower.contains('25rb') || lower.contains('25.000') || lower.contains('25000')) {
      maxPriceFilter = 25000;
    } else if (lower.contains('30rb') || lower.contains('30.000') || lower.contains('30000')) {
      maxPriceFilter = 30000;
    } else if (lower.contains('15rb') || lower.contains('15.000') || lower.contains('15000')) {
      maxPriceFilter = 15000;
    } else if (lower.contains('murah')) {
      maxPriceFilter = 20000;
    }

    try {
      final results = await SupabaseService.instance.getRestaurants(
        category: categoryFilter,
        maxPrice: maxPriceFilter,
      );

      if (results.isEmpty) {
        final fallback = await SupabaseService.instance.getRestaurants();
        if (fallback.isNotEmpty) {
          return _Msg(
            'Berikut beberapa rekomendasi kuliner autentik terkurasi di DIY & Jawa Tengah:',
            fromUser: false,
            restaurants: fallback.take(3).toList(),
          );
        }
        return const _Msg(
          'Maaf, tidak menemukan kuliner yang sesuai kriteria di wilayah DIY & Jawa Tengah. Coba kata kunci lain seperti "gudeg", "soto", atau "bakmi".',
          fromUser: false,
        );
      }

      final count = results.length;
      return _Msg(
        'Ditemukan $count rekomendasi kuliner terverifikasi di DIY & Jawa Tengah yang sesuai:',
        fromUser: false,
        restaurants: results.take(3).toList(),
      );
    } catch (_) {
      return const _Msg(
        'Maaf, terjadi gangguan koneksi ke basis data. Pastikan perangkat terhubung ke internet.',
        fromUser: false,
      );
    }
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _messages.length + (_typing ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _messages.length) return _typingBubble();
                  return _bubble(_messages[i]);
                },
              ),
            ),
            if (_messages.length <= 1) _suggestionRow(),
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
              Icons.auto_awesome,
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
                const Text(
                  'LLM Gastronomi DIY & Jawa Tengah',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Percakapan baru',
            onPressed: () =>
                setState(() => _messages.removeRange(1, _messages.length)),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.greenDark),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_Msg m) {
    final user = m.fromUser;
    return Column(
      crossAxisAlignment:
          user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: user ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              color: user ? AppColors.greenDark : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(user ? 18 : 4),
                bottomRight: Radius.circular(user ? 4 : 18),
              ),
              border: user
                  ? null
                  : Border.all(
                      color: AppColors.tint(AppColors.greenDark, 0.12)),
            ),
            child: Text(
              m.text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: user ? AppColors.yellow : AppColors.textDark,
              ),
            ),
          ),
        ),
        if (m.restaurants != null && m.restaurants!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Column(
              children: m.restaurants!
                  .map((r) => _aiRestaurantCard(r))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _aiRestaurantCard(Restaurant r) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailPage(restaurant: r)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.tint(AppColors.orange, 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.tint(AppColors.orange, 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.yellow, 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant,
                  size: 22, color: AppColors.greenDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.priceRange,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.greenDark),
          ],
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: AppColors.tint(AppColors.greenDark, 0.12)),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.orange,
          ),
        ),
      ),
    );
  }

  Widget _suggestionRow() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _send(_suggestions[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.yellow, 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.tint(AppColors.orange, 0.3)),
            ),
            child: Text(
              _suggestions[i],
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.greenDark,
              ),
            ),
          ),
        ),
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
                border: Border.all(
                  color: AppColors.tint(AppColors.greenDark, 0.15),
                ),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: _send,
                textInputAction: TextInputAction.send,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Tanyakan kuliner favoritmu...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_controller.text),
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
        ],
      ),
    );
  }
}
