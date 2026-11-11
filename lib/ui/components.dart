import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../core/theme.dart';

class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, color],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .8)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF5E7AB7).withValues(alpha: .17),
          blurRadius: 25,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: .9),
          blurRadius: 4,
          offset: const Offset(-2, -2),
        ),
      ],
    ),
    child: child,
  );
}

/// A layered canvas, with light ribbons and an orange folded corner.
class Atmosphere extends StatelessWidget {
  final Widget child;
  const Atmosphere({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0, .32, .66, 1],
            colors: [
              Color(0xFFCFDFFF),
              Color(0xFFFCFCFF),
              Color(0xFFEDF2FF),
              Color(0xFFD8E5FF),
            ],
          ),
        ),
      ),
      const Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _RibbonPainter())),
      ),
      child,
    ],
  );
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ribbon = Path()
      ..moveTo(0, h * .36)
      ..cubicTo(w * .35, h * .12, w * .7, h * .48, w, h * .2)
      ..lineTo(w, h * .28)
      ..cubicTo(w * .65, h * .54, w * .3, h * .2, 0, h * .45)
      ..close();
    canvas.drawPath(
      ribbon,
      Paint()..color = Colors.white.withValues(alpha: .42),
    );
    final lower = Path()
      ..moveTo(0, h * .82)
      ..cubicTo(w * .4, h * .55, w * .55, h * .98, w, h * .65);
    canvas.drawPath(
      lower,
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final corner = Path()
      ..lineTo(w.clamp(0, 150), 0)
      ..quadraticBezierTo(45, 25, 0, 135)
      ..close();
    canvas.drawShadow(corner, blue.withValues(alpha: .2), 16, false);
    canvas.drawPath(
      corner,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFB858), Color(0xFFFF791B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(0, 0, 150, 135)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 136)
        ..quadraticBezierTo(46, 27, 150, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Finite arrival float, then a quiet resting position; respects reduced motion.
class FloatingArt extends StatefulWidget {
  final Widget child;
  final double distance;
  const FloatingArt({super.key, required this.child, this.distance = 7});
  @override
  State<FloatingArt> createState() => _FloatingArtState();
}

class _FloatingArtState extends State<FloatingArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context)) {
      controller.forward();
    } else {
      controller.value = 1;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (_, child) => Transform.translate(
      offset: Offset(
        0,
        -math.sin(controller.value * math.pi * 4) *
            widget.distance *
            (1 - controller.value),
      ),
      child: child,
    ),
  );
}

class LiftCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const LiftCard({super.key, required this.child, this.onTap});
  @override
  State<LiftCard> createState() => _LiftCardState();
}

class _LiftCardState extends State<LiftCard> {
  bool hover = false;
  bool pressed = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hover = true),
    onExit: (_) => setState(() {
      hover = false;
      pressed = false;
    }),
    child: Listener(
      onPointerDown: (_) => setState(() => pressed = true),
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translateByDouble(0, hover && !pressed ? -6 : 0, 0, 1)
          ..scaleByDouble(pressed ? .975 : 1, pressed ? .975 : 1, 1, 1),
        transformAlignment: Alignment.center,
        child: widget.onTap == null
            ? widget.child
            : Semantics(
                button: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(28),
                    child: widget.child,
                  ),
                ),
              ),
      ),
    ),
  );
}

class SceneCard extends StatelessWidget {
  final String image;
  final String? caption;
  final double height;
  const SceneCard({
    super.key,
    this.image = 'beach-scene',
    this.caption,
    this.height = 230,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: blue.withValues(alpha: .17),
          blurRadius: 26,
          offset: const Offset(0, 13),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/$image.png',
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          if (caption != null)
            PositionedDirectional(
              bottom: 14,
              start: 14,
              end: 14,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .95),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    caption!,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class Celebration extends StatelessWidget {
  final Widget child;
  final bool active;
  const Celebration({super.key, required this.child, this.active = true});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 1100),
    tween: Tween(begin: active ? 0 : 1, end: 1),
    builder: (_, value, child) =>
        CustomPaint(painter: _ConfettiPainter(value), child: child),
    child: child,
  );
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  const _ConfettiPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi * 2 / 24;
      final radius = 25 + progress * 115;
      final position = Offset(
        size.width / 2 + math.cos(angle) * radius,
        42 + math.sin(angle) * radius + progress * progress * 30,
      );
      canvas.drawCircle(
        position,
        2.5 * (1 - progress),
        Paint()
          ..color = [
            blue,
            orange,
            const Color(0xFF36BDDE),
          ][i % 3].withValues(alpha: 1 - progress),
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class GlassAction extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  const GlassAction({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsetsDirectional.only(start: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFD5E2FF)],
      ),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF607EB9).withValues(alpha: .16),
          blurRadius: 13,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: ink),
    ),
  );
}

class VoiceWave extends StatefulWidget {
  const VoiceWave({super.key});
  @override
  State<VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<VoiceWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 24,
    height: 25,
    child: AnimatedBuilder(
      animation: controller,
      builder: (_, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          4,
          (i) => Container(
            width: 3,
            height:
                7 +
                (math.sin(controller.value * math.pi * 2 + i * 1.3) + 1) * 7,
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    ),
  );
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4282FF), blue, Color(0xFF1236A3)],
      ),
      borderRadius: BorderRadius.circular(size * .3),
      boxShadow: [
        BoxShadow(
          color: blue.withValues(alpha: .22),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .3),
      child: Image.asset('assets/images/app-icon.png', fit: BoxFit.cover),
    ),
  );
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Tag(this.text, {super.key, this.color = blue, this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

class English extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign align;
  const English(
    this.text, {
    super.key,
    this.style,
    this.align = TextAlign.start,
  });
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text(
      text,
      textAlign: align,
      style: style ?? Theme.of(context).textTheme.bodyLarge,
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

IconData symbolIcon(String symbol) => switch (symbol) {
  'beach' => Icons.beach_access_rounded,
  'air' => Icons.air_rounded,
  'sun' => Icons.wb_sunny_rounded,
  'thought' => Icons.psychology_alt_rounded,
  'quiet' => Icons.spa_rounded,
  'water' => Icons.water_drop_rounded,
  'travel' => Icons.flight_takeoff_rounded,
  'school' => Icons.school_rounded,
  'home' => Icons.cottage_rounded,
  'nature' => Icons.landscape_rounded,
  _ => Icons.layers_rounded,
};
