import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../common/protocol.dart';

class GameController {
  WebSocketChannel? _channel;
  GameStateModel? currentSnapshot; 
  Function(GameStateModel)? onStateUpdated;

  int _myPlayerId = -1;
  int get myPlayerId => _myPlayerId;

  bool get isConnected => _channel != null;

  Future<void> connect(String ip, int port) async {
    final url = 'ws://$ip:$port';
    try {
      print("[Client] Connecting to $url...");
      _channel = WebSocketChannel.connect(Uri.parse(url));

      await _channel!.ready; 
      print("[Client] Connected!");

      final Completer<void> connectionCompleter = Completer<void>();

      _channel!.stream.listen(
        (data) {
          // --- FIX: Handle Merged Packets ---
          final String packet = data.toString().trim();
          final List<String> messages = packet.split('\n');

          for (String msg in messages) {
            if (msg.isEmpty) continue;
            try {
              final jsonMap = jsonDecode(msg);
              
              // Handshake
              if (jsonMap is Map && jsonMap['type'] == 'handshake') {
                _myPlayerId = jsonMap['id'];
                print("[Client] Handshake received. I am Player $_myPlayerId");
                
                if (!connectionCompleter.isCompleted) {
                  connectionCompleter.complete();
                }
                continue; 
              }

              // Game State
              currentSnapshot = GameStateModel.fromJson(jsonMap);
              onStateUpdated?.call(currentSnapshot!);
              
            } catch (e) {
              print("[Client] Error parsing packet segment: $e");
            }
          }
        },
        onError: (error) {
           print("[Client] WS Error: $error");
           if (!connectionCompleter.isCompleted) connectionCompleter.completeError(error);
        },
        onDone: () {
           print("[Client] WS Connection Closed");
           if (!connectionCompleter.isCompleted) {
             connectionCompleter.completeError(Exception("Server Full or Closed"));
           }
        },
      );

      await connectionCompleter.future.timeout(
        const Duration(seconds: 5), 
        onTimeout: () => throw Exception("Connection Timed Out")
      );

    } catch (e) {
      print("[Client] Connection Failed: $e");
      disconnect();
      rethrow;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void sendAction(String action, String payload) {
    if (_channel == null) return;
    _channel!.sink.add("$action:$payload");
  }

  void sendMove(String direction) {
    sendAction('move_start', direction);
  }
}