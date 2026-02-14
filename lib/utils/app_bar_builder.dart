import 'package:flutter/material.dart';

/// Utility class for building consistent AppBars with back navigation
class AppBarBuilder {
  /// Creates a standard AppBar with back button and title
  /// 
  /// [title] - The title to display in the AppBar
  /// [context] - BuildContext for navigation
  /// [actions] - Optional list of additional action buttons
  /// [showBackButton] - Whether to show the back button (default: true)
  /// [bottom] - Optional bottom widget (e.g., TabBar)
  static AppBar buildAppBar({
    required String title,
    required BuildContext context,
    List<Widget>? actions,
    bool showBackButton = true,
    PreferredSizeWidget? bottom,
  }) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(title),
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      centerTitle: true,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Tilbake',
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }

  /// Creates a simple back button that can be used in custom AppBars
  static Widget buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_rounded),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Tilbake',
    );
  }
}
