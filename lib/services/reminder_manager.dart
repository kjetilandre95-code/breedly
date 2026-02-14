import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/treatment_plan.dart';
import 'package:breedly/models/medical_treatment.dart';
import 'package:breedly/models/vet_visit.dart';
import 'package:breedly/models/dog.dart';
import 'package:breedly/utils/notification_service.dart';
import 'package:breedly/utils/logger.dart';

/// Manages scheduling of reminders for important dates
class ReminderManager {
  static final ReminderManager _instance = ReminderManager._internal();
  final NotificationService _notificationService = NotificationService();

  ReminderManager._internal();

  factory ReminderManager() => _instance;

  /// Schedule all reminders for a litter
  Future<void> scheduleLitterReminders(Litter litter) async {
    AppLogger.debug(
      'Scheduling reminders for litter: ${litter.damName} x ${litter.sireName}',
    );

    // Schedule delivery reminder if due date is set
    if (litter.estimatedDueDate != null &&
        litter.estimatedDueDate!.isAfter(DateTime.now())) {
      final id = litter.id.hashCode;

      // Reminder 1 week before
      await _notificationService.scheduleDeliveryReminder(
        id: id,
        damName: litter.damName,
        dueDate: litter.estimatedDueDate!,
      );

      // Reminder 3 days before
      final threeDaysBefore = litter.estimatedDueDate!.subtract(
        const Duration(days: 3),
      );
      if (threeDaysBefore.isAfter(DateTime.now())) {
        await _scheduleCustomReminder(
          id: id + 1,
          title: 'Valping nærmer seg!',
          body: '${litter.damName} skal føde om 3 dager. Forbered valpekassen!',
          scheduledDate: threeDaysBefore,
        );
      }

      AppLogger.debug('Scheduled delivery reminders for ${litter.damName}');
    }
  }

  /// Schedule reminders for a puppy's treatment plan
  Future<void> scheduleTreatmentReminders(
    Puppy puppy,
    TreatmentPlan plan,
  ) async {
    AppLogger.debug('Scheduling treatment reminders for puppy: ${puppy.name}');

    final baseId = puppy.id.hashCode;

    // Wormer reminders
    if (plan.wormerDate1 != null && !plan.wormerDone1) {
      await _scheduleWithDayBeforeReminder(
        id: baseId + 10,
        title: 'Ormekur påminnelse',
        body: '${puppy.name} skal avmaskes i dag (1. dose)',
        scheduledDate: plan.wormerDate1!,
        puppyName: puppy.name,
        treatmentName: '1. ormekur',
      );
    }

    if (plan.wormerDate2 != null && !plan.wormerDone2) {
      await _scheduleWithDayBeforeReminder(
        id: baseId + 11,
        title: 'Ormekur påminnelse',
        body: '${puppy.name} skal avmaskes i dag (2. dose)',
        scheduledDate: plan.wormerDate2!,
        puppyName: puppy.name,
        treatmentName: '2. ormekur',
      );
    }

    if (plan.wormerDate3 != null && !plan.wormerDone3) {
      await _scheduleWithDayBeforeReminder(
        id: baseId + 12,
        title: 'Ormekur påminnelse',
        body: '${puppy.name} skal avmaskes i dag (3. dose)',
        scheduledDate: plan.wormerDate3!,
        puppyName: puppy.name,
        treatmentName: '3. ormekur',
      );
    }

    // Vaccine reminders
    if (plan.vaccineDate1 != null && !plan.vaccineDone1) {
      await _scheduleWithDayBeforeReminder(
        id: baseId + 20,
        title: 'Vaksine påminnelse',
        body: '${puppy.name} skal vaksineres i dag (1. vaksine)',
        scheduledDate: plan.vaccineDate1!,
        puppyName: puppy.name,
        treatmentName: '1. vaksine',
      );
    }

    if (plan.vaccineDate2 != null && !plan.vaccineDone2) {
      await _scheduleWithDayBeforeReminder(
        id: baseId + 21,
        title: 'Vaksine påminnelse',
        body: '${puppy.name} skal vaksineres i dag (2. vaksine)',
        scheduledDate: plan.vaccineDate2!,
        puppyName: puppy.name,
        treatmentName: '2. vaksine',
      );
    }

    if (plan.vaccineDate3 != null && !plan.vaccineDone3) {
      await _scheduleWithDayBeforeReminder(
        id: baseId + 22,
        title: 'Vaksine påminnelse',
        body: '${puppy.name} skal vaksineres i dag (3. vaksine)',
        scheduledDate: plan.vaccineDate3!,
        puppyName: puppy.name,
        treatmentName: '3. vaksine',
      );
    }

    // Microchip reminder
    if (plan.microchipDate != null && !plan.microchipDone) {
      await _scheduleWithDayBeforeReminder(
        id: baseId + 30,
        title: 'ID-merking påminnelse',
        body: '${puppy.name} skal ID-merkes i dag',
        scheduledDate: plan.microchipDate!,
        puppyName: puppy.name,
        treatmentName: 'ID-merking',
      );
    }

    AppLogger.debug('Scheduled treatment reminders for ${puppy.name}');
  }

