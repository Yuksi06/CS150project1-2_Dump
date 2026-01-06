import 'dart:ui';
import 'package:flame/components.dart';
import '../../common/constants.dart';

class CrateLayer extends PositionComponent {
  final Paint _cratePaint = Paint()..color = const Color(0xFF8D6E63); // Brown

  // Keep track of the crates
  List<List<int>> _positions = [];

  CrateLayer(): super(size: Vector2(gameWidth * tileSize, gameHeight * tileSize));

  void updateCrates(List<List<int>> newPositions) {
    _positions = newPositions;
  }

  @override
  void render(Canvas canvas) {
    const double s = 32.0;

    for (var pos in _positions) {
      double x = pos[0].toDouble();
      double y = pos[1].toDouble();

      // Draw Crate
      canvas.drawRect(
        Rect.fromLTWH(x * s + 2, y * s + 2, s - 4, s - 4),
        _cratePaint
      );
    }
  }
}