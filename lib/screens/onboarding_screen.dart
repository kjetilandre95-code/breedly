import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';

/// Onboarding screen shown to new users after first login
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  /// Check if onboarding has been completed
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.pets_rounded,
      title: 'Velkommen til Breedly',
      description: 'Din komplette løsning for oppdrettsadministrasjon. '
          'Hold oversikt over hunder, kull, kjøpere og mye mer.',
      color: AppColors.primary,
    ),
    OnboardingPage(
      icon: Icons.favorite_rounded,
      title: 'Administrer hundene dine',
      description: 'Legg til hunder med stamtavle, helseinformasjon, '
          'utstillingsresultater og bilder. Alt på ett sted.',
      color: AppColors.female,
    ),
    OnboardingPage(
      icon: Icons.pets_rounded,
      title: 'Spor kull og valper',
      description: 'Registrer kull, følg valpenes utvikling med vektlogg, '
          'og generer kontrakter for kjøpere.',
      color: AppColors.secondary,
    ),
    OnboardingPage(
      icon: Icons.calendar_today_rounded,
      title: 'Kalender og påminnelser',
      description: 'Aldri glem viktige datoer. Få varsler om vaksinasjoner, '
          'veterinærbesøk og andre hendelser.',
      color: AppColors.success,
    ),
    OnboardingPage(
      icon: Icons.analytics_rounded,
      title: 'Statistikk og rapporter',
      description: 'Få innsikt i ditt oppdrett med detaljert statistikk, '
          'finansoversikt og årsrapporter.',
      color: AppColors.info,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Hopp over',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page, isDark);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildIndicator(index, theme),
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxxl),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _pages.length - 1 
                        ? 'Kom i gang' 
                        : 'Neste',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
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

  Widget _buildPage(OnboardingPage page, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with colored background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: AppSpacing.massive),

          // Title
          Text(
            page.title,
            style: AppTypography.headlineLarge.copyWith(
              color: context.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Description
          Text(
            page.description,
            style: AppTypography.bodyLarge.copyWith(
              color: context.colors.textCaption,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index, ThemeData theme) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.primary 
            : AppColors.primary.withValues(alpha: 0.3),
        borderRadius: AppRadius.xsAll,
      ),
    );
  }
}

/// Data class for onboarding page content
class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
