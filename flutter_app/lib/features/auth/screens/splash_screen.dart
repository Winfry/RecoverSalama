import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';

/// Screen 00 — Splash Screen
/// Shows the SalamaRecover logo (heart + medical cross) with loading animation.
/// Auto-navigates to Landing after 3 seconds.
/// Background: #EBF5FB with decorative medical illustrations at ~15% opacity.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Check auth session after splash animation, route accordingly
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          context.go(AppRoutes.dashboard); // returning user — skip login
        } else {
          context.go(AppRoutes.landing);   // new user — show landing
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Decorative medical illustrations (pills, stethoscope, bandage)
            // at ~15% opacity — positioned at corners
            _buildDecorations(),

            // Center content — logo, badge, taglines
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Heart + Cross logo
                  _buildLogo(),
                  const SizedBox(height: 24),

                  // "SalamaRecover" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'SalamaRecover',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // English tagline
                  const Text(
                    'Recover Safely. Heal Confidently.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Kiswahili tagline
                  const Text(
                    'Pona Salama',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

            // Loading dots at bottom
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: _buildLoadingDots(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return CustomPaint(
      size: const Size(120, 112),
      painter: _HeartCrossLogoPainter(),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(
                  ((_controller.value * 3 - index) % 3).clamp(0.3, 1.0),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildDecorations() {
    // Decorative medical illustrations at low opacity
    return const SizedBox.shrink(); // TODO: Add SVG decorations
  }
}

/// Custom painter for the heart + medical cross logo
/// Gradient from #0077B6 (blue) to #00B37E (green)
class _HeartCrossLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final heartPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary, AppColors.success],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Heart path
    final heartPath = Path();
    final w = size.width;
    final h = size.height;

    heartPath.moveTo(w * 0.5, h * 0.88);
    heartPath.cubicTo(w * 0.5, h * 0.88, w * 0.1, h * 0.6, w * 0.1, h * 0.33);
    heartPath.cubicTo(w * 0.1, h * 0.19, w * 0.2, h * 0.1, w * 0.325, h * 0.1);
    heartPath.cubicTo(w * 0.4, h * 0.1, w * 0.46, h * 0.14, w * 0.5, h * 0.21);
    heartPath.cubicTo(w * 0.54, h * 0.14, w * 0.6, h * 0.1, w * 0.675, h * 0.1);
    heartPath.cubicTo(w * 0.8, h * 0.1, w * 0.9, h * 0.19, w * 0.9, h * 0.33);
    heartPath.cubicTo(w * 0.9, h * 0.6, w * 0.5, h * 0.88, w * 0.5, h * 0.88);

    canvas.drawPath(heartPath, heartPaint);

    // Medical cross inside heart
    final crossPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary, AppColors.success],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Vertical bar
    final vertRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.47),
        width: w * 0.12,
        height: h * 0.35,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(vertRect, crossPaint);

    // Horizontal bar
    final horizRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.47),
        width: w * 0.35,
        height: h * 0.12,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(horizRect, crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

