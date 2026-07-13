import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_paths.dart';
import '../data/auth_service.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});
  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;
  Future<void> submit({bool register = false}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .signIn(email.text, password.text, register: register);
      if (mounted) context.go(RoutePaths.splash);
    } catch (_) {
      if (mounted) {
        setState(
            () => error = 'Sign in failed. Check your details and connection.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Welcome to NutriLens')),
      body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
        Text('Your nutrition data, securely yours.',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(
            controller: password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(labelText: 'Password')),
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 24),
        FilledButton(
            onPressed: busy ? null : submit,
            child: Text(busy ? 'Signing in…' : 'Sign in')),
        TextButton(
            onPressed: busy ? null : () => submit(register: true),
            child: const Text('Create account')),
      ])));
}
