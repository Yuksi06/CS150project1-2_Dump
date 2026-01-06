import '../common/protocol.dart';
import '../common/constants.dart';
import 'game_loop.dart';

import 'dart:math';

abstract class GameEntity {
  int id;
  double x;
  double y;
  bool shouldRemove = false;

  GameEntity(this.id, this.x, this.y);
  void update(double dt);
  Object? toModel();
}

class ServerGameState implements Updatable {
  final List<GameEntity> _entities = [];
  final List<GameEntity> _pendingAdditions = [];
  final Set<int> _softBlocks = {};
  
  final List<bool> _reservedSlots = [false, false, false, false];

  final double initialDuration;

  double timeRemaining;
  int? currentWinnerId;
  double restartTimer = 0;
  double gameEndDelayTimer = -1;

  bool isLobby = true;
  bool isCountdown = false;
  double startCountdownTimer = 3.0;

  ServerGameState({required double duration}) 
    : timeRemaining = duration,
      initialDuration = duration {
    _generateMap();
  }
  
  int reserveNextSlot() {
    for (int i = 0; i < 4; i++) {
      if (!_reservedSlots[i]) {
        _reservedSlots[i] = true; 
        return i;
      }
    }
    return -1;
  }

  void freeSlot(int id) {
    if (id >= 0 && id < 4) {
      _reservedSlots[id] = false;
      print("Slot $id freed.");
    }
  }

  bool get isFull => !_reservedSlots.contains(false);

  void _generateMap() {
    final rng = Random();
    for(int y = 0; y < gameHeight; y++) {
      for (int x = 0; x < gameWidth; x++) {
        if (x == 0 || x == gameWidth -1 || y == 0 || y == gameHeight -1) continue;
        if (x % 2 == 0 && y % 2 == 0) continue;

        if ((x == 1 && y == 1) || (x == 1 && y == 2) || (x == 2 && y == 1)) continue;
        if ((x == 13 && y == 11) || (x == 13 && y == 10) || (x == 12 && y == 11)) continue;
        if ((x == 13 && y == 1) || (x == 13 && y == 2) || (x == 12 && y == 1)) continue;
        if ((x == 1 && y == 11) || (x == 1 && y == 10) || (x == 2 && y == 11)) continue;

        if (rng.nextDouble() < 0.4) {
          _softBlocks.add(y * gameWidth + x);
        }
      }
    }
  }

  bool isTileSolid(int x, int y) {
    if (x < 0 || x >= gameWidth || y < 0 || y >= gameHeight) return true;
    if (x == 0 || x == gameWidth - 1 || y == 0 || y == gameHeight - 1) return true;
    if (x % 2 == 0 && y % 2 == 0) return true;
    if (_softBlocks.contains(y * gameWidth + x)) return true;
    return false;
  }

  void addEntity(GameEntity entity) {
    _pendingAdditions.add(entity);
  }

  PlayerEntity? getPlayer(int id) {
    try {
      return _entities.whereType<PlayerEntity>().firstWhere((e) => e.id == id);
    } catch (e) {
      try {
        return _pendingAdditions.whereType<PlayerEntity>().firstWhere((e) => e.id == id);
      } catch (e2) {
        return null;
      }
    }
  }

  List<PlayerEntity> getPlayers() {
    return [
      ..._entities.whereType<PlayerEntity>(),
      ..._pendingAdditions.whereType<PlayerEntity>(),
    ];
  }

  BombEntity? getBombAt(int x, int y) {
    for (var entity in _entities) {
      if (entity is BombEntity && entity.gridX == x && entity.gridY == y) {
        return entity;
      }
    }
    for (var entity in _pendingAdditions) {
      if (entity is BombEntity && entity.gridX == x && entity.gridY == y) {
        return entity;
      }
    }
    return null;
  }

