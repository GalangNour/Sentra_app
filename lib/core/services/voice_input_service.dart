import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputService {
  final _stt = SpeechToText();
  bool _available = false;
  void Function(String)? _currentOnError;

  bool get isAvailable => _available;

  Future<bool> init() async {
    _available = await _stt.initialize(
      onError: (error) => _currentOnError?.call(error.errorMsg),
    );
    return _available;
  }

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String error) onError,
    void Function(double level)? onSoundLevel,
  }) async {
    if (!_available) return;
    _currentOnError = onError;
    await _stt.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      onSoundLevelChange: onSoundLevel,
      localeId: 'id_ID',
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 2),
      listenOptions: SpeechListenOptions(cancelOnError: true),
    );
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}
