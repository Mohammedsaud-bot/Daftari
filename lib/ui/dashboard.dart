import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/effects.dart';
import '../core/theme.dart';
import 'components.dart';
import 'study_screens.dart';

class WelcomeScreen extends StatefulWidget {
  final AppState state;
  const WelcomeScreen({super.key, required this.state});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool bridge = false;
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DesignerCredit(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const BrandMark(size: 42),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => s.settings(language: !s.arabic),
                        icon: const Icon(Icons.language_rounded, size: 18),
                        label: Text(s.arabic ? 'English' : 'العربية'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Image.asset(
                    'assets/images/study-book.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Tag(
                      s.t('كتابك، بطريقة أقرب لك', 'YOUR BOOK. YOUR PACE.'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.t('أهلًا بخطوتك الأولى.', 'A good place to begin.'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.t(
                      'نفهم معًا، نتدرّب بهدوء، ونتقدم خطوة خطوة. اختر البداية المناسبة لك.',
                      'Understand, practise, and move forward one small step at a time. Choose your starting point.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _pathCard(
                    false,
                    Icons.auto_stories_rounded,
                    s.t('أدرس Book 12', 'I’m studying Book 12'),
                    s.t(
                      'ابدأ بجلسة السفر التفاعلية',
                      'Start the interactive travel session',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _pathCard(
                    true,
                    Icons.spa_rounded,
                    s.t('أحتاج بداية أبسط', 'I’d like a gentler start'),
                    s.t(
                      'جسر قصير يجهّزك للجلسة الأولى',
                      'A short bridge into your first session',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('start-journey'),
                    onPressed: () => s.start(bridge),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(s.t('ابدأ رحلتي', 'Start my journey')),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.t(
                      'بدون حساب • تقدمك يُحفظ على هذا الجهاز',
                      'No account needed • Progress saved on this device',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pathCard(bool value, IconData icon, String title, String subtitle) {
    final selected = bridge == value;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => setState(() => bridge = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEDF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? blue : line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: blue, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? blue : line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  final AppState state;
  const AppShell({super.key, required this.state});
  void openLesson(BuildContext context, String id) {
    state.activate(id);
    if (state.forLesson(id).complete) state.restart(id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LessonScreen(state: state, lesson: state.catalog.lesson(id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    final pages = [
      HomePage(state: s, open: (id) => openLesson(context, id)),
      LessonsPage(state: s, open: (id) => openLesson(context, id)),
      PracticePage(state: s),
      ProgressPage(state: s),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: DesignerCredit(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
                  child: Row(
                    children: [
                      const BrandMark(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.t('دفتر المذاكرة', 'Daftari'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            const English(
                              'AMERICAN LANGUAGE COURSE',
                              style: TextStyle(
                                color: muted,
                                fontSize: 9,
                                letterSpacing: 1.2,
                                height: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassAction(
                        tooltip: s.t('بحث في الكلمات', 'Search vocabulary'),
                        onPressed: () => showDictionary(context, s),
                        icon: Icons.search_rounded,
                      ),
                      GlassAction(
                        tooltip: s.t('الإعدادات', 'Settings'),
                        onPressed: () => showSettings(context, s),
                        icon: Icons.tune_rounded,
                      ),
                    ],
                  ),
                ),
                Expanded(child: pages[s.tab]),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFE6EEFF)],
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3C5B9C).withValues(alpha: .28),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(4, (i) {
                  final labels = [
                    s.t('الرئيسية', 'Home'),
                    s.t('الدروس', 'Lessons'),
                    s.t('التدريب', 'Practice'),
                    s.t('تقدمي', 'Progress'),
                  ];
                  final icons = [
                    Icons.home_rounded,
                    Icons.layers_rounded,
                    Icons.track_changes_rounded,
                    Icons.bar_chart_rounded,
                  ];
                  final active = i == s.tab;
                  return Expanded(
                    child: Semantics(
                      selected: active,
                      child: InkWell(
                        key: Key('nav-$i'),
                        onTap: () => s.changeTab(i),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 2,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFCADEFF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icons[i],
                                color: active ? blue : muted,
                                size: 25,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: active ? blue : muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final AppState state;
  final ValueChanged<String> open;
  const HomePage({super.key, required this.state, required this.open});
  @override
  Widget build(BuildContext context) {
    final s = state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.t(
                  'خطوة صغيرة اليوم، ثقة أكبر بكرة',
                  'A LITTLE TODAY. MORE CONFIDENCE TOMORROW.',
                ),
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Tag('BOOK 12', icon: Icons.auto_stories_rounded),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          s.t('تعلّم بخطوة واضحة', 'Your next adventure.'),
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: 34),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 110,
            height: 5,
            margin: const EdgeInsets.only(top: 3, bottom: 21),
            decoration: BoxDecoration(
              color: orange,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final hero = _hero(context);
            return c.maxWidth > 780
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: hero),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _daily(context)),
                    ],
                  )
                : hero;
          },
        ),
        SectionTitle(
          s.t('اختر وجهتك', 'Choose your destination'),
          action: s.t('كل الدروس', 'All lessons'),
          onAction: () => s.changeTab(1),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 800 ? 4 : 2;
            return Wrap(
              spacing: 16,
              runSpacing: 22,
              children: s.catalog.units
                  .take(4)
                  .map(
                    (u) => SizedBox(
                      width: (c.maxWidth - (cols - 1) * 16) / cols,
                      child: UnitCard(
                        unit: u,
                        state: s,
                        onTap: () =>
                            u['available'] == true &&
                                s.catalog.unitLessons(u['id']).isNotEmpty
                            ? open(s.catalog.unitLessons(u['id']).first.id)
                            : showUnitDetails(context, s, u),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 28),
        _practice(context),
        const SizedBox(height: 22),
        LiftCard(
          onTap: () => open('foundation-1'),
          child: Surface(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/study-book.png',
                  width: 62,
                  height: 62,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.t(
                          'أول مرة؟ نمشيها معًا',
                          'First time? Start gently.',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        s.t(
                          'جسر البداية • 4 دقائق على راحتك',
                          'Starting bridge • 4 minutes at your pace',
                        ),
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: blue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 23),
        Text(
          s.t(
            'تعلم على راحتك • تقدمك محفوظ على جهازك',
            'YOUR PACE • YOUR PROGRESS, SAVED ON THIS DEVICE',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: muted, letterSpacing: .4),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    final s = state;
    final l = s.current;
    final p = s.forLesson(l.id);
    final fraction = p.complete ? 1.0 : p.step / l.steps.length;
    return LiftCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(52),
            topRight: Radius.circular(32),
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(52),
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF15317F), Color(0xFF225BCD), Color(0xFF428AF3)],
          ),
          border: Border.all(color: const Color(0xFF89C2FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF164AA7).withValues(alpha: .32),
              blurRadius: 30,
              offset: const Offset(0, 19),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 2,
              offset: Offset(-1, -2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 370;
            final artWidth = c.maxWidth * .46;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: IgnorePointer(
                    child: Container(
                      width: c.maxWidth * .7,
                      height: 160,
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          colors: [Color(0x666AB7FF), Color(0x006AB7FF)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -13,
                  bottom: 12,
                  width: artWidth,
                  child: FloatingArt(
                    child: Image.asset(
                      'assets/images/study-book.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(22, 25, artWidth - 17, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFEAD7), Color(0xFFFFC896)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .8),
                          ),
                        ),
                        child: Text(
                          p.step > 0
                              ? s.t('تابع من حيث توقفت', 'PICK UP YOUR JOURNEY')
                              : s.t(
                                  'جاهز لمغامرة جديدة؟',
                                  'READY FOR AN ADVENTURE?',
                                ),
                          style: const TextStyle(
                            color: Color(0xFF974310),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      Text(
                        l.title(s.arabic),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: narrow ? 26 : 32,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.t(
                          'رحلة تفاعلية • ${l.minutes} دقائق',
                          'An interactive journey • ${l.minutes} min',
                        ),
                        style: const TextStyle(
                          color: Color(0xFFD1DFFF),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        p.complete
                            ? s.t(
                                'رحلة مكتملة، وتقدر تعيدها',
                                'COMPLETED • REVISIT ANYTIME',
                              )
                            : s.t(
                                'إنجازك ${(fraction * 100).round()}٪',
                                '${(fraction * 100).round()}% COMPLETE',
                              ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 650),
                          tween: Tween(begin: 0, end: fraction),
                          builder: (_, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 10,
                            color: const Color(0xFF32CBFF),
                            backgroundColor: Colors.white.withValues(alpha: .3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 19),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF102864,
                              ).withValues(alpha: .45),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFB74E), Color(0xFFFF750C)],
                          ),
                        ),
                        child: FilledButton.icon(
                          key: const Key('hero-start'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(130, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 17),
                            side: const BorderSide(color: Color(0xFFFFD18C)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () => open(l.id),
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                          label: Text(
                            p.complete
                                ? s.t('نجرّب من جديد', 'Revisit')
                                : p.step > 0
                                ? s.t('متابعة', 'Continue')
                                : s.t('نبدأ الرحلة', 'Let’s go'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _daily(BuildContext context) => Surface(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
          child: Image.asset(
            'assets/images/beach-scene.png',
            height: 160,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tag(
                state.t('مهمة اليوم', 'TODAY’S MISSION'),
                color: const Color(0xFFB85A17),
                icon: Icons.explore_rounded,
              ),
              const SizedBox(height: 9),
              Text(
                state.t('وين نروح يوم الجمعة؟', 'Where shall we go on Friday?'),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                state.t(
                  'اسمع الخطة، راقب الطقس، وخذ القرار.',
                  'Hear the plan, check the weather, make the call.',
                ),
                style: const TextStyle(color: muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _practice(BuildContext context) {
    final s = state;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF64A8F8), Color(0xFF2359C6), Color(0xFF18317F)],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFF9CCEFF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: blue.withValues(alpha: .26),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.t('شحنة تدريب سريعة', 'A quick confidence boost'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _quick(
                  'audio-art',
                  s.t('استماع', 'Listen'),
                  () => showListeningPractice(context, s),
                ),
              ),
              Container(
                width: 1,
                height: 64,
                color: Colors.white.withValues(alpha: .22),
              ),
              Expanded(
                child: _quick(
                  'study-book',
                  s.t('كلمات', 'Words'),
                  () => showDictionary(context, s),
                ),
              ),
              Container(
                width: 1,
                height: 64,
                color: Colors.white.withValues(alpha: .22),
              ),
              Expanded(
                child: _quick(
                  'travel-kit',
                  s.t('مراجعة', 'Review'),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReviewScreen(state: s)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quick(String asset, String label, VoidCallback tap) => LiftCard(
    onTap: () {
      effects.play('tap', sound: state.sound);
      tap();
    },
    child: Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFDCE9FF)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF102A77).withValues(alpha: .4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset('assets/images/$asset.png'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class UnitCard extends StatelessWidget {
  final Map<String, dynamic> unit;
  final AppState state;
  final VoidCallback onTap;
  const UnitCard({
    super.key,
    required this.unit,
    required this.state,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final warm = unit['number'] % 2 == 0;
    final asset = switch (unit['id']) {
      'travel' => 'travel-kit',
      'education' => 'education-art',
      'home' => 'home-art',
      _ => 'nature-art',
    };
    return LiftCard(
      onTap: () {
        effects.play('tap', sound: state.sound);
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: warm
                ? [const Color(0xFFFFFCF9), const Color(0xFFFFE6D3)]
                : [const Color(0xFFF8FBFF), const Color(0xFFBFD9FF)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: (warm ? const Color(0xFFB19AA0) : const Color(0xFF6D8CBF))
                  .withValues(alpha: .28),
              blurRadius: 22,
              offset: const Offset(0, 13),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 4,
              offset: Offset(-2, -3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      '${unit['number']}',
                      style: const TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      unit['available'] == true
                          ? state.t('ابدأ الاستكشاف', 'EXPLORE')
                          : state.t('قريبًا', 'COMING SOON'),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              FloatingArt(
                distance: 5,
                child: Image.asset(
                  'assets/images/$asset.png',
                  height: 112,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unit[state.arabic ? 'ar' : 'en'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                unit[state.arabic ? 'subtitleAr' : 'subtitleEn'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showUnitDetails(
  BuildContext context,
  AppState s,
  Map<String, dynamic> unit,
) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tag(s.t('قيد الإعداد', 'UPCOMING'), color: orange),
            const SizedBox(height: 16),
            Text(
              unit[s.arabic ? 'ar' : 'en'],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(unit[s.arabic ? 'topicsAr' : 'topicsEn']),
            const SizedBox(height: 16),
            Text(
              s.t(
                'النسخة الحالية تشمل جلسة السفر وجسر البداية. سنضيف محتوى هذه الوحدة في مرحلة لاحقة.',
                'This first version includes the travel session and starting bridge. This unit’s activities will be added in a later increment.',
              ),
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.t('فهمت', 'Got it')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LessonsPage extends StatelessWidget {
  final AppState state;
  final ValueChanged<String> open;
  const LessonsPage({super.key, required this.state, required this.open});
  @override
  Widget build(BuildContext context) {
    final s = state;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          s.t('مسارك، خطوة خطوة.', 'Your path, one step at a time.'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          s.t(
            'جلسة واحدة واضحة في كل مرة. ارجع لأي خطوة وقت ما تحتاج.',
            'One clear session at a time. Revisit any step when you need to.',
          ),
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 22),
        Surface(
          color: const Color(0xFFECF6F1),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.spa_rounded, color: green, size: 32),
            title: Text(
              s.t('جسر البداية', 'Starting bridge'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              s.t(
                'تمهيد قصير لجلسة السفر • 4 دقائق',
                'A short travel prerequisite • 4 min',
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => open('foundation-1'),
          ),
        ),
        const SizedBox(height: 20),
        ...s.catalog.units.map(
          (u) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/${switch (u['id']) {
                          'travel' => 'travel-kit',
                          'education' => 'education-art',
                          'home' => 'home-art',
                          'outdoors' => 'nature-art',
                          _ => 'study-book',
                        }}.png',
                        width: 54,
                        height: 54,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          u[s.arabic ? 'ar' : 'en'],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Tag(
                        u['available']
                            ? s.t(
                                '${s.catalog.unitLessons(u['id']).length} جلسات',
                                '${s.catalog.unitLessons(u['id']).length} SESSIONS',
                              )
                            : s.t('قيد الإعداد', 'UPCOMING'),
                        color: u['available'] ? blue : muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    u[s.arabic ? 'topicsAr' : 'topicsEn'],
                    style: const TextStyle(color: muted, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: u['available']
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final l in s.catalog.unitLessons(u['id']))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: s.forLesson(l.id).complete
                                      ? OutlinedButton.icon(
                                          onPressed: () => open(l.id),
                                          icon: const Icon(
                                            Icons.check_circle_rounded,
                                            color: green,
                                          ),
                                          label: Text(
                                            '${l.title(s.arabic)} • ${s.t('${l.minutes} دقائق', '${l.minutes} min')}',
                                          ),
                                        )
                                      : FilledButton.icon(
                                          onPressed: () => open(l.id),
                                          icon: const Icon(
                                            Icons.play_arrow_rounded,
                                          ),
                                          label: Text(
                                            '${l.title(s.arabic)} • ${s.t('${l.minutes} دقائق', '${l.minutes} min')}',
                                          ),
                                        ),
                                ),
                            ],
                          )
                        : OutlinedButton(
                            onPressed: () => showUnitDetails(context, s, u),
                            child: Text(
                              s.t('ماذا سنتعلم؟', 'What will we learn?'),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PracticePage extends StatelessWidget {
  final AppState state;
  const PracticePage({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final s = state;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          s.t('قليل من التدريب، فرق كبير.', 'Small practice. Real progress.'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          s.t(
            'استرجع الكلمة من ذاكرتك، ثم شاهد المعنى. نحدد موعد مراجعتها حسب إجابتك.',
            'Recall a word before revealing its meaning. Your answer sets its next review date.',
          ),
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        Surface(
          color: const Color(0xFFECF2FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FloatingArt(
                child: Image.asset('assets/images/travel-kit.png', height: 140),
              ),
              const SizedBox(height: 12),
              Text(
                s.t(
                  '${s.dueWords().length} كلمات جاهزة للمراجعة',
                  '${s.dueWords().length} words ready to review',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                s.t(
                  'مراجعة قصيرة، بدون مؤقت أو ضغط.',
                  'A short review. No timer, no pressure.',
                ),
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReviewScreen(state: s)),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(s.t('ابدأ المراجعة', 'Start review')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Surface(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Image.asset(
              'assets/images/study-book.png',
              width: 56,
              height: 56,
            ),
            title: Text(
              s.t('قاموس كتاب 12', 'Book 12 vocabulary'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              s.t(
                '${s.catalog.words.length} كلمة مع أمثلة ونطق',
                '${s.catalog.words.length} words with examples and pronunciation',
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showDictionary(context, s),
          ),
        ),
        const SizedBox(height: 16),
        Surface(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.bookmark_rounded,
              color: orange,
              size: 32,
            ),
            title: Text(
              s.t('كلماتي المحفوظة', 'My saved words'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              s.t(
                '${s.saved.length} كلمات حفظتها للمراجعة',
                '${s.saved.length} words bookmarked for later',
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showDictionary(context, s, savedOnly: true),
          ),
        ),
      ],
    );
  }
}

class ProgressPage extends StatelessWidget {
  final AppState state;
  const ProgressPage({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final s = state;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          s.t('شوف خطواتك تكبر.', 'See your steps add up.'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          s.t(
            'هذا سجل ما أنجزته في النسخة الحالية. إكمال الجلسة لا يعني إتقان الكتاب كاملًا.',
            'Your activity in this first version. Completing a session is different from mastering the whole book.',
          ),
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _stat(
              context,
              '${s.completed}',
              s.t('جلسات مكتملة', 'Sessions completed'),
              Icons.check_circle_outline_rounded,
            ),
            _stat(
              context,
              '${s.correctAnswers}',
              s.t('صحيحة من أول محاولة', 'Correct on first try'),
              Icons.track_changes_rounded,
            ),
            _stat(
              context,
              '${s.reviews.length}',
              s.t('كلمات راجعتها', 'Words reviewed'),
              Icons.style_rounded,
            ),
          ],
        ),
        SectionTitle(s.t('تفاصيل جلساتك', 'Your sessions')),
        ...s.catalog.lessons.map((l) {
          final p = s.forLesson(l.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.title(s.arabic),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Tag(
                        p.complete
                            ? s.t('مكتملة', 'COMPLETE')
                            : p.step > 0
                            ? s.t('بدأتها', 'IN PROGRESS')
                            : s.t('لم تبدأ', 'NOT STARTED'),
                        color: p.complete ? green : blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: p.complete ? 1 : p.step / l.steps.length,
                      minHeight: 7,
                      backgroundColor: line,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.t(
                      '${p.firstCorrect} من ${l.questionCount} إجابات صحيحة من أول محاولة',
                      '${p.firstCorrect} of ${l.questionCount} correct on the first attempt',
                    ),
                    style: const TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Surface(
          color: const Color(0xFFFFF3E8),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFC2721D),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.t(
                    'المحاولة الثانية جزء من التعلم. ارجع للتفسير وجرّب من جديد.',
                    'A second try is part of learning. Read the explanation and try again.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) => SizedBox(
    width: 200,
    child: Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: blue),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: blue,
            ),
          ),
          Text(label, style: const TextStyle(color: muted, fontSize: 13)),
        ],
      ),
    ),
  );
}
