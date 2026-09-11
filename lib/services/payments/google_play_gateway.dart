import 'payment_gateway.dart';

/// Google Play Billing coins provider — STUB, intentionally disabled.
///
/// No real money can move: [purchaseCoinPack] always returns
/// [PurchaseResult.notAvailable]. Wiring it up requires the `in_app_purchase`
/// plugin, Play Console products and server-side purchase verification.
///
/// TODO(payments): add `in_app_purchase` to pubspec.yaml and initialise
///   [InAppPurchase.instance] inside the app (see the plugin docs).
/// TODO(payments): create the consumable coin SKUs in the Google Play Console
///   (e.g. `sambaclub_coins_100`, `..._500`, `..._1200`, `..._3000`) and map
///   each [CoinPack.id] to its SKU.
/// TODO(payments): verify the purchase server-side via the Play Developer API
///   (purchases.products.get) and then consume/acknowledge it — only credit
///   coins after verification.
/// TODO(payments): handle `purchaseStream`, pending purchases, refunds and
///   consumption errors before enabling any buy button.
class GooglePlayGateway implements PaymentGateway {
  const GooglePlayGateway();

  @override
  String get name => 'Google Play';

  @override
  Future<PurchaseResult> purchaseCoinPack(CoinPack pack) async {
    // TODO(payments): replace this stub with the in_app_purchase flow.
    return PurchaseResult.notAvailable('Presto disponibile');
  }
}
