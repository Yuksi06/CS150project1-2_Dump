import 'dart:io';
import 'dart:convert';
import 'game_state.dart';
import '../common/protocol.dart';

class ClientConnection {
  final WebSocket socket;
  final ServerGameState state;
  late final PlayerEntity player;

  ClientConnection(this.socket, this.state) {
    int assignedId = state.reserveNextSlot(); 

    if (assignedId == -1) {
      print("[Connection] Rejected: Server Full");
      socket.close(WebSocketStatus.normalClosure, "Server Full");
      return;
    }

    sendHandshake(assignedId);

    int colorId = assignedId;
    double startX = 1.0; 
    double startY = 1.0;
    
    if (assignedId == 0) { startX = 1.0; startY = 1.0; }
    if (assignedId == 1) { startX = 13.0; startY = 11.0; }
    if (assignedId == 2) { startX = 13.0; startY = 1.0; }
    if (assignedId == 3) { startX = 1.0;  startY = 11.0; }

    player = PlayerEntity(assignedId, startX * 32.0, startY * 32.0, colorId, state);
    state.addEntity(player);

    print("Client Connected: Slot $assignedId Locked.");

    socket.listen(
      (data) {
        handleMessage(data);
      },
      onDone: () {
        print("Client Disconnected: Player $assignedId");
        state.freeSlot(assignedId); 
        player.shouldRemove = true; 
        player.isDead = true; 
      },
      onError: (error) {
        state.freeSlot(assignedId); 
        player.shouldRemove = true;
      },
    );
  }

  void handleMessage(dynamic data) {
    if (player.shouldRemove) return; 
    if (data is String) {
      final parts = data.split(':');
      if (parts.length == 2) {
        player.handleCommand(parts[0], parts[1]);
      }
    }
  }

  // --- FIX: Add \n to delimiters ---
  void sendHandshake(int id) {
    if (socket.readyState == WebSocket.open) {
      // Append newline!
      socket.add(jsonEncode({'type': 'handshake', 'id': id}) + "\n");
    }
  }

  void sendSnapshot(GameStateModel snapshot) {
    if (socket.readyState == WebSocket.open) {
      // Append newline!
      socket.add(jsonEncode(snapshot.toJson()) + "\n");
    }
  }
}