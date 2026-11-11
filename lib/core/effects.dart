import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Short, locally bundled feedback; never plays before a user gesture.
class ExperienceAudio {
  bool enabled = true;
  AudioPlayer? _player;
  Future<void> play(String cue, {bool sound = true}) async {
    if (!enabled || !sound) return;
    try {
      if (cue == 'correct' || cue == 'complete') {
        HapticFeedback.lightImpact();
      }
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource('audio/$cue.wav'), volume: .36);
    } catch (_) {
      // Audio must never prevent an answer, navigation, or local saving.
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }
}

final effects = ExperienceAudio();
