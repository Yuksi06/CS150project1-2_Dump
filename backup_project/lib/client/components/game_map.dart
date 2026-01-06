import 'dart:ui';
import 'package:flame/components.dart';
import '../../common/constants.dart';

class GameMap extends PositionComponent {
  
  // Colors
  final Paint _grassPaint = Paint()..color = const Color(0xFF388E3C); // Green
  final Paint _wallPaint = Paint()..color = const Color(0xFF757575); // Grey

  GameMap(): super(size: Vector2(gameWidth * tileSize, gameHeight * tileSize));

  @override
  void render(Canvas canvas) {
    // 1. Draw Grass Background
    const double s = 32.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, gameWidth * s, gameHeight * s), _grassPaint);

    // 2. Draw Hard Blocks (Checkerboard pattern [Hardcode])
    for (int y = 0; y < gameHeight; y++) {
      for (int x = 0; x < gameWidth; x++) {
        // Edge = Wall
        bool isEdge = (x == 0 || x == gameWidth - 1 || y == 0 || y == gameHeight - 1);

        // Even positions = Hard Block
        bool isChecker = (x % 2 == 0 && y % 2 == 0);

        if (isEdge || isChecker) {
          canvas.drawRect(
            Rect.fromLTWH(x * s, y * s, s, s),
            _wallPaint
          );
        }
      }
    }
  }
}