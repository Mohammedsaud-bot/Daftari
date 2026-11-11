import 'dart:convert';

class Catalog {
  final List<Map<String, dynamic>> units;
  final List<StudyWord> words;
  final List<StudyLesson> lessons;
  Catalog.fromJson(Map<String, dynamic> json)
    : units = (json['units'] as List).cast<Map<String, dynamic>>(),
      words = (json['words'] as List).map((e) => StudyWord(e)).toList(),
      lessons = (json['lessons'] as List).map((e) => StudyLesson(e)).toList();
  StudyLesson lesson(String id) => lessons.firstWhere((e) => e.id == id);
  StudyWord word(String id) => words.firstWhere((e) => e.id == id);
  List<StudyLesson> unitLessons(String unit) =>
      lessons.where((e) => e.data['unit'] == unit).toList();
  StudyLesson? nextLesson(String id) {
    final i = lessons.indexWhere((e) => e.id == id);
    if (i < 0 || i + 1 >= lessons.length) return null;
    final next = lessons[i + 1];
    return next.data['unit'] == 'foundation' ? null : next;
  }
}

class StudyWord {
  final Map<String, dynamic> data;
  StudyWord(this.data);
  String get id => data['id'];
  String get word => data['word'];
  String get ar => data['ar'];
  String get example => data['example'];
  String get exampleAr => data['exampleAr'];
  String get definition => data['definition'];
  String get symbol => data['symbol'];
}

class StudyLesson {
  final Map<String, dynamic> data;
  StudyLesson(this.data);
  String get id => data['id'];
  int get minutes => data['minutes'];
  String title(bool arabic) => data[arabic ? 'ar' : 'en'];
  List<Map<String, dynamic>> get steps =>
      (data['steps'] as List).cast<Map<String, dynamic>>();
  int get questionCount => steps.where((s) => s['answer'] != null).length;
}

class LessonProgress {
  int step;
  bool complete;
  final Map<String, bool> firstAnswers;
  LessonProgress({
    this.step = 0,
    this.complete = false,
    Map<String, bool>? firstAnswers,
  }) : firstAnswers = firstAnswers ?? {};
  factory LessonProgress.fromJson(Map<String, dynamic> json, int stepCount) {
    final rawStep = json['step'];
    return LessonProgress(
      step: rawStep is int ? rawStep.clamp(0, stepCount - 1) : 0,
      complete: json['complete'] == true,
      firstAnswers: Map<String, bool>.from(json['firstAnswers'] ?? {}),
    );
  }
  void record(String id, bool correct) =>
      firstAnswers.putIfAbsent(id, () => correct);
  int get firstCorrect => firstAnswers.values.where((e) => e).length;
  Map<String, dynamic> toJson() => {
    'step': step,
    'complete': complete,
    'firstAnswers': firstAnswers,
  };
}

class ReviewRecord {
  final int streak;
  final DateTime due;
  const ReviewRecord(this.streak, this.due);
  factory ReviewRecord.fromJson(Map<String, dynamic> json) =>
      ReviewRecord(json['streak'] as int, DateTime.parse(json['due']));
  ReviewRecord answer(bool correct, DateTime now) {
    if (!correct) return ReviewRecord(0, now.add(const Duration(minutes: 10)));
    final next = (streak + 1).clamp(1, 4);
    return ReviewRecord(next, now.add(Duration(days: [1, 3, 7, 14][next - 1])));
  }

  Map<String, dynamic> toJson() => {
    'streak': streak,
    'due': due.toIso8601String(),
  };
}

String encodeProgress(Map<String, LessonProgress> values) =>
    jsonEncode(values.map((k, v) => MapEntry(k, v.toJson())));
