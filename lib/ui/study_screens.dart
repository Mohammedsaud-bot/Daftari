import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/effects.dart';
import '../core/models.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import 'components.dart';
import 'lesson_experience.dart';

class SpeechButton extends StatefulWidget {
  final AppState state;
  final String text;
  final bool slow;
  final String? label;
  const SpeechButton({
    super.key,
    required this.state,
    required this.text,
    this.slow = false,
    this.label,
  });
  @override
  State<SpeechButton> createState() => _SpeechButtonState();
}

class _SpeechButtonState extends State<SpeechButton> {
  bool playing = false;
  Future<void> play() async {
    final s = widget.state;
    if (!s.sound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.t(
              'فعّل الصوت من الإعدادات للاستماع.',
              'Enable audio in Settings to listen.',
            ),
          ),
        ),
      );
      return;
    }
    if (playing) {
      await speech.stop();
      if (mounted) setState(() => playing = false);
      return;
    }
    setState(() => playing = true);
    try {
      await speech.speak(widget.text, slow: widget.slow);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s.t(
                'تعذّر تشغيل الصوت. يمكنك قراءة النص، أو تفعيل صوت إنجليزي في إعدادات جهازك.',
                'Audio is unavailable. Read the transcript or enable an English voice on your device.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => playing = false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.label == null
      ? IconButton(
          tooltip: widget.state.t('استمع للنطق', 'Listen to pronunciation'),
          onPressed: play,
          icon: playing
              ? const VoiceWave()
              : Icon(Icons.volume_up_rounded, color: blue),
        )
      : OutlinedButton.icon(
          onPressed: play,
          icon: playing
              ? const VoiceWave()
              : Icon(
                  widget.slow
                      ? Icons.slow_motion_video_rounded
                      : Icons.play_arrow_rounded,
                ),
          label: Text(
            playing ? widget.state.t('إيقاف', 'Stop') : widget.label!,
          ),
        );
}

class LessonScreen extends StatefulWidget {
  final AppState state;
  final StudyLesson lesson;
  const LessonScreen({super.key, required this.state, required this.lesson});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String? selected;
  final List<int> ordered = [];
  bool? checked;
  bool transcript = false;
  bool translation = false;
  bool finished = false;
  final scroll = ScrollController();
  AppState get s => widget.state;
  StudyLesson get lesson => widget.lesson;
  Map<String, dynamic> get step => lesson.steps[s.forLesson(lesson.id).step];
  @override
  void dispose() {
    speech.stop();
    scroll.dispose();
    super.dispose();
  }

  bool get question => step['answer'] != null;
  void check() {
    final answer = step['kind'] == 'order'
        ? ordered.map((i) => (step['options'] as List)[i]).join(' ')
        : selected;
    final correct = answer == step['answer'];
    effects.play(correct ? 'correct' : 'retry', sound: s.sound);
    s.record(lesson.id, step['id'], correct);
    setState(() => checked = correct);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void next() {
    speech.stop();
    final last = s.forLesson(lesson.id).step == lesson.steps.length - 1;
    effects.play(last ? 'complete' : 'next', sound: s.sound);
    s.advance(lesson.id);
    setState(() {
      selected = null;
      ordered.clear();
      checked = null;
      transcript = false;
      translation = false;
      finished = last;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: s,
    builder: (context, _) {
      if (finished) return _completion(context);
      final index = s.forLesson(lesson.id).step;
      final canCheck = step['kind'] == 'order'
          ? ordered.length == (step['options'] as List).length
          : selected != null;
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: s.t('رجوع وحفظ مكاني', 'Back, with my place saved'),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(
            lesson.title(s.arabic),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: s.t('المساعدة العربية', 'Arabic assistance'),
              onPressed: () => s.settings(assistance: !s.help),
              icon: Icon(Icons.translate_rounded, color: s.help ? blue : muted),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  if (lesson.id == 'travel-1')
                    MissionRail(step: index, state: s),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: index / lesson.steps.length,
                              minHeight: 7,
                              color: blue,
                              backgroundColor: line,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        English(
                          '${index + 1} / ${lesson.steps.length}',
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(step['id']),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 450),
                        tween: Tween(begin: 0, end: 1),
                        builder: (_, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Tag(_kindLabel(), icon: _kindIcon()),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              step[s.arabic ? 'ar' : 'en'],
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 18),
                            ..._content(context),
                            if (checked != null) ...[
                              const SizedBox(height: 20),
                              _feedback(context),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                    decoration: const BoxDecoration(
                      color: Color(0xEEF6F9FF),
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('lesson-action'),
                        onPressed: question && checked != true
                            ? (canCheck ? check : null)
                            : next,
                        icon: Icon(
                          question && checked != true
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          question && checked != true
                              ? s.t('تحقق من إجابتي', 'Check my answer')
                              : index == lesson.steps.length - 1
                              ? s.t('أنهي الجلسة', 'Finish session')
                              : s.t('الخطوة التالية', 'Next step'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  String _kindLabel() => switch (step['kind']) {
    'intro' => s.t('بداية الجلسة', 'GETTING STARTED'),
    'vocabulary' => s.t('مفردات', 'VOCABULARY'),
    'listening' => s.t('استماع', 'LISTENING'),
    'grammar' => s.t('نفهم القاعدة', 'UNDERSTAND THE PATTERN'),
    _ => s.t('جرّب بنفسك', 'YOUR TURN'),
  };
  IconData _kindIcon() => switch (step['kind']) {
    'intro' => Icons.flight_takeoff_rounded,
    'vocabulary' => Icons.style_rounded,
    'listening' => Icons.headphones_rounded,
    'grammar' => Icons.lightbulb_outline_rounded,
    _ => Icons.track_changes_rounded,
  };

  List<Widget> _content(BuildContext context) {
    final widgets = <Widget>[];
    if (lesson.id == 'travel-1' && step['kind'] == 'intro') {
      return [
        SceneCard(
          caption: s.t(
            'الجمعة • يوم مناسب لمغامرة',
            'FRIDAY • A LITTLE ADVENTURE AWAITS',
          ),
        ),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tag(
                s.t('أنت صاحب الخطة', 'YOU MAKE THE PLAN'),
                color: const Color(0xFFB35D16),
                icon: Icons.explore_rounded,
              ),
              const SizedBox(height: 12),
              Text(
                s.t(
                  'مايا وعمر ينتظرون قرارك.',
                  'Maya and Omar are waiting for your plan.',
                ),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                s.t(
                  'الشاطئ أو البيت؟ اكتشف الكلمات، اسمع الحوار، وغيّر الطقس لتعرف كيف تتغيّر الخطة.',
                  'Beach or home? Discover the words, hear the conversation, then change the weather to see how the plan changes.',
                ),
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Tag(s.t('٤ كلمات جديدة', '4 NEW WORDS')),
                  Tag(s.t('حوار قصير', 'A SHORT CONVERSATION')),
                  Tag(s.t('قرار من عندك', 'YOUR OWN DECISION')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          s.t(
            'كل محاولة تقرّبك. خذ وقتك، ومكانك محفوظ.',
            'Every try helps. Take your time — your place is saved.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 13),
        ),
      ];
    }
    if (lesson.id == 'travel-1' && step['kind'] == 'grammar') {
      return [
        WeatherLab(
          state: s,
          voiceBuilder: (text) => SpeechButton(
            state: s,
            text: text,
            label: s.t('اسمع الجملة', 'Hear the sentence'),
          ),
        ),
      ];
    }
    if (step['id'] == 't-read') {
      widgets.add(
        SceneCard(
          image: 'mountain-scene',
          height: 180,
          caption: s.t(
            'مهمة جديدة • طريق الجبال',
            'NEW MISSION • THE MOUNTAIN ROAD',
          ),
        ),
      );
    }
    if (step['id'] == 't-vocab-check') {
      widgets.add(
        Center(child: Image.asset('assets/images/breeze-art.png', height: 130)),
      );
      widgets.add(const SizedBox(height: 12));
    }
    if (step['kind'] == 'intro') {
      widgets.add(
        Center(
          child: Image.asset(
            lesson.id == 'travel-1'
                ? 'assets/images/travel-kit.png'
                : 'assets/images/study-book.png',
            height: 185,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 18));
    }
    if (step['bodyEn'] != null && (step['kind'] == 'choice')) {
      widgets.add(
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              English(step['bodyEn']),
              if (s.help) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => setState(() => translation = !translation),
                  icon: const Icon(Icons.translate_rounded, size: 18),
                  label: Text(
                    s.t(
                      translation ? 'إخفاء الترجمة' : 'مساعدة بالعربي',
                      translation ? 'Hide Arabic' : 'Arabic help',
                    ),
                  ),
                ),
                if (translation)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      step['bodyAr'],
                      style: const TextStyle(color: muted),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 20));
    } else if (step['bodyAr'] != null) {
      widgets.add(Text(step[s.arabic ? 'bodyAr' : 'bodyEn']));
      widgets.add(const SizedBox(height: 20));
    }
    if (step['kind'] == 'vocabulary') {
      widgets.add(
        LayoutBuilder(
          builder: (context, c) => Wrap(
            spacing: 16,
            runSpacing: 18,
            children: [
              for (final id in step['words'])
                SizedBox(
                  width: (c.maxWidth - 16) / 2,
                  child: PictureWordCard(
                    word: s.catalog.word(id),
                    state: s,
                    voice: SpeechButton(
                      state: s,
                      text: s.catalog.word(id).word,
                    ),
                    onDetails: () => showWord(context, s, s.catalog.word(id)),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    if (step['kind'] == 'listening') {
      widgets.add(
        Surface(
          color: const Color(0xFFECF2FF),
          child: Column(
            children: [
              FloatingArt(
                child: Image.asset('assets/images/audio-art.png', height: 138),
              ),
              const SizedBox(height: 6),
              Text(
                s.t('مايا × عمر', 'MAYA × OMAR'),
                style: const TextStyle(
                  color: blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  SpeechButton(
                    state: s,
                    text: step['audio'],
                    label: s.t('استمع', 'Listen'),
                  ),
                  SpeechButton(
                    state: s,
                    text: step['audio'],
                    slow: true,
                    label: s.t('ببطء', 'Slowly'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                s.t(
                  'أصوات ElevenLabs • متاحة دون اتصال',
                  'ElevenLabs voices • available offline',
                ),
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 14));
      widgets.add(
        OutlinedButton.icon(
          onPressed: () => setState(() => transcript = !transcript),
          icon: const Icon(Icons.notes_rounded),
          label: Text(
            s.t(
              transcript ? 'إخفاء النص' : 'اعرض نص الحوار',
              transcript ? 'Hide transcript' : 'Reveal transcript',
            ),
          ),
        ),
      );
      if (transcript) {
        widgets.add(const SizedBox(height: 14));
        widgets.add(
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConversationBubbles(text: step['audio'], state: s),
                if (s.help) ...[
                  const Divider(height: 30),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      step['translation'],
                      style: const TextStyle(color: muted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }
    }
    if (step['example'] != null) {
      widgets.add(
        Surface(
          color: const Color(0xFFECF2FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              English(
                step['example'],
                style: const TextStyle(
                  color: blue,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  height: 1.65,
                ),
              ),
              if (step['translation'] != null && s.help) ...[
                const SizedBox(height: 10),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    step['translation'],
                    style: const TextStyle(color: muted),
                  ),
                ),
              ],
              if (step['kind'] != 'choice')
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SpeechButton(state: s, text: step['example']),
                ),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 18));
    }
    if (step['formula'] != null) {
      widgets.add(
        Surface(
          color: const Color(0xFFFFF3E8),
          child: English(
            step['formula'],
            style: const TextStyle(
              color: Color(0xFFAA5A1B),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    if (question) {
      widgets.add(
        Text(
          step[s.arabic ? 'promptAr' : 'promptEn'],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      );
      widgets.add(const SizedBox(height: 16));
      if (step['kind'] == 'order') {
        final options = (step['options'] as List).cast<String>();
        widgets.add(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              constraints: const BoxConstraints(minHeight: 90),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: line),
              ),
              child: ordered.isEmpty
                  ? Text(
                      s.t(
                        'اضغط على الكلمات بالترتيب',
                        'Tap the words in order',
                      ),
                      style: const TextStyle(color: muted),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ordered
                          .map(
                            (i) => InputChip(
                              label: Text(options[i]),
                              onDeleted: checked == true
                                  ? null
                                  : () => setState(() {
                                      ordered.remove(i);
                                      checked = null;
                                    }),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        );
        widgets.add(const SizedBox(height: 18));
        widgets.add(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                options.length,
                (i) => OutlinedButton(
                  onPressed: ordered.contains(i) || checked == true
                      ? null
                      : () => setState(() {
                          ordered.add(i);
                          checked = null;
                        }),
                  child: Text(options[i]),
                ),
              ),
            ),
          ),
        );
      } else {
        final options = (step['options'] as List).cast<String>();
        for (var i = 0; i < options.length; i++) {
          final option = options[i];
          final active = selected == option;
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                selected: active,
                button: true,
                child: InkWell(
                  key: Key('option-$i'),
                  onTap: checked == true
                      ? null
                      : () => setState(() {
                          selected = option;
                          checked = null;
                        }),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFEDF2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: active ? blue : line,
                        width: active ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (active ? blue : const Color(0xFF7F9BBF))
                              .withValues(alpha: active ? .15 : .09),
                          blurRadius: 16,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? blue : canvas,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: TextStyle(
                              color: active ? Colors.white : muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        if (step['id'] == 't-listen-check' ||
                            step['id'] == 't-vocab-check') ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/${step['id'] == 't-vocab-check' ? ['weather-art', 'breeze-art', 'beach-scene'][i] : ['home-art', 'beach-scene', 'education-art'][i]}.png',
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: English(
                            option,
                            style: const TextStyle(fontSize: 18, color: ink),
                          ),
                        ),
                        if (active)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: blue,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }

  Widget _feedback(BuildContext context) {
    final correct = checked == true;
    return Semantics(
      liveRegion: true,
      child: Celebration(
        key: ValueKey(correct),
        active: correct,
        child: Surface(
          color: correct ? const Color(0xFFE8F5EE) : const Color(0xFFFFF2E6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    correct
                        ? Icons.check_circle_rounded
                        : Icons.lightbulb_rounded,
                    color: correct ? green : const Color(0xFFAF641B),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      correct
                          ? s.t('أحسنت، وصلت للفكرة!', 'You’ve got it!')
                          : s.t(
                              'قريب منها، خلّنا نفهم السبب.',
                              'Close. Let’s look at why.',
                            ),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: correct ? green : const Color(0xFFAF641B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(step[s.arabic ? 'explanationAr' : 'explanationEn']),
              if (!correct) ...[
                const SizedBox(height: 8),
                Text(
                  s.t(
                    'عدّل إجابتك وجرّب مرة ثانية.',
                    'Change your answer and try again.',
                  ),
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _completion(BuildContext context) {
    final p = s.forLesson(lesson.id);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Celebration(
                    child: FloatingArt(
                      child: Image.asset(
                        'assets/images/travel-kit.png',
                        height: 210,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    s.t('خطوة تستحق تفتخر فيها.', 'A step to feel good about.'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.t(
                      'أكملت «${lesson.title(true)}». خذ نفسًا، ثم ارجع لما تعلمته وقت ما تحتاج.',
                      'You completed “${lesson.title(false)}”. Take a breath, and revisit it whenever you need.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 17,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Surface(
                    child: Column(
                      children: [
                        English(
                          '${lesson.questionCount}',
                          align: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 36,
                            color: blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          s.t(
                            'تدريبات أنجزتها',
                            'Practice activities completed',
                          ),
                          style: const TextStyle(color: muted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.t(
                            '${p.firstCorrect} من ${lesson.questionCount} مباشرة من أول محاولة',
                            '${p.firstCorrect} of ${lesson.questionCount} correct on the first attempt',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.t(
                            'المراجعة والمحاولة الثانية جزء من التعلّم.',
                            'Revisiting and retrying are part of learning.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (lesson.id == 'foundation-1') ...[
                    FilledButton(
                      onPressed: () {
                        s.activate('travel-1');
                        if (s.forLesson('travel-1').complete) {
                          s.restart('travel-1');
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonScreen(
                              state: s,
                              lesson: s.catalog.lesson('travel-1'),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        s.t('أجرّب جلسة السفر', 'Try the travel session'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (lesson.id != 'foundation-1' &&
                      s.catalog.nextLesson(lesson.id) != null) ...[
                    FilledButton.icon(
                      onPressed: () {
                        final next = s.catalog.nextLesson(lesson.id)!;
                        s.activate(next.id);
                        if (s.forLesson(next.id).complete) {
                          s.restart(next.id);
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LessonScreen(state: s, lesson: next),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        s.t(
                          'الجلسة التالية: ${s.catalog.nextLesson(lesson.id)!.title(true)}',
                          'Next: ${s.catalog.nextLesson(lesson.id)!.title(false)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: () {
                      s.changeTab(3);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.bar_chart_rounded),
                    label: Text(s.t('شاهد تقدمي', 'See my progress')),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      s.changeTab(0);
                      Navigator.pop(context);
                    },
                    child: Text(s.t('العودة للرئيسية', 'Back to home')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showListeningPractice(BuildContext context, AppState s) {
  final content = s.catalog
      .lesson('travel-1')
      .steps
      .firstWhere((step) => step['kind'] == 'listening');
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(Icons.headphones_rounded, color: blue, size: 56),
          ),
          const SizedBox(height: 16),
          Text(
            s.t('اسمع خطة الرحلة', 'Listen to the plan'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SpeechButton(
                state: s,
                text: content['audio'],
                label: s.t('استمع', 'Listen'),
              ),
              SpeechButton(
                state: s,
                text: content['audio'],
                slow: true,
                label: s.t('ببطء', 'Slowly'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          English(content['audio']),
          if (s.help) ...[
            const Divider(height: 28),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                content['translation'],
                style: const TextStyle(color: muted),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            s.t(
              'أصوات ElevenLabs • هذه المراجعة لا تغيّر مكانك في الجلسة.',
              'ElevenLabs voices • This review keeps your session place.',
            ),
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.t('رجوع', 'Back')),
          ),
        ],
      ),
    ),
  ).whenComplete(speech.stop);
}

void showDictionary(
  BuildContext context,
  AppState s, {
  bool savedOnly = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => DictionarySheet(state: s, savedOnly: savedOnly),
  );
}

class DictionarySheet extends StatefulWidget {
  final AppState state;
  final bool savedOnly;
  const DictionarySheet({
    super.key,
    required this.state,
    this.savedOnly = false,
  });
  @override
  State<DictionarySheet> createState() => _DictionarySheetState();
}

class _DictionarySheetState extends State<DictionarySheet> {
  String query = '';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.state,
    builder: (context, _) {
      final s = widget.state;
      final words = s.catalog.words
          .where(
            (w) =>
                (!widget.savedOnly || s.saved.contains(w.id)) &&
                ('${w.word} ${w.ar}'.toLowerCase().contains(
                  query.toLowerCase().trim(),
                )),
          )
          .toList();
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.savedOnly
                          ? s.t('كلماتي المحفوظة', 'My saved words')
                          : s.t('قاموس رحلتك', 'Your travel vocabulary'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: s.t('إغلاق', 'Close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: s.t(
                    'ابحث بالعربي أو الإنجليزي',
                    'Search in English or Arabic',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: words.isEmpty
                    ? Center(
                        child: Text(
                          s.t(
                            'ما فيه كلمات هنا بعد. احفظ كلمة من القاموس أو جرّب بحثًا آخر.',
                            'No words here yet. Bookmark a word or try another search.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: words.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, i) {
                          final w = words[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(symbolIcon(w.symbol), color: blue),
                            title: English(
                              w.word,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            subtitle: s.help
                                ? Text(w.ar)
                                : English(
                                    w.definition,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 13,
                                    ),
                                  ),
                            trailing: IconButton(
                              tooltip: s.t('حفظ الكلمة', 'Bookmark word'),
                              onPressed: () => s.toggleSaved(w.id),
                              icon: Icon(
                                s.saved.contains(w.id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: blue,
                              ),
                            ),
                            onTap: () => showWord(context, s, w),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showWord(BuildContext context, AppState s, StudyWord w) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => AnimatedBuilder(
      animation: s,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: English(
                    w.word,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: blue,
                    ),
                  ),
                ),
                SpeechButton(state: s, text: w.word),
                IconButton(
                  tooltip: s.t('حفظ الكلمة', 'Bookmark word'),
                  onPressed: () => s.toggleSaved(w.id),
                  icon: Icon(
                    s.saved.contains(w.id)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: blue,
                  ),
                ),
              ],
            ),
            if (s.help)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  w.ar,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            const SizedBox(height: 10),
            English(w.definition),
            const SizedBox(height: 20),
            Surface(
              color: const Color(0xFFECF2FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  English(w.example),
                  if (s.help) ...[
                    const SizedBox(height: 10),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        w.exampleAr,
                        style: const TextStyle(color: muted),
                      ),
                    ),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SpeechButton(state: s, text: w.example),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.t('رجوع', 'Back')),
            ),
          ],
        ),
      ),
    ),
  );
}

void showSettings(BuildContext context, AppState s) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => AnimatedBuilder(
      animation: s,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.t('خلّها على راحتك', 'Make yourself at home'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('العربية / Arabic'),
              subtitle: Text(s.t('لغة الواجهة', 'Interface language')),
              value: s.arabic,
              onChanged: (v) => s.settings(language: v),
            ),
            SwitchListTile(
              title: Text(s.t('مساعدة عربية', 'Arabic assistance')),
              subtitle: Text(
                s.t(
                  'معاني الكلمات وترجمة الأمثلة',
                  'Word meanings and example translations',
                ),
              ),
              value: s.help,
              onChanged: (v) => s.settings(assistance: v),
            ),
            SwitchListTile(
              title: Text(s.t('الصوت', 'Audio')),
              subtitle: Text(
                s.t(
                  'أصوات إنجليزية مرفقة ومؤثرات التفاعل',
                  'Bundled English voices and interaction sounds',
                ),
              ),
              value: s.sound,
              onChanged: (v) => s.settings(audio: v),
            ),
            const Divider(height: 26),
            Text(
              s.t(
                'نسخة تفاعلية 0.2.2 • جلسة سفر وجسر تمهيدي\nالتقدم محفوظ محليًا على هذا الجهاز.',
                'Interactive preview 0.2.2 • Travel session and prerequisite bridge\nProgress is stored locally on this device.',
              ),
              style: const TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              s.t(
                'تم تصميم هذا البرنامج بواسطة الأستاذ محمد سعود المطيري',
                'Designed by Mr. Mohammed Saud Al-Mutairi',
              ),
              style: const TextStyle(color: muted, fontSize: 13),
            ),
            if (s.storageProblem) ...[
              const SizedBox(height: 12),
              Text(
                s.t(
                  'تعذّر الوصول للتخزين المحلي. قد لا يبقى تقدمك بعد الإغلاق.',
                  'Local storage is unavailable. Your progress may not survive closing the app.',
                ),
                style: const TextStyle(color: Color(0xFFAD611D)),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                final reset = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(s.t('نبدأ من جديد؟', 'Start fresh?')),
                    content: Text(
                      s.t(
                        'سيُمسح التقدم والكلمات المحفوظة على هذا الجهاز.',
                        'This removes progress and bookmarks from this device.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(s.t('إلغاء', 'Cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(s.t('مسح التقدم', 'Reset progress')),
                      ),
                    ],
                  ),
                );
                if (reset == true && context.mounted) {
                  Navigator.pop(context);
                  await s.reset();
                }
              },
              child: Text(s.t('إعادة ضبط تقدمي', 'Reset my progress')),
            ),
          ],
        ),
      ),
    ),
  );
}

class ReviewScreen extends StatefulWidget {
  final AppState state;
  const ReviewScreen({super.key, required this.state});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final List<StudyWord> deck = widget.state.dueWords();
  int index = 0;
  bool revealed = false;
  int recalled = 0;
  AppState get s => widget.state;
  @override
  void dispose() {
    speech.stop();
    super.dispose();
  }

  void answer(bool correct) {
    s.review(deck[index].id, correct);
    speech.stop();
    setState(() {
      if (correct) recalled++;
      index++;
      revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: s,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(s.t('مراجعة الكلمات', 'Word review'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: index >= deck.length
                  ? _done(context)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Tag(s.t('استرجع ثم اكشف', 'RECALL, THEN REVEAL')),
                            const Spacer(),
                            English(
                              '${index + 1} / ${deck.length}',
                              style: const TextStyle(color: muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          s.t(
                            'ما معنى هذه الكلمة؟',
                            'What does this word mean?',
                          ),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.t(
                            'حاول تتذكر قبل ما تقلب البطاقة.',
                            'Try to recall it before turning the card.',
                          ),
                          style: const TextStyle(color: muted),
                        ),
                        const SizedBox(height: 30),
                        Surface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(
                                symbolIcon(deck[index].symbol),
                                color: blue,
                                size: 68,
                              ),
                              const SizedBox(height: 24),
                              English(
                                deck[index].word,
                                align: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: blue,
                                ),
                              ),
                              Center(
                                child: SpeechButton(
                                  state: s,
                                  text: deck[index].word,
                                ),
                              ),
                              if (revealed) ...[
                                const Divider(height: 30),
                                if (s.arabic || s.help)
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      deck[index].ar,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                    ),
                                  ),
                                English(
                                  deck[index].definition,
                                  align: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                English(
                                  deck[index].example,
                                  align: TextAlign.center,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!revealed)
                          FilledButton.icon(
                            onPressed: () => setState(() => revealed = true),
                            icon: const Icon(Icons.flip_rounded),
                            label: Text(s.t('اكشف المعنى', 'Reveal meaning')),
                          )
                        else ...[
                          FilledButton.icon(
                            onPressed: () => answer(true),
                            icon: const Icon(Icons.check_rounded),
                            label: Text(s.t('تذكّرتها', 'I remembered')),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => answer(false),
                            child: Text(
                              s.t('أحتاج أراجعها', 'I need more practice'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            s.t(
                              'إجابتك للتقييم الذاتي وتحديد موعد المراجعة.',
                              'Your self-assessment sets the next review date.',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _done(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(Icons.spa_rounded, color: green, size: 84),
      const SizedBox(height: 24),
      Text(
        deck.isEmpty
            ? s.t('أعطِ ذاكرتك وقتها.', 'Give your memory a little time.')
            : s.t('مراجعة صغيرة أنجزتها.', 'A little review, well done.'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 16),
      Text(
        deck.isEmpty
            ? s.t(
                'كل الكلمات لها موعد مراجعة قادم. تقدر تتصفح القاموس في أي وقت.',
                'All words have a future review date. You can browse the vocabulary any time.',
              )
            : s.t(
                'تذكّرت $recalled من ${deck.length} كلمات حسب تقييمك. الكلمات الصعبة ترجع بعد 10 دقائق، والبقية غدًا أو لاحقًا.',
                'You recalled $recalled of ${deck.length} words by your own assessment. Difficult words return in 10 minutes; others tomorrow or later.',
              ),
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted, fontSize: 16, height: 1.8),
      ),
      const SizedBox(height: 28),
      FilledButton(
        onPressed: () => showDictionary(context, s),
        child: Text(s.t('تصفح الكلمات', 'Browse vocabulary')),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child: Text(s.t('العودة', 'Back')),
      ),
    ],
  );
}
