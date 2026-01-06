import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
// import '../../common/constants.dart';
import '../../common/protocol.dart';

class ExplosionVisual extends PositionComponent {
  final int id;

  double _lifeTime = 1.0; // FIXED: Mismatch with Explosion Duration

  final List<List<int>> tiles;

  ExplosionVisual(ExplosionModel model)
    : id = model.id,
      tiles = model.affectedTiles,
      super(size: Vector2.all(0));

  @override
  void render(Canvas canvas) {
    final paint = BasicPalette.red.paint();
    paint.color = paint.color.withOpacity(0.8);

    const double s = 32.0;

    for (var tile in tiles) {
      canvas.drawRect(
        Rect.fromLTWH(tile[0] * s, tile[1] * s, s, s),
        paint
      );
    }
  }

  @override
  void update(double dt) {
    _lifeTime -= dt;
    if (_lifeTime <= 0) {
      removeFromParent();
    }
  }

}