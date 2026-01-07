import 'dart:isolate';
import 'dart:io';
import 'dart:async';
import 'game_loop.dart';
import 'game_state.dart';
import 'client_connection.dart';

void runServerIsolate(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final int port = args[1] as int;
  
  final int playerCount = args[2] as int;
  
  final int duration = args[3] as int;

  print("[Server] Starting Game Loop with duration: $duration, Players: $playerCount");
  final state = ServerGameState(duration: duration.toDouble());
  
  state.setPlayerLimit(playerCount);

  final gameLoop = GameLoop(state);
  gameLoop.start();

  final List<ClientConnection> clients = [];

  Timer.periodic(const Duration(milliseconds: 50), (timer) {
    try {
      clients.removeWhere((c) => c.socket.readyState != WebSocket.open);
      
      final snapshot = state.getSnapshot();
      if (clients.isNotEmpty) {
        for (var client in clients) {
           client.sendSnapshot(snapshot);
        }
      }
    } catch (e) {
      print("Server Loop Error: $e");
    }
  });

  try {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print('[Server] Listening on $port...');
    sendPort.send(true);

    await for (HttpRequest request in server) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        
        // 1. LOCK CHECK: Is game running?
        if (!state.isLobby) {
           print("[Server] Connection Rejected: Game in Progress");
           request.response.statusCode = HttpStatus.forbidden; 
           await request.response.close();
           continue; 
        }

        // 2. FULL CHECK: Are all slots reserved?
        if (state.isFull) {
           print("[Server] Connection Rejected: Lobby Full");
           request.response.statusCode = HttpStatus.serviceUnavailable;
           await request.response.close();
           continue; 
        }

        // 3. Connect
        final socket = await WebSocketTransformer.upgrade(request);
        final connection = ClientConnection(socket, state);
        if (connection.player.id != -1) {
             clients.add(connection);
        }
      }
    }
  } catch (e) {
    print('[Server] Bind Error: $e');
    sendPort.send(false);
  }
}