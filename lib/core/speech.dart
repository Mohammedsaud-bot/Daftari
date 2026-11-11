import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Speech {
  final FlutterTts _tts = FlutterTts();
  AudioPlayer? _player;
  Future<Map<String, dynamic>>? _clips;
  Future<void>? _voiceSetup;
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
    await (_voiceSetup ??= _chooseBestVoice());
    if (generation != _generation) return;
    await _tts.setSpeechRate(slow ? .34 : .46);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    final result = await _tts.speak(text);
    if (result == 0) throw StateError('Speech could not start');
  }

  // Picks the clearest English voice on the device: Google's engine when
  // installed, then the highest-quality en-US voice, preferring offline ones.
  Future<void> _chooseBestVoice() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is List && engines.contains('com.google.android.tts')) {
        await _tts.setEngine('com.google.android.tts');
      }
    } catch (_) {}
    await _tts.setLanguage('en-US');
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      Map<String, String>? best;
      var bestScore = -1;
      for (final v in voices) {
        if (v is! Map) continue;
        final name = '${v['name'] ?? ''}';
        final locale = '${v['locale'] ?? ''}'.toLowerCase().replaceAll('_', '-');
        if (name.isEmpty || !locale.startsWith('en')) continue;
        final quality = '${v['quality'] ?? ''}'.toLowerCase();
        final network = '${v['network_required'] ?? ''}' == '1' ||
            name.toLowerCase().contains('network');
        var score = 0;
        if (locale == 'en-us') score += 40;
        if (locale == 'en-gb') score += 20;
        if (quality.contains('very high')) {
          score += 30;
        } else if (quality.contains('high')) {
          score += 20;
        } else if (quality.contains('normal')) {
          score += 10;
        }
        if (!network) score += 15;
        if (name.toLowerCase().contains('local')) score += 5;
        if (score > bestScore) {
          bestScore = score;
          best = {'name': name, 'locale': '${v['locale']}'};
        }
      }
      if (best != null) await _tts.setVoice(best);
    } catch (_) {}
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
