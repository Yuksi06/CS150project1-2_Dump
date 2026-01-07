import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'host_menu.dart';
import 'join_menu.dart';
import 'audio_manager.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {

  @override
  void initState() {
    super.initState();
    AudioManager().playBgm('opening');
  }

  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (!ModalRoute.of(context)!.isCurrent) return;

    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = 0;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = 1;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        _selectItem();
      }
    }
  }

  void _selectItem() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => 
        _selectedIndex == 0 ? const HostMenu() : const JoinMenu()
      )
    ).then((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKeyEvent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 4),
                  color: const Color(0xFFB71C1C),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Text(
                  "BOMBERMAN",
                  style: GoogleFonts.pressStart2p(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              
              _buildMenuItem("HOST GAME", 0),
              const SizedBox(height: 20),
              _buildMenuItem("JOIN GAME", 1),
              
              const SizedBox(height: 60),
              Text(
                "[ ARROWS to Move | SPACE to Select ]",
                style: GoogleFonts.pressStart2p(color: Colors.green, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      width: 280,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green : Colors.black,
        border: Border.all(color: Colors.green, width: 3),
      ),
      child: Text(
        isSelected ? "> $title" : "  $title",
        textAlign: TextAlign.center,
        style: GoogleFonts.pressStart2p(
          color: isSelected ? Colors.black : Colors.green,
          fontSize: 14,
        ),
      ),
    );
  }
}