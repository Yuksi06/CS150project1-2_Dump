import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_controller.dart';
import '../common/protocol.dart';
import 'game_screen_overlay.dart'; 

class LobbyScreen extends StatefulWidget {
  final GameController controller;
  final int myPlayerId; 
  final bool isHost;

  const LobbyScreen({
    super.key, 
    required this.controller, 
    required this.myPlayerId,
    this.isHost = false,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with SingleTickerProviderStateMixin {
  GameStateModel? _latestState;
  bool _amIReady = false;
  bool _launching = false; 
  late AnimationController _blinkController;

  final List<Color> _playerColors = [
    Colors.white, Colors.black, Colors.red, Colors.green,
  ];

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    
    widget.controller.onStateUpdated = (state) {
      if (mounted) {
        setState(() => _latestState = state);
        if (!_launching && state.players.isNotEmpty && state.players.length >= 2) {
          if (state.players.every((p) => p.isReady)) {
             _launchGame();
          }
        }
      }
    };
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      if (widget.isHost) {
        _tryHostStart();
      } else {
        _toggleReady();
      }
    } else if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
    }
  }

  void _toggleReady() {
    setState(() => _amIReady = !_amIReady);
    // Send boolean for ready
    widget.controller.sendAction('ready', _amIReady.toString());
  }

  void _tryHostStart() {
    if (_latestState == null) return;
    final players = _latestState!.players;
    final others = players.where((p) => p.id != widget.myPlayerId).toList();
    
    bool canStart = others.isNotEmpty && others.every((p) => p.isReady);

    if (canStart) {
      if (!_amIReady) {
         _amIReady = true;
         widget.controller.sendAction('ready', 'true');
      }
      widget.controller.sendAction('start_game', 'true');
    }
  }

  void _launchGame() {
    setState(() => _launching = true);
    widget.controller.onStateUpdated = null; 
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const GameScreenOverlay(),
        settings: RouteSettings(arguments: {
          'controller': widget.controller,
          'myPlayerId': widget.myPlayerId, // This is now correct from Main
          'isHost': widget.isHost,
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_latestState == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    final players = _latestState!.players;
    
    bool canStart = false;
    if (widget.isHost) {
      final others = players.where((p) => p.id != widget.myPlayerId).toList();
      if (others.isNotEmpty) canStart = others.every((p) => p.isReady);
    }

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF2C2C2C),
        body: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Container(
              width: 550, 
              height: 600,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("BATTLE LOBBY", 
                    style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 30),

                  ...List.generate(4, (index) {
                    final player = players.firstWhere(
                      (p) => p.id == index, 
                      orElse: () => PlayerModel(id: -1, x: 0, y: 0, colorId: 0, isDead: true, isReady: false)
                    );
                    
                    final isConnected = player.id != -1;
                    final isReady = isConnected && player.isReady;
                    final isHostSlot = (index == 0); 
                    final color = _playerColors[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        border: Border.all(
                          color: isReady ? Colors.yellow : (isConnected ? Colors.green : Colors.grey[800]!), 
                          width: 2
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(color: isConnected ? color : Colors.transparent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            isConnected ? "PLAYER ${index + 1}" : "EMPTY",
                            style: GoogleFonts.pressStart2p(color: isConnected ? Colors.white : Colors.grey, fontSize: 14),
                          ),
                          const Spacer(),
                          if (isConnected) 
                            if (isHostSlot)
                              Text("HOST", style: GoogleFonts.pressStart2p(color: Colors.green, fontSize: 12))
                            else
                              Row(
                                children: [
                                  Text(isReady ? "READY" : "WAIT", 
                                    style: GoogleFonts.pressStart2p(color: isReady ? Colors.green : Colors.grey, fontSize: 12)
                                  ),
                                  const SizedBox(width: 10),
                                  Text(isReady ? "✅" : "...", style: TextStyle(fontSize: 12)
                                  ),
                                ],
                              )
                        ],
                      ),
                    );
                  }),

                  const Spacer(),

                  AnimatedBuilder(
                    animation: _blinkController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _blinkController.value,
                        child: Text(
                          widget.isHost 
                            ? (canStart ? "PRESS SPACE TO START" : "WAITING FOR PLAYERS...")
                            : (_amIReady ? "READY! (WAITING FOR HOST)" : "PRESS SPACE TO READY"),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            color: widget.isHost 
                                ? (canStart ? Colors.green : Colors.grey) 
                                : (_amIReady ? Colors.yellow : Colors.white),
                            fontSize: 12
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}