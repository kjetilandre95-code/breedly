import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'constants.dart';

/// Felles hjelperfunksjoner for UI-elementer
class UIHelpers {
  /// Bygger en detalj-rad for visning av label-verdi par
  static Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Kompakt versjon av detail-rad for dialoger
  static Widget buildDetailRowCompact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Vertikalt spacing med konstant
  static SizedBox verticalSpace(double height) {
    return SizedBox(height: height);
  }

  /// Horisontalt spacing med konstant
  static SizedBox horizontalSpace(double width) {
    return SizedBox(width: width);
  }

  /// Delt linje for seksjon separasjon
  static Widget sectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(),
    );
  }

  /// Liten badge container
  static Widget badge(String text, Color color, {BuildContext? context}) {
    final lowAlpha = context != null ? ThemeOpacity.low(context) : 0.1;
    final highAlpha = context != null ? ThemeOpacity.high(context) : 0.3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: lowAlpha),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: highAlpha)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
