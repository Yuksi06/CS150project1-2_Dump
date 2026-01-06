import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart'; // Added for CameraComponent
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_controller.dart';
import '../common/constants.dart'; 

import 'components/remote_player.dart';
import 'components/game_map.dart';
import 'components/crate_layer.dart';
import 'components/bomb_visual.dart';
import 'components/explosion_visual.dart';
import 'components/powerup_visual.dart';

class BombermanGame extends FlameGame with KeyboardEvents {
  final GameController controller;
  final int myPlayerId; // Added myPlayerId

  // Keep track of visual objects
  final Map<int, RemotePlayer> _players = {};
  late CrateLayer _crateLayer;
  final Map<int, BombVisual> _bombs = {};
  final Set<int> _processedExplosions = {};
  final Map<int, PowerupVisual> _powerups = {};

  BombermanGame({required this.controller, required this.myPlayerId}) {
    camera = CameraComponent.withFixedResolution(
      width: gameWidth * 32.0, 
      height: gameHeight * 32.0
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    // Add Game Map
    add(GameMap());

    // Add Crate Layer on top of the Map, but below Players
    _crateLayer = CrateLayer();
    add(_crateLayer);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final snapshot = controller.currentSnapshot;
    if (snapshot == null) return;

    // Sync players
    // 1. Update or Create Players that exist in the snapshot
    for (var playerModel in snapshot.players) {
      
      // GHOST VISIBILITY LOGIC:
      // If player is dead AND not me, skip visuals (Invisible Ghost)
      if (playerModel.isDead && playerModel.id != myPlayerId) {
        if (_players.containsKey(playerModel.id)) {
          remove(_players[playerModel.id]!);
          _players.remove(playerModel.id);
        }
        continue; 
      }

      if (_players.containsKey(playerModel.id)) {
        // Update existing
        _players[playerModel.id]!.syncToModel(playerModel);
      } else {
        // Create new
        final newPlayer = RemotePlayer(playerModel);
        _players[playerModel.id] = newPlayer;
        add(newPlayer);
        print("Added visual for Player ${playerModel.id}");
      }
    }

    // 2. Remove players that are no longer in the snapshot
    _players.keys
      .where((id) => !snapshot.players.any((p) => p.id == id))
      .toList()
      .forEach((id) {
        remove(_players[id]!);
        _players.remove(id);
      });

    // Sync Crates
    _crateLayer.updateCrates(snapshot.softBlocks);

    // Sync Bombs
    // 1. Add new bombs
    for(var bombData in snapshot.bombs) {
      if (!_bombs.containsKey(bombData.id)) {
        final newBomb = BombVisual(bombData);
        _bombs[bombData.id] = newBomb;
        add(newBomb);
      }
    }

    // 2. Remove exploded bombs
    _bombs.keys
      .where((id) => !snapshot.bombs.any((b) => b.id == id))
      .toList()
      .forEach((id) {
        remove(_bombs[id]!);
        _bombs.remove(id);
      });

    // Sync Explosions
    for (var explosionData in snapshot.explosions) {
      if (!_processedExplosions.contains(explosionData.id)) {
        // 1. Mark as seen
        _processedExplosions.add(explosionData.id);

        // 2. Add Visual
        add(ExplosionVisual(explosionData));

        print("Boom! Visual added for ${explosionData.id}");
      }
    }

    // Sync Powerups
    // 1. Add new powerups
    for (var pData in snapshot.powerups) {
      if (!_powerups.containsKey(pData.id)) {
        final pVisual = PowerupVisual(pData);
        _powerups[pData.id] = pVisual;
        add(pVisual);
      }
    }

    // 2. Remove picked up powerups
    _powerups.keys
      .where((id) => !snapshot.powerups.any((p) => p.id == id))
      .toList()
      .forEach((id) {
        remove(_powerups[id]!);
        _powerups.remove(id);
      });
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }
    
    final isDown = event is KeyDownEvent;
    final action = isDown ? 'move_start' : 'move_end';

    // Bomb
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      controller.sendAction('bomb', '');
    }

    // Movement
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      controller.sendAction(action, 'up');
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      controller.sendAction(action, 'down');
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      controller.sendAction(action, 'left');
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      controller.sendAction(action, 'right');
    }

    return KeyEventResult.handled;
  }
}