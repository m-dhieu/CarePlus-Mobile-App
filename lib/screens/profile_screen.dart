import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void toast(String msg) => ref.read(toastProvider.notifier).show(msg);
    void back() => ref.read(screenProvider.notifier).go('home');
    final user = ref.watch(userProfileProvider);

    return Column(
      children: [
        TopBar(
          title: 'My Profile',
          onBack: back,
          rightIcon: Icons.settings,
          onRight: () => toast('Settings need a backend connection'),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [teal600, teal700], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: teal600.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
                            child: Center(
                              child: Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                              Text('${user.age} years · ${user.bloodType} · ${user.height}',
                                  style: const TextStyle(color: teal100, fontSize: 12)),
                              Text('Patient ID · ${user.patientId}',
                                  style: const TextStyle(color: teal100, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white24))),
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            _StatPill(value: user.hba1c, label: 'HBA1C'),
                            _StatPill(value: user.bpAvg, label: 'BP AVG'),
                            _StatPill(value: user.weight, label: 'WEIGHT'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick-access feature tiles
                Row(
                  children: [
                    _FeatureTile(
                      icon: Icons.people,
                      label: 'Caregivers',
                      onTap: () => ref.read(screenProvider.notifier).go('caregivers'),
                    ),
                    const SizedBox(width: 12),
                    _FeatureTile(
                      icon: Icons.bar_chart,
                      label: 'Metrics',
                      onTap: () => ref.read(screenProvider.notifier).go('metrics'),
                    ),
                    const SizedBox(width: 12),
                    _FeatureTile(
                      icon: Icons.emergency,
                      label: 'Emergency',
                      onTap: () => ref.read(screenProvider.notifier).go('emergency'),
                    ),
                    const SizedBox(width: 12),
                    _FeatureTile(
                      icon: Icons.alarm,
                      label: 'Reminders',
                      onTap: () => ref.read(screenProvider.notifier).go('reminders'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Conditions', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                ...mockConditions.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: teal100), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      IconCircle(icon: c['icon'] as IconData),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name']! as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900)),
                            Text('Diagnosed ${c['diagnosed']}', style: const TextStyle(fontSize: 11, color: slate400)),
                          ],
                        ),
                      ),
                      TagChip(label: c['status']! as String),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                const Text('Allergies', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.allergies.map((a) => TagChip(label: a, rose: true)).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Emergency contact', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: teal100), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const IconCircle(icon: Icons.phone),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.emergencyContact.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900)),
                            Text('${user.emergencyContact.relation} · ${user.emergencyContact.phone}',
                                style: const TextStyle(fontSize: 11, color: slate400)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => toast('Calling needs a backend/telephony connection'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: teal600, borderRadius: BorderRadius.circular(50)),
                          child: const Text('Call', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                ...mockSettings.map((s) => GestureDetector(
                  onTap: () => toast('"${s['label']}" needs a backend connection'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: teal100), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        IconCircle(icon: s['icon'] as IconData),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s['label']! as String,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900)),
                        ),
                        Text(s['value']! as String, style: const TextStyle(fontSize: 12, color: slate400)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 14, color: slate300),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    ref.read(screenProvider.notifier).go('home');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFECACA)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 16, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Sign out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 10, color: teal100, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeatureTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: teal100),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: teal600),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: slate700)),
            ],
          ),
        ),
      ),
    );
  }
}
