import 'payment_gateway.dart';

/// Coin packs shown on the recharge screen.
///
/// The EUR labels are display-only placeholders; the app does not charge
/// anything in this phase (see [FreeCoinService]).
const List<CoinPack> kCoinPacks = <CoinPack>[
  CoinPack(id: 'pack_100', coins: 100, priceLabel: '€ 0,99'),
  CoinPack(id: 'pack_500', coins: 500, priceLabel: '€ 4,99', bonusCoins: 50),
  CoinPack(id: 'pack_1200', coins: 1200, priceLabel: '€ 9,99', bonusCoins: 150),
  CoinPack(id: 'pack_3000', coins: 3000, priceLabel: '€ 19,99', bonusCoins: 600),
];
