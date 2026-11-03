import 'package:flutter_test/flutter_test.dart';

import 'package:nexus_ai/core/services/live_voice_service.dart';

void main() {
  test('SimulatedLiveVoiceService transitions connecting->listening', () async {
    final svc = SimulatedLiveVoiceService();
    expect(svc.state, LiveVoiceState.idle);
    final states = <LiveVoiceState>[];
    final sub = svc.stateStream.listen(states.add);
    await svc.start();
    expect(svc.state, LiveVoiceState.listening);
    expect(states, contains(LiveVoiceState.connecting));
    await svc.stop();
    expect(svc.state, LiveVoiceState.idle);
    await sub.cancel();
  });
}

