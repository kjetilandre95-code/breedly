import 'package:flutter/material.dart';
import 'package:breedly/services/excel_export_service.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/utils/app_theme.dart';

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
    await _doExport('hunder', () => _exportService.exportDogs());
  }

  Future<void> _exportLitters() async {
    await _doExport('kull', () => _exportService.exportLitters());
  }

  Future<void> _exportPuppies() async {
    await _doExport('valper', () => _exportService.exportPuppies());
  }

  Future<void> _exportExpenses() async {
    await _doExport('utgifter', () => _exportService.exportExpenses());
  }

  Future<void> _exportIncome() async {
    await _doExport('inntekter', () => _exportService.exportIncome());
  }

  Future<void> _exportFinancialSummary() async {
    await _doExport('økonomisammendrag', () => _exportService.exportFinancialSummary());
  }

  Future<void> _exportLitterStats() async {
    await _doExport('kullstatistikk', () => _exportService.exportLitterStatistics());
  }

  Future<void> _exportAll() async {
    setState(() {
      _isExporting = true;
      _currentExport = 'alle data';
    });

    try {
      await _exportService.exportAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eksport fullført!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Export error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feil ved eksport: $e'),
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
            content: Text('$name eksportert!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Export error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feil ved eksport: $e'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eksporter data'),
      ),
      body: _isExporting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Eksporterer $_currentExport...'),
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
                              'Om eksport',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Data eksporteres som CSV-filer som kan åpnes i Excel, Google Sheets eller andre regneark-programmer. Filene bruker UTF-8 med BOM for å støtte norske tegn.',
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
                  label: const Text('Eksporter alt'),
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
                        'Eller eksporter enkeltvis',
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
                  title: 'Hunder',
                  subtitle: 'Alle registrerte hunder med stamtavle-info',
                  onTap: _exportDogs,
                ),
                _ExportTile(
                  icon: Icons.pets,
                  title: 'Kull',
                  subtitle: 'Alle kull med foreldre og valpestatus',
                  onTap: _exportLitters,
                ),
                _ExportTile(
                  icon: Icons.favorite,
                  title: 'Valper',
                  subtitle: 'Alle valper med detaljer og salgsstatus',
                  onTap: _exportPuppies,
                ),
                const Divider(height: AppSpacing.xxxl),
                _ExportTile(
                  icon: Icons.trending_down,
                  title: 'Utgifter',
                  subtitle: 'Alle utgifter sortert etter dato',
                  onTap: _exportExpenses,
                ),
                _ExportTile(
                  icon: Icons.trending_up,
                  title: 'Inntekter',
                  subtitle: 'Alle inntekter sortert etter dato',
                  onTap: _exportIncome,
                ),
                _ExportTile(
                  icon: Icons.summarize,
                  title: 'Økonomisammendrag',
                  subtitle: 'Årlig oversikt over resultat',
                  onTap: _exportFinancialSummary,
                ),
                const Divider(height: AppSpacing.xxxl),
                _ExportTile(
                  icon: Icons.analytics,
                  title: 'Kullstatistikk',
                  subtitle: 'Statistikk per rase',
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
