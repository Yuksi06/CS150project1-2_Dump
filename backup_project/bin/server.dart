import 'dart:io';
import 'package:dart_project/server/game_loop.dart';
import 'package:dart_project/server/game_state.dart';
import 'package:dart_project/server/client_connection.dart';

void main(List<String> args) async {
  // 1. Dynamic Port (Phase 5 Requirement)
  int port = 15000;
  if (args.isNotEmpty) {
    port = int.tryParse(args[0]) ?? 15000;
  }

  // 2. Setup Game
  final state = ServerGameState(duration: 300);
  final gameLoop = GameLoop(state);
  gameLoop.start();

  // 3. Start Server
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Server running on port $port');
  
  // 4. Handle Connections
  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      
      if (state.getPlayers().length >= 4) {
        print('Connection rejected: Server Full (4/4)');
        request.response.statusCode = HttpStatus.serviceUnavailable;
        request.response.write('Server Full');
        await request.response.close();
      } else {
        // Accept
        final socket = await WebSocketTransformer.upgrade(request);
        
        ClientConnection(socket, state); 
        print("Player joined. Count: ${state.getPlayers().length + 1}");
      }

    } else {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  }
}