import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/food.dart';
import '../models/restaurant.dart';
import '../props/app_colors.dart';
import '../props/app_text.dart';
import '../utils/format.dart';
import '../widgets/auth_widgets.dart';

class _Person {
  _Person(this.id, this.name);
  final int id;
  String name;
}

class _Item {
  _Item({
    required this.id,
    required this.name,
    required this.price,
    this.foodId,
  }) : qty = 1;

  final int id;
  final String? foodId;
  String name;
  int price;
  int qty;

  /// Siapa saja yang ikut menanggung item ini. Kosong = semua orang.
  final Set<int> who = {};

  int get total => price * qty;
}

class _Row {
  _Row(this.person, this.items, this.discount, this.total);
  final _Person person;
  final int items;
  final int discount;
  int total;
}

class _Calc {
  _Calc(
    this.rows,
    this.subtotal,
    this.discount,
    this.service,
    this.tax,
    this.total,
  );
  final List<_Row> rows;
  final int subtotal;
  final int discount;
  final int service;
  final int tax;
  final int total;
}

/// Hitung patungan: pilih pesanan dari menu (atau ketik manual), tambah
/// orang, lalu bagi rata atau per item. Pajak, service, dan diskon dibagi
/// proporsional sesuai porsi tiap orang.
class SplitBillPage extends StatefulWidget {
  const SplitBillPage({
    super.key,
    required this.restaurant,
    this.menu = const [],
  });

  final Restaurant restaurant;
  final List<Food> menu;

  @override
  State<SplitBillPage> createState() => _SplitBillPageState();
}

class _SplitBillPageState extends State<SplitBillPage> {
  int _nextId = 1;
  late final List<_Person> _people = [
    _Person(_nextId++, 'Aku'),
    _Person(_nextId++, 'Teman 1'),
  ];
  final List<_Item> _items = [];

  bool _perItem = true;
  double _taxPct = 10;
  double _svcPct = 0;
  int _discount = 0;

  final _taxCtl = TextEditingController(text: '10');
  final _svcCtl = TextEditingController(text: '0');
  final _discCtl = TextEditingController(text: '0');

