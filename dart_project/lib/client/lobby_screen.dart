import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_controller.dart';
import '../common/protocol.dart';
import 'game_screen_overlay.dart'; 
import 'audio_manager.dart';

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
  
  // Sticky Limit: Default to 4 until Server tells us otherwise via Time
  int _lobbyLimit = 4;

  late AnimationController _blinkController;

  final List<Color> _playerColors = [
    Colors.white, Colors.black, Colors.red, Colors.blue, Colors.green,
  ];

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    AudioManager().playBgm('opening');
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    
    widget.controller.onStateUpdated = (state) {
      if (mounted) {
        setState(() {
          _latestState = state;
          
          // --- SYNC LIMIT ---
          // If time is small (e.g. 2, 3, 4, 5), it's the limit.
          if (state.timeRemaining > 1.5 && state.timeRemaining < 6.0) {
             _lobbyLimit = state.timeRemaining.toInt();
          }
        });
        
        if (!_launching && state.players.isNotEmpty && state.players.length >= _lobbyLimit) {
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
      // Allow ready only if full
      if (_latestState != null && _latestState!.players.length >= _lobbyLimit) {
         _toggleReady();
      }
    } else if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
    }
  }

  void _toggleReady() {
    setState(() => _amIReady = !_amIReady);
    widget.controller.sendAction('ready', _amIReady.toString());
  }

  void _launchGame() {
    if (_launching) return;
    setState(() => _launching = true);
    widget.controller.onStateUpdated = null; 
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const GameScreenOverlay(),
        settings: RouteSettings(arguments: {
          'controller': widget.controller,
          'myPlayerId': widget.myPlayerId,
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
    final int connectedCount = players.length;
    final bool isLobbyFull = connectedCount >= _lobbyLimit;

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF2C2C2C),
        body: Stack(
          children: [
            Center(
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

                      ...List.generate(_lobbyLimit, (index) {
                        final player = players.firstWhere(
                          (p) => p.id == index, 
                          // FIX: Removed 'direction' parameter
                          orElse: () => PlayerModel(id: -1, x: 0, y: 0, colorId: 0, isDead: true, isReady: false)
                        );
                        
                        final isConnected = player.id != -1;
                        final isReady = isConnected && player.isReady;
                        final isHostSlot = (index == 0); 
                        final color = _playerColors[index % _playerColors.length];

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
                                isConnected ? "PLAYER ${index + 1}" : "WAITING...",
                                style: GoogleFonts.pressStart2p(color: isConnected ? Colors.white : Colors.grey, fontSize: 14),
                              ),
                              const Spacer(),
                              if (isConnected && isHostSlot)
                                    Text("HOST", style: GoogleFonts.pressStart2p(color: Colors.green, fontSize: 12))
                            ],
                          ),
                        );
                      }),

                      const Spacer(),

                      // Hide bottom text if Overlay is active
                      if (!isLobbyFull)
                        Text(
                          "WAITING FOR PLAYERS ($connectedCount/$_lobbyLimit)...",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // --- READY CONFIRMATION OVERLAY ---
            if (isLobbyFull)
              Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Container(
                    width: 450,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: _amIReady ? Colors.yellow : Colors.green, width: 4),
                      boxShadow: [
                         BoxShadow(color: _amIReady ? Colors.yellowAccent.withOpacity(0.5) : Colors.greenAccent.withOpacity(0.5), blurRadius: 20)
                      ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _amIReady ? "YOU ARE READY!" : "ARE YOU READY?",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            color: Colors.white, 
                            fontSize: 22,
                            height: 1.5
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        AnimatedBuilder(
                          animation: _blinkController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _blinkController.value,
                              child: Text(
                                _amIReady ? "WAITING FOR OTHERS..." : "PRESS [SPACE] TO CONFIRM",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.pressStart2p(
                                  color: _amIReady ? Colors.grey : Colors.yellow,
                                  fontSize: 14
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 30),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: players.map((p) {
                             if (p.id >= _lobbyLimit) return const SizedBox();
                             return Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 10),
                               child: Column(
                                 children: [
                                   Icon(
                                     p.isReady ? Icons.check_circle : Icons.hourglass_empty,
                                     color: p.isReady ? Colors.green : Colors.grey,
                                     size: 40,
                                   ),
                                   const SizedBox(height: 5),
                                   Text("P${p.id+1}", style: const TextStyle(color: Colors.white, fontSize: 10))
                                 ],
                               ),
                             );
                          }).toList(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}