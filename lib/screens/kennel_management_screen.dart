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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(localizations.kennelManagement),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.neutral900,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              localizations.noLittersRegistered,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.setupKennelMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showCreateKennelDialog,
                  icon: const Icon(Icons.add),
                  label: Text(localizations.createKennel),
                ),
                const SizedBox(width: 16),
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
        padding: const EdgeInsets.all(16),
        children: [
          // Kennel selector if multiple kennels
          if (_kennels.length > 1) ...[
            _buildKennelSelector(),
            const SizedBox(height: 16),
          ],

          // Kennel info card
          if (_activeKennel != null) ...[
            _buildKennelInfoCard(),
            const SizedBox(height: 16),
          ],

          // Members section
          _buildMembersSection(),
          const SizedBox(height: 16),

          // Pending invitations
          if (_invitations.isNotEmpty && (_currentUserMember?.canInvite ?? false)) ...[
            _buildInvitationsSection(),
            const SizedBox(height: 16),
          ],

          // Actions
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildKennelSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Velg kennel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _activeKennel?.id,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    final kennel = _activeKennel!;
    final isOwner = _currentUserMember?.isOwner ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.home_work,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
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
                        '${_members.length} ${_members.length == 1 ? 'medlem' : 'medlemmer'}',
                        style: TextStyle(color: Colors.grey[600]),
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
              const SizedBox(height: 12),
              Text(
                kennel.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            if (kennel.breeds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Medlemmer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_members.length}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._members.map((member) => _buildMemberTile(member)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(KennelMember member) {
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
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Deg',
                style: TextStyle(fontSize: 11, color: Colors.blue),
              ),
            ),
        ],
      ),
      subtitle: Text(_getRoleText(member.role)),
      trailing: canManage
          ? PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Endre rolle'),
                  onTap: () => Future.delayed(
                    Duration.zero,
                    () => _showChangeRoleDialog(member),
                  ),
                ),
                PopupMenuItem(
                  child: const Text('Fjern', style: TextStyle(color: Colors.red)),
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

  String _getRoleText(String role) {
    switch (role) {
      case 'owner':
        return 'Eier';
      case 'admin':
        return 'Administrator';
      default:
        return 'Medlem';
    }
  }

  Widget _buildInvitationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mail_outline, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Ventende invitasjoner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_invitations.length}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._invitations.map((inv) => _buildInvitationTile(inv)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationTile(KennelInvitation invitation) {
    final daysLeft = invitation.expiresAt.difference(DateTime.now()).inDays;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.link),
      title: Text(
        invitation.code,
        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        invitation.invitedEmail ?? 'Åpen invitasjon • Utløper om $daysLeft dager',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: invitation.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kode kopiert til utklippstavle')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteInvitation(invitation),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Handlinger',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if ((_currentUserMember?.canInvite ?? false) && _activeKennel != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.person_add, color: Theme.of(context).primaryColor),
                title: Text('Inviter medlem', style: TextStyle(color: Theme.of(context).primaryColor)),
                subtitle: const Text('Opprett invitasjonskode'),
                onTap: _showCreateInvitationDialog,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_home_work),
              title: const Text('Opprett ny kennel'),
              onTap: _showCreateKennelDialog,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.login),
              title: const Text('Bli med i kennel'),
              subtitle: const Text('Bruk invitasjonskode'),
              onTap: _showJoinKennelDialog,
            ),
            if (_currentUserMember != null && !_currentUserMember!.isOwner)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('Forlat kennel', style: TextStyle(color: Colors.orange)),
                onTap: _confirmLeaveKennel,
              ),
            if (_currentUserMember?.isOwner ?? false)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Slett kennel', style: TextStyle(color: Colors.red)),
                onTap: _confirmDeleteKennel,
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateKennelDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opprett ny kennel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Kennelnavn *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beskrivelse',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navn er påkrevd')),
                );
                return;
              }

              final user = AuthService().currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Du må være logget inn')),
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
                    const SnackBar(content: Text('Kennel opprettet!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Feil: $e')),
                  );
                }
              }
            },
            child: const Text('Opprett'),
          ),
        ],
      ),
    );
  }

  void _showJoinKennelDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bli med i kennel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Skriv inn invitasjonskoden du har mottatt:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Invitasjonskode',
                border: OutlineInputBorder(),
                hintText: 'F.eks. ABC123',
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
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Koden må være 6 tegn')),
                );
                return;
              }

              try {
                await _kennelService.acceptInvitation(codeController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Du er nå med i kennelen!')),
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
            child: const Text('Bli med'),
          ),
        ],
      ),
    );
  }

  void _showEditKennelDialog() {
    final nameController = TextEditingController(text: _activeKennel?.name);
    final descriptionController =
        TextEditingController(text: _activeKennel?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rediger kennel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Kennelnavn',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beskrivelse',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navn er påkrevd')),
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
                    const SnackBar(content: Text('Kennel oppdatert!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Feil: $e')),
                  );
                }
              }
            },
            child: const Text('Lagre'),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(KennelMember member) {
    String selectedRole = member.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Endre rolle for ${member.displayName ?? member.email}'),
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
                      title: const Text('Medlem'),
                      value: 'member',
                    ),
                    RadioListTile<String>(
                      title: const Text('Administrator'),
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
              child: const Text('Avbryt'),
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
                      SnackBar(content: Text('Feil: $e')),
                    );
                  }
                }
              },
              child: const Text('Lagre'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(KennelMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fjern medlem?'),
        content: Text(
            'Er du sikker på at du vil fjerne ${member.displayName ?? member.email} fra kennelen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _kennelService.removeMember(
                    _activeKennel!.id, member.userId);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadKennelDetails(_activeKennel!.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medlem fjernet')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Feil: $e')),
                  );
                }
              }
            },
            child: const Text('Fjern'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveKennel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forlat kennel?'),
        content: Text(
            'Er du sikker på at du vil forlate ${_activeKennel?.name}? Du vil miste tilgang til all data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              try {
                await _kennelService.leaveKennel(_activeKennel!.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Du har forlatt kennelen')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Feil: $e')),
                  );
                }
              }
            },
            child: const Text('Forlat'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKennel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett kennel?'),
        content: Text(
            'Er du HELT sikker på at du vil slette ${_activeKennel?.name}? Dette kan ikke angres!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _kennelService.deleteKennel(_activeKennel!.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kennel slettet')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Feil: $e')),
                  );
                }
              }
            },
            child: const Text('Slett'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil: $e')),
        );
      }
    }
  }

  void _showCreateInvitationDialog() {
    final emailController = TextEditingController();
    String selectedRole = 'member';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Inviter medlem'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Du kan opprette en invitasjonskode som andre kan bruke for å bli med i kennelen.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-postadresse (valgfritt)',
                    border: OutlineInputBorder(),
                    hintText: 'bruker@eksempel.no',
                    helperText: 'La stå tom for åpen invitasjon',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rolle',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RadioGroup<String>(
                    groupValue: selectedRole,
                    onChanged: (v) => setDialogState(() => selectedRole = v!),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Medlem'),
                          subtitle: const Text('Kan se og redigere data'),
                          value: 'member',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text('Administrator'),
                          subtitle: const Text('Kan også invitere medlemmer'),
                          value: 'admin',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
              child: const Text('Avbryt'),
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
                      SnackBar(content: Text('Feil: $e')),
                    );
                  }
                }
              },
              label: const Text('Opprett invitasjon'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvitationCreatedDialog(String code) {
    final kennelName = _activeKennel?.name ?? 'kennelen';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Expanded(child: Text('Invitasjon opprettet!')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Del denne koden med personen du vil invitere:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
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
                    const SizedBox(height: 8),
                    Text(
                      'Gyldig i 7 dager',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Del invitasjonen:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Kopier-knapp
                  _buildShareButton(
                    icon: Icons.copy,
                    label: 'Kopier',
                    color: Colors.grey.shade700,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kode kopiert til utklippstavle')),
                      );
                    },
                  ),
                  // E-post-knapp
                  _buildShareButton(
                    icon: Icons.email,
                    label: 'E-post',
                    color: Colors.blue.shade600,
                    onTap: () => _sendEmailInvitation(code, kennelName),
                  ),
                  // Del-knapp
                  _buildShareButton(
                    icon: Icons.share,
                    label: 'Del',
                    color: Colors.green.shade600,
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
            child: const Text('Ferdig'),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
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
    final subject = Uri.encodeComponent('Invitasjon til $kennelName på Breedly');
    final body = Uri.encodeComponent(
      'Hei!\n\n'
      'Du har blitt invitert til å bli med i $kennelName på Breedly-appen.\n\n'
      'Din invitasjonskode er: $code\n\n'
      'Slik blir du med:\n'
      '1. Last ned Breedly-appen hvis du ikke har den\n'
      '2. Logg inn eller opprett en konto\n'
      '3. Gå til Innstillinger → Kennel-administrasjon\n'
      '4. Trykk på "Bli med i kennel"\n'
      '5. Skriv inn koden: $code\n\n'
      'Koden er gyldig i 7 dager.\n\n'
      'Velkommen!\n'
    );
    
    final emailUri = Uri.parse('mailto:?subject=$subject&body=$body');
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kunne ikke åpne e-postklient')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil ved åpning av e-post: $e')),
        );
      }
    }
  }

  Future<void> _shareInvitation(String code, String kennelName) async {
    final message = 
      'Du har blitt invitert til $kennelName på Breedly!\n\n'
      '🐕 Invitasjonskode: $code\n\n'
      'Åpne Breedly-appen, gå til Innstillinger → Kennel-administrasjon → "Bli med i kennel" og skriv inn koden.\n\n'
      'Koden er gyldig i 7 dager.';
    
    try {
      await Share.share(
        message,
        subject: 'Invitasjon til $kennelName på Breedly',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil ved deling: $e')),
        );
      }
    }
  }
}
