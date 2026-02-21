import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/providers/language_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();

      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Theme.of(dialogContext).primaryColor),
            const SizedBox(width: AppSpacing.sm),
            Text(localizations.resetPassword),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.resetPasswordInstructions,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.colors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: localizations.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.emailRequired;
                  }
                  if (!value.contains('@')) {
                    return localizations.invalidEmail;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              localizations.cancel,
              style: TextStyle(color: context.colors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(dialogContext);
              await _sendPasswordResetEmail(emailController.text.trim());
            },
            child: Text(localizations.send),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(email);

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    localizations?.emailSentTo(email) ?? email,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.huge),

                        // Logo and branding
                        _buildHeader(primaryColor),

                        const SizedBox(height: AppSpacing.huge),

                    // Error message
                    if (_errorMessage != null) ...[
                      _buildErrorMessage(),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Email field
                    _buildEmailField(),

                    const SizedBox(height: AppSpacing.lg),

                    // Password field
                    _buildPasswordField(),

                    const SizedBox(height: AppSpacing.sm),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          l10n.forgotPassword,
                          style: AppTypography.labelMedium.copyWith(
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Login button
                    _buildLoginButton(primaryColor),

                    const SizedBox(height: AppSpacing.xxl),

                    // Google sign in (only on supported platforms)
                    if (!kIsWeb &&
                        defaultTargetPlatform != TargetPlatform.windows &&
                        defaultTargetPlatform != TargetPlatform.linux) ...[
                      _buildDivider(),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildGoogleButton(),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    // Sign up link
                    _buildSignUpLink(primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Language selector at top right
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: _buildLanguageSelector(primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(Color primaryColor) {
    final languageProvider = context.read<LanguageProvider>();
    final currentLang = languageProvider.currentLocale.languageCode;
    final languages = [
      {'code': 'nb', 'name': 'Norsk', 'flag': '🇳🇴'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    ];

    return PopupMenuButton<String>(
      onSelected: (String languageCode) async {
        await context.read<LanguageProvider>().setLanguage(languageCode);
        if (mounted) setState(() {});
      },
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      offset: const Offset(0, 40),
      itemBuilder: (context) => languages.map((lang) {
        final isSelected = lang['code'] == currentLang;
        return PopupMenuItem<String>(
          value: lang['code'],
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? primaryColor.withValues(alpha: ThemeOpacity.medium(context))
                  : Colors.transparent,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  lang['name']!,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? primaryColor : context.colors.textSecondary,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, color: primaryColor, size: 18),
                ],
              ],
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: context.colors.border),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLang == 'nb' ? '🇳🇴' : '🇬🇧',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.expand_more_rounded, 
                 color: context.colors.textMuted, 
                 size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
            ),
            borderRadius: AppRadius.xxlAll,
            boxShadow: AppShadows.colored(primaryColor),
          ),
          child: const Icon(Icons.pets_rounded, color: Colors.white, size: 48),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Title
        Text(
          'Breedly',
          style: AppTypography.displayMedium.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Subtitle
        Text(
          AppLocalizations.of(context)?.welcomeMessage ?? 'Your digital kennel assistant',
          style: AppTypography.bodyLarge.copyWith(color: context.colors.textMuted),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: AppTypography.bodyMedium.copyWith(color: context.colors.textPrimary),
      decoration: InputDecoration(
        labelText: localizations.email,
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: context.colors.surface,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return localizations.emailRequired;
        }
        if (!value.contains('@')) {
          return localizations.invalidEmail;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();
    return TextFormField(
      controller: _passwordController,
      obscureText: !_showPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _signInWithEmail(),
      style: AppTypography.bodyMedium.copyWith(color: context.colors.textPrimary),
      decoration: InputDecoration(
        labelText: localizations.password,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () {
            setState(() {
              _showPassword = !_showPassword;
            });
          },
        ),
        filled: true,
        fillColor: context.colors.surface,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return localizations.passwordRequired;
        }
        if (value.length < 6) {
          return localizations.passwordTooShort;
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton(Color primaryColor) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                AppLocalizations.of(context)?.login ?? 'Login',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: context.colors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            AppLocalizations.of(context)?.orContinueWith ?? 'Or continue with',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.textCaption,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.colors.divider)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.colors.divider),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google icon placeholder
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: AppRadius.xsAll,
              ),
              child: Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              AppLocalizations.of(context)?.continueWithGoogle ?? 'Continue with Google',
              style: AppTypography.titleSmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLink(Color primaryColor) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${localizations.noAccount} ',
          style: AppTypography.bodyMedium.copyWith(color: context.colors.textMuted),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/signup');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            localizations.signUp,
            style: AppTypography.titleSmall.copyWith(color: primaryColor),
          ),
        ),
      ],
    );
  }
}
