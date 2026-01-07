import 'dart:async';

abstract class Updatable {
  void update(double dt);
}

class GameLoop {
  final Updatable _target;
  final int _fps;
  Timer? _timer;

  late DateTime _lastTick;

  // Generic GameLoop that ticks any 'Updatable' target (like ServerGameState)
  GameLoop(this._target, {int fps = 30}) : _fps = fps;

  void start() {
    if (_timer != null) return; 

    _lastTick = DateTime.now();
    final duration = Duration(milliseconds: (1000 / _fps).round());

    print("Server Logic Loop start at $_fps FPS");

    _timer = Timer.periodic(duration, (timer) {
      final now = DateTime.now();

      // Calculate delta time in seconds
      final dt = now.difference(_lastTick).inMicroseconds / 1000000.0;
      _lastTick = now;

      // Execute the update
      _target.update(dt);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    print("Server Loop stopped");
  }
}