import 'dart:async';

enum LiveVoiceState { idle, connecting, listening, speaking, error }

abstract class LiveVoiceService {
  LiveVoiceState get state;
  Stream<LiveVoiceState> get stateStream;
  Future<void> start();
  Future<void> stop();
}

class SimulatedLiveVoiceService implements LiveVoiceService {
  final _controller = StreamController<LiveVoiceState>.broadcast();
  LiveVoiceState _state = LiveVoiceState.idle;

  @override
  LiveVoiceState get state => _state;

  @override
  Stream<LiveVoiceState> get stateStream => _controller.stream;

  void _emit(LiveVoiceState s) {
    _state = s;
    _controller.add(s);
  }

  @override
  Future<void> start() async {
    _emit(LiveVoiceState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _emit(LiveVoiceState.listening);
  }

  @override
  Future<void> stop() async {
    _emit(LiveVoiceState.idle);
  }
}
