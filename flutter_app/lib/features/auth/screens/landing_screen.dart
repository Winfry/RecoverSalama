 // © 2026 Winfry Nyarangi Nyabuto. All Rights Reserved.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  String _lang = 'EN';
  late AnimationController _ctrl;
  late Animation<double> _fade;

  static const _copy = {
    'EN': {
      'title': 'Recover better\nwith Pona Salama',
      'sub': 'Personalized care. Local guidance.\nBacked by AI and doctors.',
      'start': 'Start Recovery Plan',
      'guest': 'Continue in Guest Mode',
    },
    'KW': {
      'title': 'Pona vizuri zaidi\nna Pona Salama',
      'sub': 'Huduma ya kibinafsi. Mwongozo wa ndani.\nKwa AI na madaktari.',
      'start': 'Anza Mpango wa Kupona',
      'guest': 'Endelea Bila Akaunti',
    },
  };

  static const _features = [
    _Feature(
      icon: Icons.psychology_outlined,
      iconBg: Color(0xFFE6F9F5),
      iconColor: AppColors.primary,
      title: 'AI Guidance',
      desc: 'Smart answers to\nyour questions',
    ),
    _Feature(
      icon: Icons.eco_outlined,
      iconBg: Color(0xFFDCFCE7),
      iconColor: Color(0xFF16A34A),
      title: 'Kenya Diet',
      desc: 'Local foods for\nfaster healing',
    ),
    _Feature(
      icon: Icons.self_improvement_outlined,
      iconBg: Color(0xFFF3E8FF),
      iconColor: Color(0xFF9333EA),
      title: 'Mental Health',
      desc: 'Support your\nmind every day',
    ),
    _Feature(
      icon: Icons.medical_services_outlined,
      iconBg: Color(0xFFEFF6FF),
      iconColor: Color(0xFF2563EB),
      title: 'Doctor Connect',
      desc: 'Talk or call\na professional',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _copy[_lang]!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.menu_rounded,
                        size: 26, color: AppColors.textPrimary),
                    const Spacer(),
                    _LangToggle(
                      lang: _lang,
                      onToggle: () => setState(
                          () => _lang = _lang == 'EN' ? 'KW' : 'EN'),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading with green heart
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                          children: [
                            TextSpan(text: t['title']),
                            const TextSpan(text: ' 💚'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t['sub']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
                      ),

                      // ── Illustration panel ───────────────────────────
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: SizedBox(
                          width: double.infinity,
                          height: 190,
                          child: CustomPaint(painter: _PeoplePainter()),
                        ),
                      ),

                      // ── Feature cards 2×2 ───────────────────────────
                      const SizedBox(height: 22),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children: _features
                            .map((f) => _FeatureCard(feature: f))
                            .toList(),
                      ),

                      // ── Primary CTA ──────────────────────────────────
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => context.go(AppRoutes.login),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            t['start']!,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                      // ── Guest CTA ─────────────────────────────────────
                      const SizedBox(height: 14),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.dashboard),
                          child: Text(
                            t['guest']!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 12, color: AppColors.textHint),
                            SizedBox(width: 4),
                            Text(
                              'Your data is private & secure',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Illustration: three people + plants ─────────────────────────────────────

class _PeoplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF0FBF7), Color(0xFFD6F5EC)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h), const Radius.circular(22));
    canvas.drawRRect(bgRRect, bgPaint);

    // Background rolling hill
    final hillPaint = Paint()..color = const Color(0xFFB8EAD8)..style = PaintingStyle.fill;
    final hill = Path()
      ..moveTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.25, h * 0.45, w * 0.5, h * 0.58)
      ..quadraticBezierTo(w * 0.75, h * 0.48, w, h * 0.60)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(hill, hillPaint);

    // Ground strip
    final groundPaint = Paint()..color = const Color(0xFF8ED8BF)..style = PaintingStyle.fill;
    final ground = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.5, h * 0.76, w, h * 0.82)
      ..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(ground, groundPaint);

    // Background leaf plants (left)
    _bgLeaf(canvas, Offset(w * 0.06, h * 0.72), 38, 0.3, const Color(0xFF4DBF96));
    _bgLeaf(canvas, Offset(w * 0.12, h * 0.80), 28, -0.2, const Color(0xFF3DAE86));

    // Background leaf plants (right)
    _bgLeaf(canvas, Offset(w * 0.94, h * 0.72), 38, math.pi - 0.3, const Color(0xFF4DBF96));
    _bgLeaf(canvas, Offset(w * 0.88, h * 0.80), 28, math.pi + 0.2, const Color(0xFF3DAE86));

    // Foreground small plants
    _fgPlant(canvas, Offset(w * 0.04, h * 0.88), const Color(0xFF2A9D6F));
    _fgPlant(canvas, Offset(w * 0.96, h * 0.88), const Color(0xFF2A9D6F), flip: true);

    // Draw the three people
    final groundLineY = h * 0.84;
    _drawWoman(canvas, w * 0.22, groundLineY, h * 0.72, false);
    _drawDoctor(canvas, w * 0.50, groundLineY, h * 0.88);
    _drawElderlyWoman(canvas, w * 0.78, groundLineY, h * 0.72);
  }

  void _bgLeaf(Canvas canvas, Offset base, double len, double angle, Color color) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle - math.pi / 2);
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(18, -len * 0.5, 0, -len)
      ..quadraticBezierTo(-18, -len * 0.5, 0, 0)..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _fgPlant(Canvas canvas, Offset base, Color color, {bool flip = false}) {
    final sign = flip ? -1.0 : 1.0;
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    // Two small leaf shapes
    for (final angle in [0.3 * sign, -0.1 * sign]) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(angle - math.pi / 2);
      final p = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(10, -14, 0, -26)
        ..quadraticBezierTo(-10, -14, 0, 0)..close();
      canvas.drawPath(p, paint);
      canvas.restore();
    }
  }

  // ── Young woman (left) ──

  void _drawWoman(Canvas canvas, double cx, double groundY, double figureH, bool flip) {
    const skin   = Color(0xFF8B5E3C);
    const hair   = Color(0xFF1A0F0A);
    const top    = Color(0xFF2EB89A); // teal top
    const bottom = Color(0xFF1A7A60); // dark trousers

    final scale  = figureH / 200.0;
    final fy     = groundY; // feet at groundY

    // Legs
    final legPaint = Paint()..color = bottom..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 8 * scale, fy - 40 * scale), width: 16 * scale, height: 76 * scale),
        Radius.circular(8 * scale)),
      legPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 8 * scale, fy - 40 * scale), width: 16 * scale, height: 76 * scale),
        Radius.circular(8 * scale)),
      legPaint);

    // Shoes
    final shoePaint = Paint()..color = const Color(0xFF3B2A1A)..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 8 * scale, fy - 4 * scale), width: 20 * scale, height: 10 * scale), shoePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 8 * scale, fy - 4 * scale), width: 20 * scale, height: 10 * scale), shoePaint);

    // Body / top
    final bodyPaint = Paint()..color = top..style = PaintingStyle.fill;
    final bodyPath = Path()
      ..moveTo(cx - 22 * scale, fy - 76 * scale)
      ..quadraticBezierTo(cx - 24 * scale, fy - 110 * scale, cx - 18 * scale, fy - 120 * scale)
      ..lineTo(cx + 18 * scale, fy - 120 * scale)
      ..quadraticBezierTo(cx + 24 * scale, fy - 110 * scale, cx + 22 * scale, fy - 76 * scale)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Arms
    final armPaint = Paint()..color = skin..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 28 * scale, fy - 100 * scale), width: 12 * scale, height: 50 * scale),
      Radius.circular(6 * scale)), armPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 28 * scale, fy - 100 * scale), width: 12 * scale, height: 50 * scale),
      Radius.circular(6 * scale)), armPaint);

    // Neck
    final skinPaint = Paint()..color = skin..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, fy - 125 * scale), width: 14 * scale, height: 16 * scale),
      Radius.circular(6 * scale)), skinPaint);

    // Head
    final headR = 22.0 * scale;
    final headCy = fy - 148 * scale;
    canvas.drawCircle(Offset(cx, headCy), headR, skinPaint);

    // Hair
    final hairPaint = Paint()..color = hair..style = PaintingStyle.fill;
    final hairPath = Path()
      ..moveTo(cx - headR, headCy + 2 * scale)
      ..quadraticBezierTo(cx - headR * 1.1, headCy - headR * 1.6, cx, headCy - headR * 1.0)
      ..quadraticBezierTo(cx + headR * 1.1, headCy - headR * 1.6, cx + headR, headCy + 2 * scale)
      ..arcToPoint(Offset(cx - headR, headCy + 2 * scale), radius: Radius.circular(headR), clockwise: false, largeArc: false);
    canvas.drawPath(hairPath, hairPaint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1A0A00)..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 7 * scale, headCy + 2 * scale), width: 7 * scale, height: 4 * scale), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 7 * scale, headCy + 2 * scale), width: 7 * scale, height: 4 * scale), eyePaint);

    // Smile
    _smile(canvas, cx, headCy + 8 * scale, 8 * scale);
  }

  // ── Doctor (center, tallest) ──

  void _drawDoctor(Canvas canvas, double cx, double groundY, double figureH) {
    const skin   = Color(0xFF7B4E2D);
    const hair   = Color(0xFF140A06);
    const coat   = Color(0xFFF5F5F5);
    const shirt  = Color(0xFF2EB89A);
    const pants  = Color(0xFF2C3E50);

    final scale  = figureH / 240.0;
    final fy     = groundY;

    // Legs / pants
    final pantPaint = Paint()..color = pants..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 9 * scale, fy - 45 * scale), width: 18 * scale, height: 86 * scale),
      Radius.circular(8 * scale)), pantPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 9 * scale, fy - 45 * scale), width: 18 * scale, height: 86 * scale),
      Radius.circular(8 * scale)), pantPaint);

    // Shoes
    final shoePaint = Paint()..color = const Color(0xFF2C2218)..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 9 * scale, fy - 4 * scale), width: 22 * scale, height: 11 * scale), shoePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 9 * scale, fy - 4 * scale), width: 22 * scale, height: 11 * scale), shoePaint);

    // Shirt (under coat)
    final shirtPaint = Paint()..color = shirt..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, fy - 108 * scale), width: 38 * scale, height: 44 * scale),
      Radius.circular(4 * scale)), shirtPaint);

    // White coat
    final coatPaint = Paint()..color = coat..style = PaintingStyle.fill;
    final coatPath = Path()
      ..moveTo(cx - 28 * scale, fy - 88 * scale)
      ..lineTo(cx - 28 * scale, fy - 148 * scale)
      ..lineTo(cx - 18 * scale, fy - 150 * scale)
      ..lineTo(cx - 10 * scale, fy - 130 * scale)
      ..lineTo(cx, fy - 128 * scale)
      ..lineTo(cx + 10 * scale, fy - 130 * scale)
      ..lineTo(cx + 18 * scale, fy - 150 * scale)
      ..lineTo(cx + 28 * scale, fy - 148 * scale)
      ..lineTo(cx + 28 * scale, fy - 88 * scale)
      ..close();
    canvas.drawPath(coatPath, coatPaint);

    // Coat outline
    final coatLine = Paint()..color = const Color(0xFFDDDDDD)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawPath(coatPath, coatLine);

    // Stethoscope
    final stetho = Paint()
      ..color = const Color(0xFF4A4A4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round;
    final stethoPath = Path()
      ..moveTo(cx - 8 * scale, fy - 140 * scale)
      ..cubicTo(cx - 20 * scale, fy - 130 * scale, cx - 24 * scale, fy - 110 * scale, cx, fy - 106 * scale)
      ..cubicTo(cx + 24 * scale, fy - 110 * scale, cx + 20 * scale, fy - 130 * scale, cx + 8 * scale, fy - 140 * scale);
    canvas.drawPath(stethoPath, stetho);
    canvas.drawCircle(Offset(cx, fy - 105 * scale), 5 * scale,
      Paint()..color = const Color(0xFF4A4A4A)..style = PaintingStyle.fill);

    // Arms
    final armPaint = Paint()..color = coat..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 34 * scale, fy - 115 * scale), width: 14 * scale, height: 56 * scale),
      Radius.circular(7 * scale)), armPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 34 * scale, fy - 115 * scale), width: 14 * scale, height: 56 * scale),
      Radius.circular(7 * scale)), armPaint);

    // Hands
    final skinPaint = Paint()..color = skin..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 34 * scale, fy - 89 * scale), 8 * scale, skinPaint);
    canvas.drawCircle(Offset(cx + 34 * scale, fy - 89 * scale), 8 * scale, skinPaint);

    // Neck
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, fy - 155 * scale), width: 16 * scale, height: 18 * scale),
      Radius.circular(7 * scale)), skinPaint);

    // Head
    final headR = 26.0 * scale;
    final headCy = fy - 182 * scale;
    canvas.drawCircle(Offset(cx, headCy), headR, skinPaint);

    // Hair (short)
    final hairPaint = Paint()..color = hair..style = PaintingStyle.fill;
    final hairPath = Path()
      ..moveTo(cx - headR * 0.95, headCy - headR * 0.05)
      ..quadraticBezierTo(cx - headR, headCy - headR * 1.5, cx, headCy - headR * 1.05)
      ..quadraticBezierTo(cx + headR, headCy - headR * 1.5, cx + headR * 0.95, headCy - headR * 0.05)
      ..arcToPoint(Offset(cx - headR * 0.95, headCy - headR * 0.05),
        radius: Radius.circular(headR), clockwise: false, largeArc: false);
    canvas.drawPath(hairPath, hairPaint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1A0A00)..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 8 * scale, headCy + 3 * scale), width: 8 * scale, height: 5 * scale), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 8 * scale, headCy + 3 * scale), width: 8 * scale, height: 5 * scale), eyePaint);

    // Smile
    _smile(canvas, cx, headCy + 10 * scale, 10 * scale);
  }

  // ── Elderly woman (right) ──

  void _drawElderlyWoman(Canvas canvas, double cx, double groundY, double figureH) {
    const skin   = Color(0xFF8B6347);
    const scarf  = Color(0xFFE8A56A); // warm orange headscarf
    const scarfDark = Color(0xFFCC8040);
    const outfit = Color(0xFF5B8FA8); // blue-grey outfit

    final scale  = figureH / 200.0;
    final fy     = groundY;

    // Legs
    final legPaint = Paint()..color = const Color(0xFF3B2E50)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 8 * scale, fy - 38 * scale), width: 16 * scale, height: 70 * scale),
      Radius.circular(8 * scale)), legPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 8 * scale, fy - 38 * scale), width: 16 * scale, height: 70 * scale),
      Radius.circular(8 * scale)), legPaint);

    // Shoes
    final shoePaint = Paint()..color = const Color(0xFF2C2218)..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 8 * scale, fy - 4 * scale), width: 20 * scale, height: 10 * scale), shoePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 8 * scale, fy - 4 * scale), width: 20 * scale, height: 10 * scale), shoePaint);

    // Body
    final bodyPaint = Paint()..color = outfit..style = PaintingStyle.fill;
    final bodyPath = Path()
      ..moveTo(cx - 24 * scale, fy - 72 * scale)
      ..quadraticBezierTo(cx - 26 * scale, fy - 108 * scale, cx - 20 * scale, fy - 120 * scale)
      ..lineTo(cx + 20 * scale, fy - 120 * scale)
      ..quadraticBezierTo(cx + 26 * scale, fy - 108 * scale, cx + 24 * scale, fy - 72 * scale)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Arms
    final armPaint = Paint()..color = skin..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 30 * scale, fy - 100 * scale), width: 12 * scale, height: 50 * scale),
      Radius.circular(6 * scale)), armPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 30 * scale, fy - 100 * scale), width: 12 * scale, height: 50 * scale),
      Radius.circular(6 * scale)), armPaint);

    // Neck
    final skinPaint = Paint()..color = skin..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, fy - 126 * scale), width: 14 * scale, height: 14 * scale),
      Radius.circular(6 * scale)), skinPaint);

    // Head (face)
    final headR = 22.0 * scale;
    final headCy = fy - 150 * scale;
    canvas.drawCircle(Offset(cx, headCy), headR, skinPaint);

    // Headscarf — covers head from forehead up and wraps
    final scarfPaint = Paint()..color = scarf..style = PaintingStyle.fill;
    final scarfPath = Path()
      ..moveTo(cx - headR * 1.1, headCy + headR * 0.3)
      ..quadraticBezierTo(cx - headR * 1.1, headCy - headR * 1.7, cx, headCy - headR * 1.1)
      ..quadraticBezierTo(cx + headR * 1.1, headCy - headR * 1.7, cx + headR * 1.1, headCy + headR * 0.3)
      // wrap under chin to suggest scarf
      ..quadraticBezierTo(cx + headR * 0.8, headCy + headR * 0.7, cx, headCy + headR * 0.5)
      ..quadraticBezierTo(cx - headR * 0.8, headCy + headR * 0.7, cx - headR * 1.1, headCy + headR * 0.3)
      ..close();
    canvas.drawPath(scarfPath, scarfPaint);

    // Scarf fold line
    final scarfLine = Paint()..color = scarfDark..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(cx + headR * 0.5, headCy - headR * 0.3),
      Offset(cx + headR * 1.05, headCy + headR * 0.2),
      scarfLine);

    // Eyes (visible below scarf)
    final eyePaint = Paint()..color = const Color(0xFF1A0A00)..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 7 * scale, headCy + 2 * scale), width: 7 * scale, height: 4 * scale), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 7 * scale, headCy + 2 * scale), width: 7 * scale, height: 4 * scale), eyePaint);

    // Warm smile
    _smile(canvas, cx, headCy + 9 * scale, 8 * scale);
  }

  void _smile(Canvas canvas, double cx, double smileY, double r) {
    final paint = Paint()
      ..color = const Color(0xFF5C2B10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(cx - r, smileY)
      ..quadraticBezierTo(cx, smileY + r * 0.6, cx + r, smileY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Feature card ─────────────────────────────────────────────────────────────

class _Feature {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String desc;
  const _Feature({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.desc,
  });
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: feature.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon, size: 20, color: feature.iconColor),
          ),
          const Spacer(),
          Text(
            feature.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            feature.desc,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language toggle ──────────────────────────────────────────────────────────

class _LangToggle extends StatelessWidget {
  final String lang;
  final VoidCallback onToggle;
  const _LangToggle({required this.lang, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [_pill('EN', lang == 'EN'), _pill('KW', lang == 'KW')],
        ),
      ),
    );
  }

  Widget _pill(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}