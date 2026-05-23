import 'package:flutter/material.dart';

class PeddexAsyncWrapper<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(T? data) dataBuilder;
  final String loadingMessage;
  final String errorTitle;
  final String emptyTitle;
  final bool Function(T? data)? isEmpty;
  final VoidCallback? onRetry;

  const PeddexAsyncWrapper({
    super.key,
    required this.snapshot,
    required this.dataBuilder,
    this.loadingMessage = 'Loading...',
    this.errorTitle = 'Something went wrong',
    this.emptyTitle = 'No data',
    this.isEmpty,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
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
            Text(snapshot.error.toString(), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }

    final data = snapshot.data;
    if (isEmpty?.call(data) ?? false) {
      return Center(child: Text(emptyTitle));
    }

    return dataBuilder(data);
  }
}
