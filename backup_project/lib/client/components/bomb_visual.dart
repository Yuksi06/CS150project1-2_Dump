//import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import '../../common/constants.dart';
import '../../common/protocol.dart';

class BombVisual extends PositionComponent {
  final int id;
  late CircleComponent _shape;

  BombVisual(BombModel model)
    : id = model.id,
      super(size: Vector2.all(tileSize * 32)) {
    // Align to grid
    position = Vector2(model.x * 32.0, model.y * 32.0);
  }

  @override
  Future<void> onLoad() async {
    // Draw Black Ball
    _shape = CircleComponent(
      radius: 12, // smaller than tile
      paint: BasicPalette.black.paint(),
      position: Vector2(4, 4), // Center of 32x32 tile
    );
    add(_shape);

    // Add a simple "fuse" animation later
  }
}