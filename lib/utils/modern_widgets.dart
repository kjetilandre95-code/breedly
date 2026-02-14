import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/constants.dart';

/// Modern, reusable UI components for Breedly
/// All components follow the design system for consistency

// =============================================================================
// STAT CARD - For dashboard statistics
// =============================================================================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.neutral200),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: ThemeOpacity.medium(context)),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.neutral600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ACTION CARD - For quick actions
// =============================================================================

class ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Builder(
          builder: (context) => Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: color.withValues(alpha: ThemeOpacity.medium(context)),
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: color.withValues(alpha: ThemeOpacity.high(context))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: ThemeOpacity.medium(context)),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.neutral900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DOG CARD - Modern dog list item
// =============================================================================

class DogCard extends StatelessWidget {
  final String name;
  final String breed;
  final String gender;
  final String age;
  final String? imageUrl;
  final String? subtitle;
  final VoidCallback onTap;
  final List<Widget>? badges;

  const DogCard({
    super.key,
    required this.name,
    required this.breed,
    required this.gender,
    required this.age,
    this.imageUrl,
    this.subtitle,
    required this.onTap,
    this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final genderColor = gender == 'Male' ? AppColors.male : AppColors.female;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: genderColor.withValues(alpha: ThemeOpacity.medium(context)),
                  borderRadius: AppRadius.mdAll,
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: AppRadius.mdAll,
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.pets_rounded,
                            color: genderColor,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(Icons.pets_rounded, color: genderColor, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: genderColor.withValues(alpha: ThemeOpacity.medium(context)),
                            borderRadius: AppRadius.xsAll,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                gender == 'Male'
                                    ? Icons.male_rounded
                                    : Icons.female_rounded,
                                color: genderColor,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      breed,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          color: AppColors.neutral400,
                          size: 14,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(age, style: AppTypography.caption),
                        if (badges != null && badges!.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.sm),
                          ...badges!,
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutral400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// LITTER CARD - Modern litter display
// =============================================================================

class LitterCard extends StatelessWidget {
  final String damName;
  final String sireName;
  final String breed;
  final DateTime birthDate;
  final int puppyCount;
  final int availableCount;
  final VoidCallback onTap;
  final String? status;

  const LitterCard({
    super.key,
    required this.damName,
    required this.sireName,
    required this.breed,
    required this.birthDate,
    required this.puppyCount,
    required this.availableCount,
    required this.onTap,
    this.status,
  });

  String _getAgeText() {
    final now = DateTime.now();
    // Sjekk om dette er et planlagt kull (fødselsdato i fremtiden)
    if (birthDate.isAfter(now)) {
      final daysUntil = birthDate.difference(now).inDays;
      if (daysUntil == 0) return 'I dag';
      if (daysUntil == 1) return 'I morgen';
      return '$daysUntil dager';
    }
    
    final weeks = now.difference(birthDate).inDays ~/ 7;
    if (weeks < 1) return 'Nyfødt';
    if (weeks == 1) return '1 uke';
    if (weeks < 8) return '$weeks uker';
    final months = weeks ~/ 4;
    if (months == 1) return '1 måned';
    return '$months måneder';
  }

  bool get _isPlanned => birthDate.isAfter(DateTime.now());

  Color _getStatusColor(BuildContext context) {
    // Planlagt kull = oransje
    if (_isPlanned) return Colors.orange;
    
    final weeks = DateTime.now().difference(birthDate).inDays ~/ 7;
    final primaryColor = Theme.of(context).primaryColor;
    if (weeks < 8) return primaryColor; // Active
    if (weeks < 12) return primaryColor.withValues(alpha: 0.7); // Weaning
    return AppColors.neutral500; // Older
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: ThemeOpacity.medium(context)),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(
                      FontAwesomeIcons.paw,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$damName × $sireName',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          breed,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    text: _isPlanned ? 'Planlagt' : _getAgeText(), 
                    color: statusColor,
                    subtitle: _isPlanned ? _getAgeText() : null,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Stats row
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.smAll,
                ),
                child: Row(
                  children: [
                    _buildStat(
                      icon: FontAwesomeIcons.bone,
                      label: 'Valper',
                      value: puppyCount.toString(),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _buildStat(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Tilgjengelig',
                      value: availableCount.toString(),
                      color: availableCount > 0
                          ? AppColors.success
                          : AppColors.neutral500,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.neutral400,
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

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.neutral500),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                color: color ?? AppColors.neutral900,
              ),
            ),
            Text(label, style: AppTypography.caption.copyWith(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// STATUS BADGE
// =============================================================================

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final String? subtitle;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: ThemeOpacity.medium(context)),
        borderRadius: AppRadius.xsAll,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: color),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                text,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: AppTypography.labelSmall.copyWith(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.neutral900,
            ),
          ),
          if (actionText != null || actionIcon != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (actionText != null)
                    Text(
                      actionText!,
                      style: AppTypography.labelMedium.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  if (actionIcon != null) ...[
                    if (actionText != null)
                      const SizedBox(width: AppSpacing.xs),
                    Icon(actionIcon, size: 18, color: Theme.of(context).primaryColor),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY STATE
// =============================================================================

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.neutral400).withValues(alpha: ThemeOpacity.low(context)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: (iconColor ?? AppColors.neutral400).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.neutral800,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.neutral500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SEARCH BAR
// =============================================================================

class ModernSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  const ModernSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Søk...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdAll,
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.neutral900),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.neutral500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.neutral500,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.neutral500,
                  ),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          filled: false,
        ),
      ),
    );
  }
}

// =============================================================================
// INFO ROW
// =============================================================================

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.neutral500),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: valueColor ?? AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MODERN TAB BAR
// =============================================================================

class ModernTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final List<IconData>? icons;
  final List<int>? badgeCounts;

  const ModernTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.icons,
    this.badgeCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdAll,
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.smAll,
          boxShadow: AppShadows.sm,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: AppColors.neutral600,
        labelStyle: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelMedium,
        labelPadding: EdgeInsets.zero,
        tabs: List.generate(tabs.length, (index) {
          final badgeCount = badgeCounts != null && index < badgeCounts!.length 
              ? badgeCounts![index] 
              : null;
          
          return Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icons != null && index < icons!.length) ...[
                      Icon(icons![index], size: 16),
                      const SizedBox(width: 3),
                    ],
                    Text(tabs[index]),
                    if (badgeCount != null && badgeCount > 0) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: ThemeOpacity.medium(context)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
