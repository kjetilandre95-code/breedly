import 'package:flutter/material.dart';

class PeddexAsyncWrapper<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final String loadingMessage;
  final String errorTitle;
  final String emptyTitle;
  final VoidCallback? onRetry;
  final bool Function(T? data)? isEmpty;
  final Widget Function(T? data) dataBuilder;

  const PeddexAsyncWrapper({
    super.key,
    required this.snapshot,
    required this.loadingMessage,
    required this.errorTitle,
    required this.emptyTitle,
    required this.dataBuilder,
    this.onRetry,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loadingMessage),
          ],
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              snapshot.error.toString(),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    if (isEmpty?.call(snapshot.data) == true) {
      return Center(child: Text(emptyTitle));
    }

    return dataBuilder(snapshot.data);
  }
}
