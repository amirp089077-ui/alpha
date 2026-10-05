import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/app_logo_mark.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/models/auth_models.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _passwordFocused = false;
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) return;
    AppHaptics.light();
    await ref.read(authProvider.notifier).login(
          _usernameCtrl.text.trim(),
          _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colors = Theme.of(context).extension<AppColors>()!;
    final isLoading = authState.status == AuthStatus.loading;

    // Navigate on success
    ref.listen(authProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go(AppRoutes.home);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            colors.isLight ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.7, -0.8),
              radius: 1.5,
              colors: [
                AppColorsLight.bgLight1,
                AppColorsLight.bgBase,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ── Logo ──────────────────────────────────────────────
                  const AppLogoMark(size: 110, ringWidth: 2.5, showGlow: false),
                  const SizedBox(height: 20),

                  // ── App name ──────────────────────────────────────────
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'ALPHA ',
                            style: AppTypography.logoLatin.copyWith(
                              color: AppColorsLight.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: 'VPN',
                            style: AppTypography.logoLatin.copyWith(
                              color: AppColorsLight.teal,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    S.appWelcome,
                    style: AppTypography.micro
                        .copyWith(color: AppColorsLight.textSecondary),
                    textDirection: TextDirection.rtl,
                  ),

                  const SizedBox(height: 32),

                  // ── Login card ────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B5E7A).withValues(alpha: 0.10),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            S.loginTitle,
                            style: AppTypography.title2.copyWith(
                                color: AppColorsLight.textPrimary),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            S.loginSubtitle,
                            style: AppTypography.micro.copyWith(
                                color: AppColorsLight.textSecondary),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 20),

                          // Username
                          _LoginField(
                            controller: _usernameCtrl,
                            hint: S.loginUsername,
                            prefixIcon: Icons.person_outline_rounded,
                            textInputType: TextInputType.text,
                            textDirection: TextDirection.ltr,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          _LoginField(
                            controller: _passwordCtrl,
                            hint: S.loginPassword,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscure: _obscurePassword,
                            focusNode: _passwordFocus,
                            isFocused: _passwordFocused,
                            textInputType: TextInputType.visiblePassword,
                            textDirection: TextDirection.ltr,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColorsLight.textTertiary,
                                size: 20,
                              ),
                            ),
                            onSubmit: _submit,
                          ),

                          // Error message
                          if (authState.status == AuthStatus.error &&
                              authState.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    authState.errorMessage!,
                                    style: AppTypography.caption.copyWith(
                                        color: AppColorsShared.red),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppColorsShared.red, size: 16),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Login button
                          GradientButton(
                            label: S.loginButton,
                            onPressed: _submit,
                            isLoading: isLoading,
                            isDisabled: isLoading,
                            useLoginGradient: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Support link ──────────────────────────────────────
                  GestureDetector(
                    onTap: () => launchUrl(
                        Uri.parse('https://t.me/alphavpn_support')),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          S.loginSupportArrow,
                          style: TextStyle(
                            color: AppColorsLight.teal,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          S.loginSupport,
                          style: AppTypography.caption
                              .copyWith(color: AppColorsLight.teal),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reusable login field ─────────────────────────────────────────────────────
class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.textInputType = TextInputType.text,
    this.textDirection = TextDirection.rtl,
    this.obscure = false,
    this.focusNode,
    this.isFocused = false,
    this.suffixIcon,
    this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType textInputType;
  final TextDirection textDirection;
  final bool obscure;
  final FocusNode? focusNode;
  final bool isFocused;
  final Widget? suffixIcon;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isFocused ? AppColorsLight.teal : AppColorsLight.fieldBorder;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isFocused ? 1.5 : 1),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: textInputType,
        textDirection: textDirection,
        textAlign: TextAlign.right,
        onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
        style: AppTypography.body.copyWith(
          color: AppColorsLight.textPrimary,
          height: 1.3,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.body.copyWith(
            color: AppColorsLight.textTertiary,
          ),
          hintTextDirection: TextDirection.rtl,
          prefixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: suffixIcon,
                )
              : null,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(prefixIcon,
                color: isFocused
                    ? AppColorsLight.teal
                    : AppColorsLight.textTertiary,
                size: 20),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
