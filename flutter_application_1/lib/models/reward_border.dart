import 'package:flutter/material.dart';

enum BorderRarity {
  common('Umum', Color(0xFF8A9398), 150),
  uncommon('Khusus', Color(0xFF2E7D32), 350),
  rare('Langka', Color(0xFF1976D2), 750),
  epic('Epik', Color(0xFF7B1FA2), 1400),
  legendary('Legendaris', Color(0xFFE65100), 2500);

  final String label;
  final Color color;
  final int basePrice;
  const BorderRarity(this.label, this.color, this.basePrice);
}

class RewardBorder {
  final String id;
  final String name;
  final String description;
  final BorderRarity rarity;
  final int pricePoints;
  final bool isAnimated;
  final String category;
  final Map<String, dynamic> styleData;

  const RewardBorder({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.pricePoints,
    required this.isAnimated,
    required this.category,
    required this.styleData,
  });

  factory RewardBorder.fromJson(Map<String, dynamic> json) {
    BorderRarity parseRarity(String? r) {
      switch (r?.toLowerCase()) {
        case 'uncommon':
        case 'khusus':
          return BorderRarity.uncommon;
        case 'rare':
        case 'langka':
          return BorderRarity.rare;
        case 'epic':
        case 'epik':
          return BorderRarity.epic;
        case 'legendary':
        case 'legendaris':
          return BorderRarity.legendary;
        case 'common':
        case 'umum':
        default:
          return BorderRarity.common;
      }
    }

    return RewardBorder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Border Tanpa Nama',
      description: json['description']?.toString() ?? '',
      rarity: parseRarity(json['rarity']?.toString()),
      pricePoints: (json['price_points'] as num?)?.toInt() ?? 150,
      isAnimated: json['is_animated'] == true,
      category: json['category']?.toString() ?? 'Klasik',
      styleData: json['style_data'] is Map<String, dynamic>
          ? json['style_data'] as Map<String, dynamic>
          : {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'rarity': rarity.name,
        'price_points': pricePoints,
        'is_animated': isAnimated,
        'category': category,
        'style_data': styleData,
      };

  /// 20 Desain Border Profil Lengkap (Dari Sederhana Murah hingga Animasi Premium Mahal)
  static final List<RewardBorder> defaultBorders = [
    // ── COMMON (150 - 250 Poin) ──
    const RewardBorder(
      id: 'border_garuda_bronze',
      name: 'Perunggu Garuda',
      description: 'Lingkaran perunggu kokoh terinspirasi ukiran candi Jawa kuno.',
      rarity: BorderRarity.common,
      pricePoints: 150,
      isAnimated: false,
      category: 'Warisan',
      styleData: {
        'primaryColor': 0xFFCD7F32,
        'secondaryColor': 0xFF8C532B,
        'borderWidth': 3.0,
        'styleType': 'solid_metallic',
      },
    ),
    const RewardBorder(
      id: 'border_bamboo_forest',
      name: 'Rimbun Bambu',
      description: 'Garis hijau alami yang melambangkan kesegaran bambu petung.',
      rarity: BorderRarity.common,
      pricePoints: 180,
      isAnimated: false,
      category: 'Alam',
      styleData: {
        'primaryColor': 0xFF388E3C,
        'secondaryColor': 0xFF1B5E20,
        'borderWidth': 3.0,
        'styleType': 'gradient_ring',
      },
    ),
    const RewardBorder(
      id: 'border_batik_parang',
      name: 'Parang Geometris',
      description: 'Aksen motif miring diagonal khas batik keraton Yogyakarta.',
      rarity: BorderRarity.common,
      pricePoints: 200,
      isAnimated: false,
      category: 'Warisan',
      styleData: {
        'primaryColor': 0xFF8D6E63,
        'secondaryColor': 0xFF4E342E,
        'borderWidth': 3.5,
        'styleType': 'dashed_batik',
      },
    ),
    const RewardBorder(
      id: 'border_slate_minimalist',
      name: 'Slate Minimalis',
      description: 'Garis ganda bersih bernuansa batu andesit modern perkotaan.',
      rarity: BorderRarity.common,
      pricePoints: 220,
      isAnimated: false,
      category: 'Modern',
      styleData: {
        'primaryColor': 0xFF607783,
        'secondaryColor': 0xFF37474F,
        'borderWidth': 2.8,
        'styleType': 'double_line',
      },
    ),
    const RewardBorder(
      id: 'border_roasted_charcoal',
      name: 'Arang Panggang',
      description: 'Bingkai monokrom hitam arang dengan sudut bevel berkarakter.',
      rarity: BorderRarity.common,
      pricePoints: 250,
      isAnimated: false,
      category: 'Kuliner',
      styleData: {
        'primaryColor': 0xFF252D30,
        'secondaryColor': 0xFF121618,
        'borderWidth': 3.5,
        'styleType': 'chamfer_ring',
      },
    ),

    // ── UNCOMMON (350 - 550 Poin) ──
    const RewardBorder(
      id: 'border_silver_sleek',
      name: 'Perak Kotagede',
      description: 'Kilau perak murni hasil tempaan pengrajin legendaris Kotagede.',
      rarity: BorderRarity.uncommon,
      pricePoints: 350,
      isAnimated: false,
      category: 'Warisan',
      styleData: {
        'primaryColor': 0xFFE0E0E0,
        'secondaryColor': 0xFF9E9E9E,
        'borderWidth': 3.5,
        'styleType': 'metallic_silver',
      },
    ),
    const RewardBorder(
      id: 'border_cobalt_horizon',
      name: 'Cakrawala Kobalt',
      description: 'Gradien biru laut samudra selatan dengan kontras tegas.',
      rarity: BorderRarity.uncommon,
      pricePoints: 400,
      isAnimated: false,
      category: 'Alam',
      styleData: {
        'primaryColor': 0xFF1976D2,
        'secondaryColor': 0xFF0D47A1,
        'borderWidth': 3.5,
        'styleType': 'gradient_dual',
      },
    ),
    const RewardBorder(
      id: 'border_emerald_heritage',
      name: 'Zamrud Kraton',
      description: 'Nuansa hijau zamrud bangsawan dengan aksen emas halus.',
      rarity: BorderRarity.uncommon,
      pricePoints: 450,
      isAnimated: false,
      category: 'Warisan',
      styleData: {
        'primaryColor': 0xFF00796B,
        'secondaryColor': 0xFFF5BD50,
        'borderWidth': 3.5,
        'styleType': 'emerald_gold',
      },
    ),
    const RewardBorder(
      id: 'border_paprika_spice',
      name: 'Api Paprika',
      description: 'Semangat hangat rempah cabai merah yang menggugah selera.',
      rarity: BorderRarity.uncommon,
      pricePoints: 500,
      isAnimated: false,
      category: 'Kuliner',
      styleData: {
        'primaryColor': 0xFFEF8235,
        'secondaryColor': 0xFFD84315,
        'borderWidth': 3.5,
        'styleType': 'paprika_accent',
      },
    ),
    const RewardBorder(
      id: 'border_saffron_gold',
      name: 'Emas Saffron',
      description: 'Kemewahan benang saffron kuning keemasan yang berharga.',
      rarity: BorderRarity.uncommon,
      pricePoints: 550,
      isAnimated: false,
      category: 'Kuliner',
      styleData: {
        'primaryColor': 0xFFF5BD50,
        'secondaryColor': 0xFFFFA000,
        'borderWidth': 4.0,
        'styleType': 'gold_ring',
      },
    ),

    // ── RARE (750 - 1100 Poin, dengan Animasi Ringan) ──
    const RewardBorder(
      id: 'border_cyberpunk_jogja',
      name: 'Neon Malioboro',
      description: 'Pendaran neon futuristik biru-ungu berdenyut halus.',
      rarity: BorderRarity.rare,
      pricePoints: 750,
      isAnimated: true,
      category: 'Futuristik',
      styleData: {
        'primaryColor': 0xFF00E5FF,
        'secondaryColor': 0xFFD500F9,
        'borderWidth': 4.0,
        'styleType': 'neon_pulse',
      },
    ),
    const RewardBorder(
      id: 'border_ruby_gastronomy',
      name: 'Permata Delima',
      description: 'Pancaran kristal batu delima dengan kilau bersudut presisi.',
      rarity: BorderRarity.rare,
      pricePoints: 850,
      isAnimated: true,
      category: 'Permata',
      styleData: {
        'primaryColor': 0xFFC2185B,
        'secondaryColor': 0xFF880E4F,
        'borderWidth': 4.0,
        'styleType': 'gem_shimmer',
      },
    ),
    const RewardBorder(
      id: 'border_midnight_starlight',
      name: 'Bintang Tengah Malam',
      description: 'Latar gelap pekat dihiasi taburan bintang yang berpendar.',
      rarity: BorderRarity.rare,
      pricePoints: 950,
      isAnimated: true,
      category: 'Kosmik',
      styleData: {
        'primaryColor': 0xFF1A237E,
        'secondaryColor': 0xFFE0E0E0,
        'borderWidth': 4.0,
        'styleType': 'starlight_twinkle',
      },
    ),
    const RewardBorder(
      id: 'border_amethyst_nebula',
      name: 'Nebula Ametis',
      description: 'Pusaran warna ungu kosmik dengan gelombang gradien berputar.',
      rarity: BorderRarity.rare,
      pricePoints: 1100,
      isAnimated: true,
      category: 'Kosmik',
      styleData: {
        'primaryColor': 0xFF7B1FA2,
        'secondaryColor': 0xFF512DA8,
        'borderWidth': 4.0,
        'styleType': 'gradient_orbit',
      },
    ),

    // ── EPIC (1400 - 1850 Poin, Animasi Aliran & Mahkota Partikel) ──
    const RewardBorder(
      id: 'border_lava_krakatau',
      name: 'Lahar Krakatau',
      description: 'Aliran magma merah membara yang mengalir dinamis melingkar.',
      rarity: BorderRarity.epic,
      pricePoints: 1400,
      isAnimated: true,
      category: 'Elemen',
      styleData: {
        'primaryColor': 0xFFFF3D00,
        'secondaryColor': 0xFFFFAB00,
        'borderWidth': 4.5,
        'styleType': 'fiery_flow',
      },
    ),
    const RewardBorder(
      id: 'border_aurora_borealis',
      name: 'Tirai Aurora',
      description: 'Pendaran cahaya kutub hijau toska dan magenta yang bergerak anggun.',
      rarity: BorderRarity.epic,
      pricePoints: 1600,
      isAnimated: true,
      category: 'Alam',
      styleData: {
        'primaryColor': 0xFF00E676,
        'secondaryColor': 0xFFFF4081,
        'borderWidth': 4.5,
        'styleType': 'aurora_shift',
      },
    ),
    const RewardBorder(
      id: 'border_solar_flare_crown',
      name: 'Mahkota Surya',
      description: 'Pancaran sinar korona matahari dengan rotasi energi surya.',
      rarity: BorderRarity.epic,
      pricePoints: 1850,
      isAnimated: true,
      category: 'Kosmik',
      styleData: {
        'primaryColor': 0xFFFFD600,
        'secondaryColor': 0xFFFF6D00,
        'borderWidth': 4.5,
        'styleType': 'solar_corona',
      },
    ),

    // ── LEGENDARY (2500 - 4000 Poin, Tingkat Tertinggi, On-Chain Verified) ──
    const RewardBorder(
      id: 'border_celestial_diamond',
      name: 'Intan Surgawi',
      description: 'Kristal berlian prismatik dengan pantulan pelangi berputar abadi.',
      rarity: BorderRarity.legendary,
      pricePoints: 2500,
      isAnimated: true,
      category: 'Permata',
      styleData: {
        'primaryColor': 0xFF00E5FF,
        'secondaryColor': 0xFFFF80AB,
        'borderWidth': 5.0,
        'styleType': 'prismatic_diamond',
      },
    ),
    const RewardBorder(
      id: 'border_blockchain_genesis',
      name: 'Genesis Node EVM',
      description: 'Rantai blok heksagonal kriptografis terhubung langsung ke Sepolia.',
      rarity: BorderRarity.legendary,
      pricePoints: 3000,
      isAnimated: true,
      category: 'Blockchain',
      styleData: {
        'primaryColor': 0xFF627EEA, // Ethereum blue
        'secondaryColor': 0xFF00E5FF,
        'borderWidth': 5.0,
        'styleType': 'blockchain_chain',
      },
    ),
    const RewardBorder(
      id: 'border_mythic_phoenix',
      name: 'Kencana Ananta',
      description: 'Aura burung phoenix emas legendaris melambangkan keagungan kurator utama.',
      rarity: BorderRarity.legendary,
      pricePoints: 4000,
      isAnimated: true,
      category: 'Mitos',
      styleData: {
        'primaryColor': 0xFFFFAB00,
        'secondaryColor': 0xFFFF1744,
        'borderWidth': 5.5,
        'styleType': 'phoenix_aura',
      },
    ),
  ];
}
