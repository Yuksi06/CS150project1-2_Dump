import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../common/constants.dart';

class GameMap extends PositionComponent with HasGameRef {
  late Sprite _grassSprite;
  late Sprite _wallSprite;
  bool _isLoaded = false;

  GameMap(): super(size: Vector2(gameWidth * tileSize, gameHeight * tileSize));

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load('tileSet-2.png');
    
    // Grass: (32, 704) 16x16
    _grassSprite = Sprite(image, srcPosition: Vector2(32, 704), srcSize: Vector2(16, 16));
    
    // Hard Block (Wall): (16, 704) 16x16
    _wallSprite = Sprite(image, srcPosition: Vector2(16, 704), srcSize: Vector2(16, 16));
    
    _isLoaded = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded) return;
    const double s = 32.0;

    for (int y = 0; y < gameHeight; y++) {
      for (int x = 0; x < gameWidth; x++) {
         _grassSprite.render(canvas, position: Vector2(x * s, y * s), size: Vector2(s, s));
      }
    }

    for (int y = 0; y < gameHeight; y++) {
      for (int x = 0; x < gameWidth; x++) {
        bool isEdge = (x == 0 || x == gameWidth - 1 || y == 0 || y == gameHeight - 1);
        bool isChecker = (x % 2 == 0 && y % 2 == 0);

        if (isEdge || isChecker) {
          _wallSprite.render(canvas, position: Vector2(x * s, y * s), size: Vector2(s, s));
        }
      }
    }
  }
}