  /// Schedule delivery reminder for puppy to buyer
  Future<void> schedulePuppyDeliveryReminder({
    required Puppy puppy,
    required String buyerName,
    required DateTime deliveryDate,
  }) async {
    final id = puppy.id.hashCode + 100;

    // Reminder 1 week before
    final weekBefore = deliveryDate.subtract(const Duration(days: 7));
    if (weekBefore.isAfter(DateTime.now())) {
      await _scheduleCustomReminder(
        id: id,
        title: 'Leveringspåminnelse',
        body: '${puppy.name} skal leveres til $buyerName om 1 uke',
        scheduledDate: weekBefore,
      );
    }

    // Reminder 3 days before
    await _notificationService.schedulePuppyDeliveryReminder(
      id: id + 1,
      puppyName: puppy.name,
      buyerName: buyerName,
      deliveryDate: deliveryDate,
      daysBeforeReminder: 3,
    );

    // Reminder 1 day before
    await _notificationService.schedulePuppyDeliveryReminder(
      id: id + 2,
      puppyName: puppy.name,
      buyerName: buyerName,
      deliveryDate: deliveryDate,
      daysBeforeReminder: 1,
    );

    // Reminder on delivery day
    await _scheduleCustomReminder(
      id: id + 3,
      title: 'Levering i dag!',
      body: '${puppy.name} skal leveres til $buyerName i dag 🎉',
      scheduledDate: deliveryDate,
    );

    AppLogger.debug('Scheduled delivery reminders for ${puppy.name} to $buyerName');
  }

  /// Schedule 8-week milestone reminder (puppies ready for new home)
  Future<void> schedule8WeekMilestoneReminder(Litter litter) async {
    final eightWeeks = litter.dateOfBirth.add(const Duration(days: 56));

    if (eightWeeks.isAfter(DateTime.now())) {
      await _scheduleCustomReminder(
        id: litter.id.hashCode + 200,
        title: '8 uker! 🎉',
        body:
            'Kullet til ${litter.damName} er nå 8 uker og klare for nye hjem!',
        scheduledDate: eightWeeks,
      );

      // Also remind 1 week before
      final oneWeekBefore = eightWeeks.subtract(const Duration(days: 7));
      if (oneWeekBefore.isAfter(DateTime.now())) {
        await _scheduleCustomReminder(
          id: litter.id.hashCode + 201,
          title: 'Snart 8 uker',
          body:
              'Kullet til ${litter.damName} blir 8 uker om 1 uke. Forbered levering!',
          scheduledDate: oneWeekBefore,
        );
      }
    }
  }

  /// Schedule weekly weight check reminder for a litter
  Future<void> scheduleWeightCheckReminders(
    Litter litter, {
    int weeks = 8,
  }) async {
    final baseId = litter.id.hashCode + 300;

    for (int week = 1; week <= weeks; week++) {
      final checkDate = litter.dateOfBirth.add(Duration(days: week * 7));

      if (checkDate.isAfter(DateTime.now())) {
        await _scheduleCustomReminder(
          id: baseId + week,
          title: 'Ukentlig veiing',
          body: 'Husk å veie valpene til ${litter.damName} (uke $week)',
          scheduledDate: checkDate,
        );
      }
    }

    AppLogger.debug('Scheduled weight check reminders for ${litter.damName}');
  }

