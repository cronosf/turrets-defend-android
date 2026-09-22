import 'dart:convert';

import 'package:flutter/material.dart';

/// The shop item's preview image, generated from the base game sprites
/// (see assets/images/shop/) and referenced by the `asset_key` in the
/// item's `metadata` JSON. Bundles don't carry their own asset_key (their
/// metadata just lists what they include), so this returns null and the
/// caller falls back to a generic icon.
String? shopItemImagePath(Map<String, dynamic> item) {
  final rawMetadata = item['metadata'];
  if (rawMetadata is! String || rawMetadata.isEmpty) return null;
  try {
    final metadata = jsonDecode(rawMetadata) as Map<String, dynamic>;
    final assetKey = metadata['asset_key'] as String?;
    if (assetKey == null) return null;
    return 'assets/images/shop/$assetKey.png';
  } catch (_) {
    return null;
  }
}

/// Square bordered image tile shared by the shop grid and "My
/// customization", so an owned/equipped item looks the same in both
/// places. Gold border normally, green when [highlighted] (equipped).
class ShopItemImageTile extends StatelessWidget {
  const ShopItemImageTile({super.key, required this.imagePath, this.highlighted = false});

  final String? imagePath;
  final bool highlighted;

  static const _gold = Color(0xFFFFC94D);
  static const _green = Color(0xFF3E9B4F);
  static const _goldShadow = Color(0x55FFC94D);
  static const _greenShadow = Color(0x553E9B4F);

  @override
  Widget build(BuildContext context) {
    final borderColor = highlighted ? _green : _gold;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF241a11),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: highlighted ? _greenShadow : _goldShadow,
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: imagePath != null
            ? Image.asset(imagePath!, fit: BoxFit.contain)
            : Icon(Icons.redeem_rounded, color: borderColor, size: 40),
      ),
    );
  }
}
