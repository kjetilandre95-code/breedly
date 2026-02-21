import 'package:flutter/material.dart';
import 'package:breedly/utils/inbreeding_calculator.dart';
import 'package:breedly/utils/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';

/// Widget for displaying and calculating inbreeding coefficient
class InbreedingWidget extends StatefulWidget {
  final String? motherId;
  final String? fatherId;
  final ValueChanged<double>? onCOICalculated;

  const InbreedingWidget({
    super.key,
    this.motherId,
    this.fatherId,
    this.onCOICalculated,
  });

  @override
  State<InbreedingWidget> createState() => _InbreedingWidgetState();
}

class _InbreedingWidgetState extends State<InbreedingWidget> {
  final InbreedingCalculator _calculator = InbreedingCalculator();
  double? _coi;
  InbreedingRisk? _risk;
  List<CommonAncestor> _commonAncestors = [];
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _calculateCOI();
  }

  @override
  void didUpdateWidget(InbreedingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motherId != widget.motherId ||
        oldWidget.fatherId != widget.fatherId) {
      _calculateCOI();
    }
  }

  void _calculateCOI() {
    if (widget.motherId == null || widget.fatherId == null) {
      setState(() {
        _coi = null;
        _risk = null;
        _commonAncestors = [];
      });
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    // Calculate COI
    final coi = _calculator.calculateCOI(
      motherId: widget.motherId!,
      fatherId: widget.fatherId!,
      generations: 5,
    );

    final risk = _calculator.assessRisk(coi);
    final commonAncestors = _calculator.findCommonAncestors(
      motherId: widget.motherId!,
      fatherId: widget.fatherId!,
      generations: 5,
    );

    setState(() {
      _coi = coi;
      _risk = risk;
      _commonAncestors = commonAncestors;
      _isCalculating = false;
    });

    widget.onCOICalculated?.call(coi);
  }

  Color _getRiskColor() {
    if (_risk == null) return context.colors.textDisabled;
    
    switch (_risk!) {
      case InbreedingRisk.veryLow:
        return AppColors.success;
      case InbreedingRisk.low:
        return Colors.lightGreen;
      case InbreedingRisk.moderate:
        return AppColors.warning;
      case InbreedingRisk.high:
        return AppColors.warning;
      case InbreedingRisk.veryHigh:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.motherId == null || widget.fatherId == null) {
      return _buildPlaceholder();
    }

    if (_isCalculating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _buildResult(context);
  }

  Widget _buildPlaceholder() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.neutral100,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, color: context.colors.textDisabled, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.selectBothForInbreeding,
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final percentage = (_coi ?? 0) * 100;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _getRiskColor().withValues(alpha: ThemeOpacity.low(context)),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: _getRiskColor().withValues(alpha: ThemeOpacity.high(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _getRiskColor().withValues(alpha: ThemeOpacity.medium(context)),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  _getIcon(),
                  color: _getRiskColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.inbreedingCoefficientCoi,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textCaption,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getRiskColor(),
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
                  color: _getRiskColor(),
                  borderRadius: AppRadius.xlAll,
                ),
                child: Text(
                  _risk?.label ?? l10n.unknown,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _risk?.description ?? '',
            style: TextStyle(
              fontSize: 13,
              color: context.colors.textTertiary,
            ),
          ),
          if (_commonAncestors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 18, color: context.colors.textCaption),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.commonAncestors(_commonAncestors.length),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._commonAncestors.take(3).map((ancestor) => _buildAncestorTile(ancestor)),
            if (_commonAncestors.length > 3)
              TextButton(
                onPressed: _showAllAncestors,
                child: Text(l10n.seeAllAncestors(_commonAncestors.length)),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _buildInfoButton(),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (_risk) {
      case InbreedingRisk.veryLow:
        return Icons.check_circle;
      case InbreedingRisk.low:
        return Icons.thumb_up;
      case InbreedingRisk.moderate:
        return Icons.info;
      case InbreedingRisk.high:
        return Icons.warning;
      case InbreedingRisk.veryHigh:
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }

  Widget _buildAncestorTile(CommonAncestor ancestor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            ancestor.dog.gender == 'Female' ? Icons.female : Icons.male,
            size: 16,
            color: ancestor.dog.gender == 'Female' ? AppColors.female : AppColors.male,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ancestor.dog.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  ancestor.relationship,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton() {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: _showInfoDialog,
      icon: const Icon(Icons.info_outline, size: 18),
      label: Text(l10n.whatDoesThisMean),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 30),
      ),
    );
  }

  void _showInfoDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aboutInbreedingCoefficient),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.inbreedingDescription,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.recommendedLevels,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildLevelRow('< 3%', l10n.veryLow, AppColors.success),
              _buildLevelRow('3-6%', l10n.low, Colors.lightGreen),
              _buildLevelRow('6-12%', l10n.moderate, AppColors.warning),
              _buildLevelRow('12-25%', l10n.high, AppColors.warning),
              _buildLevelRow('> 25%', l10n.veryHigh, AppColors.error),
              const SizedBox(height: 16),
              Text(
                l10n.highInbreedingConsequences,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${l10n.reducedImmuneSystem}'),
              Text('• ${l10n.reducedFertility}'),
              Text('• ${l10n.increasedRiskOfDisease}'),
              Text('• ${l10n.shorterLifespan}'),
              const SizedBox(height: 16),
              Text(
                l10n.tipsCoi,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${l10n.tipRegisterAncestors}'),
              Text('• ${l10n.tipSystemRecognizes}'),
              Text('• ${l10n.tipCoiGenerations}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRow(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.xsAll,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$range: $label'),
        ],
      ),
    );
  }

  void _showAllAncestors() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.account_tree_outlined),
                  const SizedBox(width: 8),
                  Text(
                    l10n.commonAncestors(_commonAncestors.length),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _commonAncestors.length,
                itemBuilder: (context, index) {
                  final ancestor = _commonAncestors[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ancestor.dog.gender == 'Female'
                          ? AppColors.female.withValues(alpha: 0.15)
                          : AppColors.male.withValues(alpha: 0.15),
                      child: Icon(
                        ancestor.dog.gender == 'Female' ? Icons.female : Icons.male,
                        color: ancestor.dog.gender == 'Female'
                            ? AppColors.female
                            : AppColors.male,
                      ),
                    ),
                    title: Text(ancestor.dog.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ancestor.relationship),
                        Text(
                          l10n.generationsFromParents(ancestor.generationsFromMother, ancestor.generationsFromFather),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen for comparing multiple mating options
class InbreedingComparisonScreen extends StatefulWidget {
  final String? preselectedFemaleId;

  const InbreedingComparisonScreen({
    super.key,
    this.preselectedFemaleId,
  });

  @override
  State<InbreedingComparisonScreen> createState() =>
      _InbreedingComparisonScreenState();
}

class _InbreedingComparisonScreenState
    extends State<InbreedingComparisonScreen> {
  String? _selectedFemaleId;
  final InbreedingCalculator _calculator = InbreedingCalculator();
  List<Dog> _females = [];
  List<Dog> _males = [];
  List<_MatingOption> _options = [];

  @override
  void initState() {
    super.initState();
    _loadDogs();
    _selectedFemaleId = widget.preselectedFemaleId;
  }

  void _loadDogs() {
    try {
      final box = Hive.box<Dog>('dogs');
      _females = box.values.where((d) => d.gender == 'Female').toList();
      _males = box.values.where((d) => d.gender == 'Male').toList();
      setState(() {});
      _calculateOptions();
    } catch (e) {
      debugPrint('Error loading dogs: $e');
    }
  }

  void _calculateOptions() {
    if (_selectedFemaleId == null) {
      setState(() {
        _options = [];
      });
      return;
    }

    final options = <_MatingOption>[];

    for (final male in _males) {
      final coi = _calculator.calculateCOI(
        motherId: _selectedFemaleId!,
        fatherId: male.id,
        generations: 5,
      );
      final risk = _calculator.assessRisk(coi);

      options.add(_MatingOption(
        male: male,
        coi: coi,
        risk: risk,
      ));
    }

    // Sort by COI (lowest first)
    options.sort((a, b) => a.coi.compareTo(b.coi));

    setState(() {
      _options = options;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.compareMatingOptions),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedFemaleId,
              decoration: InputDecoration(
                labelText: l10n.selectFemale,
                border: const OutlineInputBorder(),
              ),
              items: _females
                  .map((dog) => DropdownMenuItem(
                        value: dog.id,
                        child: Text(
                          dog.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFemaleId = value;
                });
                _calculateOptions();
              },
            ),
          ),
          if (_options.isEmpty && _selectedFemaleId != null)
            Expanded(
              child: Center(
                child: Text(l10n.noMalesRegistered),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final option = _options[index];
                  return _buildOptionCard(context, option, index + 1);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, _MatingOption option, int rank) {
    final percentage = option.coi * 100;
    final color = _getRiskColor(option.risk);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: ThemeOpacity.medium(context)),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          option.male.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          option.male.breed,
          style: TextStyle(color: context.colors.textMuted),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${percentage.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              option.risk.label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(InbreedingRisk risk) {
    switch (risk) {
      case InbreedingRisk.veryLow:
        return AppColors.success;
      case InbreedingRisk.low:
        return Colors.lightGreen;
      case InbreedingRisk.moderate:
        return AppColors.warning;
      case InbreedingRisk.high:
        return AppColors.warning;
      case InbreedingRisk.veryHigh:
        return AppColors.error;
    }
  }
}

class _MatingOption {
  final Dog male;
  final double coi;
  final InbreedingRisk risk;

  _MatingOption({
    required this.male,
    required this.coi,
    required this.risk,
  });
}
