class PlayerModel {
  final int id;
  final double x;
  final double y;
  final int colorId;  // 0 = White, 1 = Black, 2 = Red, 3 = Green
  final bool isDead;
  final bool isReady;

  PlayerModel({
    required this.id,
    required this.x,
    required this.y,
    required this.colorId,
    this.isDead = false,
    this.isReady = false,
  });

  // Convert generic JSON Map to PlayerModel type
  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      colorId: json['colorId'],
      isDead: json['isDead'] ?? false,
      isReady: json['isReady'] ?? false,
    );
  }

  // Convert this object back to JSON Map
  Map<String, dynamic> toJson() => {
      'id': id,
      'x': x,
      'y': y,
      'colorId': colorId,
      'isDead': isDead,
      'isReady': isReady,
  };
}

// Bomb Model
class BombModel {
  final int id;
  final int x;
  final int y;

  BombModel({
    required this.id,
    required this.x,
    required this.y,
  });

  factory BombModel.fromJson(Map<String, dynamic> json) {
    return BombModel(
      id: json['id'],
      x: json['x'],
      y: json['y'],
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'x': x,
      'y': y,
  };
}

class ExplosionModel {
  final int id; // ID to avoid re-animation
  final List<List<int>> affectedTiles; // List of [x, y] coordinates

  ExplosionModel({
    required this.id,
    required this.affectedTiles,
  });

  factory ExplosionModel.fromJson(Map<String, dynamic> json) {
    var outerList = json['affectedTiles'] as List;

    var tList = outerList.map((row) {
      return (row as List).map((e) => e as int).toList();
    }).toList();
    return ExplosionModel(id: json['id'], affectedTiles: tList);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'affectedTiles': affectedTiles,
  };
}

class PowerupModel {
  final int id;
  final int x;
  final int y;
  final int type; // 0 = Range, 1 = Speed

  PowerupModel({required this.id, 
    required this.x, 
    required this.y, 
    required this.type,
  });

  factory PowerupModel.fromJson(Map<String, dynamic> json) {
    return PowerupModel(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'x': x, 'y': y, 'type': type};
}

// Game State Snapshot
class GameStateModel {
  final List<PlayerModel> players;
  final List<List<int>> softBlocks; // List of [x, y] coordinates
  final List<BombModel> bombs;
  final List<ExplosionModel> explosions;
  final double timeRemaining;
  final int? winnerId;
  final List<PowerupModel> powerups;

  GameStateModel({
    required this.players,
    required this.softBlocks,
    required this.bombs,
    required this.explosions,
    required this.powerups,
    required this.timeRemaining,
    this.winnerId,
  });

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    var pList = (json['players'] as List).map((i) => PlayerModel.fromJson(i)).toList();

    var bList = (json['softBlocks'] as List).map((row) {
      return (row as List).map((e) => e as int).toList();
    }).toList();

    var bombList = (json['bombs'] as List? ?? []).map((i) => BombModel.fromJson(i)).toList();
    
    var exList = (json['explosions'] as List? ?? []).map((i) => ExplosionModel.fromJson(i)).toList();

    var pUpList = (json['powerups'] as List? ?? []).map((i) => PowerupModel.fromJson(i)).toList();


    return GameStateModel(
      players: pList,
      softBlocks: bList,
      bombs: bombList,
      explosions: exList,
      powerups: pUpList,
      timeRemaining: (json['timeRemaining'] as num).toDouble(),
      winnerId: json['winnerId'],
    );
  }

  Map<String, dynamic> toJson() => {
      'players': players.map((p) => p.toJson()).toList(),
      'softBlocks': softBlocks,
      'bombs': bombs.map((b) => b.toJson()).toList(),
      'explosions': explosions.map((e) => e.toJson()).toList(),
      'powerups': powerups,
      'timeRemaining': timeRemaining,
      'winnerId': winnerId,
  };
}

class ClientMessage {
  final String action; // "move", "bomb", etc.
  final String? direction; // "up", "down", "left", "right" for move action

  ClientMessage({
    required this.action,
    this.direction,
  });

  factory ClientMessage.fromJson(Map<String, dynamic> json) {
    return ClientMessage(
      action: json['action'],
      direction: json['direction'],
    );
  }

  Map<String, dynamic> toJson() => {
      'action': action,
      if (direction != null) 'direction': direction,
  };
}