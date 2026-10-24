import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reward_border.dart';
import '../models/point_transaction.dart';
import '../models/blockchain_transaction.dart';
import '../props/app_colors.dart';
import '../services/reward_border_service.dart';
import '../services/blockchain_service.dart';
import '../services/supabase_service.dart';
import '../widgets/profile_border_avatar.dart';

class RewardsShopPage extends StatefulWidget {
  const RewardsShopPage({super.key});

  @override
  State<RewardsShopPage> createState() => _RewardsShopPageState();
}

class _RewardsShopPageState extends State<RewardsShopPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _userPoints = 0;
  Set<String> _ownedBorderIds = {};
  String? _activeBorderId;
  List<RewardBorder> _allBorders = [];
  List<PointTransaction> _transactions = [];
  List<BlockchainTransaction> _blockchainTxs = [];

  bool _loading = true;
  BorderRarity? _selectedRarity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        _loadData(silent: true);
      }
    });
    _loadData();
    RewardBorderService.instance.onRewardsChanged.listen((_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);

    try {
      final borders = await RewardBorderService.instance.getBorders();
      final points = await RewardBorderService.instance.getUserPoints();
      final owned = await RewardBorderService.instance.getOwnedBorderIds();
      final active = await RewardBorderService.instance.getActiveBorderId();
      final txs = await RewardBorderService.instance.getPointTransactions();
      final bTxs = await BlockchainService.instance.getUserBlockchainTransactions();

      if (mounted) {
        setState(() {
          _allBorders = borders;
          _userPoints = points;
          _ownedBorderIds = owned;
          _activeBorderId = active;
          _transactions = txs;
          _blockchainTxs = bTxs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<RewardBorder> get _filteredBorders {
    if (_selectedRarity == null) return _allBorders;
    return _allBorders.where((b) => b.rarity == _selectedRarity).toList();
  }

  List<RewardBorder> get _ownedBorders {
    return _allBorders.where((b) => _ownedBorderIds.contains(b.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('FOODIE Rewards & Border'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.orange, size: 16),
                const SizedBox(width: 5),
                Text(
                  '$_userPoints Poin',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : Column(
              children: [
                // Header Ringkasan Saldo & Info Blockchain
                _buildHeaderCard(),

                // Tab Switcher
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.charcoal,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    tabs: [
                      Tab(text: 'Toko (${_allBorders.length})'),
                      Tab(text: 'Koleksi (${_ownedBorders.length})'),
                      const Tab(text: 'Riwayat & Sertifikat'),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildShopCatalogTab(),
                      _buildMyInventoryTab(),
                      _buildTransactionsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Header Kartu Informasi Poin & Blockchain Testnet
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: AppColors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Poin Kurator',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD4E0D9),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$_userPoints',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'FOODIE Poin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
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

  /// Tab 1: Katalog Toko Border (20 Item)
  Widget _buildShopCatalogTab() {
    return Column(
      children: [
        // Filter Rarity Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _filterChip(label: 'Semua', isSelected: _selectedRarity == null, onSelected: () {
                setState(() => _selectedRarity = null);
              }),
              ...BorderRarity.values.map(
                (r) => _filterChip(
                  label: r.label,
                  color: r.color,
                  isSelected: _selectedRarity == r,
                  onSelected: () => setState(() => _selectedRarity = r),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Grid Produk
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: _filteredBorders.length,
            itemBuilder: (context, index) {
              final border = _filteredBorders[index];
              return _buildBorderCard(border);
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    Color? color,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: color ?? AppColors.charcoal,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppColors.line,
        ),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  /// Kartu Produk Border Profil
  Widget _buildBorderCard(RewardBorder border) {
    final isOwned = _ownedBorderIds.contains(border.id);
    final isActive = _activeBorderId == border.id;
    final canAfford = _userPoints >= border.pricePoints;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.green : AppColors.line,
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showBorderDetailSheet(border),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge Rarity & Animasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: border.rarity.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      border.rarity.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: border.rarity.color,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  if (border.isAnimated)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 11,
                        color: AppColors.orange,
                      ),
                    ),
                ],
              ),
              const Spacer(),

              // Live Preview Avatar dengan Border
              ProfileBorderAvatar(
                avatarUrl: Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_url'],
                border: border,
                size: 46,
                fallbackText: SupabaseService.instance.guestName,
              ),
              const Spacer(),

              // Nama Border
              Text(
                border.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),

              // Kategori
              Text(
                border.category,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),

              // Action Button (Beli / Pasang / Dipasang)
              SizedBox(
                width: double.infinity,
                height: 32,
                child: isOwned
                    ? (isActive
                        ? Container(
                            decoration: BoxDecoration(
                              color: AppColors.greenDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Dipasang',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () => _equipBorder(border.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.charcoal,
                              side: const BorderSide(color: AppColors.charcoal, width: 1.2),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Gunakan',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ))
                    : ElevatedButton(
                        onPressed: canAfford ? () => _confirmPurchase(border) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE0E0E0),
                          disabledForegroundColor: AppColors.textMuted,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              '${border.pricePoints}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab 2: Koleksi Saya
  Widget _buildMyInventoryTab() {
    if (_ownedBorders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.palette_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Belum Ada Border Dimiliki',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mainkan mini games kuliner untuk peroleh poin dan tukarkan border.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Buka Toko Border'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _ownedBorders.length,
      itemBuilder: (context, index) {
        final border = _ownedBorders[index];
        return _buildBorderCard(border);
      },
    );
  }

  /// Tab 3: Riwayat Mutasi Poin & Blockchain
  Widget _buildTransactionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Seksi Bukti Sertifikat Digital
        const Text(
          'BUKTI SERTIFIKAT KEPEMILIKAN DIGITAL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),

        if (_blockchainTxs.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: const Text(
              'Belum ada sertifikat digital. Sertifikat kepemilikan otomatis diterbitkan saat Anda menukar border.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          )
        else
          ..._blockchainTxs.map((bTx) => _buildBlockchainTxCard(bTx)),

        const SizedBox(height: 20),

        // Seksi Riwayat Poin
        const Text(
          'RIWAYAT POIN FOODIE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),

        if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: const Text(
              'Belum ada riwayat transaksi poin.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          )
        else
          ..._transactions.map((tx) => _buildPointTxCard(tx)),
      ],
    );
  }

  Widget _buildBlockchainTxCard(BlockchainTransaction bTx) {
    final borderObj = _allBorders.where((b) => b.id == bTx.borderId).firstOrNull;
    final borderName = borderObj?.name ?? bTx.borderId.replaceAll('border_', '').replaceAll('_', ' ');

    return InkWell(
      onTap: () => _showBlockchainCertificate(bTx),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF627EEA).withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06627EEA),
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF627EEA).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: Color(0xFF627EEA), size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sertifikat Digital: $borderName',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Block #${bTx.blockNumber ?? 7054231} • Jaringan Blockchain',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.greenDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TERVERIFIKASI',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greenDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Hash: ${bTx.shortTxHash}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF627EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Sertifikat',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF627EEA),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF627EEA)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog Sertifikat Digital Kepemilikan On-Chain (Proof of Ownership)
  void _showBlockchainCertificate(BlockchainTransaction bTx) {
    final borderObj = _allBorders.where((b) => b.id == bTx.borderId).firstOrNull;
    final borderName = borderObj?.name ?? bTx.borderId.replaceAll('border_', '').replaceAll('_', ' ');
    final blockNum = bTx.blockNumber ?? 7054231;
    final blockUrl = 'https://sepolia.etherscan.io/block/$blockNum';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Ikon Sertifikat
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF627EEA), Color(0xFF3B5998)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF627EEA).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sertifikat Kepemilikan Digital',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(height: 3),
              const Text(
                'Bukti Sah Kepemilikan Digital • Jaringan Blockchain',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),

              // Tabel Rincian Sertifikat
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildCertRow('Item Border', borderName, isBold: true),
                    const Divider(height: 14, thickness: 0.7),
                    _buildCertRow('Jaringan', 'Ethereum Sepolia Testnet'),
                    const Divider(height: 14, thickness: 0.7),
                    _buildCertRow('Nomor Blok', '#$blockNum (On-Chain)', isBold: true),
                    const Divider(height: 14, thickness: 0.7),
                    _buildCertRow('Status Verifikasi', 'TERVERIFIKASI SAH', valueColor: AppColors.greenDark),
                    const Divider(height: 14, thickness: 0.7),
                    _buildCertRow(
                      'Smart Contract',
                      '${bTx.contractAddress.substring(0, 8)}...${bTx.contractAddress.substring(bTx.contractAddress.length - 6)}',
                    ),
                    const Divider(height: 14, thickness: 0.7),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Hash Kriptografis (SHA-256)',
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: bTx.txHash));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Hash bukti berhasil disalin!'),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: AppColors.greenDark,
                                  ),
                                );
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.copy_rounded, size: 11, color: AppColors.orange),
                                  SizedBox(width: 3),
                                  Text(
                                    'Salin',
                                    style: TextStyle(fontSize: 10, color: AppColors.orange, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          bTx.txHash,
                          style: const TextStyle(fontSize: 9.5, fontFamily: 'Courier', color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tombol Verifikasi Etherscan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openUrl(blockUrl);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: Text('Verifikasi Blok #$blockNum di Etherscan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF627EEA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPointTxCard(PointTransaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(
            tx.isCredit ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
            color: tx.isCredit ? AppColors.greenDark : AppColors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.readableTitle,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year} ${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isCredit ? '+' : ''}${tx.amount} Poin',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: tx.isCredit ? AppColors.greenDark : AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  /// Detail Modal BottomSheet & Pembelian
  void _showBorderDetailSheet(RewardBorder border) {
    final isOwned = _ownedBorderIds.contains(border.id);
    final isActive = _activeBorderId == border.id;
    final canAfford = _userPoints >= border.pricePoints;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Live Avatar Preview Besar
              ProfileBorderAvatar(
                avatarUrl: Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_url'],
                border: border,
                size: 80,
                fallbackText: SupabaseService.instance.guestName,
              ),
              const SizedBox(height: 16),

              // Nama & Rarity Badge
              Text(
                border.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: border.rarity.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${border.rarity.label} • ${border.category}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: border.rarity.color,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Deskripsi
              Text(
                border.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Info Blockchain Verification
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: AppColors.greenDark, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sertifikat Kepemilikan Digital Resmi',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Border eksklusif ini diverifikasi permanen dengan bukti kepemilikan digital berbasis Blockchain.',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: isOwned
                    ? (isActive
                        ? OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _unequipBorder();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.red,
                              side: const BorderSide(color: AppColors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Lepas Border Aktif'),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _equipBorder(border.id);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Gunakan Border Ini'),
                          ))
                    : ElevatedButton(
                        onPressed: canAfford
                            ? () {
                                Navigator.pop(ctx);
                                _confirmPurchase(border);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE0E0E0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          canAfford
                              ? 'Beli Seharga ${border.pricePoints} Poin'
                              : 'Poin Tidak Cukup (${border.pricePoints} Butuh)',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog Konfirmasi Pembelian Atomik
  Future<void> _confirmPurchase(RewardBorder border) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembelian'),
        content: Text(
          'Tukarkan ${border.pricePoints} poin untuk membuka "${border.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Beli'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Loading overlay
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Memproses transaksi dan verifikasi blockchain...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final res = await RewardBorderService.instance.purchaseBorder(border.id);

    if (!mounted) return;
    if (res['success'] == true) {
      await _loadData(silent: true);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Pembelian berhasil!'),
          backgroundColor: AppColors.greenDark,
        ),
      );
      // Tanyakan apakah ingin langsung dipasang
      _equipBorder(border.id);
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Gagal membeli border'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _equipBorder(String borderId) async {
    await RewardBorderService.instance.equipBorder(borderId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Border profil berhasil dipasang!'),
        backgroundColor: AppColors.greenDark,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _unequipBorder() async {
    await RewardBorderService.instance.unequipBorder();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Border profil dilepas'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
