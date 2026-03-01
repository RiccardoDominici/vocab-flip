import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts _tts = FlutterTts();
bool _initialized = false;

Future<void> _ensureInitialized() async {
  if (!_initialized) {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    _initialized = true;
  }
}

void speakImpl(String text) {
  _ensureInitialized().then((_) => _tts.speak(text));
}
