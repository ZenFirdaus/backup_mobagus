class BlockchainTransaction {
  final String id;
  final String userId;
  final String? redemptionId;
  final String borderId;
  final int chainId; // e.g. 11155111 for Sepolia Testnet
  final String contractAddress;
  final String txHash;
  final int? blockNumber;
  final String status; // 'pending', 'confirmed', 'failed'
  final String explorerUrl;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  const BlockchainTransaction({
    required this.id,
    required this.userId,
    this.redemptionId,
    required this.borderId,
    required this.chainId,
    required this.contractAddress,
    required this.txHash,
    this.blockNumber,
    required this.status,
    required this.explorerUrl,
    required this.metadata,
    required this.createdAt,
    this.confirmedAt,
  });

  factory BlockchainTransaction.fromJson(Map<String, dynamic> json) {
    return BlockchainTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      redemptionId: json['redemption_id']?.toString(),
      borderId: json['border_id']?.toString() ?? '',
      chainId: (json['chain_id'] as num?)?.toInt() ?? 11155111,
      contractAddress: json['contract_address']?.toString() ?? '',
      txHash: json['tx_hash']?.toString() ?? '',
      blockNumber: (json['block_number'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'pending',
      explorerUrl: json['explorer_url']?.toString() ??
          (json['tx_hash'] != null
              ? 'https://sepolia.etherscan.io/tx/${json['tx_hash']}'
              : ''),
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'redemption_id': redemptionId,
        'border_id': borderId,
        'chain_id': chainId,
        'contract_address': contractAddress,
        'tx_hash': txHash,
        'block_number': blockNumber,
        'status': status,
        'explorer_url': explorerUrl,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'confirmed_at': confirmedAt?.toIso8601String(),
      };

  bool get isConfirmed => status == 'confirmed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  String get shortTxHash {
    if (txHash.length <= 14) return txHash;
    return '${txHash.substring(0, 8)}...${txHash.substring(txHash.length - 6)}';
  }
}
