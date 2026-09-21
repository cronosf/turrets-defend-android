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

  /// Loads every frame under [dirPrefix] (relative to assets/images/) as a
  /// [Sprite], sorted alphabetically.
  static Future<List<Sprite>> loadFrames(String dirPrefix) async {
    final keys = _keysIn(dirPrefix);
    final sprites = <Sprite>[];
    for (final key in keys) {
      final relative = key.substring('assets/images/'.length);
      final image = await Flame.images.load(relative);
      sprites.add(Sprite(image));
    }
    return sprites;
  }

  /// Loads a single named image relative to assets/images/.
  static Future<Sprite> loadSprite(String relativePath) async {
    final image = await Flame.images.load(relativePath);
    return Sprite(image);
  }
}