  @override
  void dispose() {
    _taxCtl.dispose();
    _svcCtl.dispose();
    _discCtl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Perhitungan
  // ------------------------------------------------------------------

  _Calc _calc() {
    final n = _people.length;
    final ids = _people.map((p) => p.id).toList();
    final sub = <int, double>{for (final id in ids) id: 0};
    var subtotal = 0.0;

    for (final it in _items) {
      final t = it.total.toDouble();
      subtotal += t;
      if (!_perItem) continue;
      var targets = it.who.isEmpty
          ? ids
          : ids.where((id) => it.who.contains(id)).toList();
      if (targets.isEmpty) targets = ids;
      for (final id in targets) {
        sub[id] = sub[id]! + t / targets.length;
      }
    }
    if (!_perItem) {
      for (final id in ids) {
        sub[id] = subtotal / n;
      }
    }

    final disc = _discount > subtotal ? subtotal : _discount.toDouble();
    final after = subtotal - disc;
    final service = after * _svcPct / 100;
    final tax = (after + service) * _taxPct / 100;
    final grand = after + service + tax;

    final totals = <double>[];
    final shares = <double>[];
    for (final p in _people) {
      final share = subtotal == 0 ? 0.0 : sub[p.id]! / subtotal;
      shares.add(share);
      totals.add(sub[p.id]! - disc * share + service * share + tax * share);
    }

    // Pembulatan: jumlah semua orang harus sama persis dengan total.
    final rounded = totals.map((e) => e.round()).toList();
    final diff = grand.round() - rounded.fold<int>(0, (a, b) => a + b);
    if (rounded.isNotEmpty) rounded[0] += diff;

    final rows = <_Row>[
      for (var i = 0; i < _people.length; i++)
        _Row(
          _people[i],
          sub[_people[i].id]!.round(),
          (disc * shares[i]).round(),
          rounded[i],
        ),
    ];

    return _Calc(
      rows,
      subtotal.round(),
      disc.round(),
      service.round(),
      tax.round(),
      grand.round(),
    );
  }

  // ------------------------------------------------------------------
  // Aksi
  // ------------------------------------------------------------------

  Future<String?> _askText(
    String title, {
    String hint = '',
    String initial = '',
  }) {
    final ctl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: AppText.display(17)),
        content: TextField(
          controller: ctl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPerson() async {
    final name = await _askText(
      'Tambah orang',
      hint: 'Nama, mis. Rina',
      initial: 'Teman ${_people.length}',
    );
    if (name == null || name.isEmpty) return;
    setState(() => _people.add(_Person(_nextId++, name)));
  }

  Future<void> _renamePerson(_Person p) async {
    final name = await _askText('Ubah nama', initial: p.name);
    if (name == null || name.isEmpty) return;
    setState(() => p.name = name);
  }

  void _removePerson(_Person p) {
    if (_people.length <= 1) return;
    setState(() {
      _people.removeWhere((e) => e.id == p.id);
      for (final it in _items) {
        it.who.remove(p.id);
        if (it.who.length >= _people.length) it.who.clear();
      }
    });
  }

  Future<void> _addManualItem() async {
    final nameCtl = TextEditingController();
    final priceCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tambah pesanan', style: AppText.display(17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Nama menu'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'Harga satuan',
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    final name = nameCtl.text.trim();
    final price = int.tryParse(priceCtl.text.trim()) ?? 0;
    if (ok != true || name.isEmpty || price <= 0) return;
    setState(() => _items.add(_Item(id: _nextId++, name: name, price: price)));
  }

  int _qtyOf(Food f) {
    for (final it in _items) {
      if (it.foodId == f.id) return it.qty;
    }
    return 0;
  }

  void _changeQty(Food f, int delta) {
    final idx = _items.indexWhere((it) => it.foodId == f.id);
    setState(() {
      if (idx == -1) {
        if (delta > 0) {
          _items.add(
            _Item(id: _nextId++, foodId: f.id, name: f.name, price: f.price),
          );
        }
        return;
      }
      final next = _items[idx].qty + delta;
      if (next <= 0) {
        _items.removeAt(idx);
      } else {
        _items[idx].qty = next;
      }
    });
  }

  void _toggleWho(_Item it, _Person p) {
    setState(() {
      if (it.who.isEmpty) {
        it.who
          ..addAll(_people.map((e) => e.id))
          ..remove(p.id);
        if (it.who.length >= _people.length) it.who.clear();
      } else if (it.who.contains(p.id)) {
        if (it.who.length > 1) it.who.remove(p.id);
      } else {
        it.who.add(p.id);
        if (it.who.length == _people.length) it.who.clear();
      }
    });
  }

  void _openMenuPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pilih dari menu',
                          style: AppText.display(18),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Selesai'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: widget.menu.length,
                    itemBuilder: (_, i) {
                      final f = widget.menu[i];
                      final q = _qtyOf(f);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    f.priceLabel,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.greenDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _stepper(
                              q,
                              onMinus: () {
                                _changeQty(f, -1);
                                setSheet(() {});
                              },
                              onPlus: () {
                                _changeQty(f, 1);
                                setSheet(() {});
                              },
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
      ),
    );
  }

  void _reset() {
    setState(() {
      _items.clear();
      _people
        ..clear()
        ..addAll([_Person(_nextId++, 'Aku'), _Person(_nextId++, 'Teman 1')]);
      _perItem = true;
      _taxPct = 10;
      _svcPct = 0;
      _discount = 0;
      _taxCtl.text = '10';
      _svcCtl.text = '0';
      _discCtl.text = '0';
    });
  }

  String _summary(_Calc c) {
    final b = StringBuffer()
      ..writeln('Split Bill - ${widget.restaurant.name}')
      ..writeln(_perItem ? 'Cara: per item' : 'Cara: bagi rata')
      ..writeln();
    for (final it in _items) {
      b.writeln('${it.qty}x ${it.name}  ${formatRp(it.total)}');
    }
    b
      ..writeln()
      ..writeln('Subtotal ${formatRp(c.subtotal)}');
    if (c.discount > 0) b.writeln('Diskon -${formatRp(c.discount)}');
    if (c.service > 0) b.writeln('Service ${formatRp(c.service)}');
    if (c.tax > 0) b.writeln('Pajak ${formatRp(c.tax)}');
    b
      ..writeln('Total ${formatRp(c.total)}')
      ..writeln()
      ..writeln('Per orang:');
    for (final r in c.rows) {
      b.writeln('- ${r.person.name}: ${formatRp(r.total)}');
    }
    return b.toString().trimRight();
  }

  Future<void> _copy(_Calc c) async {
    await Clipboard.setData(ClipboardData(text: _summary(c)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ringkasan disalin. Tinggal tempel ke chat!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = _calc();
    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _peopleCard(),
                    const SizedBox(height: 14),
                    _modeToggle(),
                    const SizedBox(height: 14),
                    _itemsCard(),
                    const SizedBox(height: 14),
                    _extrasCard(),
                    const SizedBox(height: 14),
                    _resultCard(c),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Split Bill', style: AppText.display(20)),
                Text(
                  widget.restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: _reset, child: const Text('Reset')),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.charcoal),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppText.display(15))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ---- Orang ----
  Widget _peopleCard() {
    return _card(
      title: 'Siapa saja? (${_people.length})',
      icon: Icons.groups_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in _people)
            GestureDetector(
              onTap: () => _renamePerson(p),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.yellow, 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.tint(AppColors.orange, 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _people.length > 1 ? () => _removePerson(p) : null,
                      child: Icon(
                        Icons.close,
                        size: 15,
                        color: _people.length > 1
                            ? AppColors.greenDark
                            : AppColors.line,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          GestureDetector(
            onTap: _addPerson,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.greenDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 15, color: AppColors.yellow),
                  SizedBox(width: 4),
                  Text(
                    'Tambah',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.yellow,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Mode ----
  Widget _modeToggle() {
    Widget btn(String label, IconData icon, bool active, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 42,
            decoration: BoxDecoration(
              color: active ? AppColors.greenDark : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active ? AppColors.yellow : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
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
          btn(
            'Per item',
            Icons.receipt_long_rounded,
            _perItem,
            () => setState(() => _perItem = true),
          ),
          btn(
            'Bagi rata',
            Icons.balance_rounded,
            !_perItem,
            () => setState(() => _perItem = false),
          ),
        ],
      ),
    );
  }

  // ---- Pesanan ----
  Widget _stepper(
    int value, {
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    Widget b(IconData icon, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.tint(AppColors.orange, 0.2),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: AppColors.red),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        b(Icons.remove, onMinus),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        b(Icons.add, onPlus),
      ],
    );
  }

  Widget _itemsCard() {
    return _card(
      title: 'Pesanan',
      icon: Icons.restaurant_menu_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.menu.isNotEmpty)
            TextButton(
              onPressed: _openMenuPicker,
              child: const Text('Dari menu'),
            ),
          TextButton(onPressed: _addManualItem, child: const Text('Manual')),
        ],
      ),
      child: _items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Belum ada pesanan. Tambahkan dari menu atau ketik manual.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          : Column(children: _items.map(_itemTile).toList()),
    );
  }

  Widget _itemTile(_Item it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  it.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _items.remove(it)),
                child: const Icon(
                  Icons.delete_outline,
                  size: 19,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatRp(it.price)} × ${it.qty} = ${formatRp(it.total)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
              _stepper(
                it.qty,
                onMinus: () => setState(() {
                  if (it.qty > 1) {
                    it.qty--;
                  } else {
                    _items.remove(it);
                  }
                }),
                onPlus: () => setState(() => it.qty++),
              ),
            ],
          ),
          if (_perItem) ...[
            const SizedBox(height: 10),
            const Text(
              'DITANGGUNG OLEH',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in _people)
                  _whoChip(
                    p.name,
                    it.who.isEmpty || it.who.contains(p.id),
                    () => _toggleWho(it, p),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _whoChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.greenDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.greenDark : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.yellow : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // ---- Biaya tambahan ----
  Widget _extrasCard() {
    Widget field(
      String label,
      TextEditingController ctl,
      String suffix,
      ValueChanged<String> onChanged, {
      bool decimal = false,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: ctl,
              onChanged: onChanged,
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(decimal ? r'[0-9.,]' : r'[0-9]'),
                ),
              ],
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                suffixText: suffix,
                prefixText: suffix.isEmpty ? 'Rp ' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
          ],
        ),
      );
    }

