import 'dart:js_interop';

@JS('speechSynthesis.speak')
external void _speak(JSObject utterance);

@JS()
@staticInterop
class _SpeechSynthesisUtterance {
  external factory _SpeechSynthesisUtterance(JSString text);
}

extension _SpeechSynthesisUtteranceExt on _SpeechSynthesisUtterance {
  external set lang(JSString value);
  external set rate(JSNumber value);
}

class SpeechUtil {
  static void speak(String text) {
    try {
      final utterance = _SpeechSynthesisUtterance(text.toJS);
      utterance.lang = 'en-US'.toJS;
      utterance.rate = 0.9.toJS;
      _speak(utterance as JSObject);
    } catch (_) {
      // Speech synthesis not available
    }
  }
}
