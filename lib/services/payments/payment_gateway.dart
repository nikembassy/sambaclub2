/// A purchasable bundle of coins.
class CoinPack {
  const CoinPack({
    required this.id,
    required this.coins,
    required this.priceLabel,
    this.bonusCoins = 0,
  });

  final String id;
  final int coins;
  final String priceLabel;
  final int bonusCoins;

  int get totalCoins => coins + bonusCoins;
}

/// Result of a purchase attempt.
class PurchaseResult {
  const PurchaseResult._({
    required this.success,
    this.reason,
    this.transactionId,
  });

  /// Successful purchase.
  factory PurchaseResult.ok({String? transactionId}) => PurchaseResult._(
        success: true,
        transactionId: transactionId,
      );

  /// The gateway is not wired up yet (or the store is unavailable).
  factory PurchaseResult.notAvailable(String reason) => PurchaseResult._(
        success: false,
        reason: reason,
      );

  final bool success;
  final String? reason;
  final String? transactionId;

  bool get isOk => success;
}

/// Contract every coin payment provider must implement.
///
/// Both shipped implementations ([PayPalGateway], [GooglePlayGateway]) are
/// intentional stubs returning [PurchaseResult.notAvailable] — no real money
/// can move in this build.
abstract class PaymentGateway {
  const PaymentGateway();

  /// Human-readable provider name, e.g. "PayPal".
  String get name;

  /// Attempts to buy [pack]. Never throws for the stub providers.
  Future<PurchaseResult> purchaseCoinPack(CoinPack pack);
}
