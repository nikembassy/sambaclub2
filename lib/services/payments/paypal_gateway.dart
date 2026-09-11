import 'payment_gateway.dart';

/// PayPal coins provider — STUB, intentionally disabled.
///
/// No real money can move: [purchaseCoinPack] always returns
/// [PurchaseResult.notAvailable]. Wiring it up requires an external PayPal SDK
/// plus a backend that creates and captures orders.
///
/// TODO(payments): choose a client SDK (e.g. `flutter_paypal_checkout`) and add
///   it to pubspec.yaml together with the sandbox client-id.
/// TODO(payments): create the order on the backend
///   (POST /v2/checkout/orders) and only open the PayPal sheet with that id —
///   never build the amount on the client.
/// TODO(payments): capture the order server-side
///   (POST /v2/checkout/orders/{id}/capture) and credit the coins through the
///   backend wallet API instead of trusting a client-side success callback.
/// TODO(payments): validate the PayPal webhook (PAYMENT.CAPTURE.COMPLETED)
///   before crediting, and store the order id for refunds/audit.
class PayPalGateway implements PaymentGateway {
  const PayPalGateway();

  @override
  String get name => 'PayPal';

  @override
  Future<PurchaseResult> purchaseCoinPack(CoinPack pack) async {
    // TODO(payments): replace this stub with the real checkout flow.
    return PurchaseResult.notAvailable('Presto disponibile');
  }
}
