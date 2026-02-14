import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:breedly/models/puppy.dart';
import 'package:breedly/models/litter.dart';
import 'package:breedly/models/kennel_profile.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service for sharing puppy updates with buyers via SMS, email, or other apps
class ShareService {
  static final ShareService _instance = ShareService._internal();

  ShareService._internal();

  factory ShareService() => _instance;

  /// Get kennel info for messages
  KennelProfile? _getKennel() {
    try {
      final kennelBox = Hive.box<KennelProfile>('kennel_profile');
      if (kennelBox.isNotEmpty) {
        return kennelBox.values.first;
      }
    } catch (e) {
      // Box not open or not available
    }
    return null;
  }

  /// Generate a puppy update message
  String generatePuppyUpdateMessage(
    Puppy puppy,
    Litter litter, {
    String? customMessage,
    bool includeWeight = true,
    bool includeTreatments = true,
    bool includeAge = true,
  }) {
    final kennel = _getKennel();
    final kennelName = kennel?.kennelName ?? 'Kennelen';
    final ageWeeks = puppy.getAgeInWeeks();
    final ageDays = puppy.getAgeInDays() % 7;

    final buffer = StringBuffer();

    // Header
    buffer.writeln('🐕 Oppdatering fra $kennelName');
    buffer.writeln('');

    // Puppy info
    buffer.writeln('Valp: ${puppy.name}');
    buffer.writeln('Rase: ${litter.breed}');

    if (includeAge) {
      if (ageDays > 0) {
        buffer.writeln('Alder: $ageWeeks uker og $ageDays dager');
      } else {
        buffer.writeln('Alder: $ageWeeks uker');
      }
    }

    if (includeWeight && puppy.birthWeight != null) {
      buffer.writeln('Fødselsvekt: ${puppy.birthWeight?.toStringAsFixed(0)} g');
    }

    if (includeTreatments) {
      buffer.writeln('');
      buffer.writeln('📋 Status:');
      buffer.writeln('• Vaksinert: ${puppy.vaccinated ? "✅" : "⏳"}');
      buffer.writeln('• Avmasket: ${puppy.dewormed ? "✅" : "⏳"}');
      buffer.writeln('• ID-merket: ${puppy.microchipped ? "✅" : "⏳"}');
    }

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('💬 Melding:');
      buffer.writeln(customMessage);
    }

    buffer.writeln('');
    buffer.writeln('Med vennlig hilsen,');
    buffer.writeln(kennelName);

    if (kennel?.contactPhone != null && kennel!.contactPhone!.isNotEmpty) {
      buffer.writeln('📞 ${kennel.contactPhone}');
    }

    return buffer.toString();
  }

  /// Generate a litter update message (for all puppies in a litter)
  String generateLitterUpdateMessage(
    Litter litter,
    List<Puppy> puppies, {
    String? customMessage,
  }) {
    final kennel = _getKennel();
    final kennelName = kennel?.kennelName ?? 'Kennelen';
    final ageWeeks = litter.getAgeInWeeks();

    final buffer = StringBuffer();

    buffer.writeln('🐾 Kulloppdatering fra $kennelName');
    buffer.writeln('');
    buffer.writeln('Kull: ${litter.damName} × ${litter.sireName}');
    buffer.writeln('Rase: ${litter.breed}');
    buffer.writeln('Alder: $ageWeeks uker');
    buffer.writeln('Antall valper: ${puppies.length}');
    buffer.writeln('');

    // Status summary
    final vaccinated = puppies.where((p) => p.vaccinated).length;
    final dewormed = puppies.where((p) => p.dewormed).length;
    final microchipped = puppies.where((p) => p.microchipped).length;

    buffer.writeln('📋 Behandlingsstatus:');
    buffer.writeln('• Vaksinert: $vaccinated/${puppies.length}');
    buffer.writeln('• Avmasket: $dewormed/${puppies.length}');
    buffer.writeln('• ID-merket: $microchipped/${puppies.length}');

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('💬 Melding:');
      buffer.writeln(customMessage);
    }

    buffer.writeln('');
    buffer.writeln('Med vennlig hilsen,');
    buffer.writeln(kennelName);

    return buffer.toString();
  }

  /// Generate delivery reminder message
  String generateDeliveryReminderMessage(
    Puppy puppy,
    Litter litter,
    DateTime deliveryDate,
  ) {
    final kennel = _getKennel();
    final kennelName = kennel?.kennelName ?? 'Kennelen';
    final formattedDate = DateFormat('dd.MM.yyyy').format(deliveryDate);
    final daysUntil = deliveryDate.difference(DateTime.now()).inDays;

    final buffer = StringBuffer();

    buffer.writeln('🏠 Leveringspåminnelse fra $kennelName');
    buffer.writeln('');
    buffer.writeln('${puppy.name} er klar for å flytte hjem til deg!');
    buffer.writeln('');
    buffer.writeln('📅 Leveringsdato: $formattedDate');
    if (daysUntil > 0) {
      buffer.writeln('⏰ Om $daysUntil ${daysUntil == 1 ? "dag" : "dager"}');
    } else if (daysUntil == 0) {
      buffer.writeln('⏰ I dag!');
    }
    buffer.writeln('');
    buffer.writeln('Husk å ta med:');
    buffer.writeln('• Transportbur/bæreveske');
    buffer.writeln('• Teppe med hjemmets lukt');
    buffer.writeln('• Vann til turen');
    buffer.writeln('');

    if (kennel?.address != null && kennel!.address!.isNotEmpty) {
      buffer.writeln('📍 Adresse: ${kennel.address}');
    }

    if (kennel?.contactPhone != null && kennel!.contactPhone!.isNotEmpty) {
      buffer.writeln('📞 Kontakt: ${kennel.contactPhone}');
    }

    buffer.writeln('');
    buffer.writeln('Vi gleder oss til å se deg!');
    buffer.writeln(kennelName);

    return buffer.toString();
  }

  /// Share via system share dialog
  Future<void> shareViaApp(String message, {String? subject}) async {
    await Share.share(message, subject: subject);
  }

  /// Send SMS to a phone number
  Future<bool> sendSMS(String phoneNumber, String message) async {
    // Clean phone number
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    final uri = Uri(
      scheme: 'sms',
      path: cleanNumber,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  /// Send email
  Future<bool> sendEmail(String email, String subject, String body) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  /// Show share options dialog
  Future<void> showShareOptionsDialog(
    BuildContext context, {
    required String message,
    String? phoneNumber,
    String? email,
    String? subject,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.share, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    'Del oppdatering',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // SMS option
              if (phoneNumber != null && phoneNumber.isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sms, color: Colors.green),
                  ),
                  title: const Text('Send SMS'),
                  subtitle: Text(phoneNumber),
                  onTap: () {
                    Navigator.pop(context);
                    sendSMS(phoneNumber, message);
                  },
                ),

              // Email option
              if (email != null && email.isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.email, color: Colors.red),
                  ),
                  title: const Text('Send e-post'),
                  subtitle: Text(email),
                  onTap: () {
                    Navigator.pop(context);
                    sendEmail(email, subject ?? 'Valpeoppdatering', message);
                  },
                ),

              // Share via other apps
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share, color: Colors.blue),
                ),
                title: const Text('Del via andre apper'),
                subtitle: const Text('Messenger, WhatsApp, etc.'),
                onTap: () {
                  Navigator.pop(context);
                  shareViaApp(message, subject: subject);
                },
              ),

              // Copy to clipboard
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.copy, color: Colors.grey),
                ),
                title: const Text('Kopier tekst'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(context, message);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tekst kopiert til utklippstavlen'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