  /// Refresh all reminders for all litters and puppies
  Future<void> refreshAllReminders() async {
    AppLogger.debug('Refreshing all reminders...');

    // Cancel all existing notifications first
    await _notificationService.cancelAllNotifications();

    // Schedule reminders for all litters
    final litterBox = Hive.box<Litter>('litters');
    for (final litter in litterBox.values) {
      await scheduleLitterReminders(litter);

      // Schedule 8-week milestone
      if (litter.dateOfBirth.isBefore(DateTime.now())) {
        await schedule8WeekMilestoneReminder(litter);
      }
    }

    // Schedule treatment reminders for all puppies
    final puppyBox = Hive.box<Puppy>('puppies');
    final treatmentBox = Hive.box<TreatmentPlan>('treatment_plans');

    for (final puppy in puppyBox.values) {
      try {
        final plan = treatmentBox.values.firstWhere(
          (tp) => tp.puppyId == puppy.id,
        );
        await scheduleTreatmentReminders(puppy, plan);
      } catch (e) {
        // No treatment plan for this puppy
      }
    }

    // Schedule medical treatment and vet follow-up reminders for all dogs
    final dogBox = Hive.box<Dog>('dogs');
    for (final dog in dogBox.values) {
      await scheduleDogTreatmentReminders(dog);
      await scheduleDogVetFollowUpReminders(dog);
    }

    AppLogger.debug('All reminders refreshed');
  }

  /// Cancel all reminders for a specific litter
  Future<void> cancelLitterReminders(String litterId) async {
    final baseId = litterId.hashCode;
    for (int i = 0; i < 10; i++) {
      await _notificationService.cancelNotification(baseId + i);
    }
    for (int i = 200; i < 210; i++) {
      await _notificationService.cancelNotification(baseId + i);
    }
    for (int i = 300; i < 320; i++) {
      await _notificationService.cancelNotification(baseId + i);
    }
  }

  /// Cancel all reminders for a specific puppy
  Future<void> cancelPuppyReminders(String puppyId) async {
    final baseId = puppyId.hashCode;
    for (int i = 0; i < 50; i++) {
      await _notificationService.cancelNotification(baseId + i);
    }
    for (int i = 100; i < 110; i++) {
      await _notificationService.cancelNotification(baseId + i);
    }
  }

  // ============ MEDICAL TREATMENT REMINDERS ============

  /// Schedule reminders for a medical treatment (deworming, flea, tick, etc.)
  Future<void> scheduleMedicalTreatmentReminder({
    required MedicalTreatment treatment,
    required String dogName,
  }) async {
    if (!treatment.reminderEnabled ||
        treatment.nextDueDate == null ||
        !treatment.nextDueDate!.isAfter(DateTime.now())) {
      return;
    }

    final baseId = treatment.id.hashCode + 500;
    final treatmentTypeLabel = _getTreatmentTypeLabel(treatment.treatmentType);

    // Reminder on the day
    await _scheduleCustomReminder(
      id: baseId,
      title: '$treatmentTypeLabel i dag',
      body: '$dogName skal ha ${treatment.name} i dag',
      scheduledDate: treatment.nextDueDate!,
    );

    // Reminder days before (based on reminderDaysBefore setting)
    final daysBefore = treatment.reminderDaysBefore ?? 3;
    final reminderDate = treatment.nextDueDate!.subtract(
      Duration(days: daysBefore),
    );
    if (reminderDate.isAfter(DateTime.now())) {
      await _scheduleCustomReminder(
        id: baseId + 1,
        title: '$treatmentTypeLabel snart',
        body:
            '$dogName skal ha ${treatment.name} om $daysBefore ${daysBefore == 1 ? 'dag' : 'dager'}',
        scheduledDate: reminderDate,
      );
    }

    AppLogger.debug('Scheduled treatment reminders for $dogName - ${treatment.name}');
  }

  /// Schedule reminders for a vet visit follow-up
  Future<void> scheduleVetVisitFollowUpReminder({
    required VetVisit visit,
    required String dogName,
  }) async {
    if (visit.followUpDate == null ||
        !visit.followUpDate!.isAfter(DateTime.now())) {
      return;
    }

    final baseId = visit.id.hashCode + 600;
    final visitTypeLabel = _getVisitTypeLabel(visit.visitType);

    // Reminder on the day
    await _scheduleCustomReminder(
      id: baseId,
      title: 'Veterinæroppfølging i dag',
      body: '$dogName har oppfølging ($visitTypeLabel) hos veterinæren i dag',
      scheduledDate: visit.followUpDate!,
    );

    // Reminder 3 days before
    final threeDaysBefore = visit.followUpDate!.subtract(
      const Duration(days: 3),
    );
    if (threeDaysBefore.isAfter(DateTime.now())) {
      await _scheduleCustomReminder(
        id: baseId + 1,
        title: 'Veterinæroppfølging snart',
        body: '$dogName har oppfølging hos veterinæren om 3 dager',
        scheduledDate: threeDaysBefore,
      );
    }

    AppLogger.debug('Scheduled vet follow-up reminders for $dogName');
  }

