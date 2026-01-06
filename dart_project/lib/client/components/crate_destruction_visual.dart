import 'package:flame/components.dart';
import 'package:flame/game.dart';

class CrateDestructionVisual extends SpriteAnimationComponent with HasGameRef {
  
  CrateDestructionVisual({required Vector2 position}) 
    : super(position: position, size: Vector2(32, 32), removeOnFinish: true);

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load('tileSet-2.png');
    
    // Soft Block Burning Animation
    // 8 Frames starting at (0, 880) -> Same as soft block, but played as anim
    // Assuming the soft block frames ARE the burning frames played in sequence
    final sprites = <Sprite>[];
    for (int i = 0; i < 8; i++) {
      sprites.add(Sprite(image, srcPosition: Vector2(i * 16.0, 880), srcSize: Vector2(16, 16)));
    }

    animation = SpriteAnimation.spriteList(sprites, stepTime: 0.1, loop: false);
  }
}