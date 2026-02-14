import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:breedly/utils/constants.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/treatment_plan.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/utils/app_theme.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Calendar event types
enum CalendarEventType {
  heatCycle, // Løpetid
  expectedHeat, // Forventet løpetid
  expectedBirth, // Forventet fødsel
  delivery, // Leveringsdato
  treatment, // Behandling (vaksinering, ormekur)
  birthday, // Hundens bursdag
}

/// Calendar event model
class CalendarEvent {
  final String id;
  final String title;
  final String? subtitle;
  final DateTime date;
  final CalendarEventType type;
  final Color color;
  final String? dogId;
  final String? litterId;

  CalendarEvent({
    required this.id,
    required this.title,
    this.subtitle,
    required this.date,
    required this.type,
    required this.color,
    this.dogId,
    this.litterId,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _dateFormat = DateFormat('dd.MM.yyyy');

  // Event filter
  Set<CalendarEventType> _enabledEventTypes = CalendarEventType.values.toSet();

  List<CalendarEvent> _getAllEvents() {
    final events = <CalendarEvent>[];

    final dogBox = Hive.box<Dog>('dogs');
    final litterBox = Hive.box<Litter>('litters');

    // Heat cycles from Dog model (heatCycles is List<DateTime>)
    for (final dog in dogBox.values) {
      if (dog.gender == 'Female' && dog.heatCycles.isNotEmpty) {
        for (int i = 0; i < dog.heatCycles.length; i++) {
          final cycleDate = dog.heatCycles[i];

          // Actual heat cycle
          events.add(
            CalendarEvent(
              id: 'heat_${dog.id}_$i',
              title: '${dog.name} - Løpetid',
              date: cycleDate,
              type: CalendarEventType.heatCycle,
              color: Colors.pink,
              dogId: dog.id,
            ),
          );
        }

        // Expected next heat (approximately 6 months after last cycle)
        final lastCycle = dog.heatCycles.reduce((a, b) => a.isAfter(b) ? a : b);
        final expectedHeat = lastCycle.add(const Duration(days: 180));
        if (expectedHeat.isAfter(DateTime.now())) {
          events.add(
            CalendarEvent(
              id: 'expected_heat_${dog.id}',
              title: '${dog.name} - Forventet løpetid',
              date: expectedHeat,
              type: CalendarEventType.expectedHeat,
              color: Colors.pink.shade200,
              dogId: dog.id,
            ),
          );
        }
      }
    }

    // Births and deliveries from litters
    for (final litter in litterBox.values) {
      // Actual birth date
      events.add(
        CalendarEvent(
          id: 'birth_${litter.id}',
          title: '${litter.damName} fødte',
          subtitle: '${litter.numberOfPuppies} valper',
          date: litter.dateOfBirth,
          type: CalendarEventType.birthday,
          color: Colors.green,
          litterId: litter.id,
        ),
      );

      // Delivery date (8 weeks after birth)
      final deliveryDate = litter.dateOfBirth.add(const Duration(days: 56));
      events.add(
        CalendarEvent(
          id: 'delivery_${litter.id}',
          title: 'Levering: ${litter.damName} kull',
          subtitle: '8 uker gammel',
          date: deliveryDate,
          type: CalendarEventType.delivery,
          color: Colors.orange,
          litterId: litter.id,
        ),
      );
    }

    // Treatments from TreatmentPlan (for puppies)
    try {
      final treatmentPlanBox = Hive.box<TreatmentPlan>('treatment_plans');
      final puppyBox = Hive.box<Puppy>('puppies');

      for (final plan in treatmentPlanBox.values) {
        final puppy = puppyBox.values.firstWhere(
          (p) => p.id == plan.puppyId,
          orElse: () => Puppy(
            id: '',
            name: 'Ukjent',
            gender: '',
            color: '',
            dateOfBirth: DateTime.now(),
            litterId: '',
          ),
        );

        if (puppy.id.isNotEmpty) {
          // Add vaccination dates
          if (plan.vaccineDate1 != null && !plan.vaccineDone1) {
            events.add(
              CalendarEvent(
                id: 'vaccine1_${plan.id}',
                title: '${puppy.name} - 1. vaksinering',
                date: plan.vaccineDate1!,
                type: CalendarEventType.treatment,
                color: Colors.blue,
              ),
            );
          }
          if (plan.vaccineDate2 != null && !plan.vaccineDone2) {
            events.add(
              CalendarEvent(
                id: 'vaccine2_${plan.id}',
                title: '${puppy.name} - 2. vaksinering',
                date: plan.vaccineDate2!,
                type: CalendarEventType.treatment,
                color: Colors.blue,
              ),
            );
          }

          // Add wormer dates
          if (plan.wormerDate1 != null && !plan.wormerDone1) {
            events.add(
              CalendarEvent(
                id: 'wormer1_${plan.id}',
                title: '${puppy.name} - 1. ormekur',
                date: plan.wormerDate1!,
                type: CalendarEventType.treatment,
                color: Colors.teal,
              ),
            );
          }
          if (plan.wormerDate2 != null && !plan.wormerDone2) {
            events.add(
              CalendarEvent(
                id: 'wormer2_${plan.id}',
                title: '${puppy.name} - 2. ormekur',
                date: plan.wormerDate2!,
                type: CalendarEventType.treatment,
                color: Colors.teal,
              ),
            );
          }

          // Add microchip date
          if (plan.microchipDate != null && !plan.microchipDone) {
            events.add(
              CalendarEvent(
                id: 'microchip_${plan.id}',
                title: '${puppy.name} - ID-merking',
                date: plan.microchipDate!,
                type: CalendarEventType.treatment,
                color: Colors.indigo,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Treatment plan box might not exist
    }

    // Dog birthdays
    for (final dog in dogBox.values) {
      // Get this year's birthday
      final now = DateTime.now();
      var birthday = DateTime(
        now.year,
        dog.dateOfBirth.month,
        dog.dateOfBirth.day,
      );

      // If birthday has passed this year, show next year's
      if (birthday.isBefore(now)) {
        birthday = DateTime(
          now.year + 1,
          dog.dateOfBirth.month,
          dog.dateOfBirth.day,
        );
      }

      final age = birthday.year - dog.dateOfBirth.year;
      events.add(
        CalendarEvent(
          id: 'birthday_${dog.id}_$age',
          title: '${dog.name} fyller $age år',
          date: birthday,
          type: CalendarEventType.birthday,
          color: Colors.amber,
          dogId: dog.id,
        ),
      );
    }

    return events;
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final allEvents = _getAllEvents();
    return allEvents.where((event) {
      if (!_enabledEventTypes.contains(event.type)) return false;
      return isSameDay(event.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final selectedEvents = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.calendar,
          style: AppTypography.headlineLarge.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.neutral900,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(color: Colors.transparent),
              cellMargin: const EdgeInsets.all(4),
              outsideDaysVisible: false,
            ),
            rowHeight: 48,
            daysOfWeekHeight: 20,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(3).map((event) {
                    return Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: event.color,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: TextStyle(color: AppColors.primary),
            ),
          ),

          const Divider(height: 1),

          // Event list
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _selectedDay != null
                              ? l10n.noUpcomingEvents
                              : l10n.noUpcomingEvents,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      return _EventCard(event: event, dateFormat: _dateFormat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.filter),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: CalendarEventType.values.map((type) {
              return CheckboxListTile(
                title: Text(_getEventTypeName(type, l10n)),
                value: _enabledEventTypes.contains(type),
                activeColor: _getEventTypeColor(type),
                onChanged: (value) {
                  setDialogState(() {
                    if (value == true) {
                      _enabledEventTypes.add(type);
                    } else {
                      _enabledEventTypes.remove(type);
                    }
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _enabledEventTypes = CalendarEventType.values.toSet();
                });
              },
              child: Text(l10n.all),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
    );
  }

  String _getEventTypeName(CalendarEventType type, AppLocalizations l10n) {
    switch (type) {
      case CalendarEventType.heatCycle:
        return l10n.heatCycles;
      case CalendarEventType.expectedHeat:
        return '${l10n.heatCycles} (forventet)';
      case CalendarEventType.expectedBirth:
        return 'Estimert dato for fødsel';
      case CalendarEventType.delivery:
        return l10n.deliveryDate;
      case CalendarEventType.treatment:
        return 'Behandlinger';
      case CalendarEventType.birthday:
        return 'Bursdager';
    }
  }

  Color _getEventTypeColor(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.heatCycle:
        return Colors.pink;
      case CalendarEventType.expectedHeat:
        return Colors.pink.shade200;
      case CalendarEventType.expectedBirth:
        return Colors.purple;
      case CalendarEventType.delivery:
        return Colors.orange;
      case CalendarEventType.treatment:
        return Colors.blue;
      case CalendarEventType.birthday:
        return Colors.amber;
    }
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final DateFormat dateFormat;

  const _EventCard({required this.event, required this.dateFormat});

  IconData _getEventIcon() {
    switch (event.type) {
      case CalendarEventType.heatCycle:
      case CalendarEventType.expectedHeat:
        return Icons.favorite;
      case CalendarEventType.expectedBirth:
        return Icons.pets;
      case CalendarEventType.delivery:
        return Icons.local_shipping;
      case CalendarEventType.treatment:
        return Icons.medical_services;
      case CalendarEventType.birthday:
        return Icons.cake;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: event.color.withValues(alpha: ThemeOpacity.high(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getEventIcon(), color: event.color),
        ),
        title: Text(
          event.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: event.subtitle != null
            ? Text(
                event.subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.neutral600,
                ),
              )
            : null,
        trailing: Text(
          dateFormat.format(event.date),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.neutral500,
          ),
        ),
      ),
    );
  }
}
