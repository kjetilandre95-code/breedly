import 'package:flutter/material.dart';
import 'package:breedly/services/user_sharing_service.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class UserSharingScreen extends StatefulWidget {
  final String breedingGroupId;
  final String breedingGroupName;

  const UserSharingScreen({
    super.key,
    required this.breedingGroupId,
    required this.breedingGroupName,
  });

  @override
  State<UserSharingScreen> createState() => _UserSharingScreenState();
}

class _UserSharingScreenState extends State<UserSharingScreen> {
  final _userSharingService = UserSharingService();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  List<Map<String, dynamic>> _sharedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSharedUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSharedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users =
          await _userSharingService.getSharedUsersForGroup(widget.breedingGroupId);
      setState(() => _sharedUsers = users);
    } catch (e) {
      AppLogger.debug('Error loading shared users: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLoadingSharedUsers(e))),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareWithUser() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterEmail)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _userSharingService.shareBreedingGroupWithUser(
        widget.breedingGroupId,
        email,
        role: 'collaborator',
      );

      if (result != null) {
        _emailController.clear();
        await _loadSharedUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.sharedWithEmail(email))),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.userNotFoundByEmail(email))),
          );
        }
      }
    } catch (e) {
      AppLogger.debug('Error sharing with user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSharing(e.toString()))),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeUser(String userId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeUser),
        content: Text(l10n.confirmRemoveUser),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remove, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _userSharingService.removeUserFromBreedingGroup(
          widget.breedingGroupId,
          userId,
        );
        await _loadSharedUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.userRemoved)),
          );
        }
      } catch (e) {
        AppLogger.debug('Error removing user: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorRemovingUser(e))),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: l10n.shareGroupName(widget.breedingGroupName),
        context: context,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Share input section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.shareWithCollaborator,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              decoration: InputDecoration(
                                hintText: l10n.emailAddress,
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.smAll,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.email],
                              onSubmitted: (_) {
                                if (!_isLoading) {
                                  _shareWithUser();
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _shareWithUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                ),
                                child: Text(
                                  l10n.share,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Shared users list
                    Text(
                      l10n.sharedWith,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_sharedUsers.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            l10n.notSharedWithAnyone,
                            style: TextStyle(color: context.colors.textDisabled),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sharedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _sharedUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Icon(
                                  user['role'] == 'owner'
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(user['email'] ?? 'Unknown'),
                              subtitle: Text(
                                user['role'] == 'owner' ? l10n.ownerRoleLabel : l10n.collaborator,
                              ),
                              trailing: user['role'] != 'owner'
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: AppColors.error,
                                      ),
                                      onPressed: () =>
                                          _removeUser(user['userId']),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
