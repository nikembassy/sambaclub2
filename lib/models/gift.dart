/// A virtual gift that can be sent inside a live room.
class Gift {
  const Gift({
    required this.id,
    required this.emoji,
    required this.name,
    required this.price,
  });

  final String id;
  final String emoji;
  final String name;

  /// Price in coins.
  final int price;

  bool get isFreeTier => price <= 10;
}

/// A gift bundle: a [Gift] plus how many copies were sent at once
/// (used by the x1 / x10 / x88 / x520 combo selector).
class GiftOrder {
  const GiftOrder(this.gift, this.qty);

  final Gift gift;
  final int qty;

  /// Total coins for the whole bundle.
  int get total => gift.price * qty;
}

/// A named group of gifts (Gratis, Popolari, …) used by the tiered gift tray.
class GiftTier {
  const GiftTier(this.name, this.gifts);

  final String name;
  final List<Gift> gifts;
}

const List<Gift> _gratisGifts = <Gift>[
  Gift(id: 'rosa', emoji: '🌹', name: 'Rosa', price: 1),
  Gift(id: 'cuore', emoji: '❤️', name: 'Cuore', price: 5),
  Gift(id: 'finger_heart', emoji: '🫰', name: 'Finger Heart', price: 10),
  Gift(id: 'bacio', emoji: '💋', name: 'Bacio', price: 20),
  Gift(id: 'applausi', emoji: '👏', name: 'Applausi', price: 50),
  Gift(id: 'birra', emoji: '🍺', name: 'Birra', price: 88),
  Gift(id: 'caffe', emoji: '☕', name: 'Caffè', price: 99),
  Gift(id: 'orsetto', emoji: '🧸', name: 'Orsetto', price: 188),
  Gift(id: 'torta', emoji: '🎂', name: 'Torta', price: 299),
  Gift(id: 'busta_rossa', emoji: '🧧', name: 'Busta rossa', price: 520),
  Gift(id: 'biglietto', emoji: '💌', name: 'Biglietto', price: 666),
  Gift(id: 'palloncino', emoji: '🎈', name: 'Palloncino', price: 888),
];

const List<Gift> _popolariGifts = <Gift>[
  Gift(id: 'corona', emoji: '👑', name: 'Corona', price: 1000),
  Gift(id: 'occhiali', emoji: '🕶️', name: 'Occhiali', price: 1999),
  Gift(id: 'chitarra', emoji: '🎸', name: 'Chitarra', price: 2500),
  Gift(id: 'profumo', emoji: '💄', name: 'Profumo', price: 2888),
  Gift(id: 'bouquet', emoji: '💐', name: 'Bouquet', price: 3999),
  Gift(id: 'auto_sportiva', emoji: '🚗', name: 'Auto sportiva', price: 5999),
  Gift(id: 'cavallo', emoji: '🐎', name: 'Cavallo', price: 7000),
  Gift(id: 'ruota', emoji: '🎡', name: 'Ruota', price: 8888),
];

const List<Gift> _lussoGifts = <Gift>[
  Gift(id: 'yacht', emoji: '🛥️', name: 'Yacht', price: 12000),
  Gift(id: 'elicottero', emoji: '🚁', name: 'Elicottero', price: 15000),
  Gift(id: 'castello_lusso', emoji: '🏰', name: 'Castello', price: 18888),
  Gift(id: 'razzo', emoji: '🚀', name: 'Razzo', price: 22000),
  Gift(id: 'jet_privato', emoji: '🛩️', name: 'Jet privato', price: 28888),
  Gift(id: 'isola', emoji: '🏝️', name: 'Isola', price: 39999),
  Gift(id: 'fuochi_reali', emoji: '🎆', name: 'Fuochi reali', price: 49999),
  Gift(id: 'drago', emoji: '🐉', name: 'Drago', price: 59999),
];

const List<Gift> _leggendariGifts = <Gift>[
  Gift(id: 'fenice', emoji: '🦅', name: 'Fenice', price: 88888),
  Gift(id: 'diamante', emoji: '💎', name: 'Diamante', price: 99999),
  Gift(id: 'pianeta', emoji: '🪐', name: 'Pianeta', price: 150000),
  Gift(id: 'galassia', emoji: '🌌', name: 'Galassia', price: 288888),
  Gift(id: 'drago_supremo', emoji: '🐲', name: 'Drago Supremo', price: 520000),
  Gift(id: 'olimpo', emoji: '🏛️', name: 'Olimpo', price: 999999),
];

/// The full catalogue, grouped by tier (cheapest first).
const List<GiftTier> kGiftTiers = <GiftTier>[
  GiftTier('Gratis', _gratisGifts),
  GiftTier('Popolari', _popolariGifts),
  GiftTier('Lusso', _lussoGifts),
  GiftTier('Leggendari', _leggendariGifts),
];

/// The free tier, kept as a flat list so existing callers keep working.
const List<Gift> kFreeGifts = _gratisGifts;
