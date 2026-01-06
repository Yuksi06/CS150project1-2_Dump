import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../common/protocol.dart';

class BombVisual extends SpriteAnimationComponent with HasGameRef {
  final int bombId;

  BombVisual(BombModel model) 
    : bombId = model.id,
      super(
        position: Vector2(model.x * 32.0, model.y * 32.0),
        size: Vector2(32, 32)
      );

  @override
  Future<void> onLoad() async {
    try {
      final image = await gameRef.images.load('tileSet-2.png');
      
      final spriteList = [
        Sprite(image, srcPosition: Vector2(0, 816), srcSize: Vector2(16, 16)),
        Sprite(image, srcPosition: Vector2(16, 816), srcSize: Vector2(16, 16)),
        Sprite(image, srcPosition: Vector2(32, 816), srcSize: Vector2(16, 16)),
      ];

      animation = SpriteAnimation.spriteList(
        spriteList,
        stepTime: 0.2,
        loop: true,
      );
    } catch(e) {
      print("Error bomb: $e");
    }
  }
}