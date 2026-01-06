import 'dart:async';

abstract class Updatable {
  void update(double dt);
}

class GameLoop {
  final Updatable _target;
  final int _fps;
  Timer? _timer;

  late DateTime _lastTick;

  GameLoop(this._target, {int fps = 60}) : _fps = fps;

  void start() {
    if (_timer != null) return; // Already running

    _lastTick = DateTime.now();
    final duration = Duration(milliseconds: (1000 / _fps).round());

    print("Server Loop start at $_fps FPS");

    _timer = Timer.periodic(duration, (timer) {
      final now = DateTime.now();

      // Calculate delta time in seconds [Microseconds / 1,000,000 = Seconds]
      final dt = now.difference(_lastTick).inMicroseconds / 1000000.0;
      _lastTick = now;

      // Execute the update on the target
      _target.update(dt);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    print("Server Loop stopped");
  }
}