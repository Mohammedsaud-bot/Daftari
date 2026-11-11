import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'effects.dart';
import 'speech.dart';

abstract interface class StudyStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalStudyStorage implements StudyStorage {
  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();
  @override
  Future<String?> read() => _prefs.getString('study_state_v1');
  @override
  Future<void> write(String value) => _prefs.setString('study_state_v1', value);
}

class AppState extends ChangeNotifier {
  final StudyStorage _storage;
  AppState({StudyStorage? storage}) : _storage = storage ?? LocalStudyStorage();
  late Catalog catalog;
  bool arabic = true;
  bool help = true;
  bool sound = true;
  bool onboarded = false;
  bool beginner = false;
  bool storageProblem = false;
  int tab = 0;
  String activeLesson = 'travel-1';
  final Map<String, LessonProgress> progress = {};
  final Map<String, ReviewRecord> reviews = {};
  final Set<String> saved = {};
  Future<void> _writes = Future.value();

  String t(String ar, String en) => arabic ? ar : en;
  Future<void> initialize() async {
    catalog = Catalog.fromJson(
      jsonDecode(await rootBundle.loadString('assets/content/book12.json')),
    );
    try {
      final raw = await _storage.read();
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      arabic = j['arabic'] != false;
      help = j['help'] != false;
      sound = j['sound'] != false;
      onboarded = j['onboarded'] == true;
      beginner = j['beginner'] == true;
      if (catalog.lessons.any((l) => l.id == j['activeLesson'])) {
        activeLesson = j['activeLesson'];
      }
      for (final l in catalog.lessons) {
        final value = j['progress']?[l.id];
        if (value is Map<String, dynamic>) {
          progress[l.id] = LessonProgress.fromJson(value, l.steps.length);
        }
      }
      for (final entry
          in ((j['reviews'] ?? {}) as Map<String, dynamic>).entries) {
        if (catalog.words.any((w) => w.id == entry.key)) {
          reviews[entry.key] = ReviewRecord.fromJson(entry.value);
        }
      }
      saved.addAll(
        ((j['saved'] ?? []) as List).cast<String>().where(
          (id) => catalog.words.any((w) => w.id == id),
        ),
      );
    } catch (_) {
      storageProblem = true;
    }
  }

  LessonProgress forLesson(String id) =>
      progress.putIfAbsent(id, LessonProgress.new);
  StudyLesson get current => catalog.lesson(activeLesson);
  int get completed => progress.values.where((p) => p.complete).length;
  int get correctAnswers =>
      progress.values.fold(0, (n, p) => n + p.firstCorrect);
  List<StudyWord> dueWords([DateTime? at]) {
    final now = at ?? DateTime.now();
    return catalog.words
        .where((w) => reviews[w.id] == null || !reviews[w.id]!.due.isAfter(now))
        .toList();
  }

  void changeTab(int value) {
    effects.play('tap', sound: sound);
    tab = value;
    notifyListeners();
  }

  void settings({bool? language, bool? assistance, bool? audio}) {
    arabic = language ?? arabic;
    help = assistance ?? help;
    sound = audio ?? sound;
    if (!sound) {
      effects.stop();
      speech.stop();
    }
    _save();
  }

  void start(bool needsBridge) {
    effects.play('next', sound: sound);
    beginner = needsBridge;
    onboarded = true;
    activeLesson = needsBridge ? 'foundation-1' : 'travel-1';
    _save();
  }

  void activate(String id) {
    effects.play('next', sound: sound);
    activeLesson = id;
    _save();
  }

  void toggleSaved(String id) {
    effects.play('tap', sound: sound);
    saved.contains(id) ? saved.remove(id) : saved.add(id);
    _save();
  }

  void record(String lesson, String step, bool correct) {
    forLesson(lesson).record(step, correct);
    _save();
  }

  void advance(String id) {
    final p = forLesson(id);
    final l = catalog.lesson(id);
    if (p.step < l.steps.length - 1) {
      p.step++;
    } else {
      p.complete = true;
    }
    _save();
  }

  void restart(String id) {
    // Preserve first-attempt results and completion when revisiting material.
    forLesson(id).step = 0;
    _save();
  }

  void review(String id, bool correct, {DateTime? now}) {
    final at = now ?? DateTime.now();
    reviews[id] = (reviews[id] ?? ReviewRecord(0, at)).answer(correct, at);
    _save();
  }

  Future<void> reset() async {
    progress.clear();
    reviews.clear();
    saved.clear();
    onboarded = false;
    beginner = false;
    activeLesson = 'travel-1';
    tab = 0;
    _save();
    await _writes;
  }

  void _save() {
    final snapshot = jsonEncode({
      'arabic': arabic,
      'help': help,
      'sound': sound,
      'onboarded': onboarded,
      'beginner': beginner,
      'activeLesson': activeLesson,
      'progress': progress.map((k, v) => MapEntry(k, v.toJson())),
      'reviews': reviews.map((k, v) => MapEntry(k, v.toJson())),
      'saved': saved.toList(),
    });
    _writes = _writes.then((_) async {
      try {
        await _storage.write(snapshot);
      } catch (_) {
        storageProblem = true;
        notifyListeners();
      }
    });
    notifyListeners();
  }
}
