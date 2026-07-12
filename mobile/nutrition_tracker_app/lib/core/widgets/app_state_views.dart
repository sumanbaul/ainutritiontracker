import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({required this.message, this.onRetry, super.key});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry'))
          ])));
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({required this.message, super.key});
  final String message;
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(message, textAlign: TextAlign.center));
}
