import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:isolate';
import '../../server/isolate_server.dart';
import 'game_controller.dart';
import 'lobby_screen.dart';
import 'audio_manager.dart';

class HostMenu extends StatefulWidget {
  const HostMenu({super.key});

  @override
  State<HostMenu> createState() => _HostMenuState();
}

class _HostMenuState extends State<HostMenu> {

  @override
  void initState() {
    super.initState();
    AudioManager().playBgm('opening');
  }

  int _selectedIndex = 0;
  bool _isEditing = false;
  
  final int _idxPort = 0;
  final int _idxPlayers = 1;
  final int _idxDuration = 2;
  final int _idxStart = 3;
  final int _idxBack = 4;

  final TextEditingController _portController = TextEditingController(text: "25000");
  final TextEditingController _playersController = TextEditingController(text: "4");
  final TextEditingController _durationController = TextEditingController(text: "300");

  final FocusNode _mainNode = FocusNode(); 
  final FocusNode _portNode = FocusNode();
  final FocusNode _playersNode = FocusNode();
  final FocusNode _durationNode = FocusNode();
  
  @override
  void dispose() {
    _mainNode.dispose();
    _portNode.dispose();
    _playersNode.dispose();
    _durationNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_isEditing) {
      return KeyEventResult.ignored; 
    }
    
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          if (_selectedIndex > 0) _selectedIndex--;
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          if (_selectedIndex < 4) _selectedIndex++;
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
        _activateItem();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _activateItem() {
    if (_selectedIndex == _idxStart) {
      _startHosting();
    } else if (_selectedIndex == _idxBack) {
      Navigator.pop(context);
    } else {
      setState(() => _isEditing = true);
      
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_selectedIndex == _idxPort) _portNode.requestFocus();
        else if (_selectedIndex == _idxPlayers) _playersNode.requestFocus();
        else if (_selectedIndex == _idxDuration) _durationNode.requestFocus();
      });
    }
  }

  void _finishEditing(String value) {
    setState(() => _isEditing = false);
    _mainNode.requestFocus();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      )
    );
  }

  void _startHosting() async {
    final port = int.tryParse(_portController.text);
    final players = int.tryParse(_playersController.text);
    final duration = int.tryParse(_durationController.text);

    if (port == null || players == null || duration == null) {
      _showError("INVALID INPUT FORMAT");
      return;
    }

    if (port < 1024 || port > 65535) {
      _showError("PORT MUST BE 1024-65535");
      return;
    }

    if (players < 2 || players > 5) {
      _showError("PLAYERS MUST BE 2-5");
      return;
    }

    if (duration < 30 || duration > 600) {
      _showError("TIME MUST BE 30-600s");
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Initializing...", style: GoogleFonts.pressStart2p(fontSize: 10)))
    );

    final receivePort = ReceivePort();
    try {
      await Isolate.spawn(
        runServerIsolate, 
        // We pass the validated inputs here
        [receivePort.sendPort, port, players, duration]
      );
    } catch (e) {
      _showError("ISOLATE ERROR: $e");
      return;
    }

    final isReady = await receivePort.first as bool;
    if (!isReady) {
      _showError("PORT $port IS BUSY!");
      return;
    }

    final controller = GameController();
    bool connected = false;
    int attempts = 0;

    while (!connected && attempts < 5) {
      try {
        await controller.connect('127.0.0.1', port);
        connected = true;
      } catch (e) {
        attempts++;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (mounted && connected) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyScreen(
            controller: controller, 
            myPlayerId: controller.myPlayerId, 
            isHost: true,
          ),
        ),
      );
    } else {
      _showError("FAILED TO CONNECT TO HOST");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _mainNode, 
      autofocus: true,
      onKeyEvent: _handleKeyEvent, 
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
            width: 700, 
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 4),
              color: Colors.black,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("HOST CONFIG", 
                  style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 20)
                ),
                const SizedBox(height: 40),

                _buildRetroInput("PORT (1024+)", _portController, _portNode, _idxPort),
                const SizedBox(height: 20),

                _buildRetroInput("PLAYERS (2-5)", _playersController, _playersNode, _idxPlayers),
                const SizedBox(height: 20),

                _buildRetroInput("TIME (30-600s)", _durationController, _durationNode, _idxDuration),
                const SizedBox(height: 40),

                _buildButton("START SERVER", _idxStart),
                const SizedBox(height: 20),
                
                _buildButton("BACK", _idxBack, color: Colors.red),

                const SizedBox(height: 20),
                Text(
                  "[SPACE] EDIT/SELECT  [ENTER] CONFIRM",
                  style: GoogleFonts.pressStart2p(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroInput(String label, TextEditingController controller, FocusNode node, int index) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: isSelected ? (_isEditing ? Colors.green[900] : Colors.green[800]) : Colors.grey[900],
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey[800]!, 
          width: 2
        ),
      ),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 12)),
          const Spacer(),
          SizedBox(
            width: 150,
            child: TextField(
              controller: controller,
              focusNode: node,
              style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.right,
              readOnly: !_isEditing, 
              onSubmitted: _finishEditing,
              keyboardType: TextInputType.number,
              showCursor: _isEditing, 
              cursorColor: Colors.green, 
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, int index, {Color color = Colors.green}) {
    final isSelected = _selectedIndex == index;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.grey[900],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.pressStart2p(
          color: isSelected ? Colors.black : Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}