  void explode(int x, int y, int range) {
    List<List<int>> fireTiles = [];
    fireTiles.add([x, y]);

    void castRay(int dx, int dy) {
      for (int i = 1; i <= range; i++) {
        int tx = x + (dx * i);
        int ty = y + (dy * i);

        if (tx < 0 || tx >= gameWidth || ty < 0 || ty >= gameHeight) break;
        if (tx == 0 || tx == gameWidth - 1 || ty == 0 || ty == gameHeight - 1) break;
        if (tx % 2 == 0 && ty % 2 == 0) break;

        BombEntity? hitBomb = getBombAt(tx, ty);
        if (hitBomb != null) {
          if (hitBomb.timer > 0.1) hitBomb.timer = 0.05;
          fireTiles.add([tx, ty]);
          break;
        }

        int blockId = ty * gameWidth + tx;
        if (_softBlocks.contains(blockId)) {
          _softBlocks.remove(blockId);
          if (Random().nextDouble() < 0.35) {
            int pId = DateTime.now().microsecondsSinceEpoch + tx;
            int type = Random().nextInt(3);
            addEntity(PowerupEntity(pId, tx, ty, type, this));
          }
          break;
        }
        fireTiles.add([tx, ty]);

        // Remove Powerups when hit by explosion
        for (var entity in _entities) {
          if (entity is PowerupEntity) {
            if (entity.x.toInt() == tx && entity.y.toInt() == ty) {
              entity.shouldRemove = true;
            }
          }
        }
      }
    }

    castRay(0, -1); 
    castRay(0, 1);  
    castRay(-1, 0); 
    castRay(1, 0);  

    int exId = -DateTime.now().microsecondsSinceEpoch;
    addEntity(ExplosionEntity(exId, fireTiles, this));
  }

  void startCountdown() {
    if (isLobby) {
      isLobby = false;
      isCountdown = true;
      startCountdownTimer = 3.0;
      print("Game Countdown Started!");
    }
  }

  @override
  void update(double dt) {
    if (isCountdown) {
      startCountdownTimer -= dt;
      if (startCountdownTimer <= 0) {
        isCountdown = false;
        print("GO!");
      }
      return;
    }
    
    if (isLobby) return;

    if (timeRemaining > 0) {
      timeRemaining -= dt;
      if (timeRemaining < 0) timeRemaining = 0;
    }

    // End Game when timer hits 0
    if (timeRemaining <= 0 && currentWinnerId == null) {
      var alivePlayers = _entities.whereType<PlayerEntity>().where((p) => !p.isDead).toList();
      if (alivePlayers.length == 1) {
        currentWinnerId = alivePlayers.first.id;
      } else {
        currentWinnerId = -1; // tie
      }
    }

    for (var entity in _entities) {
      entity.update(dt);
    }

    if (_pendingAdditions.isNotEmpty) {
      _entities.addAll(_pendingAdditions);
      _pendingAdditions.clear();
    }

    _entities.removeWhere((e) => e.shouldRemove);

    var alivePlayers = _entities.whereType<PlayerEntity>().where((p) => !p.isDead).toList();

    if (_entities.whereType<PlayerEntity>().length > 1) {
      if (alivePlayers.length <= 1) {
         if (gameEndDelayTimer == -1) {
            gameEndDelayTimer = 1.0; 
         } else {
            gameEndDelayTimer -= dt;
            if (gameEndDelayTimer <= 0) {
               if (alivePlayers.length == 1) {
                 currentWinnerId = alivePlayers.first.id;
               } else if (alivePlayers.isEmpty) {
                 currentWinnerId = -1; 
               }
            }
         }
      } else {
         gameEndDelayTimer = -1; 
      }
    }

    if (currentWinnerId != null) {
      restartTimer += dt;
      if (restartTimer > 5.0) {
        _resetGame();
      }
    }
  }

  void _resetGame() {
    print("Restarting Game...");
    
    timeRemaining = initialDuration;

    currentWinnerId = null;
    restartTimer = 0;
    gameEndDelayTimer = -1; 
    _softBlocks.clear();
    _pendingAdditions.clear();
    _entities.removeWhere((e) => e is! PlayerEntity);

    for (var entity in _entities) {
      if (entity is PlayerEntity) {
        entity.isDead = false;
        entity.shouldRemove = false;
        entity.speed = 120.0; 
        entity.explosionRange = 1;
        entity.maxBombs = 1;
        entity.isReady = false; 

        if (entity.id == 0) { entity.x = 1.0 * 32.0; entity.y = 1.0 * 32.0; }
        else if (entity.id == 1) { entity.x = (gameWidth - 2.0) * 32.0; entity.y = (gameHeight - 2.0) * 32.0; }
        else if (entity.id == 2) { entity.x = (gameWidth - 2.0) * 32.0; entity.y = 1.0 * 32.0; }
        else if (entity.id == 3) { entity.x = 1.0 * 32.0; entity.y = (gameHeight - 2.0) * 32.0; }
      }
    }
    _generateMap();
    isLobby = true;
    isCountdown = false;
    print("Server is back in Lobby Mode");
  }

