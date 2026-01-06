import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'game_controller.dart';
import '../common/constants.dart'; 

import 'components/remote_player.dart';
import 'components/game_map.dart';
import 'components/crate_layer.dart';
import 'components/bomb_visual.dart';
import 'components/explosion_visual.dart';
import 'components/powerup_visual.dart';
import 'components/crate_destruction_visual.dart';

class BombermanGame extends FlameGame with KeyboardEvents {
  final GameController controller;
  final int myPlayerId; 

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
    int retries = 0;
    while (retries < 5) {
      try {
        await images.loadAll([
          'bombermanAndNPCs.png', 
          'ghost.png',
          'tileSet-2.png',
        ]);
        print("Assets loaded successfully.");
        break; 
      } catch (e) {
        retries++;
        print("Asset load failed (Attempt $retries/5): $e");
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }

    add(GameMap()..priority = 0);

    _crateLayer = CrateLayer()..priority = 1;
    _crateLayer.onCrateDestroyed = (pos) {
      add(CrateDestructionVisual(position: pos)..priority = 3);
    };
    add(_crateLayer);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final snapshot = controller.currentSnapshot;
    if (snapshot == null) return;

    bool amIDead = false;
    try {
      final me = snapshot.players.firstWhere((p) => p.id == myPlayerId);
      amIDead = me.isDead;
    } catch (_) {}

    for (var playerModel in snapshot.players) {
      
      // --- FIX: VISIBILITY LOGIC ---
      if (playerModel.isDead && playerModel.id != myPlayerId) {
        if (!amIDead) {
          // I am alive. I should only hide them if they are fully a Ghost.
          // If they are still playing the death animation, keep them visible.
          if (_players.containsKey(playerModel.id)) {
             final rp = _players[playerModel.id]!;
             
             // Must update model so it knows it is dead and plays anim
             rp.syncToModel(playerModel);

             if (rp.isVisiblyGhost) {
               remove(rp);
               _players.remove(playerModel.id);
             }
          }
          // Do not create NEW players if they are already dead ghosts
          else {
             // (Optional: You could allow them to spawn just to play death anim if they just died, 
             // but 'containsKey' covers the normal case of being on screen then dying)
          }
          continue; 
        }
      }

      if (_players.containsKey(playerModel.id)) {
        _players[playerModel.id]!.syncToModel(playerModel);
      } else {
        final newPlayer = RemotePlayer(playerModel);
        newPlayer.priority = 10; 
        _players[playerModel.id] = newPlayer;
        add(newPlayer);
      }
    }

    _players.keys
      .where((id) => !snapshot.players.any((p) => p.id == id))
      .toList()
      .forEach((id) {
        remove(_players[id]!);
        _players.remove(id);
      });

    _crateLayer.updateCrates(snapshot.softBlocks);

    for(var bombData in snapshot.bombs) {
      if (!_bombs.containsKey(bombData.id)) {
        final newBomb = BombVisual(bombData);
        newBomb.priority = 5; 
        _bombs[bombData.id] = newBomb;
        add(newBomb);
      }
    }

    _bombs.keys
      .where((id) => !snapshot.bombs.any((b) => b.id == id))
      .toList()
      .forEach((id) {
        remove(_bombs[id]!);
        _bombs.remove(id);
      });

    for (var explosionData in snapshot.explosions) {
      if (!_processedExplosions.contains(explosionData.id)) {
        _processedExplosions.add(explosionData.id);
        add(ExplosionVisual(explosionData)..priority = 8);
      }
    }

    for (var pData in snapshot.powerups) {
      if (!_powerups.containsKey(pData.id)) {
        final pVisual = PowerupVisual(pData);
        pVisual.priority = 2;
        _powerups[pData.id] = pVisual;
        add(pVisual);
      }
    }

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
    if (event is KeyRepeatEvent) return KeyEventResult.handled;
    
    final isDown = event is KeyDownEvent;
    final action = isDown ? 'move_start' : 'move_end';

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      controller.sendAction('bomb', '');
    }

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