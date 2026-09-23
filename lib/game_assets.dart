import 'package:flame/components.dart' show Vector2;
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart' show rootBundle, AssetManifest;

/// Discovers frame files under an asset directory at runtime by reading the
/// Flutter asset manifest, instead of hardcoding per-folder file names.
/// This keeps the game resilient to naming quirks in the source art kit
/// (some folders reuse a different variant's file prefix internally).
class GameAssets {
  GameAssets._();

  static List<String> _allKeys = [];

  // Every enemy/turret spawn used to call loadFrames fresh — Flame.images
  // already caches the decoded ui.Image, but this still re-scanned the
  // manifest and, worse, allocated a brand new List<Sprite> every single
  // spawn. Across a run with hundreds of spawns that's a lot of avoidable
  // garbage, and it was visibly worse on a second consecutive "Play Again"
  // run: the first run's garbage hadn't been collected yet, so the second
  // run started under extra GC pressure on top of generating its own.
  // Caching by dirPrefix means the Sprite list is built once and safely
  // shared — SpriteAnimation.spriteList only reads the list (maps it into
  // its own SpriteAnimationFrame list), it never mutates the input.
  static final Map<String, List<Sprite>> _frameCache = {};

  static Future<void> init() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _allKeys = manifest.listAssets();
  }

  /// Returns the manifest keys (full asset paths) under [dirPrefix] (given
  /// relative to assets/images/), sorted.
  static List<String> _keysIn(String dirPrefix) {
    final withoutSlash = dirPrefix.endsWith('/')
        ? dirPrefix.substring(0, dirPrefix.length - 1)
        : dirPrefix;
    final norm = 'assets/images/$withoutSlash/';
    final list = _allKeys
        .where((k) => k.startsWith(norm) && k.toLowerCase().endsWith('.png'))
        .toList();
    list.sort();
    return list;
  }

  /// Loads (and caches) every frame under [dirPrefix] (relative to
  /// assets/images/) as a [Sprite], sorted alphabetically.
  static Future<List<Sprite>> loadFrames(String dirPrefix) async {
    final cached = _frameCache[dirPrefix];
    if (cached != null) return cached;

    final keys = _keysIn(dirPrefix);
    final sprites = <Sprite>[];
    for (final key in keys) {
      final relative = key.substring('assets/images/'.length);
      final image = await Flame.images.load(relative);
      sprites.add(Sprite(image));
    }
    _frameCache[dirPrefix] = sprites;
    return sprites;
  }

  /// Loads a single named image relative to assets/images/.
  static Future<Sprite> loadSprite(String relativePath) async {
    final image = await Flame.images.load(relativePath);
    return Sprite(image);
  }

  /// Slices one row out of a uniform sprite sheet into individual [Sprite]s.
  /// Boss art (see assets/images/bosses/) comes as one PNG per animation
  /// with a fixed-size frame grid (rows = facing direction, columns =
  /// animation frames) rather than the per-frame-file convention
  /// [loadFrames] expects, so this reads a single row directly via
  /// srcPosition/srcSize instead.
  static Future<List<Sprite>> loadSheetRow(
    String relativePath, {
    required double frameWidth,
    required double frameHeight,
    required int row,
    required int columns,
  }) async {
    final image = await Flame.images.load(relativePath);
    return [
      for (var col = 0; col < columns; col++)
        Sprite(
          image,
          srcPosition: Vector2(col * frameWidth, row * frameHeight),
          srcSize: Vector2(frameWidth, frameHeight),
        ),
    ];
  }
}
