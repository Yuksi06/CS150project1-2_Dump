import 'dart:ui' hide TextStyle;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import '../../common/constants.dart';
import '../../common/protocol.dart';

class RemotePlayer extends PositionComponent {
  final int id;
  final int colorId;

  late CircleComponent _visual;

  Vector2 _targetPosition = Vector2.zero();

  RemotePlayer(PlayerModel model)
    : id = model.id,
      colorId = model.colorId,
      super(size: Vector2.all(tileSize * 30)) {
  }

  @override
  Future<void> onLoad() async {
    final paint = _getPaint(colorId);

    _visual = CircleComponent(
      radius: size.x / 2,
      paint: paint,
    );
    add(_visual);

    final textComponent = TextComponent(
      text:'P${id + 1}',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    textComponent.position = Vector2(size.x / 2  - 8, -15);
    add(textComponent);
  }

  void syncToModel(PlayerModel model) {
    // FIX: Server now sends Pixels, so DO NOT multiply by 32 here.
    _targetPosition = Vector2(model.x, model.y);

    if (model.isDead) {
      _visual.paint.color = _visual.paint.color.withOpacity(0.5);
    } else {
      _visual.paint.color = _visual.paint.color.withOpacity(1.0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Interpolate for smooth movement
    position.lerp(_targetPosition, dt * 20);
  }

  Paint _getPaint(int id) {
    switch (id) {
      case 0: return BasicPalette.white.paint();
      case 1: return BasicPalette.black.paint();
      case 2: return BasicPalette.red.paint();
      case 3: return BasicPalette.green.paint();
      default: return BasicPalette.blue.paint();
    }
  }
}