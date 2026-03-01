import 'speech_stub.dart'
    if (dart.library.js_interop) 'speech_web.dart'
    if (dart.library.io) 'speech_native.dart';

class SpeechUtil {
  static void speak(String text) {
    speakImpl(text);
  }
}
