import 'package:flutter/material.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/services/offline_mode_manager.dart';
import 'package:breedly/utils/logger.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valp lagt til')),
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: 'Legg til valp',
        context: context,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
            // Name
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Navn på valpen',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) => _name = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Vennligst skriv inn navn' : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Display Name (kallenavn) og Fargekode for å skille valper
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.label_outline, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Identifikasjon (for å skille valper)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Kallenavn / Visningsnavn',
                        hintText: 'f.eks. "Blå bånd", "Lillegutt"',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) => _displayName = value,
                    ),
                    const SizedBox(height: 16),
                    const Text('Fargekode (bånd/merke)', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
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
                      const SizedBox(height: 8),
                      Text(
                        'Valgt: ${_puppyColors.firstWhere((c) => c['color'] == _colorCode, orElse: () => {'name': 'Ukjent'})['name']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gender
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Hann')),
                    DropdownMenuItem(value: 'Female', child: Text('Tispe')),
                  ],
                  onChanged: (value) {
                    setState(() => _gender = value ?? 'Male');
                  },
                  decoration: InputDecoration(
                    labelText: 'Kjønn',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Farge',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) => _color = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Vennligst skriv inn farge' : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date of Birth
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Fødselsdato: ${DateFormat('dd.MM.yyyy').format(_dateOfBirth)}'),
                        Icon(Icons.calendar_today, size: 20, color: Theme.of(context).primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Birth Weight
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Fødselsvekt (gram)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _birthWeight = double.tryParse(value),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Birth Time
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _birthTime != null
                              ? 'Fødselsidspunkt: ${DateFormat('HH:mm').format(_birthTime!)}'
                              : 'Fødselsidspunkt (valgfritt)',
                        ),
                        Icon(Icons.access_time, size: 20, color: Theme.of(context).primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Birth Notes
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Merknader fra fødsel (f.eks. drahjelp)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  maxLines: 2,
                  onChanged: (value) => _birthNotes = value,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  items: const [
                    DropdownMenuItem(value: 'Available', child: Text('Ledig')),
                    DropdownMenuItem(value: 'Sold', child: Text('Solgt')),
                    DropdownMenuItem(value: 'Reserved', child: Text('Reservert')),
                  ],
                  onChanged: (value) {
                    setState(() => _status = value ?? 'Available');
                  },
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Checkboxes
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Helse & dokumentasjon', 
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vaksinert', style: TextStyle(fontSize: 13)),
                      value: _vaccinated,
                      onChanged: (value) => setState(() => _vaccinated = value ?? false),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Avmasket', style: TextStyle(fontSize: 13)),
                      value: _dewormed,
                      onChanged: (value) => setState(() => _dewormed = value ?? false),
                    ),
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Microchippet', style: TextStyle(fontSize: 13)),
                      value: _microchipped,
                      onChanged: (value) =>
                          setState(() => _microchipped = value ?? false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Notater',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  maxLines: 2,
                  onChanged: (value) => _notes = value,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: _savePuppy,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Lagre valp'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
