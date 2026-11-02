import 'package:flutter_tts/flutter_tts.dart';

class VoiceAlertService {
  final FlutterTts _tts = FlutterTts();
  bool enabled = true;
  bool _ready = false;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48); // a bit slower — easier to catch while driving
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _ready = true;
  }

  Future<void> speak(String text) async {
    if (!enabled || !_ready) return;
    // Don't queue up stale warnings behind each other — the latest
    // one is the relevant one.
    await _tts.stop();
    await _tts.speak(text);
  }

  void setEnabled(bool value) {
    enabled = value;
    if (!value) _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}
