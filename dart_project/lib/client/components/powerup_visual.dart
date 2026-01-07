import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../common/protocol.dart';

class PowerupVisual extends SpriteAnimationComponent with HasGameRef {
  final int type;

  PowerupVisual(PowerupModel model) 
    : type = model.type,
      super(
        position: Vector2(model.x * 32.0, model.y * 32.0),
        size: Vector2(32, 32)
      );

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load('powerups.png'); // OR 'powerups.png' - CHECK THIS!
    // Using frames from text file
    
    List<Vector2> frames = [];
    
    switch (type) {
      case 0: // Fire Up [(40, 20), (40, 60)]
        frames = [Vector2(40, 20), Vector2(40, 60)];
        break;
      case 1: // Speed Up [(0, 0), (0, 40)]
        frames = [Vector2(0, 0), Vector2(0, 40)];
        break;
      case 2: // Bomb Up [(40, 0), (40, 40)]
        frames = [Vector2(40, 0), Vector2(40, 40)];
        break;
      case 3: // Vest
        frames = [Vector2(60, 0), Vector2(60, 40)];
        break;
      case 4: // Heart
        frames = [Vector2(80, 0), Vector2(80, 40)];
        break;
      default: // Vest [(60, 0), (60, 40)]
        frames = [Vector2(60, 0), Vector2(60, 40)];
        break;
    }

    final spriteList = frames.map((pos) {
      return Sprite(image, srcPosition: pos, srcSize: Vector2(16, 16));
    }).toList();

    animation = SpriteAnimation.spriteList(spriteList, stepTime: 0.2, loop: true);
  }
}