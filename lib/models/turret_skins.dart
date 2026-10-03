import 'dart:ui' show Color;

/// A thrown-star projectile (the Ninja Assassin's attack, and the colored
/// shuriken `bullet_effect` items): a spinning pixel-art sprite with a soft
/// comet trail of [trail] color behind it.
class ShurikenType {
  const ShurikenType(this.sprite, this.trail);

  /// Relative to assets/images/.
  final String sprite;
  final Color trail;
}

/// What a Ninja Assassin throws while the bullet slot is on Basic.
const ShurikenType kBasicShuriken = ShurikenType('projectile/shuriken_white.png', Color(0xFFFFFFFF));

/// The purchasable shuriken `bullet_effect` items, keyed by the shop item's
/// `asset_key` (also the shop icon name, assets/images/shop/$asset_key.png).
const Map<String, ShurikenType> kShurikenBullets = {
  'bullet_shuriken_red': ShurikenType('projectile/shuriken_red.png', Color(0xFFFF3B30)),
  'bullet_shuriken_blue': ShurikenType('projectile/shuriken_blue.png', Color(0xFF3D6BFF)),
  'bullet_shuriken_fuchsia': ShurikenType('projectile/shuriken_fuchsia.png', Color(0xFFE040FB)),
  'bullet_shuriken_green': ShurikenType('projectile/shuriken_green.png', Color(0xFF2ECC71)),
  'bullet_shuriken_orange': ShurikenType('projectile/shuriken_orange.png', Color(0xFFFF9800)),
  'bullet_shuriken_cyan': ShurikenType('projectile/shuriken_cyan.png', Color(0xFF00E5FF)),
};

/// Sound for any shuriken shot (file under assets/audio/).
const String kShurikenSound = 'Knife_throwing.wav';

/// A purchasable `turret_skin` that fully replaces every turret's art with a
/// character (seen from behind on the board, from the front in the Buy
/// sheet) and its shots with an attack effect — unlike the legacy
/// hue-rotate skins (see theme/hue_rotate.dart), which only tinted the base
/// turret. Keyed by the shop item's `asset_key` exactly (this is also what
/// names the shop icon, assets/images/shop/$asset_key.png).
class TurretSkinType {
  const TurretSkinType({
    required this.family,
    required this.idleDir,
    required this.attackDir,
    required this.dieDir,
    required this.frontAsset,
    required this.boardSize,
    required this.attackSound,
    this.idleStepTime = 0.07,
    this.effectDir,
    this.effectSize = (36, 18),
    this.shuriken,
    this.attackSoundHigh,
  });

  /// Shop/customization filter group: 'warrior' | 'ninja'.
  final String family;

  /// Looping idle frames (back view), relative to assets/images/.
  final String idleDir;
  final double idleStepTime;

  /// One-shot swing frames (back view), played every time the turret fires.
  final String attackDir;

  /// One-shot death frames, played once when the base is destroyed; the
  /// turret then stays on the last frame. The canvas shares the idle
  /// frames' pixel scale and top-left corner (it may only be taller).
  final String dieDir;

  /// Front-view sprite shown in the Buy sheet, relative to assets/images/.
  final String frontAsset;

  /// On-screen size (game pixels) of one idle/attack frame on the board.
  final (double, double) boardSize;

  /// Animated shot effect frames (drawn pointing right, rotated toward the
  /// target while it flies) — null for skins that throw [shuriken] instead.
  final String? effectDir;

  /// On-screen size of the shot effect (width x height in game pixels) —
  /// matches the frames' own aspect so nothing gets stretched.
  final (double, double) effectSize;

  /// The projectile thrown while the bullet slot is on Basic (instead of
  /// [effectDir]).
  final ShurikenType? shuriken;

  /// Shot sound (file under assets/audio/) played instead of the regular
  /// turret shot sound whenever the skin's own attack effect is active.
  final String attackSound;

  /// Optional alternate sound for turrets of level [highTierFrom] and up.
  final String? attackSoundHigh;

  static const int highTierFrom = 7;

  String soundForTier(int tier) =>
      tier >= highTierFrom ? (attackSoundHigh ?? attackSound) : attackSound;
}

const (double, double) _warriorBoard = (58.1, 39.9);

const Map<String, TurretSkinType> kTurretSkins = {
  'turret_warrior_black': TurretSkinType(
    family: 'warrior',
    idleDir: 'turrets/warrior_black_idle',
    attackDir: 'turrets/warrior_black_attack',
    dieDir: 'turrets/warrior_black_die',
    frontAsset: 'turrets/warrior_front/warrior_black.png',
    boardSize: _warriorBoard,
    effectDir: 'fx/fx_water_black',
    attackSound: 'warrior_splash.wav',
    attackSoundHigh: 'warrior_drown.wav',
  ),
  'turret_warrior_blue': TurretSkinType(
    family: 'warrior',
    idleDir: 'turrets/warrior_blue_idle',
    attackDir: 'turrets/warrior_blue_attack',
    dieDir: 'turrets/warrior_blue_die',
    frontAsset: 'turrets/warrior_front/warrior_blue.png',
    boardSize: _warriorBoard,
    effectDir: 'fx/fx_water_blue',
    attackSound: 'warrior_splash.wav',
    attackSoundHigh: 'warrior_drown.wav',
  ),
  'turret_warrior_red': TurretSkinType(
    family: 'warrior',
    idleDir: 'turrets/warrior_red_idle',
    attackDir: 'turrets/warrior_red_attack',
    dieDir: 'turrets/warrior_red_die',
    frontAsset: 'turrets/warrior_front/warrior_red.png',
    boardSize: _warriorBoard,
    effectDir: 'fx/fx_flame_fuchsia',
    effectSize: (46, 21),
    attackSound: 'warrior_flame.wav',
  ),
  // Intense red: original red-fire effect (the fuchsia skin's flame is
  // recolored; this one keeps flame10's own colors).
  'turret_warrior_scarlet': TurretSkinType(
    family: 'warrior',
    idleDir: 'turrets/warrior_scarlet_idle',
    attackDir: 'turrets/warrior_scarlet_attack',
    dieDir: 'turrets/warrior_scarlet_die',
    frontAsset: 'turrets/warrior_front/warrior_scarlet.png',
    boardSize: _warriorBoard,
    effectDir: 'fx/fx_flame_red',
    effectSize: (46, 21),
    attackSound: 'warrior_flame.wav',
  ),
  'turret_ninja_assassin': TurretSkinType(
    family: 'ninja',
    idleDir: 'turrets/ninja_idle',
    idleStepTime: 0.13,
    attackDir: 'turrets/ninja_attack',
    dieDir: 'turrets/ninja_die',
    frontAsset: 'turrets/warrior_front/ninja_assassin.png',
    boardSize: (52.2, 40.0),
    shuriken: kBasicShuriken,
    attackSound: kShurikenSound,
  ),
};
