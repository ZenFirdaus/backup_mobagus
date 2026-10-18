import 'package:flutter/material.dart';

import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../widgets/auth_widgets.dart';

class _Msg {
  final String text;
  final bool fromUser;
  const _Msg(this.text, {required this.fromUser});
}

/// Asisten kuliner FOODIE AI (UI chat; sambungkan ke API AI di _reply()).
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
      'Halo! Aku FOODIE AI 👋\nCeritakan selera, budget, atau suasana yang '
      'kamu cari, nanti aku rekomendasikan kuliner di DIY & Jawa Tengah.',
      fromUser: false,
    ),
  ];

  static const _suggestions = [
    'Gudeg enak budget 25rb',
    'Sarapan dekat Kraton',
    'Warung legendaris buka malam',
    'Kuliner pedas di Bantul',
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

    final answer = await _reply(t);
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(answer, fromUser: false));
      _typing = false;
    });
    _scrollDown();
  }

  /// TODO: ganti dengan panggilan ke backend / API AI.
  Future<String> _reply(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return 'Rekomendasi untuk "$prompt":\n'
        '• Gudeg Yu Djum 167 Wijilan (Kraton)\n'
        '• Mangut Lele Mbah Marto (Sewon, Bantul)\n'
        '• Soto Bathok Mbah Katro (Kalasan, Sleman)\n\n'
        'Buka tab Explore untuk melihat detail dan jarak dari lokasimu.';
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
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
                  'Asisten kuliner DIY & Jawa Tengah',
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
    return Align(
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
              : Border.all(color: AppColors.tint(AppColors.greenDark, 0.12)),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: user ? AppColors.yellow : AppColors.greenDark,
          ),
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
          border: Border.all(color: AppColors.tint(AppColors.greenDark, 0.12)),
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                  hintText: 'Tanya rekomendasi kuliner...',
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
