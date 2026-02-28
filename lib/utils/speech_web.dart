import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void speakImpl(String text) {
  try {
    final constructor = globalContext.getProperty('SpeechSynthesisUtterance'.toJS) as JSFunction;
    final utterance = constructor.callAsConstructor<JSObject>(text.toJS);
    utterance.setProperty('lang'.toJS, 'en-US'.toJS);
    utterance.setProperty('rate'.toJS, (0.9).toJS);
    final synth = globalContext.getProperty('speechSynthesis'.toJS) as JSObject;
    synth.callMethod('speak'.toJS, utterance);
  } catch (_) {
    // Speech synthesis not available
  }
}
