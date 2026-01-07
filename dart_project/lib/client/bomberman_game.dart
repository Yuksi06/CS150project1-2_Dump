import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'game_controller.dart';
import '../common/constants.dart'; 
import '../common/protocol.dart'; // Ensure this is imported
import 'audio_manager.dart';

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
  
  bool _gameEnded = false;
  final Set<int> _processedDeaths = {};

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
    AudioManager().playBgm('ingame');

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

    if (!_gameEnded && snapshot.winnerId != null) {
      _gameEnded = true;
      if (snapshot.winnerId == -1) {
        AudioManager().playDrawMusic();
      } else if (snapshot.winnerId == myPlayerId) {
        AudioManager().playWinMusic();
      } else {
        AudioManager().playLoseMusic();
      }
    }

    bool amIDead = false;
    PlayerModel? myModel;
    try {
      myModel = snapshot.players.firstWhere((p) => p.id == myPlayerId);
      amIDead = myModel.isDead;
    } catch (_) {}

    // Death SFX
    for (var p in snapshot.players) {
      if (p.isDead && !_processedDeaths.contains(p.id)) {
        _processedDeaths.add(p.id);
        AudioManager().playDeath();
      }
    }

    for (var playerModel in snapshot.players) {
      if (playerModel.isDead && playerModel.id != myPlayerId) {
        if (!amIDead) {
          if (_players.containsKey(playerModel.id)) {
             final rp = _players[playerModel.id]!;
             rp.syncToModel(playerModel);

             if (rp.isVisiblyGhost) {
               remove(rp);
               _players.remove(playerModel.id);
             }
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
        AudioManager().playExplosion();
      }
    }

    // Powerup SFX Logic
    final currentIds = _powerups.keys.toSet();
    final snapshotIds = snapshot.powerups.map((p) => p.id).toSet();
    final removedIds = currentIds.difference(snapshotIds);

    for (var id in removedIds) {
      if (myModel != null && _powerups.containsKey(id)) {
        final pVisual = _powerups[id]!;
        double dx = (myModel.x) - pVisual.position.x;
        double dy = (myModel.y) - pVisual.position.y;
        if (dx.abs() < 20 && dy.abs() < 20) { 
           AudioManager().playPowerup();
        }
      }
      remove(_powerups[id]!);
      _powerups.remove(id);
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