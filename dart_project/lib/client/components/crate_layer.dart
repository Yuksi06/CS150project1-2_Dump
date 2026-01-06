import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../common/constants.dart';

class CrateLayer extends PositionComponent with HasGameRef {
  late Sprite _crateSprite;
  bool _isLoaded = false;
  
  // Track positions to detect destruction
  Set<String> _knownCrates = {};
  
  // Callback to spawn visual effects
  Function(Vector2)? onCrateDestroyed;

  CrateLayer(): super(size: Vector2(gameWidth * tileSize, gameHeight * tileSize));

  void updateCrates(List<List<int>> newPositions) {
    if (!_isLoaded) return;

    final Set<String> newSet = {};
    for (var pos in newPositions) {
      newSet.add("${pos[0]},${pos[1]}");
    }

    // Diffing: Find crates that were here before but are gone now
    for (var oldKey in _knownCrates) {
      if (!newSet.contains(oldKey)) {
        // Crate Destroyed!
        final parts = oldKey.split(',');
        final x = int.parse(parts[0]);
        final y = int.parse(parts[1]);
        
        onCrateDestroyed?.call(Vector2(x * 32.0, y * 32.0));
      }
    }

    _knownCrates = newSet;
  }

  @override
  Future<void> onLoad() async {
    try {
      final image = await gameRef.images.load('tileSet-2.png');
      // Static Frame (Index 0) at 0, 880
      _crateSprite = Sprite(image, srcPosition: Vector2(0, 880), srcSize: Vector2(16, 16));
      _isLoaded = true;
    } catch (e) {
      print("Error loading crate sprite: $e");
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isLoaded) return;
    const double s = 32.0;

    for (var key in _knownCrates) {
      final parts = key.split(',');
      final x = double.parse(parts[0]);
      final y = double.parse(parts[1]);
      _crateSprite.render(canvas, position: Vector2(x * s, y * s), size: Vector2(s, s));
    }
  }
}