  /// Schedule all medical treatment reminders for a dog
  Future<void> scheduleDogTreatmentReminders(Dog dog) async {
    final treatmentBox = Hive.box<MedicalTreatment>('medical_treatments');
    final treatments =
        treatmentBox.values.where((t) => t.dogId == dog.id).toList();

    for (final treatment in treatments) {
      if (treatment.reminderEnabled && treatment.nextDueDate != null) {
        await scheduleMedicalTreatmentReminder(
          treatment: treatment,
          dogName: dog.name,
        );
      }
    }
  }

  /// Schedule all vet visit follow-up reminders for a dog
  Future<void> scheduleDogVetFollowUpReminders(Dog dog) async {
    final vetVisitBox = Hive.box<VetVisit>('vet_visits');
    final visits = vetVisitBox.values.where((v) => v.dogId == dog.id).toList();

    for (final visit in visits) {
      if (visit.followUpDate != null) {
        await scheduleVetVisitFollowUpReminder(
          visit: visit,
          dogName: dog.name,
        );
      }
    }
  }

  /// Cancel all medical treatment reminders for a dog
  Future<void> cancelDogTreatmentReminders(String dogId) async {
    final treatmentBox = Hive.box<MedicalTreatment>('medical_treatments');
    final treatments =
        treatmentBox.values.where((t) => t.dogId == dogId).toList();

    for (final treatment in treatments) {
      await cancelMedicalTreatmentReminder(treatment.id);
    }
  }

  /// Cancel reminder for a specific medical treatment
  Future<void> cancelMedicalTreatmentReminder(String treatmentId) async {
    final baseId = treatmentId.hashCode + 500;
    await _notificationService.cancelNotification(baseId);
    await _notificationService.cancelNotification(baseId + 1);
  }

  /// Cancel reminder for a specific vet visit follow-up
  Future<void> cancelVetVisitFollowUpReminder(String visitId) async {
    final baseId = visitId.hashCode + 600;
    await _notificationService.cancelNotification(baseId);
    await _notificationService.cancelNotification(baseId + 1);
  }

  /// Get treatment type label in Norwegian
  String _getTreatmentTypeLabel(String treatmentType) {
    switch (treatmentType) {
      case 'deworming':
        return 'Ormekur';
      case 'flea':
        return 'Loppebehandling';
      case 'tick':
        return 'Flåttbehandling';
      case 'medication':
        return 'Medisin';
      case 'supplement':
        return 'Kosttilskudd';
      default:
        return 'Behandling';
    }
  }

  /// Get visit type label in Norwegian
  String _getVisitTypeLabel(String visitType) {
    switch (visitType) {
      case 'routine':
        return 'Rutinekontroll';
      case 'emergency':
        return 'Akutt';
      case 'surgery':
        return 'Operasjon';
      case 'vaccination':
        return 'Vaksinering';
      case 'followup':
        return 'Oppfølging';
      default:
        return 'Annet';
    }
  }

  /// Helper to schedule with day-before reminder
  Future<void> _scheduleWithDayBeforeReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String puppyName,
    required String treatmentName,
  }) async {
    // Main reminder
    if (scheduledDate.isAfter(DateTime.now())) {
      await _scheduleCustomReminder(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
      );

      // Day before reminder
      final dayBefore = scheduledDate.subtract(const Duration(days: 1));
      if (dayBefore.isAfter(DateTime.now())) {
        await _scheduleCustomReminder(
          id: id + 1000,
          title: 'Påminnelse for i morgen',
          body: '$puppyName skal ha $treatmentName i morgen',
          scheduledDate: dayBefore,
        );
      }
    }
  }

  /// Schedule a custom reminder
  Future<void> _scheduleCustomReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      await NotificationService.flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _toTZDateTime(scheduledDate),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'breedly_channel',
            'Breedly Notifications',
            channelDescription: 'Notifications for Breedly app',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      AppLogger.debug('Error scheduling custom reminder: $e');
    }
  }

  tz.TZDateTime _toTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}
