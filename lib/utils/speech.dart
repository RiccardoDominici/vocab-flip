import 'speech_stub.dart'
    if (dart.library.js_interop) 'speech_web.dart';

class SpeechUtil {
  static void speak(String text) {
    speakImpl(text);
  }
}
