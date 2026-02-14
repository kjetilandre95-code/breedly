import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/temperature_record.dart';
import 'package:breedly/utils/app_bar_builder.dart';
import 'package:breedly/utils/page_info_helper.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/services/auth_service.dart';
import 'package:breedly/services/cloud_sync_service.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';

class TemperatureTrackingScreen extends StatefulWidget {
  final Litter litter;

  const TemperatureTrackingScreen({super.key, required this.litter});

  @override
  State<TemperatureTrackingScreen> createState() =>
      _TemperatureTrackingScreenState();
}

class _TemperatureTrackingScreenState extends State<TemperatureTrackingScreen> {
  final _temperatureController = TextEditingController();
  final _notesController = TextEditingController();
  final _temperatureFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _temperatureController.dispose();
    _notesController.dispose();
    _temperatureFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _addTemperatureRecord() async {
    final l10n = AppLocalizations.of(context)!;
    if (_temperatureController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterTemperature)),
      );
      return;
    }

    try {
      final temperature = double.parse(_temperatureController.text);
      final record = TemperatureRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        litterId: widget.litter.id,
        dateTime: _selectedDateTime,
        temperature: temperature,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final box = Hive.box<TemperatureRecord>('temperature_records');
      await box.put(record.id, record);

      // Save to Firebase
      final userId = AuthService().currentUser?.uid;
      if (userId != null) {
        await CloudSyncService().saveTemperatureRecord(
          userId: userId,
          litterId: record.litterId,
          recordId: record.id,
          recordData: record.toJson(),
        );
      }

      _temperatureController.clear();
      _notesController.clear();
      _selectedDateTime = DateTime.now();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.temperatureRecorded)),
        );

        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invalidTemperatureValue)),
        );
      }
    }
  }

  List<TemperatureRecord> _getTemperatureRecords() {
    final box = Hive.box<TemperatureRecord>('temperature_records');
    final records = box.values
        .where((record) => record.litterId == widget.litter.id)
        .toList();
    records.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return records;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBarBuilder.buildAppBar(
        title: l10n.temperatureTracking,
        context: context,
        actions: [
          PageInfoHelper.buildInfoButton(
            context,
            title: PageInfoContent.temperatureTracking.title,
            description: PageInfoContent.temperatureTracking.description,
            features: PageInfoContent.temperatureTracking.features,
            tip: PageInfoContent.temperatureTracking.tip,
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box<TemperatureRecord>('temperature_records')
              .listenable(),
          builder: (context, Box<TemperatureRecord> box, _) {
            final records = _getTemperatureRecords();

            return ListView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
              children: [
              // Mating info
              if (widget.litter.damMatingDate != null)
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
                        Text(
                          l10n.planningInformation,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${l10n.matingDate}:'),
                            Text(
                              DateFormat('dd.MM.yyyy')
                                  .format(widget.litter.damMatingDate!),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (widget.litter.estimatedDueDate != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${l10n.estimatedDueDate}:'),
                              Text(
                                DateFormat('dd.MM.yyyy').format(
                                    widget.litter.estimatedDueDate!),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        // Vis bare "Dager til valping" hvis kullet ikke er født ennå
                        if (widget.litter.estimatedDueDate != null && 
                            widget.litter.dateOfBirth.isAfter(DateTime.now())) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.daysUntilWhelping),
                              Text(
                                '${widget.litter.estimatedDueDate!.difference(DateTime.now()).inDays}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Temperature graph
              if (records.isNotEmpty)
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
                        Text(
                          l10n.temperatureHistory,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: records.isEmpty
                              ? Center(
                                  child: Text(
                                    l10n.noDataToShowGraph,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: records.length,
                                  itemBuilder: (context, index) {
                                    final record = records[index];
                                    final maxTemp = records
                                        .map((r) => r.temperature)
                                        .reduce((a, b) => a > b ? a : b);
                                    final minTemp = records
                                        .map((r) => r.temperature)
                                        .reduce((a, b) => a < b ? a : b);
                                    final range = maxTemp - minTemp;
                                    final normalized = range == 0
                                      ? 1.0
                                      : (record.temperature - minTemp) /
                                        range;

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Text(
                                            '${record.temperature}°C',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Container(
                                            width: 20,
                                            height: (normalized * 150)
                                                .clamp(5, 150)
                                                .toDouble(),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          Text(
                                            record.dateTime.day.toString(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Add temperature form
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
                      Text(
                        l10n.addTemperatureReading,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(l10n.dateAndTime),
                        subtitle: Text(DateFormat('dd.MM.yyyy HH:mm')
                            .format(_selectedDateTime)),
                        onTap: () async {
                          if (!mounted) return;
                          final ctx = context;
                          
                          final pickedDate = await showDatePicker(
                            context: ctx,
                            initialDate: _selectedDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          
                          if (pickedDate == null || !mounted) return;
                          
                          final pickedTime = await showTimePicker(
                            // ignore: use_build_context_synchronously
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(
                                _selectedDateTime),
                          );
                          
                          if (pickedTime == null || !mounted) return;
                          
                          setState(() {
                            _selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _temperatureController,
                        focusNode: _temperatureFocusNode,
                        decoration: InputDecoration(
                          labelText: l10n.temperatureCelsius,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _notesFocusNode.requestFocus(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        focusNode: _notesFocusNode,
                        decoration: InputDecoration(
                          labelText: l10n.notesOptional,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _addTemperatureRecord(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addTemperatureRecord,
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addMeasurement),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Temperature list
              if (records.isEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        l10n.noTemperatureReadings,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                )
              else
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
                        Text(
                          l10n.measurementsOverview,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...records.map((record) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor
                                    .withValues(alpha: ThemeOpacity.medium(context)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${record.temperature}°C',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd.MM.yyyy HH:mm')
                                            .format(record.dateTime),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (record.notes != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            record.notes!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () async {
                                      // Delete from Firebase first
                                      final userId = AuthService().currentUser?.uid;
                                      if (userId != null) {
                                        await CloudSyncService().deleteTemperatureRecord(
                                          userId: userId,
                                          litterId: record.litterId,
                                          recordId: record.id,
                                        );
                                      }
                                      // Then delete from Hive
                                      await record.delete();
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
