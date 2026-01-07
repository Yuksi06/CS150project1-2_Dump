import 'dart:ui' hide TextStyle;
import 'package:flutter/material.dart' hide Image;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../common/protocol.dart';

// Expanded Enum for Directional Idles
enum PlayerState { idle, idleUp, idleLeft, idleRight, moveDown, moveUp, moveLeft, moveRight, dying }

class RemotePlayer extends PositionComponent with HasGameRef {
  final int id;
  final int colorId;

  SpriteAnimationGroupComponent<PlayerState>? _spriteComponent;
  SpriteAnimationComponent? _ghostComponent;

  Vector2 _targetPosition = Vector2.zero();
  PlayerState _currentState = PlayerState.idle;
  
  // Track last move to determine idle facing
  String _lastDirection = 'down'; 

  bool _isDyingAnimationPlaying = false;
  bool _firstSync = true;

  final Vector2 sizeWalking = Vector2(29, 38);
  final Vector2 posCenter = Vector2(16, 12); 
  final Vector2 sizeDying = Vector2(48, 36); 
  final Vector2 sizeGhost = Vector2(40, 40);

  bool get isVisiblyGhost => _ghostComponent != null && _ghostComponent!.isMounted;

  RemotePlayer(PlayerModel model)
    : id = model.id,
      colorId = model.colorId,
      super(size: Vector2.all(32)) { 
      _targetPosition = Vector2(model.x, model.y);
      position = _targetPosition.clone();
  }

  @override
  Future<void> onLoad() async {
    try {
      final image = await gameRef.images.load('bombermanAndNPCs.png');
      final ghostImage = await gameRef.images.load('ghost.png');

      final coords = _getPlayerCoords(colorId);
      const double step = 0.15;

      // IDLES (Directional)
      final idleDown = _createAnim(image, coords['standSouth']!, stepTime: step);
      final idleUp   = _createAnim(image, coords['standNorth']!, stepTime: step);
      final idleLeft = _createAnim(image, coords['standLeft']!, stepTime: step);
      final idleRight= _createAnim(image, coords['standLeft']!, stepTime: step); // Flipped

      // WALKS
      final walkDown  = _createAnim(image, coords['walkSouth']!, stepTime: step);
      final walkUp    = _createAnim(image, coords['walkNorth']!, stepTime: step);
      final walkLeft  = _createAnim(image, coords['walkLeft']!, stepTime: step);
      final walkRight = _createAnim(image, coords['walkLeft']!, stepTime: step); 
      
      final dieAnim   = _createAnim(image, coords['die']!, stepTime: 0.15, loop: false);

      _spriteComponent = SpriteAnimationGroupComponent<PlayerState>(
        animations: {
          PlayerState.idle: idleDown, // Default South
          PlayerState.idleUp: idleUp,
          PlayerState.idleLeft: idleLeft,
          PlayerState.idleRight: idleRight,
          PlayerState.moveDown: walkDown,
          PlayerState.moveUp: walkUp,
          PlayerState.moveLeft: walkLeft,
          PlayerState.moveRight: walkRight,
          PlayerState.dying: dieAnim,
        },
        current: PlayerState.idle,
        size: sizeWalking,
        position: posCenter,
        anchor: Anchor.center, 
      );
      add(_spriteComponent!);

      final ghostAnim = _createAnim(ghostImage, _getGhostRects(), stepTime: 0.1);
      _ghostComponent = SpriteAnimationComponent(
        animation: ghostAnim,
        size: sizeGhost,
        position: Vector2(16, 16),
        anchor: Anchor.center,
      )..opacity = 0.6;

      _addNameTag();

    } catch (e) {
      print("Error loading sprites for P$id: $e");
      add(RectangleComponent(size: Vector2(32, 32), paint: Paint()..color = Colors.white));
    }
  }

