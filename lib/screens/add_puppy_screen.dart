import 'package:flutter/material.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/utils/theme_colors.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/utils/logger.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class AddPuppyScreen extends StatefulWidget {
  final Litter litter;

  const AddPuppyScreen({super.key, required this.litter});

  @override
  State<AddPuppyScreen> createState() => _AddPuppyScreenState();
}

class _AddPuppyScreenState extends State<AddPuppyScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _gender = 'Male';
  String _color = '';
  DateTime _dateOfBirth = DateTime.now();
  DateTime? _birthTime;
  double? _birthWeight;
  String _birthNotes = '';
  String _status = 'Available';
  bool _vaccinated = false;
  bool _dewormed = false;
  bool _microchipped = false;
  String _notes = '';
  String _displayName = ''; // Kallenavn for å skille valper
  String? _colorCode; // Fargekode for UI-skilling
  
  // Tilgjengelige farger for valper
  static const List<Map<String, dynamic>> _puppyColors = [
    {'name': 'Rød', 'color': '#FF0000'},
    {'name': 'Blå', 'color': '#0000FF'},
    {'name': 'Grønn', 'color': '#00FF00'},
    {'name': 'Gul', 'color': '#FFFF00'},
    {'name': 'Lilla', 'color': '#800080'},
    {'name': 'Oransje', 'color': '#FFA500'},
    {'name': 'Rosa', 'color': '#FFC0CB'},
    {'name': 'Turkis', 'color': '#40E0D0'},
    {'name': 'Brun', 'color': '#8B4513'},
    {'name': 'Svart', 'color': '#000000'},
    {'name': 'Hvit', 'color': '#FFFFFF'},
    {'name': 'Grå', 'color': '#808080'},
  ];

  void _savePuppy() async {
    if (_formKey.currentState!.validate()) {
      final puppy = Puppy(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name,
        litterId: widget.litter.id,
        dateOfBirth: _dateOfBirth,
        gender: _gender,
        color: _color,
        status: _status,
        vaccinated: _vaccinated,
        dewormed: _dewormed,
        microchipped: _microchipped,
        notes: _notes.isEmpty ? null : _notes,
        birthWeight: _birthWeight,
        birthTime: _birthTime,
        birthNotes: _birthNotes.isEmpty ? null : _birthNotes,
        displayName: _displayName.isEmpty ? null : _displayName,
        colorCode: _colorCode,
      );

      final box = Hive.box<Puppy>('puppies');
      await box.put(puppy.id, puppy);

      // Save to Firebase if user is authenticated and online
      final authService = AuthService();
      final offlineManager = OfflineModeManager();
      
      if (authService.isAuthenticated && offlineManager.isOnline) {
        final cloudSync = CloudSyncService();
        try {
          await cloudSync.savePuppy(
            userId: authService.currentUserId!,
            litterId: widget.litter.id,
            puppyId: puppy.id,
            puppyData: puppy.toJson(),
          );
        } catch (e) {
          AppLogger.debug('Feil ved lagring av valp til Firebase: $e');
        }
      }

      // Update litter counts
      if (_gender == 'Male') {
        widget.litter.actualMalesCount++;
      } else {
        widget.litter.actualFemalesCount++;
      }
      widget.litter.save();

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.puppyAdded)),
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: l10n.addPuppy,
        context: context,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
            // Name
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.puppyNameLabel,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                  ),
                  onChanged: (value) => _name = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.pleaseEnterName : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Display Name (kallenavn) og Fargekode for å skille valper
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.label_outline, color: Theme.of(context).primaryColor),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n.puppyIdentification,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: l10n.nicknameDisplayName,
                        hintText: l10n.nicknameHint,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.mdAll,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.mdAll,
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                      ),
                      onChanged: (value) => _displayName = value,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.colorCodeBandMark, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _puppyColors.map((colorItem) {
                        final isSelected = _colorCode == colorItem['color'];
                        final color = Color(int.parse(colorItem['color'].replaceFirst('#', '0xFF')));
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _colorCode = isSelected ? null : colorItem['color'];
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Theme.of(context).primaryColor : context.colors.border,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ] : null,
                            ),
                            child: isSelected 
                                ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_colorCode != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${l10n.selected}: ${_puppyColors.firstWhere((c) => c['color'] == _colorCode, orElse: () => {'name': l10n.unknown})['name']}',
                        style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Gender
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  items: [
                    DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
                    DropdownMenuItem(value: 'Female', child: Text(l10n.female)),
                  ],
                  onChanged: (value) {
                    setState(() => _gender = value ?? 'Male');
                  },
                  decoration: InputDecoration(
                    labelText: l10n.gender,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Color
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.color,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                  ),
                  onChanged: (value) => _color = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.pleaseEnterColor : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Date of Birth
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateOfBirth,
                      firstDate: widget.litter.dateOfBirth,
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _dateOfBirth = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.border),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${l10n.dateOfBirth}: ${DateFormat('dd.MM.yyyy').format(_dateOfBirth)}'),
                        Icon(Icons.calendar_today, size: 20, color: Theme.of(context).primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Birth Weight
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.birthWeightGrams,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _birthWeight = double.tryParse(value),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Birth Time
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _birthTime = DateTime(_dateOfBirth.year, _dateOfBirth.month,
                            _dateOfBirth.day, time.hour, time.minute);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.border),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _birthTime != null
                              ? '${l10n.birthTimeLabel}: ${DateFormat('HH:mm').format(_birthTime!)}'
                              : l10n.birthTimeOptional,
                        ),
                        Icon(Icons.access_time, size: 20, color: Theme.of(context).primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Birth Notes
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.birthNotes,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                  ),
                  maxLines: 2,
                  onChanged: (value) => _birthNotes = value,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Status
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  items: [
                    DropdownMenuItem(value: 'Available', child: Text(l10n.available)),
                    DropdownMenuItem(value: 'Sold', child: Text(l10n.sold)),
                    DropdownMenuItem(value: 'Reserved', child: Text(l10n.reserved)),
                  ],
                  onChanged: (value) {
                    setState(() => _status = value ?? 'Available');
                  },
                  decoration: InputDecoration(
                    labelText: l10n.status,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Checkboxes
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text(l10n.healthAndDocumentation, 
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.vaccinated, style: const TextStyle(fontSize: 13)),
                      value: _vaccinated,
                      onChanged: (value) => setState(() => _vaccinated = value ?? false),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.dewormed, style: const TextStyle(fontSize: 13)),
                      value: _dewormed,
                      onChanged: (value) => setState(() => _dewormed = value ?? false),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.microchipped, style: const TextStyle(fontSize: 13)),
                      value: _microchipped,
                      onChanged: (value) =>
                          setState(() => _microchipped = value ?? false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Notes
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.notes,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                  ),
                  maxLines: 2,
                  onChanged: (value) => _notes = value,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save Button
            ElevatedButton(
              onPressed: _savePuppy,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.savePuppy),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
