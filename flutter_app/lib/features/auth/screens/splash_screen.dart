import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)),
    );
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final user = Supabase.instance.client.auth.currentUser;
      context.go(user != null ? AppRoutes.dashboard : AppRoutes.landing);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slideUp,
          child: Column(
            children: [
              // ── Top section: white background with logo + name ──
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 44),
                  child: Column(
                    children: [
                      // Teal heart logo with white cross
                      const _HeartLogo(),
                      const SizedBox(height: 16),
                      const Text(
                        'Pona Salama',
                        style: TextStyle(
                          color: Color(0xFF1A2E35),
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Recover. Heal. Live.',
                        style: TextStyle(
                          color: Color(0xFF6E9BA6),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Illustration fills remaining space ──
              Expanded(
                child: Stack(
                  children: [
                    // Landscape + woman painted together
                    Positioned.fill(
                      child: CustomPaint(painter: _ScenePainter()),
                    ),

                    // Bottom text + page dots
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Your AI companion for a\nfaster, safer recovery.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF1A2E35),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _PageDots(count: 4, active: 0),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Heart logo ──────────────────────────────────────────────────────────────

class _HeartLogo extends StatelessWidget {
  const _HeartLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(70, 70),
      painter: _HeartLogoPainter(),
    );
  }
}

class _HeartLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF00B494).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    _drawHeart(canvas, cx, cy + 3, size, shadowPaint);

    // Teal heart fill
    final heartPaint = Paint()
      ..color = const Color(0xFF00B494)
      ..style = PaintingStyle.fill;
    _drawHeart(canvas, cx, cy, size, heartPaint);

    // White cross / plus
    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final arm = size.width * 0.22;
    canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), crossPaint);
    canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), crossPaint);
  }

  void _drawHeart(Canvas canvas, double cx, double cy, Size size, Paint paint) {
    final s = size.width * 0.42;
    final path = Path();
    path.moveTo(cx, cy + s * 0.9);
    path.cubicTo(cx - s * 2.2, cy + s * 0.1, cx - s * 2.2, cy - s * 1.3, cx, cy - s * 0.5);
    path.cubicTo(cx + s * 2.2, cy - s * 1.3, cx + s * 2.2, cy + s * 0.1, cx, cy + s * 0.9);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Scene painter (landscape + woman) ──────────────────────────────────────

class _ScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF2FAF6), Color(0xFFD6EFE2), Color(0xFFB8E4CC)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Far-background misty mountains
    _drawFarMountains(canvas, w, h);

    // 3. Mid-ground rolling hills
    _drawMidHills(canvas, w, h);

    // 4. Foreground ground
    _drawForeground(canvas, w, h);

    // 5. Side plants (left + right)
    _drawSidePlants(canvas, w, h);

    // 6. Woman in lotus pose
    _drawWoman(canvas, w, h);
  }

  // --- Landscape layers ---

  void _drawFarMountains(Canvas canvas, double w, double h) {
    final y0 = h * 0.28;

    final paint1 = Paint()
      ..color = const Color(0xFFCDE8D8).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final p1 = Path()
      ..moveTo(0, y0 + h * 0.14)
      ..quadraticBezierTo(w * 0.12, y0 - h * 0.04, w * 0.28, y0 + h * 0.06)
      ..quadraticBezierTo(w * 0.44, y0 - h * 0.10, w * 0.58, y0 + h * 0.04)
      ..quadraticBezierTo(w * 0.72, y0 - h * 0.06, w * 0.88, y0 + h * 0.08)
      ..quadraticBezierTo(w * 0.94, y0, w, y0 + h * 0.10)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(p1, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFFB5DACC).withOpacity(0.45)
      ..style = PaintingStyle.fill;
    final p2 = Path()
      ..moveTo(0, y0 + h * 0.08)
      ..quadraticBezierTo(w * 0.2, y0 - h * 0.14, w * 0.38, y0 + h * 0.02)
      ..quadraticBezierTo(w * 0.55, y0 - h * 0.10, w * 0.7, y0 + h * 0.05)
      ..quadraticBezierTo(w * 0.85, y0 - h * 0.06, w, y0 + h * 0.06)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(p2, paint2);
  }

  void _drawMidHills(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF72BC91)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, h * 0.60)
      ..quadraticBezierTo(w * 0.18, h * 0.32, w * 0.38, h * 0.50)
      ..quadraticBezierTo(w * 0.52, h * 0.38, w * 0.65, h * 0.50)
      ..quadraticBezierTo(w * 0.80, h * 0.34, w, h * 0.52)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path, paint);

    // Slightly darker overlay hill
    final paint2 = Paint()
      ..color = const Color(0xFF5FAE7E)
      ..style = PaintingStyle.fill;
    final path2 = Path()
      ..moveTo(0, h * 0.68)
      ..quadraticBezierTo(w * 0.22, h * 0.50, w * 0.44, h * 0.63)
      ..quadraticBezierTo(w * 0.62, h * 0.52, w * 0.78, h * 0.62)
      ..quadraticBezierTo(w * 0.90, h * 0.56, w, h * 0.62)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path2, paint2);
  }

  void _drawForeground(Canvas canvas, double w, double h) {
    // Dark green ground
    final paint = Paint()
      ..color = const Color(0xFF3D9E62)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, h * 0.74)
      ..quadraticBezierTo(w * 0.3, h * 0.66, w * 0.5, h * 0.70)
      ..quadraticBezierTo(w * 0.7, h * 0.65, w, h * 0.72)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path, paint);

    // Very dark foreground strip at the very bottom
    final darkPaint = Paint()..color = const Color(0xFF2E8050)..style = PaintingStyle.fill;
    final darkPath = Path()
      ..moveTo(0, h * 0.88)
      ..quadraticBezierTo(w * 0.5, h * 0.82, w, h * 0.87)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(darkPath, darkPaint);
  }

  // --- Side plants ---

  void _drawSidePlants(Canvas canvas, double w, double h) {
    final darkGreen = const Color(0xFF1B6B3A);
    final medGreen  = const Color(0xFF2E8050);
    final lightGreen = const Color(0xFF4CAF71);

    // Left side
    _leaf(canvas, Offset(w * 0.0,  h * 0.68), 40, 28, -0.25, darkGreen);
    _leaf(canvas, Offset(w * 0.06, h * 0.74), 32, 22,  0.15, medGreen);
    _leaf(canvas, Offset(w * 0.0,  h * 0.80), 36, 24, -0.45, darkGreen);
    _leaf(canvas, Offset(w * 0.10, h * 0.82), 26, 18,  0.30, lightGreen);
    _leaf(canvas, Offset(w * 0.02, h * 0.87), 30, 20, -0.20, medGreen);
    _stemGrass(canvas, Offset(w * 0.08, h * 0.76), 18, medGreen);
    _stemGrass(canvas, Offset(w * 0.14, h * 0.78), 14, lightGreen);

    // Right side
    _leaf(canvas, Offset(w * 1.0,  h * 0.68), 40, 28, math.pi + 0.25, darkGreen);
    _leaf(canvas, Offset(w * 0.94, h * 0.74), 32, 22, math.pi - 0.15, medGreen);
    _leaf(canvas, Offset(w * 1.0,  h * 0.80), 36, 24, math.pi + 0.45, darkGreen);
    _leaf(canvas, Offset(w * 0.90, h * 0.82), 26, 18, math.pi - 0.30, lightGreen);
    _leaf(canvas, Offset(w * 0.98, h * 0.87), 30, 20, math.pi + 0.20, medGreen);
    _stemGrass(canvas, Offset(w * 0.92, h * 0.76), 18, medGreen);
    _stemGrass(canvas, Offset(w * 0.86, h * 0.78), 14, lightGreen);
  }

  void _leaf(Canvas canvas, Offset base, double len, double width, double angle, Color color) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle - math.pi / 2);
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(width * 0.6,  -len * 0.5, 0, -len)
      ..quadraticBezierTo(-width * 0.6, -len * 0.5, 0, 0)
      ..close();
    canvas.drawPath(path, paint);
    // Vein
    final vein = Paint()..color = color.withOpacity(0.5)..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(0, -len), vein);
    canvas.restore();
  }

  void _stemGrass(Canvas canvas, Offset base, double h, Color color) {
    final paint = Paint()..color = color..strokeWidth = 2..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    canvas.drawLine(base, Offset(base.dx + 4, base.dy - h), paint);
    canvas.drawLine(base, Offset(base.dx - 3, base.dy - h * 0.8), paint);
  }

  // --- Woman in lotus meditation pose ---

  void _drawWoman(Canvas canvas, double w, double h) {
    // Base center of the seated figure — sits on the foreground hill
    final cx = w * 0.5;
    final groundY = h * 0.72;

    const skin   = Color(0xFF8B5E3C);
    const outfit = Color(0xFF2E7A4E);
    const outfitDark = Color(0xFF1F5C38);
    const hair   = Color(0xFF1A0F0A);
    const hairBand = Color(0xFF2E7A4E);

    // ── Lotus legs ──
    // The crossed legs form a low wide shape
    final legPaint = Paint()..color = outfit..style = PaintingStyle.fill;
    final legPath = Path()
      ..moveTo(cx - w * 0.19, groundY)
      ..quadraticBezierTo(cx - w * 0.22, groundY - h * 0.05, cx - w * 0.12, groundY - h * 0.06)
      ..quadraticBezierTo(cx - w * 0.04, groundY - h * 0.07, cx, groundY - h * 0.07)
      ..quadraticBezierTo(cx + w * 0.04, groundY - h * 0.07, cx + w * 0.12, groundY - h * 0.06)
      ..quadraticBezierTo(cx + w * 0.22, groundY - h * 0.05, cx + w * 0.19, groundY)
      ..close();
    canvas.drawPath(legPath, legPaint);

    // Leg cross detail
    final legLine = Paint()..color = outfitDark..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - w * 0.15, groundY - h * 0.01),
      Offset(cx + w * 0.05, groundY - h * 0.065),
      legLine,
    );
    canvas.drawLine(
      Offset(cx + w * 0.15, groundY - h * 0.01),
      Offset(cx - w * 0.05, groundY - h * 0.065),
      legLine,
    );

    // Feet peeking out
    final skinPaint = Paint()..color = skin..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.17, groundY - h * 0.01), width: w * 0.07, height: h * 0.025),
      skinPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.17, groundY - h * 0.01), width: w * 0.07, height: h * 0.025),
      skinPaint,
    );

    // ── Torso ──
    final torsoTop = groundY - h * 0.22;
    final torsoPaint = Paint()..color = outfit..style = PaintingStyle.fill;
    final torsoPath = Path()
      ..moveTo(cx - w * 0.085, groundY - h * 0.068)
      ..quadraticBezierTo(cx - w * 0.095, torsoTop + h * 0.05, cx - w * 0.075, torsoTop)
      ..quadraticBezierTo(cx, torsoTop - h * 0.01, cx + w * 0.075, torsoTop)
      ..quadraticBezierTo(cx + w * 0.095, torsoTop + h * 0.05, cx + w * 0.085, groundY - h * 0.068)
      ..close();
    canvas.drawPath(torsoPath, torsoPaint);

    // Outfit fold lines
    final foldPaint = Paint()..color = outfitDark..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - w * 0.03, torsoTop + h * 0.04),
      Offset(cx - w * 0.06, groundY - h * 0.085),
      foldPaint,
    );
    canvas.drawLine(
      Offset(cx + w * 0.01, torsoTop + h * 0.04),
      Offset(cx + w * 0.04, groundY - h * 0.085),
      foldPaint,
    );

    // ── Shoulders / upper arms ──
    // Left arm: shoulder to knee resting in mudra
    final armPaint = Paint()..color = outfit..style = PaintingStyle.fill..strokeWidth = w * 0.045;
    _drawArm(canvas, cx, groundY, h, w, armPaint, skinPaint, isLeft: true);
    _drawArm(canvas, cx, groundY, h, w, armPaint, skinPaint, isLeft: false);

    // Shoulder width line
    final shoulderPaint = Paint()..color = outfit..style = PaintingStyle.fill;
    final shoulderY = torsoTop + h * 0.01;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, shoulderY), width: w * 0.20, height: h * 0.028),
        const Radius.circular(10),
      ),
      shoulderPaint,
    );

    // ── Neck ──
    final neckPaint = Paint()..color = skin..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, torsoTop - h * 0.025), width: w * 0.055, height: h * 0.05),
        const Radius.circular(8),
      ),
      neckPaint,
    );

    // ── Head ──
    final headCy = torsoTop - h * 0.075;
    final headR  = w * 0.085;
    canvas.drawCircle(Offset(cx, headCy), headR, skinPaint);

    // Face highlights (subtle)
    final highlightPaint = Paint()..color = const Color(0xFFA0724A)..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.025, headCy + h * 0.005), width: w * 0.018, height: h * 0.012),
      highlightPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.025, headCy + h * 0.005), width: w * 0.018, height: h * 0.012),
      highlightPaint,
    );

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1A0A00)..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.026, headCy - h * 0.002), width: w * 0.022, height: h * 0.012),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.026, headCy - h * 0.002), width: w * 0.022, height: h * 0.012),
      eyePaint,
    );

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF5C2B10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(cx - w * 0.022, headCy + h * 0.018)
      ..quadraticBezierTo(cx, headCy + h * 0.030, cx + w * 0.022, headCy + h * 0.018);
    canvas.drawPath(smilePath, smilePaint);

    // ── Hair ──
    final hairPaint = Paint()..color = hair..style = PaintingStyle.fill;
    // Main hair (covers top & sides of head)
    final hairPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, headCy - headR * 0.1), width: headR * 2.15, height: headR * 1.6));
    canvas.drawPath(hairPath, hairPaint);

    // Hair bun
    canvas.drawCircle(Offset(cx, headCy - headR * 0.85), headR * 0.38, hairPaint);

    // Hair band (green)
    final bandPaint = Paint()..color = hairBand..style = PaintingStyle.stroke..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, headCy - headR * 0.85), width: headR * 0.9, height: headR * 0.9),
      math.pi * 0.9, math.pi * 1.2, false, bandPaint,
    );
  }

  void _drawArm(Canvas canvas, double cx, double groundY, double h, double w,
      Paint armPaint, Paint skinPaint, {required bool isLeft}) {
    final sign = isLeft ? -1.0 : 1.0;

    // Upper arm (sleeve)
    final armTop = groundY - h * 0.20;
    final armMid = groundY - h * 0.12;

    final armPath = Path()
      ..moveTo(cx + sign * w * 0.075, armTop)
      ..quadraticBezierTo(
        cx + sign * w * 0.13, armMid - h * 0.02,
        cx + sign * w * 0.12, armMid + h * 0.01,
      )
      ..quadraticBezierTo(
        cx + sign * w * 0.105, armMid + h * 0.025,
        cx + sign * w * 0.09, armTop + h * 0.01,
      )
      ..close();
    canvas.drawPath(armPath, armPaint);

    // Forearm (skin)
    final forearmPath = Path()
      ..moveTo(cx + sign * w * 0.115, armMid)
      ..quadraticBezierTo(
        cx + sign * w * 0.155, groundY - h * 0.055,
        cx + sign * w * 0.13, groundY - h * 0.025,
      )
      ..quadraticBezierTo(
        cx + sign * w * 0.105, groundY - h * 0.01,
        cx + sign * w * 0.09, armMid + h * 0.01,
      )
      ..close();
    canvas.drawPath(forearmPath, skinPaint);

    // Hand / mudra (small oval resting on knee)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + sign * w * 0.125, groundY - h * 0.022),
        width: w * 0.045, height: h * 0.028,
      ),
      skinPaint,
    );

    // Mudra circle (index to thumb)
    final mudra = Paint()
      ..color = const Color(0xFF6B3E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      Offset(cx + sign * w * 0.125, groundY - h * 0.022),
      w * 0.012, mudra,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Page dots ───────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int count;
  final int active;
  const _PageDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00B494) : const Color(0xFFB8D8CC),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