    double pct(String v) {
      final d = double.tryParse(v.replaceAll(',', '.')) ?? 0;
      return d.clamp(0, 100).toDouble();
    }

    return _card(
      title: 'Biaya tambahan',
      icon: Icons.percent_rounded,
      child: Row(
        children: [
          field(
            'Pajak',
            _taxCtl,
            '%',
            (v) => setState(() => _taxPct = pct(v)),
            decimal: true,
          ),
          const SizedBox(width: 10),
          field(
            'Service',
            _svcCtl,
            '%',
            (v) => setState(() => _svcPct = pct(v)),
            decimal: true,
          ),
          const SizedBox(width: 10),
          field(
            'Diskon',
            _discCtl,
            '',
            (v) => setState(() => _discount = int.tryParse(v) ?? 0),
          ),
        ],
      ),
    );
  }

  // ---- Hasil ----
  Widget _resultCard(_Calc c) {
    Widget line(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 13 : 12,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: Colors.white.withValues(alpha: bold ? 1 : 0.75),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.yellow : Colors.white,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hasil', style: AppText.display(18)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              line('Subtotal', formatRp(c.subtotal)),
              if (c.discount > 0) line('Diskon', '-${formatRp(c.discount)}'),
              if (c.service > 0) line('Service', formatRp(c.service)),
              if (c.tax > 0) line('Pajak', formatRp(c.tax)),
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 18),
              line('Total tagihan', formatRp(c.total), bold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final r in c.rows) _personResult(r),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: c.total > 0 ? () => _copy(c) : null,
          child: Opacity(
            opacity: c.total > 0 ? 1 : 0.5,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 17, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Salin ringkasan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

  Widget _personResult(_Row r) {
    final extra = r.total - r.items + r.discount;
    final initial = r.person.name.isEmpty
        ? '?'
        : r.person.name[0].toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.greenDark,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.yellow,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.person.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pesanan ${formatRp(r.items)}'
                  '${extra != 0 ? ' · pajak/service ${formatRp(extra)}' : ''}'
                  '${r.discount > 0 ? ' · diskon -${formatRp(r.discount)}' : ''}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRp(r.total),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}
