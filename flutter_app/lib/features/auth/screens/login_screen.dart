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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final phone = _phoneCtrl.text.trim();
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
    if (raw.contains('invalid_credentials') || raw.contains('Invalid login'))
      return 'Incorrect phone number or password. Please try again.';
    if (raw.contains('user_already_exists') || raw.contains('already registered'))
      return 'An account with this number already exists. Sign in instead.';
    if (raw.contains('SocketException') || raw.contains('connection'))
      return 'No internet connection. Please check your network.';
    if (raw.contains('weak_password'))
      return 'Password is too weak. Use at least 6 characters.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back arrow ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.landing),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 22, color: AppColors.textPrimary),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Heading ──
                      const Text('Welcome back! 👋',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      const Text(
                          "Let's continue your\nrecovery journey",
                          style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.4)),
                      const SizedBox(height: 28),

                      // ── Tab switcher ──
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabCtrl,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textSecondary,
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                          tabs: const [
                            Tab(text: 'Log In'),
                            Tab(text: 'Sign Up'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Error message ──
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.emergencyLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.emergency.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.emergency, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        color: AppColors.emergency,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Full name (signup only) ──
                      if (!_isLogin) ...[
                        _label('Full Name'),
                        _field(
                          controller: _nameCtrl,
                          hint: 'Winnie Akinyi',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Phone ──
                      _label('Phone Number'),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.textPrimary),
                        decoration: _dec(
                          hint: '700 000 000',
                          icon: Icons.phone_outlined,
                        ).copyWith(
                          prefixIcon: Padding(
                            padding:
                                const EdgeInsets.only(left: 14, right: 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇰🇪',
                                    style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                const Text('+254',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                const SizedBox(width: 8),
                                Container(
                                    width: 1,
                                    height: 20,
                                    color: AppColors.border),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 0, minHeight: 48),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Phone is required';
                          if (v.trim().length < 9)
                            return 'Enter a valid Kenyan number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Password ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _label('Password'),
                          if (_isLogin)
                            const Text('Forgot password?',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: _dec(
                                hint: 'Min 6 characters',
                                icon: Icons.lock_outline_rounded)
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
                          if (v == null || v.isEmpty)
                            return 'Password is required';
                          if (v.length < 6)
                            return 'Must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Submit ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
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

                      // ── Divider ──
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: AppColors.border)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or',
                                style: TextStyle(
                                    color: AppColors.textHint, fontSize: 13)),
                          ),
                          const Expanded(
                              child: Divider(color: AppColors.border)),
                        ],
                      ),

                      // ── Google sign-in ──
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Text('🇬',
                              style: TextStyle(fontSize: 18)),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),

                      // ── Toggle ──
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
                              onTap: () => _tabCtrl.animateTo(
                                  _isLogin ? 1 : 0),
                              child: Text(
                                _isLogin ? 'Sign up' : 'Sign in',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
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
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emergency),
        ),
      );
}
