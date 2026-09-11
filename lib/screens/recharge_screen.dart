import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/payments/coin_packs.dart';
import '../services/payments/google_play_gateway.dart';
import '../services/payments/payment_gateway.dart';
import '../services/payments/paypal_gateway.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Coin packs screen.
///
/// IMPORTANT: every coin is FREE in this phase. The PayPal and Google Play
/// buttons are deliberately disabled and show "Presto disponibile"; they use
/// the [PaymentGateway] stubs ([PayPalGateway], [GooglePlayGateway]) that
/// always return [PurchaseResult.notAvailable]. No real purchase can happen.
class RechargeScreen extends StatelessWidget {
  const RechargeScreen({super.key});

  static const List<PaymentGateway> _gateways = <PaymentGateway>[
    PayPalGateway(),
    GooglePlayGateway(),
  ];

  static const String _notAvailable = 'Presto disponibile';

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.sambaBlack,
      appBar: AppBar(title: const Text('Monete')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _freeBanner(context, state),
          const SizedBox(height: 20),
          const Text(
            'Pacchetti monete',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.sambaText,
            ),
          ),
          const SizedBox(height: 12),
          ...kCoinPacks.map(
            (CoinPack pack) => _packCard(pack),
          ),
          const SizedBox(height: 20),
          const Text(
            'Metodi di pagamento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.sambaText,
            ),
          ),
          const SizedBox(height: 12),
          ..._gateways.map(_gatewayButton),
          const SizedBox(height: 20),
          const Text(
            'Nota: in questa fase tutte le monete sono GRATUITE e non viene '
            'addebitato nulla. I pagamenti PayPal e Google Play resteranno '
            'disabilitati finché il backend non sarà pronto.',
            style: TextStyle(fontSize: 12, color: AppColors.sambaMuted),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _freeBanner(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '🎁 Monete gratuite',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.sambaBlack,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nessun acquisto reale: le monete si ottengono gratis '
            '(credito iniziale + bonus giornaliero).',
            style: TextStyle(fontSize: 12, color: AppColors.sambaBlack),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                '🪙 ${state.coins}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.sambaBlack,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sambaBlack,
                  foregroundColor: AppColors.sambaGold,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  final int granted = state.addFreeCoins();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        granted > 0
                            ? 'Hai riscattato $granted monete gratis! 🎉'
                            : 'Bonus giornaliero già riscattato, torna domani',
                      ),
                    ),
                  );
                },
                child: const Text('Riscatta bonus'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _packCard(CoinPack pack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sambaSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sambaLines),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('🪙', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '${pack.coins}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.sambaText,
                ),
              ),
              if (pack.bonusCoins > 0) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.sambaOk.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${pack.bonusCoins} bonus',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sambaOk,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                pack.priceLabel,
                style: const TextStyle(color: AppColors.sambaMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _disabledGateway(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'PayPal',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _disabledGateway(
                  icon: Icons.shop_outlined,
                  label: 'Google Play',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _disabledGateway({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sambaSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sambaLines),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.sambaMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sambaMuted,
                  ),
                ),
                const Text(
                  _notAvailable,
                  style: TextStyle(fontSize: 10, color: AppColors.sambaMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gatewayButton(PaymentGateway gateway) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sambaSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sambaLines),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.lock_outline, size: 18, color: AppColors.sambaMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              gateway.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.sambaMuted,
              ),
            ),
          ),
          const Text(
            _notAvailable,
            style: TextStyle(fontSize: 12, color: AppColors.sambaMuted),
          ),
        ],
      ),
    );
  }
}
