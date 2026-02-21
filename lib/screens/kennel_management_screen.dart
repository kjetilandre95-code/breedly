import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:breedly/models/kennel.dart';
import 'package:breedly/models/kennel_member.dart';
import 'package:breedly/models/kennel_invitation.dart';
import 'package:breedly/services/kennel_service.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class KennelManagementScreen extends StatefulWidget {
  const KennelManagementScreen({super.key});

  @override
  State<KennelManagementScreen> createState() => _KennelManagementScreenState();
}

class _KennelManagementScreenState extends State<KennelManagementScreen> {
  final _kennelService = KennelService();
  List<Kennel> _kennels = [];
  List<KennelMember> _members = [];
  List<KennelInvitation> _invitations = [];
  Kennel? _activeKennel;
  KennelMember? _currentUserMember;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = AuthService().currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final kennels = await _kennelService.getUserKennels(userId);
      setState(() {
        _kennels = kennels;
      });

      if (kennels.isNotEmpty) {
        final activeId = _kennelService.activeKennelId ?? kennels.first.id;
        await _loadKennelDetails(activeId);
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations?.loadingError(e.toString()) ?? 'Feil ved lasting: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadKennelDetails(String kennelId) async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;

    final kennel = _kennels.firstWhere((k) => k.id == kennelId);
    final members = await _kennelService.getKennelMembers(kennelId);
    final currentMember = await _kennelService.getMemberInfo(kennelId, userId);
    final invitations = await _kennelService.getActiveInvitations(kennelId);

    setState(() {
      _activeKennel = kennel;
      _members = members;
      _currentUserMember = currentMember;
      _invitations = invitations;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(localizations.kennelManagement),
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: context.colors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _kennels.isEmpty
              ? _buildNoKennelState()
              : _buildKennelContent(),
    );
  }

  Widget _buildNoKennelState() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: context.colors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              localizations.noLittersRegistered,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              localizations.setupKennelMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.md,
              children: [
                ElevatedButton.icon(
                  onPressed: _showCreateKennelDialog,
                  icon: const Icon(Icons.add),
                  label: Text(localizations.createKennel),
                ),
                OutlinedButton.icon(
                  onPressed: _showJoinKennelDialog,
                  icon: const Icon(Icons.login),
                  label: Text(localizations.joinKennel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKennelContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Kennel selector if multiple kennels
          if (_kennels.length > 1) ...[
            _buildKennelSelector(),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Kennel info card
          if (_activeKennel != null) ...[
            _buildKennelInfoCard(),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Members section
          _buildMembersSection(),
          const SizedBox(height: AppSpacing.lg),

          // Pending invitations
          if (_invitations.isNotEmpty && (_currentUserMember?.canInvite ?? false)) ...[
            _buildInvitationsSection(),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Actions
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildKennelSelector() {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.selectKennel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _activeKennel?.id,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
              items: _kennels.map((k) {
                return DropdownMenuItem(
                  value: k.id,
                  child: Text(
                    k.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _kennelService.setActiveKennel(value);
                  _loadKennelDetails(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKennelInfoCard() {
    final localizations = AppLocalizations.of(context)!;
    final kennel = _activeKennel!;
    final isOwner = _currentUserMember?.isOwner ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(
                    Icons.home_work,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kennel.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_members.length} ${_members.length == 1 ? localizations.memberSingular : localizations.membersPlural}',
                        style: TextStyle(color: context.colors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _showEditKennelDialog,
                  ),
              ],
            ),
            if (kennel.description != null && kennel.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                kennel.description!,
                style: TextStyle(color: context.colors.textMuted),
              ),
            ],
            if (kennel.breeds.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: kennel.breeds.map((breed) {
                  return Chip(
                    label: Text(breed, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context)!.membersSection,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_members.length}',
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ..._members.map((member) => _buildMemberTile(member)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(KennelMember member) {
    final localizations = AppLocalizations.of(context)!;
    final isCurrentUser = member.userId == AuthService().currentUserId;
    final canManage = (_currentUserMember?.isOwner ?? false) && !isCurrentUser;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: member.photoUrl != null
            ? NetworkImage(member.photoUrl!)
            : null,
        child: member.photoUrl == null
            ? Text(member.displayName?.substring(0, 1).toUpperCase() ?? '?')
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.displayName ?? member.email,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrentUser)
            Container(
              margin: const EdgeInsets.only(left: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: AppRadius.smAll,
              ),
              child: Text(
                localizations.youLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.info),
              ),
            ),
        ],
      ),
      subtitle: Text(_getRoleText(member.role, localizations)),
      trailing: canManage
          ? PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text(localizations.changeRole),
                  onTap: () => Future.delayed(
                    Duration.zero,
                    () => _showChangeRoleDialog(member),
                  ),
                ),
                PopupMenuItem(
                  child: Text(localizations.removeLabel, style: const TextStyle(color: AppColors.error)),
                  onTap: () => Future.delayed(
                    Duration.zero,
                    () => _confirmRemoveMember(member),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  String _getRoleText(String role, AppLocalizations localizations) {
    switch (role) {
      case 'owner':
        return localizations.ownerRole;
      case 'admin':
        return localizations.administratorRole;
      default:
        return localizations.memberRole;
    }
  }

  Widget _buildInvitationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mail_outline, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context)!.pendingInvitations,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_invitations.length}',
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ..._invitations.map((inv) => _buildInvitationTile(inv)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationTile(KennelInvitation invitation) {
    final localizations = AppLocalizations.of(context)!;
    final daysLeft = invitation.expiresAt.difference(DateTime.now()).inDays;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.link),
      title: Text(
        invitation.code,
        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        invitation.invitedEmail ?? localizations.openInvitationExpires(daysLeft.toString()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: invitation.code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.codeCopiedToClipboard)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _deleteInvitation(invitation),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.actionsSection,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if ((_currentUserMember?.canInvite ?? false) && _activeKennel != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.person_add, color: Theme.of(context).primaryColor),
                title: Text(localizations.inviteMember, style: TextStyle(color: Theme.of(context).primaryColor)),
                subtitle: Text(localizations.createInvitationCode),
                onTap: _showCreateInvitationDialog,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_home_work),
              title: Text(localizations.createNewKennel),
              onTap: _showCreateKennelDialog,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.login),
              title: Text(localizations.joinKennelLabel),
              subtitle: Text(localizations.useInvitationCode),
              onTap: _showJoinKennelDialog,
            ),
            if (_currentUserMember != null && !_currentUserMember!.isOwner)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: AppColors.warning),
                title: Text(localizations.leaveKennel, style: const TextStyle(color: AppColors.warning)),
                onTap: _confirmLeaveKennel,
              ),
            if (_currentUserMember?.isOwner ?? false)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever, color: AppColors.error),
                title: Text(localizations.deleteKennelLabel, style: const TextStyle(color: AppColors.error)),
                onTap: _confirmDeleteKennel,
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateKennelDialog() {
    final localizations = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.createNewKennel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: localizations.kennelNameRequired,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: localizations.descriptionLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.nameIsRequired)),
                );
                return;
              }

              final user = AuthService().currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.mustBeLoggedIn)),
                );
                return;
              }

