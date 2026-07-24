import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/providers.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/meds_screen.dart';
import 'screens/records_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/emergency_access_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/caregivers_screen.dart';
import 'screens/metrics_screen.dart';
import 'widgets/shared_widgets.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: CarePlusApp()));
}

class CarePlusApp extends StatelessWidget {
  const CarePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'sans-serif', colorScheme: ColorScheme.fromSeed(seedColor: teal600)),
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(authProvider);
    final onboarded = ref.watch(onboardingProvider);
    final screen = ref.watch(screenProvider);
    final toast = ref.watch(toastProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Stack(
          children: [
            if (!authed)
              if (!onboarded)
                const OnboardingScreen()
              else
                const AuthScreen()
            else
              Stack(
                children: [
                  if (screen == 'home')   const HomeScreen(),
                  if (screen == 'journal') const JournalScreen(),
                  if (screen == 'meds')   const MedsScreen(),
                  if (screen == 'records') const RecordsScreen(),
                  if (screen == 'profile') const ProfileScreen(),
                  if (screen == 'emergency') const EmergencyAccessScreen(),
                  if (screen == 'reminders') const RemindersScreen(),
                  if (screen == 'caregivers') const CaregiversScreen(),
                  if (screen == 'metrics') const MetricsScreen(),
                  const Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: _BottomNavBar(),
                  ),
                ],
              ),
            if (toast != null)
              Positioned(
                bottom: 96, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                    ),
                    child: Text(toast, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(screenProvider);
    return BottomNav(
      active: screen,
      onNavigate: (s) => ref.read(screenProvider.notifier).go(s),
    );
  }
}
