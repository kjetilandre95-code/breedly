import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:peddex/generated_l10n/app_localizations.dart';
import 'package:peddex/providers/kennel_provider.dart';
import 'package:peddex/providers/subscription_provider.dart';
import 'package:peddex/services/auth_service.dart';
import 'package:peddex/services/cloud_sync_service.dart';
import 'package:peddex/screens/kennel_management_screen.dart';
import 'package:peddex/screens/kennel_profile_screen.dart';
import 'package:peddex/screens/personal_profile_screen.dart';
import 'package:peddex/screens/settings_screen.dart';
import 'package:peddex/utils/app_theme.dart';
import 'package:peddex/utils/theme_colors.dart';
import 'package:peddex/utils/notification_service.dart';
import 'package:peddex/services/reminder_manager.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _cloudProfile;
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadCloudProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCloudProfile() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;
    try {
      final profile = await FirestoreService().getUserProfile(userId);
      if (mounted) {
        setState(() {
          _cloudProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error loading cloud profile: $e');
    }
  }

  User? get _user => _authService.currentUser;

  String get _displayName =>
      _user?.displayName ??
      _cloudProfile?['displayName'] ??
      '';

  String get _email => _user?.email ?? _cloudProfile?['email'] ?? '';

  String? get _photoUrl => _user?.photoURL ?? _cloudProfile?['photoUrl'];

  DateTime? get _creationDate => _user?.metadata.creationTime;

  DateTime? get _lastSignIn => _user?.metadata.lastSignInTime;

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat.yMMMd().format(date);
  }

  Future<void> _updateDisplayName(String newName) async {
    if (newName.trim().isEmpty) return;
    try {
      await _authService.updateUserProfile(displayName: newName.trim());
      // Also update in Firestore
      final userId = _authService.currentUserId;
      if (userId != null) {
        await FirestoreService().saveUserProfile(
          userId: userId,
          email: _email,
          displayName: newName.trim(),
          photoUrl: _photoUrl,
        );
      }
      if (mounted) {
        setState(() => _isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.dataSynced ?? 'Saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.errorWithDetails(e.toString()) ?? 'Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_email.isEmpty) return;
    try {
      await _authService.sendPasswordResetEmail(_email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.passwordResetSent ??
                  'Password reset email sent to $_email',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorWithDetails(e.toString()) ?? 'Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteAccount ?? 'Delete Account'),
        content: Text(
          l10n?.deleteAccountConfirmation ??
              'This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.deleteUserAccount();
        // The auth state stream in main.dart will redirect to login
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.errorWithDetails(e.toString()) ?? 'Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.logOut ?? 'Log out'),
        content: Text(l10n?.logOutConfirm ?? 'Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n?.logOut ?? 'Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // ignore: use_build_context_synchronously
        await context.read<SubscriptionProvider>().logout();
        await _authService.signOut();
        // Pop all pushed routes so the StreamBuilder in main.dart can
        // show the LoginScreen instead of keeping this page visible.
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.errorWithDetails(e.toString()) ?? 'Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    final subProvider = context.watch<SubscriptionProvider>();
    final kennelProvider = context.watch<KennelProvider>();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: kIsWeb ? 900 : double.infinity,
          ),
          child: CustomScrollView(
            slivers: [
          // Profile header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Gap(32),
                        // Avatar
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage:
                              _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                          child: _photoUrl == null
                              ? Text(
                                  _displayName.isNotEmpty
                                      ? _displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const Gap(12),
                        // Name
                        Text(
                          _displayName.isNotEmpty
                              ? _displayName
                              : (l10n?.noName ?? 'No name'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.settings),
                tooltip: l10n?.settings ?? 'Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Account Info ──
                _buildSectionCard(
                  icon: LucideIcons.user,
                  title: l10n?.account ?? 'Account',
                  children: [
                    _buildInfoRow(
                      icon: LucideIcons.badgeCheck,
                      label: l10n?.name ?? 'Name',
                      value: _displayName.isNotEmpty
                          ? _displayName
                          : (l10n?.noName ?? 'Not set'),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.pencil, size: 18),
                        onPressed: () {
                          _nameController.text = _displayName;
                          setState(() => _isEditingName = true);
                        },
                      ),
                    ),
                    if (_isEditingName) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: l10n?.name ?? 'Name',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                                onSubmitted: _updateDisplayName,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              icon: const Icon(LucideIcons.check,
                                  color: AppColors.success),
                              onPressed: () =>
                                  _updateDisplayName(_nameController.text),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x,
                                  color: AppColors.error),
                              onPressed: () =>
                                  setState(() => _isEditingName = false),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _buildInfoRow(
                      icon: LucideIcons.mail,
                      label: l10n?.email ?? 'Email',
                      value: _email.isNotEmpty ? _email : '—',
                    ),
                    _buildInfoRow(
                      icon: LucideIcons.calendarDays,
                      label: l10n?.memberSince ?? 'Member since',
                      value: _formatDate(_creationDate),
                    ),
                    _buildInfoRow(
                      icon: LucideIcons.logIn,
                      label: l10n?.lastLogin ?? 'Last login',
                      value: _formatDate(_lastSignIn),
                    ),
                    if (_user?.uid != null)
                      _buildInfoRow(
                        icon: LucideIcons.fingerprint,
                        label: l10n?.userId ?? 'User ID',
                        value: '${_user!.uid.substring(0, 12)}…',
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _user!.uid));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n?.copied ?? 'Copied')),
                            );
                          },
                        ),
                      ),
                  ],
                ),

                const Gap(AppSpacing.lg),

                // ── Subscription ──
                _buildSectionCard(
                  icon: LucideIcons.award,
                  title: l10n?.subscription ?? 'Subscription',
                  children: [
                    _buildInfoRow(
                      icon: LucideIcons.star,
                      label: l10n?.status ?? 'Status',
                      value: l10n?.peddexPremium ?? 'Peddex Premium',
                      valueColor: AppColors.success,
                    ),
                    if (subProvider.expirationDate != null)
                      _buildInfoRow(
                        icon: LucideIcons.calendarDays,
                        label: l10n?.expires ?? 'Expires',
                        value: _formatDate(subProvider.expirationDate),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await subProvider.restorePurchases();
                            if (mounted) {
                              final msg = subProvider.isPremium
                                  ? (l10n?.premiumRestored ??
                                      'Premium restored!')
                                  : (l10n?.noPreviousPurchases ??
                                      'No previous purchases found');
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          },
                          icon: const Icon(LucideIcons.rotateCcw),
                          label: Text(
                              l10n?.restorePurchases ?? 'Restore purchases'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdAll),
                            side: BorderSide(color: primaryColor),
                          ),
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                  ],
                ),

                const Gap(AppSpacing.lg),

                // ── Kennel ──
                _buildSectionCard(
                  icon: LucideIcons.building2,
                  title: l10n?.kennel ?? 'Kennel',
                  children: [
                    if (kennelProvider.hasActiveKennel) ...[
                      _buildInfoRow(
                        icon: LucideIcons.footprints,
                        label: l10n?.kennelName ?? 'Kennel name',
                        value: kennelProvider.activeKennel?.name ?? '—',
                      ),
                      _buildInfoRow(
                        icon: LucideIcons.shieldCheck,
                        label: l10n?.role ?? 'Role',
                        value: kennelProvider.isOwner
                            ? (l10n?.owner ?? 'Owner')
                            : kennelProvider.isAdmin
                                ? (l10n?.admin ?? 'Admin')
                                : (l10n?.member ?? 'Member'),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          l10n?.noKennelYet ?? 'No kennel set up yet',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const KennelManagementScreen()),
                              ),
                              icon: const Icon(LucideIcons.settings, size: 18),
                              label: Text(l10n?.kennelManagement ?? 'Manage'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm),
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.mdAll),
                                side: BorderSide(color: primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const KennelProfileScreen()),
                              ),
                              icon: const Icon(LucideIcons.pencil, size: 18),
                              label: Text(l10n?.editProfile ?? 'Profile'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm),
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.mdAll),
                                side: BorderSide(color: primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Gap(AppSpacing.lg),

                // ── Breeder Profile (for users without a kennel) ──
                if (!kennelProvider.hasActiveKennel)
                  _buildSectionCard(
                    icon: LucideIcons.user,
                    title: l10n?.breederProfile ?? 'Breeder Profile',
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.breederProfileDesc ??
                                  'Create a public profile as an individual breeder',
                              style: AppTypography.bodySmall.copyWith(
                                color: context.colors.textMuted,
                              ),
                            ),
                            const Gap(AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PersonalProfileScreen()),
                                ),
                                icon: const Icon(LucideIcons.user, size: 18),
                                label: Text(l10n?.createBreederProfile ??
                                    'Create Breeder Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.info,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.mdAll),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const Gap(AppSpacing.lg),

                // ── Data ──
                _buildSectionCard(
                  icon: LucideIcons.cloudCog,
                  title: 'Data',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _refreshProfileData(),
                              icon: const Icon(LucideIcons.refreshCw),
                              label: const Text('Refresh'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.mdAll),
                                side: BorderSide(color: primaryColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Gap(AppSpacing.lg),

                // ── Notifications ──
                _buildSectionCard(
                  icon: LucideIcons.bell,
                  title: l10n?.notifications ?? 'Notifications',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        l10n?.updatingReminders ??
                                            'Updating reminders...'),
                                  ),
                                );
                                await ReminderManager().refreshAllReminders(l10n: l10n);
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          l10n?.remindersUpdated ??
                                              'Reminders updated'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(LucideIcons.refreshCw),
                              label: Text(l10n?.updateAllReminders ??
                                  'Update all reminders'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.mdAll),
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          // Info text
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: AppRadius.mdAll,
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.info,
                                    color: AppColors.info, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    l10n?.notificationsInfo ??
                                        'Reminders are set automatically for upcoming events.',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.info,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          // Cancel all
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(
                                        l10n?.turnOffNotificationsTitle ??
                                            'Turn off notifications?'),
                                    content: Text(
                                        l10n?.turnOffNotificationsMessage ??
                                            'This will cancel all scheduled notifications.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: Text(
                                            l10n?.cancel ?? 'Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final navigator =
                                              Navigator.of(dialogContext);
                                          final scaffoldMessenger =
                                              ScaffoldMessenger.of(
                                                  dialogContext);
                                          await NotificationService()
                                              .cancelAllNotifications();
                                          navigator.pop();
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Text(l10n
                                                      ?.allNotificationsTurnedOff ??
                                                  'All notifications turned off'),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(
                                            l10n?.turnOff ?? 'Turn off'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(
                                  LucideIcons.bellOff),
                              label: Text(
                                  l10n?.turnOffAllNotifications ??
                                      'Turn off all notifications'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(
                                    color: AppColors.error),
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.mdAll),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Gap(AppSpacing.lg),

                // ── Security ──
                _buildSectionCard(
                  icon: LucideIcons.shield,
                  title: l10n?.security ?? 'Security',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _sendPasswordReset,
                              icon: const Icon(LucideIcons.keyRound),
                              label: Text(l10n?.resetPassword ??
                                  'Send password reset email'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.mdAll),
                                side: BorderSide(color: primaryColor),
                              ),
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _confirmDeleteAccount,
                              icon: const Icon(LucideIcons.trash2),
                              label: Text(l10n?.deleteAccount ??
                                  'Delete account'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.mdAll),
                                side:
                                    const BorderSide(color: AppColors.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Gap(AppSpacing.xl),

                // ── Logout ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(LucideIcons.logOut),
                    label: Text(l10n?.logOut ?? 'Log out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdAll),
                    ),
                  ),
                ),

                const Gap(AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.colors.textMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: context.colors.textCaption,
                  ),
                ),
                const Gap(2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: valueColor ?? context.colors.textPrimary,
                    fontWeight:
                        valueColor != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Future<void> _refreshProfileData() async {
    final l10n = AppLocalizations.of(context);
    try {
      await _loadCloudProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.dataSynced ?? 'Data refreshed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
