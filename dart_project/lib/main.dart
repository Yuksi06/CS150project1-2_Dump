import 'package:flutter/material.dart';
import 'client/main_menu.dart';
import 'client/audio_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AudioManager().init();

  runApp(const MaterialApp(
    home: MainMenu(),
    debugShowCheckedModeBanner: false,
  ));
}