import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/buyer.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class WaitlistScreen extends StatefulWidget {
  final String? litterId; // Optional: filter by litter

  const WaitlistScreen({super.key, this.litterId});

  @override
  State<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends State<WaitlistScreen> {
  final _dateFormat = DateFormat('dd.MM.yyyy');
  String? _selectedLitterId;

  @override
  void initState() {
    super.initState();
    _selectedLitterId = widget.litterId;
  }

  List<Buyer> _getWaitlistBuyers() {
    final buyerBox = Hive.box<Buyer>('buyers');
    var buyers = buyerBox.values.where((b) => b.isOnWaitlist).toList();

    if (_selectedLitterId != null) {
      buyers = buyers.where((b) => b.litterId == _selectedLitterId).toList();
    }

    // Sort by waitlist position
    buyers.sort(
      (a, b) =>
          (a.waitlistPosition ?? 999).compareTo(b.waitlistPosition ?? 999),
    );
    return buyers;
  }

  List<Litter> _getLitters() {
    final litterBox = Hive.box<Litter>('litters');
    return litterBox.values.toList()
      ..sort((a, b) => b.dateOfBirth.compareTo(a.dateOfBirth));
  }

  void _moveUp(Buyer buyer) {
    if (buyer.waitlistPosition == null || buyer.waitlistPosition! <= 1) return;

    final buyers = _getWaitlistBuyers();
    final currentPos = buyer.waitlistPosition!;

    // Find buyer at position above
    final aboveBuyer = buyers.firstWhere(
      (b) => b.waitlistPosition == currentPos - 1,
      orElse: () => buyer,
    );

    if (aboveBuyer != buyer) {
      aboveBuyer.waitlistPosition = currentPos;
      buyer.waitlistPosition = currentPos - 1;
      aboveBuyer.save();
      buyer.save();
      setState(() {});
    }
  }

  void _moveDown(Buyer buyer) {
    final buyers = _getWaitlistBuyers();
    if (buyer.waitlistPosition == null ||
        buyer.waitlistPosition! >= buyers.length) {
      return;
    }

    final currentPos = buyer.waitlistPosition!;

    // Find buyer at position below
    final belowBuyer = buyers.firstWhere(
      (b) => b.waitlistPosition == currentPos + 1,
      orElse: () => buyer,
    );

    if (belowBuyer != buyer) {
      belowBuyer.waitlistPosition = currentPos;
      buyer.waitlistPosition = currentPos + 1;
      belowBuyer.save();
      buyer.save();
      setState(() {});
    }
  }

  void _updateStatus(Buyer buyer, String newStatus) {
    buyer.waitlistStatus = newStatus;
    buyer.save();
    setState(() {});
  }

  void _removeFromWaitlist(Buyer buyer) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFromWaitlist),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              buyer.waitlistPosition = null;
              buyer.waitlistDate = null;
              buyer.waitlistStatus = null;
              buyer.save();
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.removedFromWaitlist)));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'contacted':
        return AppColors.info;
      case 'reserved':
        return AppColors.accent5;
      case 'purchased':
        return AppColors.success;
      case 'declined':
        return AppColors.error;
      case 'cancelled':
        return AppColors.neutral500;
      default:
        return AppColors.neutral500;
    }
  }

  String _getStatusText(String? status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'contacted':
        return l10n.contacted;
      case 'reserved':
        return l10n.reserved;
      case 'purchased':
        return l10n.purchased;
      case 'declined':
        return l10n.declined;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return l10n.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final buyers = _getWaitlistBuyers();
    final litters = _getLitters();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.waitlist),
        backgroundColor: AppColors.primary,
        foregroundColor: context.colors.surface,
      ),
      body: Column(
        children: [
          // Filter by litter
          if (litters.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedLitterId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.litters,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(l10n.all)),
                  ...litters.map(
                    (litter) => DropdownMenuItem<String?>(
                      value: litter.id,
                      child: Text(
                        '${litter.damName} x ${litter.sireName} (${_dateFormat.format(litter.dateOfBirth)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedLitterId = value);
                },
              ),
            ),

          // Info banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: ThemeOpacity.low(context)),
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.waitlistInfo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Waitlist
          Expanded(
            child: buyers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 64,
                          color: context.colors.textDisabled,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.waitlistEmpty,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: buyers.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex--;

                      // Update all positions
                      final buyerList = List<Buyer>.from(buyers);
                      final item = buyerList.removeAt(oldIndex);
                      buyerList.insert(newIndex, item);

                      for (int i = 0; i < buyerList.length; i++) {
                        buyerList[i].waitlistPosition = i + 1;
                        buyerList[i].save();
                      }

                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final buyer = buyers[index];
                      return _WaitlistCard(
                        key: ValueKey(buyer.id),
                        buyer: buyer,
                        position: index + 1,
                        isFirst: index == 0,
                        isLast: index == buyers.length - 1,
                        statusColor: _getStatusColor(buyer.waitlistStatus),
                        statusText: _getStatusText(buyer.waitlistStatus, l10n),
                        onMoveUp: () => _moveUp(buyer),
                        onMoveDown: () => _moveDown(buyer),
                        onRemove: () => _removeFromWaitlist(buyer),
                        onStatusChange: (status) =>
                            _updateStatus(buyer, status),
                        dateFormat: _dateFormat,
                        l10n: l10n,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WaitlistCard extends StatelessWidget {
  final Buyer buyer;
  final int position;
  final bool isFirst;
  final bool isLast;
  final Color statusColor;
  final String statusText;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final Function(String) onStatusChange;
  final DateFormat dateFormat;
  final AppLocalizations l10n;

  const _WaitlistCard({
    required super.key,
    required this.buyer,
    required this.position,
    required this.isFirst,
    required this.isLast,
    required this.statusColor,
    required this.statusText,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onStatusChange,
    required this.dateFormat,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Position badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.xlAll,
              ),
              alignment: Alignment.center,
              child: Text(
                '#$position',
                style: TextStyle(
                  color: context.colors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Buyer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    buyer.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (buyer.phone != null)
                    Text(
                      buyer.phone!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.colors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (buyer.waitlistDate != null)
                    Text(
                      '${l10n.waitlistDate}: ${dateFormat.format(buyer.waitlistDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.colors.textCaption,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: ThemeOpacity.high(context)),
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Preference chips
                      if (buyer.preferredGender != null)
                        _PreferenceChip(
                          icon: buyer.preferredGender == 'Male'
                              ? Icons.male
                              : Icons.female,
                          color: buyer.preferredGender == 'Male'
                              ? AppColors.male
                              : AppColors.female,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: isFirst ? null : onMoveUp,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  onPressed: isLast ? null : onMoveDown,
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),

            // Status menu
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'remove') {
                  onRemove();
                } else {
                  onStatusChange(value);
                }
              },
              itemBuilder: (context) => [
                ...WaitlistStatus.all.map(
                  (status) => PopupMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(_getStatusText(status, l10n)),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n.removeFromWaitlist,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'contacted':
        return AppColors.info;
      case 'reserved':
        return AppColors.accent5;
      case 'purchased':
        return AppColors.success;
      case 'declined':
        return AppColors.error;
      case 'cancelled':
        return AppColors.neutral500;
      default:
        return AppColors.neutral500;
    }
  }

  String _getStatusText(String? status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'contacted':
        return l10n.contacted;
      case 'reserved':
        return l10n.reserved;
      case 'purchased':
        return l10n.purchased;
      case 'declined':
        return l10n.declined;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return l10n.pending;
    }
  }
}

class _PreferenceChip extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _PreferenceChip({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: ThemeOpacity.high(context)),
        borderRadius: AppRadius.mdAll,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
