class PointTransaction {
  final String id;
  final String userId;
  final int amount;
  final String transactionType; // 'game_reward', 'border_purchase', 'checkin', 'refund'
  final String? referenceId;
  final String idempotencyKey;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const PointTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.transactionType,
    this.referenceId,
    required this.idempotencyKey,
    required this.metadata,
    required this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      transactionType: json['transaction_type']?.toString() ?? 'unknown',
      referenceId: json['reference_id']?.toString(),
      idempotencyKey: json['idempotency_key']?.toString() ?? '',
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'transaction_type': transactionType,
        'reference_id': referenceId,
        'idempotency_key': idempotencyKey,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
      };

  String get readableTitle => switch (transactionType) {
        'border_purchase' => 'Pembelian ${metadata['border_name'] ?? 'Border Profil'}',
        'game_reward' => 'Hadiah ${metadata['game_name'] ?? 'Mini Game'}',
        'checkin' => 'Bonus Check-in Kuliner',
        'refund' => 'Pengembalian Poin Rasa',
        _ => 'Aktivitas Poin Rasa',
      };

  bool get isCredit => amount > 0;
}
