import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _storage = const FlutterSecureStorage();
  late TabController _tabCtrl;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _errorMessage = null));
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  bool get _isLogin => _tabCtrl.index == 0;

  // Normalize to E.164 (+254XXXXXXXXX)
  String _formatPhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('0')) return '+254${cleaned.substring(1)}';
    if (cleaned.startsWith('254')) return '+$cleaned';
    return '+254$cleaned';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final phone = _formatPhone(_phoneCtrl.text.trim());
      if (_isLogin) {
        final resp = await authRepo.signInWithPhone(
            phone: phone, password: _passwordCtrl.text);
        if (resp.session != null) {
          await _storage.write(
              key: 'access_token', value: resp.session!.accessToken);
          if (!mounted) return;
          context.go(AppRoutes.dashboard);
        }
      } else {
        final resp = await authRepo.signUpWithPhone(
          phone: phone,
          password: _passwordCtrl.text,
          fullName: _nameCtrl.text.trim(),
        );
        if (resp.session != null) {
          await _storage.write(
              key: 'access_token', value: resp.session!.accessToken);
          if (!mounted) return;
          context.go(AppRoutes.profileSetup);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = _friendly(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendly(String raw) {
    if (raw.contains('invalid_credentials') || raw.contains('Invalid login')) {
      return 'Incorrect phone number or password. Please try again.';
    }
    if (raw.contains('user_already_exists') || raw.contains('already registered')) {
      return 'An account with this number already exists. Sign in instead.';
    }
    if (raw.contains('SocketException') || raw.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    if (raw.contains('weak_password')) {
      return 'Password too weak — use at least 6 characters.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back arrow ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: AppColors.textPrimary),
                onPressed: () => context.go(AppRoutes.landing),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                child: Form(
                  key: _formKey,
                  child: AnimatedBuilder(
                    animation: _tabCtrl,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Heading ──
                        Text(
                          _isLogin ? 'Welcome back! 👋' : 'Get started! 🌱',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin
                              ? "Let's continue your\nrecovery journey"
                              : "Begin your recovery\njourney today",
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.4),
                        ),
                        const SizedBox(height: 28),

                        // ── Segmented tab ──
                        _buildTabs(),
                        const SizedBox(height: 24),

                        // ── Error banner ──
                        if (_errorMessage != null) _buildError(),

                        // ── Full name (sign-up only) ──
                        if (!_isLogin) ...[
                          _field(
                            ctrl: _nameCtrl,
                            hint: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Phone ──
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textPrimary),
                          decoration: _dec(
                              hint: '+254 700 000 000',
                              icon: Icons.phone_outlined),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            final d =
                                v.replaceAll(RegExp(r'[\s\-+()]'), '');
                            if (d.length < 9) {
                              return 'Enter a valid Kenyan number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Password ──
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textPrimary),
                          decoration:
                              _dec(hint: 'Password', icon: Icons.lock_outline_rounded)
                                  .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textHint,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 6) {
                              return 'Min 6 characters';
                            }
                            return null;
                          },
                        ),

                        // ── Forgot password / spacer ──
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 0)),
                              child: const Text('Forgot password?',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          )
                        else
                          const SizedBox(height: 20),

                        // ── Submit ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                                : Text(
                                    _isLogin ? 'Log In' : 'Create Account',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),

                        // ── Or divider ──
                        const SizedBox(height: 20),
                        const Row(children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text('or',
                                style: TextStyle(
                                    color: AppColors.textHint, fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ]),
                        const SizedBox(height: 16),

                        // ── Google ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content:
                                  Text('Google sign-in coming soon!'),
                              duration: Duration(seconds: 2),
                            )),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side:
                                  const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GoogleLogo(size: 22),
                                SizedBox(width: 10),
                                Text('Continue with Google',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        ),

                        // ── Toggle link ──
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin
                                    ? "Don't have an account? "
                                    : 'Already have an account? ',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _tabCtrl.animateTo(_isLogin ? 1 : 0);
                                  _errorMessage = null;
                                }),
                                child: Text(
                                  _isLogin ? 'Sign up' : 'Sign in',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // ── Segmented tab control ──────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _segTab('Log In', 0),
          _segTab('Sign Up', 1),
        ],
      ),
    );
  }

  Widget _segTab(String label, int index) {
    final active = _tabCtrl.index == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _tabCtrl.animateTo(index);
          _errorMessage = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.emergencyLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.emergency.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.emergency, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!,
                style: const TextStyle(
                    color: AppColors.emergency, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Field helpers ─────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: _dec(hint: hint, icon: icon),
        validator: validator,
      );

  InputDecoration _dec({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emergency),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.emergency, width: 1.5),
        ),
      );
}

// ── Google logo (CustomPainter) ────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({this.size = 22.0});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: size, height: size, child: CustomPaint(painter: _GoogleLogoPainter()));
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;
    final sw = size.width * 0.19;
    const d = math.pi / 180;

    void arc(Color color, double startDeg, double sweepDeg) =>
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          startDeg * d,
          sweepDeg * d,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = sw
            ..strokeCap = StrokeCap.butt,
        );

    // 0° = 3 o'clock, clockwise
    arc(const Color(0xFF4285F4), -28, 118);  // blue: top-right → bottom-right
    arc(const Color(0xFFFBBC04), 90, 52);    // yellow: bottom-right
    arc(const Color(0xFF34A853), 142, 63);   // green: bottom-left
    arc(const Color(0xFFEA4335), 205, 128);  // red: left → top

    // Horizontal crossbar of the G
    canvas.drawLine(
      Offset(cx + r * 0.05, cy),
      Offset(cx + r + sw / 2, cy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
