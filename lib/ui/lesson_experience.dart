import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/effects.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'components.dart';

class MissionRail extends StatelessWidget {
  final int step;
  final AppState state;
  const MissionRail({super.key, required this.step, required this.state});
  @override
  Widget build(BuildContext context) {
    final stage = step == 0
        ? 0
        : step <= 2
        ? 1
        : step <= 4
        ? 2
        : step <= 7
        ? 3
        : 4;
    final labels = state.arabic
        ? ['المهمة', 'اكتشف', 'اسمع', 'جرّب', 'انطلق']
        : ['Mission', 'Discover', 'Listen', 'Build', 'Go!'];
    const icons = [
      Icons.explore_rounded,
      Icons.style_rounded,
      Icons.headphones_rounded,
      Icons.touch_app_rounded,
      Icons.flag_rounded,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 0, 17, 12),
      child: Row(
        children: List.generate(
          5,
          (i) => Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: stage == i ? 37 : 29,
                  height: stage == i ? 37 : 29,
                  decoration: BoxDecoration(
                    color: i < stage
                        ? blue
                        : stage == i
                        ? orange
                        : Colors.white.withValues(alpha: .8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (stage == i ? orange : blue).withValues(
                          alpha: .14,
                        ),
                        blurRadius: 9,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    i < stage ? Icons.check_rounded : icons[i],
                    size: 17,
                    color: i <= stage ? Colors.white : muted,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: stage == i ? FontWeight.w700 : FontWeight.w400,
                    color: stage == i ? ink : muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PictureWordCard extends StatelessWidget {
  final StudyWord word;
  final AppState state;
  final Widget voice;
  final VoidCallback onDetails;
  const PictureWordCard({
    super.key,
    required this.word,
    required this.state,
    required this.voice,
    required this.onDetails,
  });
  @override
  Widget build(BuildContext context) {
    final image = switch (word.id) {
      'beach' => 'beach-scene',
      'breeze' => 'breeze-art',
      'climate' || 'expect' => 'weather-art',
      'trip' => 'travel-kit',
      'mountain' => 'nature-art',
      'slippery' => 'mountain-scene',
      'quiet' => 'beach-scene',
      _ when word.data['image'] is String => word.data['image'] as String,
      _ => switch (word.symbol) {
        'school' => 'education-art',
        'home' => 'home-art',
        'nature' => 'nature-art',
        'air' => 'breeze-art',
        'sun' || 'water' => 'weather-art',
        'travel' => 'travel-kit',
        _ => 'study-book',
      },
    };
    return LiftCard(
      child: Surface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              label: state.t(
                'افتح معنى ${word.word}',
                'Open meaning of ${word.word}',
              ),
              child: InkWell(
                onTap: onDetails,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(23),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(23),
                  ),
                  child: Container(
                    height: 110,
                    color: const Color(0xFFEAF1FF),
                    child: Image.asset(
                      'assets/images/$image.png',
                      fit: image.contains('scene')
                          ? BoxFit.cover
                          : BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  English(
                    word.word,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  if (state.help)
                    Text(
                      word.ar,
                      style: const TextStyle(color: muted, fontSize: 14),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                voice,
                IconButton(
                  tooltip: state.t('حفظ الكلمة', 'Bookmark word'),
                  onPressed: () => state.toggleSaved(word.id),
                  icon: Icon(
                    state.saved.contains(word.id)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: blue,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// An ungraded sandbox: change the condition and watch the result change.
class WeatherLab extends StatefulWidget {
  final AppState state;
  final Widget Function(String)? voiceBuilder;
  const WeatherLab({super.key, required this.state, this.voiceBuilder});
  @override
  State<WeatherLab> createState() => _WeatherLabState();
}

class _WeatherLabState extends State<WeatherLab> {
  bool sunny = true;
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.t(
            'أنت تغيّر الطقس. الخطة تتغيّر معه.',
            'You change the weather. The plan follows.',
          ),
          style: const TextStyle(color: muted, fontSize: 15),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _weather(true)),
            const SizedBox(width: 12),
            Expanded(child: _weather(false)),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 450),
          child: sunny
              ? SceneCard(
                  key: const ValueKey('sunny-scene'),
                  height: 190,
                  caption: s.t(
                    'مشمس؟ وجهتنا الشاطئ!',
                    'SUNSHINE? OFF TO THE BEACH!',
                  ),
                )
              : Container(
                  key: const ValueKey('rain-scene'),
                  height: 212,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCCE0FF), Color(0xFFE6EEFF)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/home-art.png',
                          height: 170,
                        ),
                      ),
                      PositionedDirectional(
                        top: 12,
                        start: 14,
                        child: Image.asset(
                          'assets/images/weather-art.png',
                          width: 74,
                          height: 64,
                        ),
                      ),
                      PositionedDirectional(
                        bottom: 12,
                        start: 12,
                        end: 12,
                        child: Text(
                          s.t(
                            'مطر؟ نبقى في البيت ونقرأ.',
                            'RAIN? A GOOD DAY TO STAY HOME.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Tag(s.t('الشرط', 'CONDITION')),
                  Tag(s.t('النتيجة', 'RESULT'), color: const Color(0xFFAF5B19)),
                ],
              ),
              const SizedBox(height: 14),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: sunny ? 'If it is sunny, ' : 'If it rains, ',
                        style: const TextStyle(color: blue),
                      ),
                      TextSpan(
                        text: sunny
                            ? 'we will go to the beach.'
                            : 'we will stay home.',
                        style: const TextStyle(color: Color(0xFFAE5312)),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (s.help) ...[
                const SizedBox(height: 9),
                Text(
                  sunny
                      ? 'إذا كان الجو مشمسًا، سنذهب إلى الشاطئ.'
                      : 'إذا أمطرت، سنبقى في المنزل.',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: muted),
                ),
              ],
              const Divider(height: 28),
              if (widget.voiceBuilder != null) ...[
                widget.voiceBuilder!(
                  sunny
                      ? 'If it is sunny, we will go to the beach.'
                      : 'If it rains, we will stay home.',
                ),
                const SizedBox(height: 14),
              ],
              const English(
                'If + present simple, will + verb',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.t(
                  'بعد if نصف الشرط. بعد will نستخدم الفعل بصورته الأساسية.',
                  'After if, describe the condition. After will, use the base verb.',
                ),
                style: const TextStyle(color: muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weather(bool value) {
    final s = widget.state;
    return OutlinedButton.icon(
      key: Key(value ? 'weather-sunny' : 'weather-rain'),
      style: OutlinedButton.styleFrom(
        backgroundColor: sunny == value
            ? (value ? const Color(0xFFFFE4BF) : const Color(0xFFD5E6FF))
            : Colors.white,
        side: BorderSide(
          color: sunny == value ? blue : Colors.white,
          width: 1.5,
        ),
      ),
      onPressed: () {
        effects.play('tap', sound: s.sound);
        setState(() => sunny = value);
      },
      icon: Icon(
        value ? Icons.wb_sunny_rounded : Icons.water_drop_rounded,
        color: value ? const Color(0xFFC36B0C) : blue,
      ),
      label: Text(value ? s.t('مشمس', 'Sunny') : s.t('ممطر', 'Rainy')),
    );
  }
}

class ConversationBubbles extends StatelessWidget {
  final String text;
  final AppState state;
  const ConversationBubbles({
    super.key,
    required this.text,
    required this.state,
  });
  @override
  Widget build(BuildContext context) {
    final lines = RegExp(
      r'(Maya|Omar):.*?(?=Maya:|Omar:|$)',
    ).allMatches(text).map((m) => m.group(0)!.trim()).toList();
    if (lines.isEmpty) {
      // Narrated passages (e.g. Majed's story) and other dialogues: show the text as one paragraph.
      return English(
        text,
        style: const TextStyle(color: ink, fontSize: 17, height: 1.7),
      );
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: lines
            .asMap()
            .entries
            .map(
              (e) => Padding(
                padding: EdgeInsets.only(
                  bottom: 12,
                  left: e.key.isOdd ? 25 : 0,
                  right: e.key.isEven ? 25 : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: e.key.isEven ? blue : orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        e.key.isEven ? 'M' : 'O',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Surface(
                        padding: const EdgeInsets.all(13),
                        color: e.key.isEven
                            ? const Color(0xFFE9F1FF)
                            : const Color(0xFFFFF0DF),
                        child: Text(
                          e.value,
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
