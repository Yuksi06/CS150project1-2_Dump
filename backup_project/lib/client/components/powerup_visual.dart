import 'package:flutter/material.dart';
import 'package:flame/components.dart';
//import '../../common/constants.dart';
import '../../common/protocol.dart';

class PowerupVisual extends PositionComponent {
  final int id;
  final int type; // 0 = Range, 1 = Speed, 2 = Ammo

  PowerupVisual(PowerupModel model)
    : id = model.id,
      type = model.type,
      super(size: Vector2.all(32)) { // Fixed size to match tile (32x32)
    position = Vector2(model.x * 32.0, model.y * 32.0);
  }

  @override
  Future<void> onLoad() async {
    // 1. Determine Color & Label based on Type
    Color color;
    String label;

    switch (type) {
      case 0: // Fire Up
        color = Colors.orange;
        label = 'F';
        break;
      case 1: // Speed Up
        color = Colors.blue;
        label = 'S';
        break;
      case 2: // Bomb Up (Ammo)
        color = const Color(0xFF9C27B0); // Purple
        label = 'B';
        break;
      default:
        color = Colors.grey;
        label = '?';
    }

    // 2. Draw the Box (Background)
    add(RectangleComponent(
      size: Vector2(24, 24), // Slightly smaller than 32 to look like an item
      position: Vector2(4, 4), // Centered (32-24)/2 = 4
      paint: Paint()..color = color,
    ));

    // 3. Draw the Border (White Outline)
    add(RectangleComponent(
      size: Vector2(24, 24),
      position: Vector2(4, 4),
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));

    // 4. Draw the Letter
    add(TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900, // Extra Bold
          fontFamily: 'Courier', // Retro feel
        ),
      ),
      // Approximate centering for the text
      position: Vector2(type == 0 ? 10 : 9, 4), 
    ));
  }
}