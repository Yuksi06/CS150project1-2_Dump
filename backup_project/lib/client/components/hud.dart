import 'dart:ui' hide TextStyle;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../common/constants.dart';

class Hud extends PositionComponent {
  late TextComponent _timerText;
  late TextComponent _statusText;
  late TextComponent _centerText;

  Hud() : super(priority: 100);

  @override
  Future<void> onLoad() async {
    // 1. Timer Display
    _timerText = TextComponent(
      text: 'Time: 300',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
        ),
      ),
    );

    _timerText.position = Vector2(gameWidth * tileSize / 2 - 50, 10);
    add(_timerText);

    // 2. Status Text
    _statusText = TextComponent(
      text: 'Waiting...',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFCCCCCC),
          fontSize: 14,
        ),
      ),
    );

    _statusText.position = Vector2(10, gameHeight * tileSize - 30);
    add(_statusText);

    // 3. Game Over Text
    _centerText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2,2))]
        ),
      ),
    );

    _centerText.position = Vector2(gameWidth * tileSize / 2, gameHeight * tileSize / 2);
    _centerText.anchor = Anchor.center;
    add(_centerText);
  }

  void updateData(double timeRemaining, int playerCount, int? winnerId) {
    _timerText.text = 'Time: ${timeRemaining.ceil()}';
    _statusText.text = 'Players: $playerCount';

    if (winnerId != null) {
      if (winnerId == -1) {
        _centerText.text = "DRAW!";
      } else {
        _centerText.text = "P$winnerId WINS!";
      }
    } else {
      _centerText.text = "";  // Game is still running
    }
  }
}