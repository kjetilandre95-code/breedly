import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:breedly/generated_l10n/app_localizations.dart';
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
    AppLocalizations? l10n,
    String? customMessage,
    bool includeWeight = true,
    bool includeTreatments = true,
    bool includeAge = true,
  }) {
    final kennel = _getKennel();
    final kennelName = kennel?.kennelName ?? (l10n?.msgDefaultKennelName ?? 'Kennelen');
    final ageWeeks = puppy.getAgeInWeeks();
    final ageDays = puppy.getAgeInDays() % 7;

    final buffer = StringBuffer();

    // Header
    buffer.writeln('🐕 ${l10n?.msgUpdateFromKennel(kennelName) ?? 'Oppdatering fra $kennelName'}');
    buffer.writeln('');

    // Puppy info
    buffer.writeln(l10n?.msgPuppy(puppy.name) ?? 'Valp: ${puppy.name}');
    buffer.writeln(l10n?.msgBreed(litter.breed) ?? 'Rase: ${litter.breed}');

    if (includeAge) {
      if (ageDays > 0) {
        buffer.writeln(l10n?.msgAgeWeeksAndDays(ageWeeks, ageDays) ?? 'Alder: $ageWeeks uker og $ageDays dager');
      } else {
        buffer.writeln(l10n?.msgAgeWeeks(ageWeeks) ?? 'Alder: $ageWeeks uker');
      }
    }

    if (includeWeight && puppy.birthWeight != null) {
      buffer.writeln(l10n?.msgBirthWeight(puppy.birthWeight!.toStringAsFixed(0)) ?? 'Fødselsvekt: ${puppy.birthWeight?.toStringAsFixed(0)} g');
    }

    if (includeTreatments) {
      buffer.writeln('');
      buffer.writeln('📋 ${l10n?.msgStatusHeader ?? 'Status:'}');
      buffer.writeln('• ${l10n?.msgVaccinated(puppy.vaccinated ? "✅" : "⏳") ?? 'Vaksinert: ${puppy.vaccinated ? "✅" : "⏳"}'}');
      buffer.writeln('• ${l10n?.msgDewormed(puppy.dewormed ? "✅" : "⏳") ?? 'Avmasket: ${puppy.dewormed ? "✅" : "⏳"}'}');
      buffer.writeln('• ${l10n?.msgIdTagged(puppy.microchipped ? "✅" : "⏳") ?? 'ID-merket: ${puppy.microchipped ? "✅" : "⏳"}'}');
    }

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('💬 ${l10n?.msgMessageHeader ?? 'Melding:'}');
      buffer.writeln(customMessage);
    }

    buffer.writeln('');
    buffer.writeln(l10n?.msgBestRegards ?? 'Med vennlig hilsen,');
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
    AppLocalizations? l10n,
    String? customMessage,
  }) {
    final kennel = _getKennel();
    final kennelName = kennel?.kennelName ?? (l10n?.msgDefaultKennelName ?? 'Kennelen');
    final ageWeeks = litter.getAgeInWeeks();

    final buffer = StringBuffer();

    buffer.writeln('🐾 ${l10n?.msgLitterUpdateFromKennel(kennelName) ?? 'Kulloppdatering fra $kennelName'}');
    buffer.writeln('');
    buffer.writeln(l10n?.msgLitter(litter.damName, litter.sireName) ?? 'Kull: ${litter.damName} × ${litter.sireName}');
    buffer.writeln(l10n?.msgBreed(litter.breed) ?? 'Rase: ${litter.breed}');
    buffer.writeln(l10n?.msgAgeWeeks(ageWeeks) ?? 'Alder: $ageWeeks uker');
    buffer.writeln(l10n?.msgPuppyCount(puppies.length) ?? 'Antall valper: ${puppies.length}');
    buffer.writeln('');

    // Status summary
    final vaccinated = puppies.where((p) => p.vaccinated).length;
    final dewormed = puppies.where((p) => p.dewormed).length;
    final microchipped = puppies.where((p) => p.microchipped).length;

    buffer.writeln('📋 ${l10n?.msgTreatmentStatus ?? 'Behandlingsstatus:'}');
    buffer.writeln('• ${l10n?.msgVaccinated('$vaccinated/${puppies.length}') ?? 'Vaksinert: $vaccinated/${puppies.length}'}');
    buffer.writeln('• ${l10n?.msgDewormed('$dewormed/${puppies.length}') ?? 'Avmasket: $dewormed/${puppies.length}'}');
    buffer.writeln('• ${l10n?.msgIdTagged('$microchipped/${puppies.length}') ?? 'ID-merket: $microchipped/${puppies.length}'}');

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('💬 ${l10n?.msgMessageHeader ?? 'Melding:'}');
      buffer.writeln(customMessage);
    }

    buffer.writeln('');
    buffer.writeln(l10n?.msgBestRegards ?? 'Med vennlig hilsen,');
    buffer.writeln(kennelName);

    return buffer.toString();
  }

  /// Generate delivery reminder message
  String generateDeliveryReminderMessage(
    Puppy puppy,
    Litter litter,
    DateTime deliveryDate, {
    AppLocalizations? l10n,
  }) {
    final kennel = _getKennel();
    final kennelName = kennel?.kennelName ?? (l10n?.msgDefaultKennelName ?? 'Kennelen');
    final formattedDate = DateFormat('dd.MM.yyyy').format(deliveryDate);
    final daysUntil = deliveryDate.difference(DateTime.now()).inDays;

    final buffer = StringBuffer();

    buffer.writeln('🏠 ${l10n?.msgDeliveryReminder(kennelName) ?? 'Leveringspåminnelse fra $kennelName'}');
    buffer.writeln('');
    buffer.writeln(l10n?.msgReadyToMoveHome(puppy.name) ?? '${puppy.name} er klar for å flytte hjem til deg!');
    buffer.writeln('');
    buffer.writeln('📅 ${l10n?.msgDeliveryDate(formattedDate) ?? 'Leveringsdato: $formattedDate'}');
    if (daysUntil > 0) {
      final dayWord = daysUntil == 1
          ? (l10n?.msgDaySingular ?? 'dag')
          : (l10n?.msgDayPlural ?? 'dager');
      buffer.writeln('⏰ ${l10n?.msgInDays(daysUntil, dayWord) ?? 'Om $daysUntil $dayWord'}');
    } else if (daysUntil == 0) {
      buffer.writeln('⏰ ${l10n?.msgToday ?? 'I dag!'}');
    }
    buffer.writeln('');
    buffer.writeln(l10n?.msgRememberToBring ?? 'Husk å ta med:');
    buffer.writeln('• ${l10n?.msgTransportCrate ?? 'Transportbur/bæreveske'}');
    buffer.writeln('• ${l10n?.msgBlanketWithHomeScent ?? 'Teppe med hjemmets lukt'}');
    buffer.writeln('• ${l10n?.msgWaterForTrip ?? 'Vann til turen'}');
    buffer.writeln('');

    if (kennel?.address != null && kennel!.address!.isNotEmpty) {
      buffer.writeln('📍 ${l10n?.msgAddress(kennel.address!) ?? 'Adresse: ${kennel.address}'}');
    }

    if (kennel?.contactPhone != null && kennel!.contactPhone!.isNotEmpty) {
      buffer.writeln('📞 ${l10n?.msgContact(kennel.contactPhone!) ?? 'Kontakt: ${kennel.contactPhone}'}');
    }

    buffer.writeln('');
    buffer.writeln(l10n?.msgLookingForward ?? 'Vi gleder oss til å se deg!');
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

    // Use platform-appropriate SMS URI
    // Android: sms:number?body=message
    // iOS: sms:number&body=message (but Flutter Uri handles this)
    final encodedBody = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$cleanNumber?body=$encodedBody');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      // Fallback: try without body
      final fallbackUri = Uri.parse('sms:$cleanNumber');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri);
        return true;
      }
    } catch (e) {
      debugPrint('Error launching SMS: $e');
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

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
    return false;
  }

  /// Detect if a string looks like an email address
  bool _isEmail(String contact) {
    return contact.contains('@') && contact.contains('.');
  }

  /// Detect if a string looks like a phone number
  bool _isPhone(String contact) {
    final cleaned = contact.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\+?\d{8,}$').hasMatch(cleaned);
  }

  /// Parse a contact string that may contain phone, email, or both
  /// Returns (phone, email) tuple
  ({String? phone, String? email}) parseContact(String? contact) {
    if (contact == null || contact.trim().isEmpty) {
      return (phone: null, email: null);
    }

    String? phone;
    String? email;

    // Try splitting by common separators
    final parts = contact.split(RegExp(r'[,/;]\s*'));
    for (final part in parts) {
      final trimmed = part.trim();
      if (_isEmail(trimmed)) {
        email = trimmed;
      } else if (_isPhone(trimmed)) {
        phone = trimmed;
      }
    }

    // If no split found, check the whole string
    if (phone == null && email == null) {
      if (_isEmail(contact.trim())) {
        email = contact.trim();
      } else if (_isPhone(contact.trim())) {
        phone = contact.trim();
      }
    }

    return (phone: phone, email: email);
  }

  /// Show share options dialog
  Future<void> showShareOptionsDialog(
    BuildContext context, {
    required String message,
    String? phoneNumber,
    String? email,
    String? subject,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    
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
                    l10n.shareUpdateTitle,
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
                  title: Text(l10n.sendSmsLabel),
                  subtitle: Text(phoneNumber),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await sendSMS(phoneNumber, message);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.couldNotOpenSms)),
                      );
                    }
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
                  title: Text(l10n.sendEmailLabel),
                  subtitle: Text(email),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await sendEmail(email, subject ?? l10n.puppyUpdateSubject, message);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.couldNotOpenEmail)),
                      );
                    }
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
                title: Text(l10n.shareViaOtherApps),
                subtitle: Text(l10n.messengerWhatsappEtc),
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
                title: Text(l10n.copyTextLabel),
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
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.textCopiedToClipboard ?? 'Text copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
