/// Grants coins without any payment.
///
/// Phase-1 policy: ALL coins in Sambaclub are free — there is no real purchase
/// path yet, so gifting is never gated behind a payment. [FreeCoinService]
/// provides the starting balance and the free daily allowance.
class FreeCoinService {
  const FreeCoinService();

  /// Coins granted on the first login.
  int get startingCoins => 500;

  /// Free coins claimable once per day.
  int get dailyFreeCoins => 200;
}
