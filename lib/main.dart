import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'ui/components.dart';
import 'ui/dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DaftariApp());
}

class DaftariApp extends StatefulWidget {
  const DaftariApp({super.key});
  @override
  State<DaftariApp> createState() => _DaftariAppState();
}

class _DaftariAppState extends State<DaftariApp> {
  final state = AppState();
  late Future<void> loading = state.initialize();
  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => MaterialApp(
      title: 'Daftari • دفتر المذاكرة',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      builder: (context, child) =>
          Atmosphere(child: child ?? const SizedBox.shrink()),
      locale: Locale(state.arabic ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: FutureBuilder<void>(
        future: loading,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandMark(size: 64),
                      const SizedBox(height: 24),
                      Text(
                        state.t(
                          'تعذّر فتح المحتوى. جرّب مرة أخرى.',
                          'Could not load the session. Please try again.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            setState(() => loading = state.initialize()),
                        child: Text(state.t('إعادة المحاولة', 'Try again')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandMark(size: 86),
                    SizedBox(height: 24),
                    Text(
                      'دفتر المذاكرة',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text('One step closer.', style: TextStyle(color: muted)),
                    SizedBox(height: 30),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
              ),
            );
          }
          return state.onboarded
              ? AppShell(state: state)
              : WelcomeScreen(state: state);
        },
      ),
    ),
  );
}
