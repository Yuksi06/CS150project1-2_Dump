import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'game_controller.dart';
import 'bomberman_game.dart';
import 'lobby_screen.dart'; 

class GameScreenOverlay extends StatefulWidget {
  const GameScreenOverlay({super.key});

  @override
  State<GameScreenOverlay> createState() => _GameScreenOverlayState();
}

class _GameScreenOverlayState extends State<GameScreenOverlay> {
  String _centerText = "READY";
  Color _centerTextColor = Colors.white;
  bool _showOverlay = true;
  GameController? _controller;
  
  int _timeLeft = 300;
  
  List<bool> _isAlive = [true, true, true, true, true];
  List<int> _playerLives = [0, 0, 0, 0, 0]; 
  
  int _totalPlayers = 0; 
  int? _previousWinnerId;
  int _myId = -1;
  bool _isHost = false; 

  BombermanGame? _gameInstance;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _centerText = "GET SET");
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _centerText = "BOMB TIME!");
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _showOverlay = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_controller == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _controller = args['controller'] as GameController;
      _myId = _controller!.myPlayerId;
      _isHost = args['isHost'] as bool; 

      _gameInstance = BombermanGame(
        controller: _controller!, 
        myPlayerId: _controller!.myPlayerId,
        );

      _controller!.onStateUpdated = (state) {
        if (!mounted) return;

        setState(() {
          if (state.winnerId == null) {
             _timeLeft = state.timeRemaining.toInt();
          }

          if (_totalPlayers == 0 && state.players.isNotEmpty) {
             _totalPlayers = state.players.length;
          }

          for (var p in state.players) {
            if (p.id >= 0 && p.id < 5) {
              _isAlive[p.id] = !p.isDead;
              // SYNC LIVES HERE
              _playerLives[p.id] = p.extraLives; 
            }
          }
        });

        if (state.winnerId != null) {
          if (!_showOverlay) {
            setState(() {
              _showOverlay = true;
              if (state.winnerId == -1) {
                _centerText = "DRAW!";
                _centerTextColor = Colors.white;
              } else if (state.winnerId == _myId) {
                _centerText = "YOU WIN!";
                _centerTextColor = Colors.yellowAccent; 
              } else {
                _centerText = "PLAYER ${state.winnerId! + 1} WINS!";
                _centerTextColor = Colors.redAccent; 
              }
            });
          }
          _previousWinnerId = state.winnerId;
        }

        if (_previousWinnerId != null && state.winnerId == null) {
          _controller!.onStateUpdated = null;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LobbyScreen(
                controller: _controller!, 
                myPlayerId: _myId, 
                isHost: _isHost,
              ),
            ),
          );
        }
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _gameInstance == null) return const SizedBox(); 

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          Container(
            height: 80,
            color: const Color(0xFF0060B0),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text("⏰", style: TextStyle(fontSize: 24)), 
                const SizedBox(width: 10),
                Text(
                  _formatTime(_timeLeft),
                  style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 20, letterSpacing: 2.0),
                ),

                const Spacer(),

                for (int i = 0; i < 5; i++)
                  if (i < _totalPlayers) ...[
                    _buildPlayerStatus(i),
                    // HUGE SPACING to prevent overlaps
                    const SizedBox(width: 45), 
                  ]
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 15 * 32.0,  
                    height: 13 * 32.0, 
                    child: Stack(
                      children: [
                        GameWidget(game: _gameInstance!),

                        if (_showOverlay)
                          Container(
                            color: Colors.black.withOpacity(0.7),
                            child: Center(
                              child: Text(
                                _centerText,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 35,
                                  color: _centerTextColor, 
                                  shadows: [
                                    const Shadow(offset: Offset(4, 4), color: Colors.black, blurRadius: 0)
                                  ]
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatus(int index) {
    bool alive = _isAlive[index];
    Color color = _getPlayerColor(index);
    int lives = _playerLives[index]; 

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: alive ? color : Colors.grey[800],
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: alive 
              ? Text("P${index+1}", style: GoogleFonts.pressStart2p(fontSize: 8, color: index == 1 ? Colors.white : Colors.black))
              : const Text("💀", style: TextStyle(fontSize: 16)),
          ),
        ),
        
        // HEART ROW
        // Using Fixed Height to prevent jumping when heart appears/disappears
        SizedBox(
          height: 16, 
          child: (lives > 0 && alive)
             ? Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: List.generate(lives, (index) => 
                   const Padding(
                     padding: EdgeInsets.symmetric(horizontal: 1),
                     child: Icon(Icons.favorite, color: Colors.red, size: 12),
                   )
                 ),
               )
             : null,
        )
      ],
    );
  }

  Color _getPlayerColor(int index) {
    switch (index) {
      case 0: return Colors.white;
      case 1: return Colors.black; 
      case 2: return Colors.red;
      case 3: return Colors.blue;
      case 4: return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}