  GameStateModel getSnapshot() {
    List<PlayerModel> players = [
        ..._entities.whereType<PlayerEntity>(),
        ..._pendingAdditions.whereType<PlayerEntity>()
      ].map((p) => p.toModel()).toList();
      
    List<BombModel> bombs = _entities
        .whereType<BombEntity>()
        .map((b) => b.toModel()) 
        .toList();
    
    List<List<int>> blocks = _softBlocks.map((encoded) {
      int y = encoded ~/ gameWidth;
      int x = encoded % gameWidth;
      return [x, y];
    }).toList();

    List<ExplosionModel> explosions = _entities
      .whereType<ExplosionEntity>()
      .map((e) => e.toModel())
      .toList();

    List<PowerupModel> powerups = _entities
      .whereType<PowerupEntity>()
      .map((e) => e.toModel())
      .toList();
    
    return GameStateModel(
      players: players,
      softBlocks: blocks,
      bombs: bombs, 
      explosions: explosions,
      powerups: powerups,
      timeRemaining: timeRemaining,
      winnerId: currentWinnerId,
    );
  }
}

class PlayerEntity extends GameEntity {
  final int colorId;
  final ServerGameState state;
  bool isDead = false;
  bool isReady = false;

  double speed = 120.0; 
  
  int maxBombs = 1;
  int activeBombs = 0;
  int explosionRange = 1;

  final List<String> _inputStack = [];
  final double size = 0.5; 

  PlayerEntity(int id, double x, double y, this.colorId, this.state) : super(id, x, y);

  @override
  void update(double dt) {
    
    if (state.currentWinnerId != null) {
      _inputStack.clear();
      return;
    }

    if (isDead) {
       if (_inputStack.isEmpty) return;
       final direction = _inputStack.last;
       double nextX = x;
       double nextY = y;
       
       double ghostSpeed = 150.0; 

       switch(direction) {
         case 'up':    nextY -= ghostSpeed * dt; break;
         case 'down':  nextY += ghostSpeed * dt; break;
         case 'left':  nextX -= ghostSpeed * dt; break;
         case 'right': nextX += ghostSpeed * dt; break;
       }
       
       // Ghost clipping (Walls 0..W-1)
       if (nextX >= 0.0 && nextX <= (gameWidth - 1) * 32.0) x = nextX;
       if (nextY >= 0.0 && nextY <= (gameHeight - 1) * 32.0) y = nextY;
       return;
    }

    if (_inputStack.isEmpty) return;

    final direction = _inputStack.last;
    double nextX = x;
    double nextY = y;

    switch(direction) {
      case 'up':    nextY -= speed * dt; break;
      case 'down':  nextY += speed * dt; break;
      case 'left':  nextX -= speed * dt; break;
      case 'right': nextX += speed * dt; break;
    }

    if (!_checkCollision(nextX, y)) {
      x = nextX;
    }
    if (!_checkCollision(x, nextY)) {
      y = nextY;
    }
  }

  bool _checkCollision(double newX, double newY) {
    final double margin = (32.0 * (1.0 - size)) / 2.0; 

    double left = newX + margin;
    double right = newX + 32.0 - margin;
    double top = newY + margin;
    double bottom = newY + 32.0 - margin;

    bool hitTerrain(double px, double py) {
      return state.isTileSolid((px / 32).floor(), (py / 32).floor());
    }

    if (hitTerrain(left, top) || hitTerrain(right, top) ||
        hitTerrain(left, bottom) || hitTerrain(right, bottom)) {
      return true;
    }

    bool hitsBlockingBomb(double px, double py) {
      int tx = (px / 32).floor();
      int ty = (py / 32).floor();
      
      if (state.getBombAt(tx, ty) == null) return false;

      if (_doesRectOverlapTile(x, y, tx, ty)) {
         return false; 
      }
      return true; 
    }

    if (hitsBlockingBomb(left, top) || hitsBlockingBomb(right, top) ||
        hitsBlockingBomb(left, bottom) || hitsBlockingBomb(right, bottom)) {
      return true;
    }

    return false;
  }

