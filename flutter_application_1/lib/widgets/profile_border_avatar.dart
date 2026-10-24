import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/reward_border.dart';
import '../props/app_colors.dart';

/// Widget Avatar Profil dengan 20 Desain Border Profil FOODIE
/// Mendukung rendering statis dan animasi 60 FPS pada border Rare, Epic, dan Legendary.
class ProfileBorderAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String? borderId;
  final RewardBorder? border;
  final double size;
  final String fallbackText;
  final Color backgroundColor;
  final bool animate;

  const ProfileBorderAvatar({
    super.key,
    required this.avatarUrl,
    this.borderId,
    this.border,
    required this.size,
    this.fallbackText = 'F',
    this.backgroundColor = AppColors.orange,
    this.animate = true,
  });

  @override
  State<ProfileBorderAvatar> createState() => _ProfileBorderAvatarState();
}

class _ProfileBorderAvatarState extends State<ProfileBorderAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileBorderAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  RewardBorder? _resolveBorder() {
    if (widget.border != null) return widget.border;
    if (widget.borderId == null || widget.borderId!.isEmpty) return null;
    return RewardBorder.defaultBorders.firstWhere(
      (b) => b.id == widget.borderId,
      orElse: () => RewardBorder.defaultBorders.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final border = _resolveBorder();
    final size = widget.size;

    // Jika tidak memiliki border, tampilkan avatar lingkaran standar yang bersih
    if (border == null) {
      return _buildRawAvatar(size);
    }

    // Hitung ketebalan border relatif terhadap ukuran avatar
    final scale = size / 56.0;
    final borderWidth =
        ((border.styleData['borderWidth'] as num?)?.toDouble() ?? 3.5) *
            scale.clamp(0.65, 1.8);
    final styleType = border.styleData['styleType']?.toString() ?? 'solid';

    // Outer padding untuk menampung efek glow / mahkota animasi
    final glowPadding = (border.rarity == BorderRarity.legendary ||
            border.rarity == BorderRarity.epic)
        ? (5.0 * scale)
        : (2.0 * scale);

    final totalSize = size + (borderWidth * 2) + (glowPadding * 2);

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BorderEffectPainter(
              border: border,
              styleType: styleType,
              borderWidth: borderWidth,
              progress: _controller.value,
              rarity: border.rarity,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(borderWidth + (glowPadding * 0.7)),
                child: _buildRawAvatar(size),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Raw Avatar (Foto profil internet, base64, atau inisial nama)
  Widget _buildRawAvatar(double innerSize) {
    final initial = widget.fallbackText.trim().isNotEmpty
        ? widget.fallbackText.trim()[0].toUpperCase()
        : 'F';

    final fallback = Container(
      width: innerSize,
      height: innerSize,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: innerSize * 0.42,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

    if (widget.avatarUrl == null || widget.avatarUrl!.trim().isEmpty) {
      return fallback;
    }

    final trimmed = widget.avatarUrl!.trim();
    if (trimmed.startsWith('data:image')) {
      try {
        final comma = trimmed.indexOf(',');
        if (comma != -1) {
          final b64 = trimmed.substring(comma + 1);
          final bytes = base64Decode(b64);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: innerSize,
              height: innerSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
          );
        }
      } catch (_) {}
    }

    return ClipOval(
      child: Image.network(
        trimmed,
        width: innerSize,
        height: innerSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

/// CustomPainter untuk 20 Efek Desain Border Profil
class _BorderEffectPainter extends CustomPainter {
  final RewardBorder border;
  final String styleType;
  final double borderWidth;
  final double progress;
  final BorderRarity rarity;

  _BorderEffectPainter({
    required this.border,
    required this.styleType,
    required this.borderWidth,
    required this.progress,
    required this.rarity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - borderWidth) / 2 - 2.0;

    final primary = Color((border.styleData['primaryColor'] as num?)?.toInt() ?? 0xFFCD7F32);
    final secondary = Color((border.styleData['secondaryColor'] as num?)?.toInt() ?? 0xFF8C532B);

    switch (styleType) {
      // 1. Garuda Bronze: Logam Candi Klasik
      case 'solid_metallic':
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, const Color(0xFFF0B376), secondary, primary],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, paint);

        // Aksen cincin dalam tipis
        final innerPaint = Paint()
          ..color = primary.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(center, radius - borderWidth + 0.5, innerPaint);
        break;

      // 2. Bamboo Forest: Gradien Cincin Rimbun
      case 'gradient_ring':
        final paint = Paint()
          ..shader = SweepGradient(
            colors: [primary, secondary, const Color(0xFF81C784), primary],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, paint);
        break;

      // 3. Batik Parang: Garis Putus Miring Berkarakter
      case 'dashed_batik':
        final basePaint = Paint()
          ..color = secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, basePaint);

        final dashPaint = Paint()
          ..color = const Color(0xFFD7CCC8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth * 0.8;

        const count = 16;
        for (var i = 0; i < count; i++) {
          final angle = (i * 2 * math.pi / count);
          final p1 = Offset(
            center.dx + (radius - 1) * math.cos(angle),
            center.dy + (radius - 1) * math.sin(angle),
          );
          final p2 = Offset(
            center.dx + (radius + 1) * math.cos(angle + 0.14),
            center.dy + (radius + 1) * math.sin(angle + 0.14),
          );
          canvas.drawLine(p1, p2, dashPaint);
        }
        break;

      // 4. Slate Minimalis: Garis Ganda Modern
      case 'double_line':
        final p1 = Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth * 0.5;
        canvas.drawCircle(center, radius, p1);

        final p2 = Paint()
          ..color = secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth * 0.5;
        canvas.drawCircle(center, radius - borderWidth * 0.7, p2);
        break;

      // 5. Roasted Charcoal: Bingkai Bevel Bersudut
      case 'chamfer_ring':
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [secondary, primary],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, paint);
        break;

      // 6. Silver Kotagede: Kilau Perak Murni
      case 'metallic_silver':
        final paint = Paint()
          ..shader = SweepGradient(
            colors: [
              const Color(0xFFFFFFFF),
              primary,
              secondary,
              const Color(0xFFFFFFFF),
              primary,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, paint);
        break;

      // 7. Cobalt Horizon: Gradien Biru Samudra
      case 'gradient_dual':
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primary, secondary],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, paint);
        break;

      // 8. Emerald Heritage: Zamrud Kraton & Aksen Emas
      case 'emerald_gold':
        final paint = Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, paint);

        final goldPaint = Paint()
          ..color = secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, radius + (borderWidth * 0.5) - 0.5, goldPaint);
        break;

      // 9. Paprika Spice: Aksen Rempah Hangat
      case 'paprika_accent':
        final paint = Paint()
          ..shader = SweepGradient(
            colors: [primary, secondary, const Color(0xFFFFCC80), primary],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, paint);
        break;

      // 10. Saffron Gold: Cincin Kemewahan Emas
      case 'gold_ring':
        final paint = Paint()
          ..shader = SweepGradient(
            colors: [
              primary,
              const Color(0xFFFFF9C4),
              secondary,
              primary,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, paint);
        break;

      // 11. Cyberpunk Neon Jogja: Pendaran Neon Berdenyut Halus
      case 'neon_pulse':
        final pulse = math.sin(progress * 2 * math.pi) * 0.5 + 0.5;
        final glowPaint = Paint()
          ..color = primary.withValues(alpha: 0.35 + 0.35 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth + (3.0 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(center, radius, glowPaint);

        final corePaint = Paint()
          ..shader = SweepGradient(
            colors: [primary, secondary, primary],
            transform: GradientRotation(progress * 2 * math.pi),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, corePaint);
        break;

      // 12. Ruby Royal: Kilau Permata Delima
      case 'gem_shimmer':
        final paint = Paint()
          ..shader = LinearGradient(
            colors: [primary, secondary, const Color(0xFFFF80AB), primary],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, paint);

        // Kilau sudut 8 facet
        final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
        for (var i = 0; i < 8; i++) {
          final angle = (i * math.pi / 4) + (progress * math.pi * 0.5);
          final dx = center.dx + radius * math.cos(angle);
          final dy = center.dy + radius * math.sin(angle);
          canvas.drawCircle(Offset(dx, dy), 1.5, dotPaint);
        }
        break;

      // 13. Midnight Starlight: Taburan Bintang Berpendar
      case 'starlight_twinkle':
        final basePaint = Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, basePaint);

        // Bintang berkilau
        final starPaint = Paint()..color = Colors.white;
        for (var i = 0; i < 12; i++) {
          final phase = (progress + (i / 12)) % 1.0;
          final starAlpha = (math.sin(phase * 2 * math.pi).abs()).clamp(0.1, 1.0);
          starPaint.color = Colors.white.withValues(alpha: starAlpha);
          final angle = (i * 2 * math.pi / 12);
          final dx = center.dx + radius * math.cos(angle);
          final dy = center.dy + radius * math.sin(angle);
          canvas.drawCircle(Offset(dx, dy), 1.8, starPaint);
        }
        break;

      // 14. Amethyst Nebula: Pusaran Warna Ungu Kosmik Berputar
      case 'gradient_orbit':
        final paint = Paint()
          ..shader = SweepGradient(
            colors: [primary, secondary, const Color(0xFFE1BEE7), primary],
            transform: GradientRotation(progress * 2 * math.pi),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, paint);
        break;

      // 15. Lahar Krakatau: Aliran Magma Membara Melingkar
      case 'fiery_flow':
        final glow = Paint()
          ..color = primary.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth + 4.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawCircle(center, radius, glow);

        final firePaint = Paint()
          ..shader = SweepGradient(
            colors: [
              primary,
              secondary,
              const Color(0xFFFFD54F),
              primary,
            ],
            transform: GradientRotation(-progress * 2 * math.pi),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, firePaint);
        break;

      // 16. Tirai Aurora: Gelombang Cahaya Kutub Dinamis
      case 'aurora_shift':
        final wave = math.sin(progress * 2 * math.pi);
        final glow = Paint()
          ..shader = SweepGradient(
            colors: [primary, secondary, primary],
            transform: GradientRotation(progress * 2 * math.pi),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth + (2.5 * wave.abs())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(center, radius, glow);

        final core = Paint()
          ..shader = SweepGradient(
            colors: [primary, secondary, primary],
            transform: GradientRotation(progress * 2 * math.pi),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, core);
        break;

      // 17. Mahkota Surya: Sinar Korona Matahari Berputar
      case 'solar_corona':
        final crownPaint = Paint()
          ..color = primary.withValues(alpha: 0.6)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke;

        const rayCount = 18;
        for (var i = 0; i < rayCount; i++) {
          final angle = (i * 2 * math.pi / rayCount) + (progress * 2 * math.pi);
          final r1 = radius + (borderWidth * 0.5);
          final r2 = r1 + 3.5;
          final p1 = Offset(center.dx + r1 * math.cos(angle), center.dy + r1 * math.sin(angle));
          final p2 = Offset(center.dx + r2 * math.cos(angle), center.dy + r2 * math.sin(angle));
          canvas.drawLine(p1, p2, crownPaint);
        }

        final ring = Paint()
          ..shader = SweepGradient(
            colors: [primary, secondary, const Color(0xFFFFF176), primary],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, ring);
        break;

      // 18. Celestial Diamond: Intan Prismatik Pelangi Berputar
      case 'prismatic_diamond':
        final prismPaint = Paint()
          ..shader = SweepGradient(
            colors: const [
              Color(0xFF00E5FF),
              Color(0xFFFF4081),
              Color(0xFFFFEA00),
              Color(0xFF76FF03),
              Color(0xFF00E5FF),
            ],
            transform: GradientRotation(progress * 2 * math.pi),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, prismPaint);

        // Efek aura kristal
        final auraPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth + 4.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawCircle(center, radius, auraPaint);
        break;

      // 19. Blockchain Genesis Node: Rantai Heksagonal Kriptografis EVM
      case 'blockchain_chain':
        // Aura Ether
        final ethGlow = Paint()
          ..color = primary.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth + 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
        canvas.drawCircle(center, radius, ethGlow);

        final chainPaint = Paint()
          ..shader = SweepGradient(
            colors: [primary, secondary, Colors.white, primary],
            transform: GradientRotation(progress * 2 * math.pi),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, chainPaint);

        // Simpul-simpul node heksagonal di sekeliling border
        const nodes = 6;
        final nodePaint = Paint()..color = Colors.white;
        for (var i = 0; i < nodes; i++) {
          final angle = (i * 2 * math.pi / nodes) + (progress * math.pi);
          final dx = center.dx + radius * math.cos(angle);
          final dy = center.dy + radius * math.sin(angle);
          canvas.drawCircle(Offset(dx, dy), 2.8, nodePaint);
        }
        break;

      // 20. Mythic Phoenix: Aura Kencana Burung Phoenix
      case 'phoenix_aura':
        final aura = Paint()
          ..shader = RadialGradient(
            colors: [
              primary.withValues(alpha: 0.0),
              secondary.withValues(alpha: 0.4),
              primary.withValues(alpha: 0.7),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius + 6.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth + 5.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
        canvas.drawCircle(center, radius, aura);

        final core = Paint()
          ..shader = SweepGradient(
            colors: [
              primary,
              secondary,
              const Color(0xFFFFD700),
              primary,
            ],
            transform: GradientRotation(-progress * 2 * math.pi),
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, core);
        break;

      default:
        final fallbackPaint = Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawCircle(center, radius, fallbackPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BorderEffectPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.border.id != border.id;
  }
}
