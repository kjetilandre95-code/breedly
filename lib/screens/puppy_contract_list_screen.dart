import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/purchase_contract.dart';
import 'package:breedly/models/buyer.dart';
import 'package:breedly/screens/purchase_contract_screen.dart';
import 'package:breedly/screens/reservation_contract_screen.dart';
import 'package:intl/intl.dart';
import 'package:breedly/utils/pdf_generator.dart';
import 'package:breedly/utils/notification_service.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'dart:io' show Directory, File;
import 'package:path_provider/path_provider.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class PuppyContractListScreen extends StatefulWidget {
  final Puppy puppy;

  const PuppyContractListScreen({
    super.key,
    required this.puppy,
  });

  @override
  State<PuppyContractListScreen> createState() =>
      _PuppyContractListScreenState();
}

class _PuppyContractListScreenState extends State<PuppyContractListScreen> {
  late Box<PurchaseContract> contractBox;
  late Box<Buyer> buyerBox;

  /// Get currency code based on current locale
  String _getCurrencyCode(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'sv') {
      return 'SEK'; // Swedish krona
    } else {
      return 'NOK'; // Norwegian krona
    }
  }

  /// Format price with correct currency for current language
  String _formatPrice(double price, BuildContext context) {
    final currencyCode = _getCurrencyCode(context);
    return '${price.toStringAsFixed(0)} $currencyCode';
  }

  @override
  void initState() {
    super.initState();
    contractBox = Hive.box<PurchaseContract>('purchase_contracts');
    buyerBox = Hive.box<Buyer>('buyers');
  }

  List<PurchaseContract> _getContracts() {
    return contractBox.values
        .where((c) => c.puppyId == widget.puppy.id)
        .toList();
  }

  Buyer? _getBuyer(String buyerId) {
    try {
      return buyerBox.values.firstWhere((b) => b.id == buyerId);
    } catch (e) {
      return null;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Draft':
        return AppColors.neutral500;
      case 'Active':
        return AppColors.info;
      case 'Completed':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.error;
      default:
        return AppColors.neutral500;
    }
  }

  String _getStatusLabel(String? status, AppLocalizations l10n) {
    switch (status) {
      case 'Draft':
        return l10n.statusDraft;
      case 'Active':
        return l10n.statusActive;
      case 'Completed':
        return l10n.statusCompleted;
      case 'Cancelled':
        return l10n.statusCancelled;
      default:
        return status ?? l10n.statusDraft;
    }
  }

  void _deleteContract(PurchaseContract contract) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteContract),
        content: Text(l10n.confirmDeleteContract),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              // Delete from Firebase first
              final userId = AuthService().currentUser?.uid;
              if (userId != null) {
                await CloudSyncService().deletePurchaseContract(
                  userId: userId,
                  contractId: contract.id,
                );
              }
              // Then delete from Hive
              await contract.delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.contractDeleted)),
                );
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: l10n.contracts,
        context: context,
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: contractBox.listenable(),
          builder: (context, Box<PurchaseContract> box, _) {
            final contracts = _getContracts();

            if (contracts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.info.withValues(alpha: ThemeOpacity.low(context)),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        size: 40,
                        color: AppColors.info.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.noContracts,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.createPurchaseContractForPuppy,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PurchaseContractScreen(
                              puppy: widget.puppy,
                            ),
                          ),
                        );
                        setState(() {});
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.createContract),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg, bottom: 88),
              itemCount: contracts.length,
              itemBuilder: (context, index) {
                final contract = contracts[index];
                final buyer = _getBuyer(contract.buyerId);

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (buyer != null)
                                    Text(
                                      buyer.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    l10n.contractNumberLabel(contract.contractNumber ?? '—'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(contract.status)
                                    .withValues(alpha: ThemeOpacity.high(context)),
                                border: Border.all(
                                  color: _getStatusColor(contract.status),
                                ),
                                borderRadius: AppRadius.xlAll,
                              ),
                              child: Text(
                                _getStatusLabel(contract.status, l10n),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusColor(contract.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),
                        _buildDetailRow(
                          l10n.price,
                          _formatPrice(contract.price, context),
                        ),
                        _buildDetailRow(
                          l10n.createdDate,
                          DateFormat('d. MMM yyyy', 'nb_NO')
                              .format(contract.contractDate),
                        ),
                        if (contract.purchaseDate != null)
                          _buildDetailRow(
                            l10n.purchasedDate,
                            DateFormat('d. MMM yyyy', 'nb_NO')
                                .format(contract.purchaseDate!),
                          ),
                        if (contract.paymentTerms != null)
                          _buildDetailRow(
                            l10n.paymentTerms,
                            contract.paymentTerms!,
                          ),
                        if (contract.spayNeuterRequired ||
                            contract.returnClauseIncluded)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.termsLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (contract.spayNeuterRequired)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          l10n.spayNeuterRequired,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (contract.returnClauseIncluded)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          l10n.returnClauseIncluded,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PurchaseContractScreen(
                                        puppy: widget.puppy,
                                        existingContract: contract,
                                      ),
                                    ),
                                  );
                                  setState(() {});
                                },
                                icon: const Icon(Icons.edit),
                                label: Text(l10n.edit),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _exportContractPDF(contract),
                                icon: const Icon(Icons.file_download),
                                label: const Text('PDF'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _deleteContract(contract),
                                icon: const Icon(Icons.delete),
                                label: Text(l10n.delete),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContractTypeDialog(),
        icon: const Icon(Icons.add),
        label: Text(l10n.newContract),
      ),
    );
  }

  void _showContractTypeDialog() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: Text(l10n.purchaseContract),
              subtitle: Text(l10n.fullSalesContract),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PurchaseContractScreen(
                      puppy: widget.puppy,
                    ),
                  ),
                ).then((_) => setState(() {}));
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: Text(l10n.reservationAgreement),
              subtitle: Text(l10n.reserveWithDeposit),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReservationContractScreen(
                      preselectedPuppy: widget.puppy,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportContractPDF(PurchaseContract contract) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final buyer = _getBuyer(contract.buyerId);
      if (buyer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.buyerInfoNotFound)),
        );
        return;
      }

      final pdf = await PDFGenerator.generateContractPDF(
        contract,
        widget.puppy,
        buyer,
      );

      late Directory directory;
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName = 'kontrakt_${widget.puppy.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      await NotificationService().showDownloadNotification(
        title: l10n.pdfDownloaded,
        fileName: 'kontrakt_${widget.puppy.name}.pdf',
        filePath: file.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pdfSavedAt(file.path)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportErrorGeneric(e.toString()))),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.colors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