  bool _doesRectOverlapTile(double playerX, double playerY, int tileX, int tileY) {
    final double margin = (32.0 * (1.0 - size)) / 2.0;
    double pLeft = playerX + margin;
    double pRight = playerX + 32.0 - margin;
    double pTop = playerY + margin;
    double pBottom = playerY + 32.0 - margin;

    double tLeft = tileX * 32.0;
    double tRight = (tileX + 1) * 32.0;
    double tTop = tileY * 32.0;
    double tBottom = (tileY + 1) * 32.0;

    return pLeft < tRight && pRight > tLeft &&
           pTop < tBottom && pBottom > tTop;
  }

  void restoreAmmo() {
    activeBombs--;
    if (activeBombs < 0) activeBombs = 0;
  }

  void handleCommand(String action, String direction) {
    if (action == 'ready') {
      isReady = direction == 'true';
      return;
    }

    if (action == 'start_game') {
      if (id == 0) {
        isReady = true;
        final allPlayers = state.getPlayers();
        final othersReady = allPlayers.where((p) => p.id != 0).every((p) => p.isReady);
        if (allPlayers.isNotEmpty && othersReady) {
           print("Host started game.");
           state.startCountdown(); 
        }
      }
    }

    if (state.currentWinnerId != null) {
      return;
    }

    if (isDead) {
       if (action == 'move_start') {
          if (!_inputStack.contains(direction)) _inputStack.add(direction);
       } else if (action == 'move_end') {
          _inputStack.remove(direction);
       }
       return; 
    }

    if (action == 'move_start') {
      if (!_inputStack.contains(direction)) {
        _inputStack.add(direction);
      }
    } else if (action == 'move_end') {
      _inputStack.remove(direction);
    } else if (action == 'bomb') {
      if (activeBombs >= maxBombs) return;
      int gx = (x / 32 + 0.5).floor();
      int gy = (y / 32 + 0.5).floor();
      if (state.getBombAt(gx, gy) != null) return;  

      activeBombs++;
      int bombId = DateTime.now().microsecondsSinceEpoch;
      state.addEntity(BombEntity(bombId, gx, gy, id, state, explosionRange, this));
    }
  }

  @override
  PlayerModel toModel() {
    return PlayerModel(id: id, x: x, y: y, colorId: colorId, isDead: isDead, isReady: isReady);
  }
}

class BombEntity extends GameEntity {
  double timer = 3.0;
  final int range;
  final int ownerId;
  final ServerGameState state;
  final PlayerEntity? owner;

  BombEntity(int id, int gridX, int gridY, this.ownerId, this.state, this.range, this.owner) 
    : super(id, gridX.toDouble(), gridY.toDouble());

  @override
  void update(double dt) {
    timer -= dt;
    if (timer <= 0) {
      shouldRemove = true;
      state.explode(gridX, gridY, range);
      owner?.restoreAmmo();
    }
  }

  int get gridX => x.toInt();
  int get gridY => y.toInt();

  @override
  BombModel toModel() {
    return BombModel(id: id, x: gridX, y: gridY); 
  }   
}

class ExplosionEntity extends GameEntity {
  double timer = 1.0; 
  final List<List<int>> tiles;
  final ServerGameState state;

  ExplosionEntity(int id, this.tiles, this.state) : super(id, 0, 0);

  @override
  void update(double dt) {
    timer -= dt;
    if (timer <= 0) shouldRemove = true;

    for (var player in state.getPlayers()) {
      if (player.isDead) continue; 
      int px = (player.x / 32 + 0.5).floor();
      int py = (player.y / 32 + 0.5).floor();

      for (var tile in tiles) {
        if (tile[0] == px && tile[1] == py) {
          player.isDead = true;
        }
      }
    }
  }

  @override
  ExplosionModel toModel() {
    return ExplosionModel(id: id, affectedTiles: tiles);
  }
}

class PowerupEntity extends GameEntity {
  final int type; 
  final ServerGameState state;

  PowerupEntity(int id, int x, int y, this.type, this.state)
    : super(id, x.toDouble(), y.toDouble());

  @override
  void update(double dt) {
    for (var player in state.getPlayers()) {
      if (player.isDead) continue; 
      int px = (player.x / 32 + 0.5).floor();
      int py = (player.y / 32 + 0.5).floor();

      if (px == x && py == y) {
        if (type == 0) player.explosionRange++;
        else if (type == 1) {
          if (player.speed < 250.0) player.speed += 40.0; 
        } else if (type == 2) player.maxBombs++;
        shouldRemove = true;
      }
    }
  }

  @override
  PowerupModel toModel() {
    return PowerupModel(id: id, x: x.toInt(), y: y.toInt(), type: type);
  }
}