import 'package:flutter/material.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/providers/language_provider.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/constants.dart';

class SignUpScreen extends StatefulWidget {
  final LanguageProvider languageProvider;
  final VoidCallback onSignUpSuccess;

  const SignUpScreen({
    super.key,
    required this.languageProvider,
    required this.onSignUpSuccess,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _authService = AuthService();
  final _cloudSyncService = CloudSyncService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // Validation
    if (_nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Vennligst skriv inn navn');
      return;
    }

    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = 'Vennligst skriv inn e-postadresse');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      setState(() => _errorMessage = 'Ugyldig e-postadresse');
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Vennligst skriv inn passord');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Passordet må være minst 6 tegn');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passordene stemmer ikke overens');
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Du må godta vilkårene for bruk');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      // Save user profile to Firestore
      if (userCredential.user != null) {
        await _cloudSyncService.saveUserProfile(
          userId: userCredential.user!.uid,
          email: _emailController.text.trim(),
          displayName: _nameController.text.trim(),
        );
      }

      if (mounted) {
        widget.onSignUpSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final currentLang = widget.languageProvider.currentLocale.languageCode;
    final isEnglish = currentLang == 'en';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEnglish ? 'Create Account' : 'Opprett konto'),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          _buildLanguageSelector(primaryColor),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const SizedBox(height: 24),

            // Header
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.person_add,
                    size: 56,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Registrer deg',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opprett en konto for å komme i gang',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[700], fontSize: 14),
                ),
              ),

            // Name field
            AutofillGroup(
              child: TextField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Fullt navn',
                  hintText: 'Ola Nordmann',
                  prefixIcon: const Icon(Icons.person_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                onSubmitted: (_) => _emailFocusNode.requestFocus(),
              ),
            ),
            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              focusNode: _emailFocusNode,
              decoration: InputDecoration(
                labelText: 'E-postadresse',
                hintText: 'navn@eksempel.no',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: !_showPassword,
              focusNode: _passwordFocusNode,
              decoration: InputDecoration(
                labelText: 'Passord',
                hintText: 'Minst 6 tegn',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),

            // Confirm password field
            TextField(
              controller: _confirmPasswordController,
              enabled: !_isLoading,
              obscureText: !_showConfirmPassword,
              focusNode: _confirmPasswordFocusNode,
              decoration: InputDecoration(
                labelText: 'Bekreft passord',
                hintText: 'Gjenta passordet',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _showConfirmPassword = !_showConfirmPassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) {
                if (!_isLoading) {
                  _signUp();
                }
              },
            ),
            const SizedBox(height: 20),

            // Terms checkbox
            CheckboxListTile(
              value: _agreedToTerms,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
              contentPadding: EdgeInsets.zero,
              title: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  children: [
                    const TextSpan(text: 'Jeg godtar '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          // Open terms and conditions
                        },
                        child: Text(
                          'vilkårene for bruk',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sign up button
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Opprett konto',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Login link
            Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  children: [
                    const TextSpan(text: 'Har du allerede en konto? '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: Text(
                          'Logg inn',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _buildLanguageSelector(Color primaryColor) {
    final currentLang = widget.languageProvider.currentLocale.languageCode;
    final languages = [
      {'code': 'nb', 'name': 'Norsk', 'flag': '🇳🇴'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    ];

    return PopupMenuButton<String>(
      onSelected: (String languageCode) async {
        await widget.languageProvider.setLanguage(languageCode);
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
                    color: isSelected ? primaryColor : AppColors.neutral800,
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
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLang == 'nb' ? '🇳🇴' : '🇬🇧',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more_rounded, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}
