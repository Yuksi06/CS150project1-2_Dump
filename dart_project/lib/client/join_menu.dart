import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_controller.dart';
import 'lobby_screen.dart';
import 'audio_manager.dart';

class JoinMenu extends StatefulWidget {
  const JoinMenu({super.key});

  @override
  State<JoinMenu> createState() => _JoinMenuState();
}

class _JoinMenuState extends State<JoinMenu> {

  @override
  void initState() {
    super.initState();
    AudioManager().playBgm('opening');
  }

  int _selectedIndex = 0;
  bool _isEditing = false;
  
  final int _idxIp = 0;
  final int _idxPort = 1;
  final int _idxJoin = 2;
  final int _idxBack = 3;

  final TextEditingController _ipController = TextEditingController(text: "127.0.0.1");
  final TextEditingController _portController = TextEditingController(text: "25000");

  final FocusNode _mainNode = FocusNode();
  final FocusNode _ipNode = FocusNode();
  final FocusNode _portNode = FocusNode();

  @override
  void dispose() {
    _mainNode.dispose();
    _ipNode.dispose();
    _portNode.dispose();
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
          if (_selectedIndex < 3) _selectedIndex++;
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
    if (_selectedIndex == _idxJoin) {
      _joinGame();
    } else if (_selectedIndex == _idxBack) {
      Navigator.pop(context);
    } else {
      setState(() => _isEditing = true);
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_selectedIndex == _idxIp) _ipNode.requestFocus();
        else if (_selectedIndex == _idxPort) _portNode.requestFocus();
      });
    }
  }

  void _finishEditing(String value) {
    setState(() => _isEditing = false);
    _mainNode.requestFocus();
  }

  void _joinGame() async {
    final ip = _ipController.text;
    final port = int.tryParse(_portController.text);

    if (ip.isEmpty || port == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Connecting...", style: GoogleFonts.pressStart2p(fontSize: 10)))
    );

    final controller = GameController();
    try {
      await controller.connect(ip, port);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              controller: controller, 
              myPlayerId: -1, 
              isHost: false,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Failed: $e", style: GoogleFonts.pressStart2p(fontSize: 10)), backgroundColor: Colors.red)
      );
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
            width: 600,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 4),
              color: Colors.black,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("JOIN GAME", 
                  style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 24)
                ),
                const SizedBox(height: 40),

                _buildRetroInput("HOST IP", _ipController, _ipNode, _idxIp),
                const SizedBox(height: 20),

                _buildRetroInput("PORT", _portController, _portNode, _idxPort),
                const SizedBox(height: 40),

                _buildButton("CONNECT", _idxJoin),
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
            width: 250,
            child: TextField(
              controller: controller,
              focusNode: node,
              style: GoogleFonts.pressStart2p(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.right,
              readOnly: !_isEditing,
              onSubmitted: _finishEditing,
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