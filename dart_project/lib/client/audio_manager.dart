import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Audio Mixing Settings
  double bgmVolume = 0.15;
  double sfxVolume = 1.2;

  String? _currentBgm;
  
  // Debounce Timer for Explosions ---
  DateTime? _lastExplosionTime;

  Future<void> init() async {
    await FlameAudio.audioCache.loadAll([
      'sfx/death.wav',
      'sfx/explosion.wav',
      'sfx/powerups.wav',
      'music/draw.wav',
      'music/ingame.wav',
      'music/losingPlayer.wav',
      'music/opening.wav', 
      'music/winningPlayer.wav',
    ]);
  }

  void playBgm(String filename) {
    if (_currentBgm == filename) return;
    FlameAudio.bgm.stop();
    _currentBgm = filename;
    FlameAudio.bgm.play('music/$filename.wav', volume: bgmVolume);
  }

  void stopBgm() {
    FlameAudio.bgm.stop();
    _currentBgm = null;
  }

  void playWinMusic() {
    stopBgm();
    FlameAudio.play('music/winningPlayer.wav', volume: bgmVolume);
  }

  void playLoseMusic() {
    stopBgm();
    FlameAudio.play('music/losingPlayer.wav', volume: bgmVolume);
  }
  
  void playDrawMusic() {
    stopBgm();
    FlameAudio.play('music/draw.wav', volume: bgmVolume);
  }

  void playExplosion() {
    final now = DateTime.now();
    
    if (_lastExplosionTime != null) {
      final difference = now.difference(_lastExplosionTime!).inMilliseconds;
      if (difference < 100) return; 
    }

    _lastExplosionTime = now;
    FlameAudio.play('sfx/explosion.wav', volume: sfxVolume);
  }

  void playDeath() {
    FlameAudio.play('sfx/death.wav', volume: sfxVolume);
  }

  void playPowerup() {
    FlameAudio.play('sfx/powerups.wav', volume: sfxVolume);
  }
}