  void _addNameTag() {
    final text = TextComponent(
      text: 'P${id + 1}',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)]
        ),
      ),
    );
    text.position = Vector2(10, -16);
    add(text);
  }

  void syncToModel(PlayerModel model) {
    _targetPosition = Vector2(model.x, model.y);

    if (model.isInvincible) {
      _spriteComponent!.opacity = 0.5;
    } else {
      _spriteComponent!.opacity = 1.0;
    }

    if (_spriteComponent == null) return;

    if (_firstSync) {
      _firstSync = false;
      if (model.isDead) {
        if (_spriteComponent!.isMounted) remove(_spriteComponent!);
        if (_ghostComponent != null) add(_ghostComponent!);
        return; 
      }
    }

    if (model.isDead) {
      if (_ghostComponent != null && _ghostComponent!.isMounted) {
        _isDyingAnimationPlaying = false; 
      } 
      else if (!_isDyingAnimationPlaying) {
        _isDyingAnimationPlaying = true;
        _currentState = PlayerState.dying;
        _spriteComponent!.current = PlayerState.dying;
        _spriteComponent!.size = sizeDying;
        _spriteComponent!.scale = Vector2(1, 1); 
        _spriteComponent!.animationTickers?[PlayerState.dying]?.reset();
      }
    } else {
      _isDyingAnimationPlaying = false;
      if (_ghostComponent != null && _ghostComponent!.isMounted) {
        remove(_ghostComponent!);
        add(_spriteComponent!);
      }

      _spriteComponent!.size = sizeWalking;

      Vector2 diff = _targetPosition - position;
      const double threshold = 0.1; 

      if (diff.length > threshold) {
        // MOVING
        if (diff.y.abs() > diff.x.abs()) {
          _currentState = diff.y > 0 ? PlayerState.moveDown : PlayerState.moveUp;
          _lastDirection = diff.y > 0 ? 'down' : 'up';
        } else {
          _currentState = diff.x > 0 ? PlayerState.moveRight : PlayerState.moveLeft;
          _lastDirection = diff.x > 0 ? 'right' : 'left';
        }
      } else {
        // IDLE - Pick based on last direction
        switch (_lastDirection) {
          case 'up': _currentState = PlayerState.idleUp; break;
          case 'left': _currentState = PlayerState.idleLeft; break;
          case 'right': _currentState = PlayerState.idleRight; break;
          case 'down': 
          default: _currentState = PlayerState.idle; break;
        }
      }

      _spriteComponent!.current = _currentState;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // FLIP LOGIC (Includes IdleRight)
    if (_spriteComponent != null && _spriteComponent!.isMounted) {
      if (_currentState == PlayerState.moveRight || _currentState == PlayerState.idleRight) {
        _spriteComponent!.scale = Vector2(-1, 1);
      } else {
        _spriteComponent!.scale = Vector2(1, 1);
      }
    }

    if (_ghostComponent != null && _ghostComponent!.isMounted) {
       double dx = _targetPosition.x - position.x;
       if (dx.abs() > 0.1) {
         if (dx < 0) _ghostComponent!.scale = Vector2(-1, 1);
         else _ghostComponent!.scale = Vector2(1, 1);
       }
    }

    if (_isDyingAnimationPlaying) {
      final ticker = _spriteComponent?.animationTickers?[PlayerState.dying];
      if (ticker != null && ticker.done()) {
        _isDyingAnimationPlaying = false;
        if (_ghostComponent != null) {
          if (_spriteComponent!.isMounted) remove(_spriteComponent!);
          add(_ghostComponent!);
        }
      }
    } else {
      position.lerp(_targetPosition, dt * 20);
    }
  }

  SpriteAnimation _createAnim(Image image, List<Rect> rects, {double stepTime = 0.15, bool loop = true}) {
    final spriteList = rects.map((r) {
      return Sprite(
        image,
        srcPosition: Vector2(r.left, r.top),
        srcSize: Vector2(r.width, r.height),
      );
    }).toList();
    return SpriteAnimation.spriteList(spriteList, stepTime: stepTime, loop: loop);
  }

  List<Rect> _getGhostRects() {
    List<Rect> frames = [];
    for (int i = 0; i < 5; i++) frames.add(Rect.fromLTWH(i * 160.0 + i, 0, 160, 160)); 
    for (int i = 0; i < 5; i++) frames.add(Rect.fromLTWH(i * 160.0 + i, 161, 160, 160));
    return frames;
  }

  Map<String, List<Rect>> _getPlayerCoords(int colorId) {
    Rect r(double l, double t, double w, double h) => Rect.fromLTWH(l, t, w, h);
    Rect rDeath(double x, double y) => Rect.fromLTWH(x, y, 32, 24);

    double yOff = 0;
    if (colorId == 1) yOff = 75;
    else if (colorId == 2) yOff = 281;
    else if (colorId == 3) yOff = 331;
    else if (colorId == 4) yOff = 381;

    return {
      'standSouth': [r(4, 5 + yOff, 16, 21)],
      'standLeft':  [r(79, 5 + yOff, 17, 21)], // Used for Left & Right (flipped)
      'standNorth': [r(154, 4 + yOff, 16, 21)],
      
      'walkLeft':   [r(104, 5 + yOff, 16, 21), r(129, 5 + yOff, 17, 21)],
      'walkNorth':  [r(179, 4 + yOff, 17, 21), r(211, 4 + yOff, 16, 21)],
      'walkSouth':  [r(29, 5 + yOff, 17, 21), r(61, 5 + yOff, 16, 21)],
      'die': [
        rDeath(4, 29 + yOff), rDeath(37, 29 + yOff), rDeath(70, 29 + yOff), 
        rDeath(103, 29 + yOff), rDeath(136, 29 + yOff), rDeath(169, 29 + yOff), 
        rDeath(202, 29 + yOff), rDeath(235, 29 + yOff), rDeath(268, 29 + yOff)
      ]
    };
  }
}