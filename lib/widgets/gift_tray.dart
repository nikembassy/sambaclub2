import 'package:flutter/material.dart';

import '../models/gift.dart';
import '../theme/app_theme.dart';

/// Bottom sheet that lists the tiered gift catalogue (Gratis / Popolari /
/// Lusso / Leggendari) plus a x1 / x10 / x88 / x520 quantity (combo) selector.
///
/// Resolves with a [GiftOrder] (gift + quantity) or null if dismissed.
class GiftTray extends StatefulWidget {
  const GiftTray({super.key, required this.onGiftSelected});

  /// Called when the user taps a gift, with the chosen combo quantity.
  final ValueChanged<GiftOrder> onGiftSelected;

  /// Selectable combo quantities.
  static const List<int> quantities = <int>[1, 10, 88, 520];

  /// Shows the tray and resolves with the chosen [GiftOrder], or null if the
  /// sheet was dismissed without a choice.
  static Future<GiftOrder?> show(BuildContext context) {
    return showModalBottomSheet<GiftOrder>(
      context: context,
      backgroundColor: AppColors.sambaSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext sheetContext) => GiftTray(
        onGiftSelected: (GiftOrder order) =>
            Navigator.of(sheetContext).pop(order),
      ),
    );
  }

  @override
  State<GiftTray> createState() => _GiftTrayState();
}

class _GiftTrayState extends State<GiftTray> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: kGiftTiers.length,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sambaLines,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  const Text('🎁', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Text(
                    'Regali',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sambaText,
                    ),
                  ),
                  const Spacer(),
                  if (_qty > 1) _comboBadge(_qty),
                ],
              ),
              const SizedBox(height: 12),
              _qtySelector(),
              const SizedBox(height: 8),
              TabBar(
                isScrollable: true,
                labelColor: AppColors.sambaBlack,
                unselectedLabelColor: AppColors.sambaMuted,
                indicatorColor: AppColors.sambaGold,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: AppColors.sambaLines,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                tabs: kGiftTiers
                    .map((GiftTier t) => Tab(text: t.name))
                    .toList(),
              ),
              SizedBox(
                height: 240,
                child: TabBarView(
                  children: kGiftTiers
                      .map((GiftTier t) => _tierGrid(t))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comboBadge(int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'x$qty COMBO!',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.sambaBlack,
        ),
      ),
    );
  }

  Widget _qtySelector() {
    return Row(
      children: <Widget>[
        const Text(
          'Quantità',
          style: TextStyle(fontSize: 12, color: AppColors.sambaMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: GiftTray.quantities.map((int qty) {
              return ChoiceChip(
                label: Text('x$qty'),
                selected: qty == _qty,
                onSelected: (bool selected) {
                  if (selected) setState(() => _qty = qty);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _tierGrid(GiftTier tier) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: tier.gifts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (BuildContext context, int index) {
        final Gift gift = tier.gifts[index];
        return _GiftTile(
          gift: gift,
          qty: _qty,
          onTap: () => widget.onGiftSelected(GiftOrder(gift, _qty)),
        );
      },
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.gift, required this.qty, required this.onTap});

  final Gift gift;
  final int qty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.sambaSurface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sambaLines),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(gift.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                gift.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.sambaText),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('🪙', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  '${gift.price * qty}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sambaGold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
