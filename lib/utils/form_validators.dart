import 'package:flutter/material.dart';

/// Centralized form validation utilities with localized error messages
class FormValidators {
  /// Validates that a field is not empty
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      if (fieldName != null) {
        return '$fieldName er påkrevd';
      }
      return 'Dette feltet er påkrevd';
    }
    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-postadresse er påkrevd';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ugyldig e-postformat (f.eks. navn@eksempel.no)';
    }
    return null;
  }

  /// Validates phone number format
  static String? phone(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Telefonnummer er påkrevd' : null;
    }
    // Remove spaces and dashes for validation
    final cleanNumber = value.replaceAll(RegExp(r'[\s\-]'), '');
    // Allow Norwegian numbers (8 digits) or international (+47 etc)
    final phoneRegex = RegExp(r'^(\+\d{1,3})?\d{8,12}$');
    if (!phoneRegex.hasMatch(cleanNumber)) {
      return 'Ugyldig telefonnummer (8-12 siffer)';
    }
    return null;
  }

  /// Validates password strength
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Passord er påkrevd';
    }
    if (value.length < minLength) {
      return 'Passord må være minst $minLength tegn';
    }
    return null;
  }

  /// Validates password confirmation matches
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Bekreft passordet';
    }
    if (value != originalPassword) {
      return 'Passordene samsvarer ikke';
    }
    return null;
  }

  /// Validates a number is within range
  static String? numberInRange(
    String? value, {
    required String fieldName,
    double? min,
    double? max,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$fieldName er påkrevd' : null;
    }
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null) {
      return 'Skriv inn et gyldig tall';
    }
    if (min != null && number < min) {
      return '$fieldName må være minst $min';
    }
    if (max != null && number > max) {
      return '$fieldName kan ikke være mer enn $max';
    }
    return null;
  }

  /// Validates positive number
  static String? positiveNumber(String? value, {String? fieldName, bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? '${fieldName ?? 'Verdi'} er påkrevd' : null;
    }
    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null) {
      return 'Skriv inn et gyldig tall';
    }
    if (number <= 0) {
      return '${fieldName ?? 'Verdien'} må være større enn 0';
    }
    return null;
  }

  /// Validates a date is not in the future
  static String? dateNotFuture(DateTime? date, {String? fieldName}) {
    if (date == null) {
      return '${fieldName ?? 'Dato'} er påkrevd';
    }
    if (date.isAfter(DateTime.now())) {
      return '${fieldName ?? 'Dato'} kan ikke være i fremtiden';
    }
    return null;
  }

  /// Validates a date is in the future
  static String? dateInFuture(DateTime? date, {String? fieldName}) {
    if (date == null) {
      return '${fieldName ?? 'Dato'} er påkrevd';
    }
    if (date.isBefore(DateTime.now())) {
      return '${fieldName ?? 'Dato'} må være i fremtiden';
    }
    return null;
  }

  /// Validates text length
  static String? textLength(
    String? value, {
    required String fieldName,
    int? minLength,
    int? maxLength,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$fieldName er påkrevd' : null;
    }
    if (minLength != null && value.length < minLength) {
      return '$fieldName må være minst $minLength tegn';
    }
    if (maxLength != null && value.length > maxLength) {
      return '$fieldName kan ikke være mer enn $maxLength tegn';
    }
    return null;
  }

  /// Validates that at least one option is selected
  static String? selectionRequired(dynamic value, {String? fieldName}) {
    if (value == null || (value is String && value.isEmpty)) {
      return 'Vennligst velg ${fieldName ?? 'et alternativ'}';
    }
    return null;
  }

  /// Validates chip/microchip number format
  static String? chipNumber(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Chip-nummer er påkrevd' : null;
    }
    // Chip numbers are typically 15 digits
    final cleanChip = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleanChip.length != 15 || int.tryParse(cleanChip) == null) {
      return 'Chip-nummer må være 15 siffer';
    }
    return null;
  }

  /// Validates registration number format
  static String? registrationNumber(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Registreringsnummer er påkrevd' : null;
    }
    // Basic validation - allow alphanumeric with dashes
    final regNumRegex = RegExp(r'^[A-Za-z0-9\-/]+$');
    if (!regNumRegex.hasMatch(value)) {
      return 'Ugyldig registreringsnummer format';
    }
    return null;
  }

  /// Validates price/amount format
  static String? amount(String? value, {String currency = 'kr', bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Beløp er påkrevd' : null;
    }
    final cleanValue = value.replaceAll(RegExp(r'[^\d.,]'), '');
    final number = double.tryParse(cleanValue.replaceAll(',', '.'));
    if (number == null) {
      return 'Skriv inn et gyldig beløp';
    }
    if (number < 0) {
      return 'Beløp kan ikke være negativt';
    }
    return null;
  }

  /// Combines multiple validators
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}

/// Helper class for displaying validation feedback
class ValidationFeedback {
  /// Shows a snackbar with error message
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a snackbar with success message
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a snackbar with warning message
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows a snackbar with info message
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows an error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_rounded, color: Colors.red.shade700, size: 48),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
