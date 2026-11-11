import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Speech {
  final FlutterTts _tts = FlutterTts();
  AudioPlayer? _player;
  Future<Map<String, dynamic>>? _clips;
  Completer<void>? _completion;
  int _generation = 0;

  Future<void> speak(String text, {bool slow = false}) async {
    final generation = _generation + 1;
    await stop();
    if (generation != _generation) return;
    final clips = await (_clips ??= rootBundle
        .loadString('assets/audio/voice/index.json')
        .then(
          (raw) =>
              jsonDecode(raw.replaceFirst('\uFEFF', ''))
                  as Map<String, dynamic>,
        ));
    if (generation != _generation) return;
    final asset = clips[text];
    if (asset is String) {
      final player = _player ??= AudioPlayer();
      final completion = Completer<void>();
      _completion = completion;
      final subscription = player.onPlayerComplete.listen((_) {
        if (!completion.isCompleted) completion.complete();
      });
      try {
        await player.setPlaybackRate(slow ? .78 : 1);
        if (generation != _generation) return;
        await player.play(AssetSource('audio/voice/$asset'));
        await completion.future.timeout(const Duration(seconds: 90));
      } finally {
        await subscription.cancel();
        if (identical(_completion, completion)) _completion = null;
      }
      return;
    }
    // Device TTS is a fallback for future content without a bundled clip.
    final available = await _tts.isLanguageAvailable('en-US');
    if (available != true && available != 1) {
      throw StateError('No English voice available');
    }
    if (generation != _generation) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(slow ? .32 : .48);
    await _tts.awaitSpeakCompletion(true);
    final result = await _tts.speak(text);
    if (result == 0) throw StateError('Speech could not start');
  }

  Future<void> stop() async {
    _generation++;
    final completion = _completion;
    if (completion != null && !completion.isCompleted) completion.complete();
    _completion = null;
    try {
      await _player?.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

final speech = Speech();
