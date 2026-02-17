import 'package:flutter/material.dart';
import 'package:breedly/services/excel_export_service.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

/// Screen for exporting data to CSV/Excel
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _exportService = ExcelExportService();
  bool _isExporting = false;
  String? _currentExport;

  Future<void> _exportDogs() async {
    final l10n = AppLocalizations.of(context)!;
    await _doExport(l10n.dogs, () => _exportService.exportDogs());
  }

  Future<void> _exportLitters() async {
    final l10n = AppLocalizations.of(context)!;
    await _doExport(l10n.litters, () => _exportService.exportLitters());
  }

  Future<void> _exportPuppies() async {
    final l10n = AppLocalizations.of(context)!;
    await _doExport(l10n.puppies, () => _exportService.exportPuppies());
  }

  Future<void> _exportExpenses() async {
    final l10n = AppLocalizations.of(context)!;
    await _doExport(l10n.expenses, () => _exportService.exportExpenses());
  }

  Future<void> _exportIncome() async {
    final l10n = AppLocalizations.of(context)!;
    await _doExport(l10n.income, () => _exportService.exportIncome());
  }

  Future<void> _exportFinancialSummary() async {
    final l10n = AppLocalizations.of(context)!;
    await _doExport(l10n.financialSummary, () => _exportService.exportFinancialSummary());
  }

  Future<void> _exportLitterStats() async {
    final l10n = AppLocalizations.of(context)!;
    await _doExport(l10n.litterStatistics, () => _exportService.exportLitterStatistics());
  }

  Future<void> _exportAll() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isExporting = true;
      _currentExport = l10n.allData;
    });

    try {
      await _exportService.exportAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportCompleted),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Export error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportError(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _currentExport = null;
        });
      }
    }
  }

  Future<void> _doExport(String name, Future<dynamic> Function() exportFunc) async {
    setState(() {
      _isExporting = true;
      _currentExport = name;
    });

    try {
      final file = await exportFunc();
      await _exportService.shareFile(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.itemExported(name)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Export error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportError(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _currentExport = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exportData),
      ),
      body: _isExporting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.exportingItem(_currentExport ?? '')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Info card
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.aboutExport,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.exportDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Export all button
                FilledButton.icon(
                  onPressed: _exportAll,
                  icon: const Icon(Icons.file_download),
                  label: Text(l10n.exportAll),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        l10n.orExportIndividually,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Individual exports
                _ExportTile(
                  icon: Icons.pets,
                  title: l10n.dogs,
                  subtitle: l10n.exportDogsDesc,
                  onTap: _exportDogs,
                ),
                _ExportTile(
                  icon: Icons.pets,
                  title: l10n.litters,
                  subtitle: l10n.exportLittersDesc,
                  onTap: _exportLitters,
                ),
                _ExportTile(
                  icon: Icons.favorite,
                  title: l10n.puppies,
                  subtitle: l10n.exportPuppiesDesc,
                  onTap: _exportPuppies,
                ),
                const Divider(height: AppSpacing.xxxl),
                _ExportTile(
                  icon: Icons.trending_down,
                  title: l10n.expenses,
                  subtitle: l10n.exportExpensesDesc,
                  onTap: _exportExpenses,
                ),
                _ExportTile(
                  icon: Icons.trending_up,
                  title: l10n.income,
                  subtitle: l10n.exportIncomeDesc,
                  onTap: _exportIncome,
                ),
                _ExportTile(
                  icon: Icons.summarize,
                  title: l10n.financialSummary,
                  subtitle: l10n.exportFinancialSummaryDesc,
                  onTap: _exportFinancialSummary,
                ),
                const Divider(height: AppSpacing.xxxl),
                _ExportTile(
                  icon: Icons.analytics,
                  title: l10n.litterStatistics,
                  subtitle: l10n.exportLitterStatsDesc,
                  onTap: _exportLitterStats,
                ),
              ],
            ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            icon,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.file_download_outlined),
        onTap: onTap,
      ),
    );
  }
}
