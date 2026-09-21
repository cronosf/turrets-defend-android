import 'package:flame/components.dart';

/// One-shot visual effect (explosion or muzzle flash) that removes itself
/// once its frame sequence finishes playing.
class FxComponent extends SpriteAnimationComponent {
  FxComponent({
    required List<Sprite> frames,
    required Vector2 position,
    required Vector2 size,
    double stepTime = 0.02,
  }) : super(
          animation: SpriteAnimation.spriteList(frames, stepTime: stepTime, loop: false),
          position: position,
          size: size,
          anchor: Anchor.center,
          removeOnFinish: true,
        );
}
