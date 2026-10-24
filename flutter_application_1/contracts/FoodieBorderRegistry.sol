// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FoodieBorderRegistry
 * @dev Smart Contract pencatatan bukti kepemilikan Border Profil FOODIE pada Ethereum Sepolia Testnet.
 * Transaksi dicatat secara on-chain dan diverifikasi via blockchain explorer (Etherscan).
 */
contract FoodieBorderRegistry {
    // Nama & Simbol Registry
    string public constant name = "FOODIE Profile Border Registry";
    string public constant symbol = "FBR";

    // Alamat Backend / Oracle yang diizinkan memvalidasi minting
    address public owner;

    // Struktur Bukti Kepemilikan On-Chain
    struct BorderProof {
        address buyer;
        string borderId;
        uint256 pointsSpent;
        uint256 timestamp;
        uint256 blockNumber;
        string idempotencyKey;
    }

    // Mapping: buyer => borderId => isOwned
    mapping(address => mapping(string => bool)) private _ownership;

    // Mapping: idempotencyKeyHash => sudah diproses
    mapping(bytes32 => bool) private _processedKeys;

    // Daftar semua riwayat bukti pembelian
    BorderProof[] public allProofs;

    // Event on-chain yang dapat diinspeksi di Etherscan Sepolia
    event BorderPurchased(
        address indexed buyer,
        string indexed borderId,
        uint256 pointsSpent,
        uint256 timestamp,
        string idempotencyKey,
        uint256 proofIndex
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Hanya operator FOODIE yang dapat mencatat bukti");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Mencatat bukti pembelian border secara atomik dan idempoten pada blockchain Sepolia.
     */
    function recordBorderPurchase(
        address buyer,
        string memory borderId,
        uint256 pointsSpent,
        string memory idempotencyKey
    ) external onlyOwner returns (uint256 proofIndex) {
        require(buyer != address(0), "Alamat pembeli tidak valid");
        require(bytes(borderId).length > 0, "ID border tidak boleh kosong");

        bytes32 keyHash = keccak256(abi.encodePacked(idempotencyKey));
        require(!_processedKeys[keyHash], "Idempotency key sudah pernah diproses di blockchain");

        _processedKeys[keyHash] = true;
        _ownership[buyer][borderId] = true;

        proofIndex = allProofs.length;
        allProofs.push(
            BorderProof({
                buyer: buyer,
                borderId: borderId,
                pointsSpent: pointsSpent,
                timestamp: block.timestamp,
                blockNumber: block.number,
                idempotencyKey: idempotencyKey
            })
        );

        emit BorderPurchased(
            buyer,
            borderId,
            pointsSpent,
            block.timestamp,
            idempotencyKey,
            proofIndex
        );

        return proofIndex;
    }

    /**
     * @dev Verifikasi apakah alamat tertentu memiliki border secara on-chain.
     */
    function verifyBorderOwnership(address buyer, string memory borderId)
        external
        view
        returns (bool)
    {
        return _ownership[buyer][borderId];
    }

    /**
     * @dev Mengambil total bukti border yang telah tercatat on-chain.
     */
    function totalRecordedProofs() external view returns (uint256) {
        return allProofs.length;
    }

    /**
     * @dev Memindahkan kepemilikan contract jika diperlukan.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner baru tidak valid");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