              try {
                await _kennelService.createKennel(
                  userId: user.uid,
                  userEmail: user.email ?? '',
                  name: nameController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                  displayName: user.displayName,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.kennelCreatedSuccess)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.errorGeneric(e.toString()))),
                  );
                }
              }
            },
            child: Text(localizations.createButton),
          ),
        ],
      ),
    );
  }

  void _showJoinKennelDialog() {
    final localizations = AppLocalizations.of(context)!;
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.joinKennelLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.enterInvitationCodeMessage),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: localizations.invitationCode,
                border: const OutlineInputBorder(),
                hintText: localizations.invitationCodeHint,
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.codeMustBe6Chars)),
                );
                return;
              }

              try {
                await _kennelService.acceptInvitation(codeController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.joinedKennelSuccess)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            child: Text(localizations.joinButton),
          ),
        ],
      ),
    );
  }

  void _showEditKennelDialog() {
    final localizations = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: _activeKennel?.name);
    final descriptionController =
        TextEditingController(text: _activeKennel?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.editKennel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: localizations.kennelNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: localizations.descriptionLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.nameIsRequired)),
                );
                return;
              }

              try {
                await _kennelService.updateKennel(
                  kennelId: _activeKennel!.id,
                  name: nameController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.kennelUpdated)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.errorGeneric(e.toString()))),
                  );
                }
              }
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(KennelMember member) {
    final localizations = AppLocalizations.of(context)!;
    String selectedRole = member.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(localizations.changeRoleFor(member.displayName ?? member.email)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: selectedRole,
                onChanged: (v) => setState(() => selectedRole = v!),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: Text(localizations.memberRole),
                      value: 'member',
                    ),
                    RadioListTile<String>(
                      title: Text(localizations.administratorRole),
                      value: 'admin',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _kennelService.updateMemberRole(
                    _activeKennel!.id,
                    member.userId,
                    selectedRole,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadKennelDetails(_activeKennel!.id);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.errorGeneric(e.toString()))),
                    );
                  }
                }
              },
              child: Text(localizations.save),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(KennelMember member) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.removeMemberQuestion),
        content: Text(
            localizations.confirmRemoveMember(member.displayName ?? member.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              try {
                await _kennelService.removeMember(
                    _activeKennel!.id, member.userId);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadKennelDetails(_activeKennel!.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.memberRemoved)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.errorGeneric(e.toString()))),
                  );
                }
              }
            },
            child: Text(localizations.removeLabel),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveKennel() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.leaveKennelQuestion),
        content: Text(
            localizations.confirmLeaveKennel(_activeKennel?.name ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () async {
              try {
                await _kennelService.leaveKennel(_activeKennel!.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.leftKennel)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.errorGeneric(e.toString()))),
                  );
                }
              }
            },
            child: Text(localizations.leaveButton),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKennel() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteKennelQuestion),
        content: Text(
            localizations.confirmDeleteKennel(_activeKennel?.name ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              try {
                await _kennelService.deleteKennel(_activeKennel!.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.kennelDeleted)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.errorGeneric(e.toString()))),
                  );
                }
              }
            },
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
  }

  void _deleteInvitation(KennelInvitation invitation) async {
    try {
      await _kennelService.deleteInvitation(invitation.code);
      _loadKennelDetails(_activeKennel!.id);
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.errorGeneric(e.toString()))),
        );
      }
    }
  }

  void _showCreateInvitationDialog() {
    final localizations = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    String selectedRole = 'member';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(localizations.inviteMember),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.invitationCodeDescription,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: localizations.emailOptional,
                    border: const OutlineInputBorder(),
                    hintText: localizations.emailPlaceholder,
                    helperText: localizations.leaveEmptyForOpen,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  localizations.roleLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: context.colors.border),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: RadioGroup<String>(
                    groupValue: selectedRole,
                    onChanged: (v) => setDialogState(() => selectedRole = v!),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: Text(localizations.memberRole),
                          subtitle: Text(localizations.canViewAndEdit),
                          value: 'member',
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: Text(localizations.administratorRole),
                          subtitle: Text(localizations.canAlsoInvite),
                          value: 'admin',
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send, size: 18),
              onPressed: () async {
                try {
                  final invitation = await _kennelService.createInvitation(
                    kennelId: _activeKennel!.id,
                    role: selectedRole,
                    invitedEmail: emailController.text.isEmpty ? null : emailController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadKennelDetails(_activeKennel!.id);
                    _showInvitationCreatedDialog(invitation.code);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.errorGeneric(e.toString()))),
                    );
                  }
                }
              },
              label: Text(localizations.createInvitation),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvitationCreatedDialog(String code) {
    final localizations = AppLocalizations.of(context)!;
    final kennelName = _activeKennel?.name ?? 'kennelen';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(localizations.invitationCreated)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localizations.shareCodeMessage),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.colors.neutral100,
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      localizations.validFor7Days,
                      style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                localizations.shareInvitationLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareButton(
                    icon: Icons.copy,
                    label: localizations.copyLabel,
                    color: context.colors.textTertiary,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(localizations.codeCopiedToClipboard)),
                      );
                    },
                  ),
                  _buildShareButton(
                    icon: Icons.email,
                    label: localizations.emailButtonLabel,
                    color: AppColors.info,
                    onTap: () => _sendEmailInvitation(code, kennelName),
                  ),
                  _buildShareButton(
                    icon: Icons.share,
                    label: localizations.shareButtonLabel,
                    color: AppColors.success,
                    onTap: () => _shareInvitation(code, kennelName),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.finishedButton),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.mdAll,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmailInvitation(String code, String kennelName) async {
    final localizations = AppLocalizations.of(context)!;
    final subject = Uri.encodeComponent(localizations.invitationEmailSubject(kennelName));
    final body = Uri.encodeComponent(localizations.invitationEmailBody(kennelName, code));
    
    final emailUri = Uri.parse('mailto:?subject=$subject&body=$body');
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.couldNotOpenEmail)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.errorOpeningEmail(e.toString()))),
        );
      }
    }
  }

  Future<void> _shareInvitation(String code, String kennelName) async {
    final localizations = AppLocalizations.of(context)!;
    final message = localizations.invitationShareMessage(kennelName, code);
    
    try {
      await Share.share(
        message,
        subject: localizations.invitationEmailSubject(kennelName),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.errorSharing(e.toString()))),
        );
      }
    }
  }
}
