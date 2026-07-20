import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(currentAppUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Care+'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 48, color: Colors.teal),
              const SizedBox(height: 16),
              Text(
                appUser == null
                    ? 'Welcome to Care+'
                    : 'Welcome, ${appUser.fullName}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (appUser != null) ...[
                const SizedBox(height: 8),
                Text(appUser.phone),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
