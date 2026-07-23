import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class EmergencyAccessScreen extends ConsumerWidget {
  const EmergencyAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(emergencyAccessProvider);
    final user = ref.watch(userProfileProvider);
    void back() => ref.read(screenProvider.notifier).go('profile');

    return Column(
      children: [
        TopBar(title: 'Emergency Access', onBack: back, rightIcon: Icons.info_outline),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Critical info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    border: Border.all(color: const Color(0xFFFECACA)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emergency, color: Color(0xFFEF4444), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Critical Medical Info',
                                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                            Text('${user.bloodType} · Allergies: ${user.allergies.join(', ')}',
                                style: const TextStyle(fontSize: 12, color: slate700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Active code card
                if (code != null && !code.isExpired) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [teal600, teal700], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Text('ACTIVE ACCESS CODE', style: TextStyle(fontSize: 11, color: teal100, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        Text(code.code,
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 8)),
                        const SizedBox(height: 8),
                        Text('Scope: ${code.scope == 'full' ? 'Full records' : 'Summary only'}',
                            style: const TextStyle(fontSize: 12, color: teal100)),
                        Text('Expires: ${_formatExpiry(code.expiresAt)}',
                            style: const TextStyle(fontSize: 12, color: teal100)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: code.code));
                                  ref.read(toastProvider.notifier).show('Code copied to clipboard');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(50)),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.copy, size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text('Copy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => ref.read(emergencyAccessProvider.notifier).revoke(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white54),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Text('Revoke', textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Text('Generate Access Code', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                  const SizedBox(height: 8),
                  const Text('A first responder or ER doctor can use this code to view your records for 30 minutes.',
                      style: TextStyle(fontSize: 13, color: slate500, height: 1.5)),
                  const SizedBox(height: 16),
                  _ScopeButton(
                    label: 'Summary only',
                    subtitle: 'Blood type, allergies, conditions, current meds',
                    icon: Icons.summarize,
                    onTap: () => ref.read(emergencyAccessProvider.notifier).generate('summary'),
                  ),
                  const SizedBox(height: 10),
                  _ScopeButton(
                    label: 'Full records',
                    subtitle: 'Complete medical history, documents, lab results',
                    icon: Icons.folder_open,
                    onTap: () => ref.read(emergencyAccessProvider.notifier).generate('full'),
                  ),
                ],

                const SizedBox(height: 24),
                const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                _ContactTile(
                  name: user.emergencyContact.name,
                  subtitle: '${user.emergencyContact.relation} · ${user.emergencyContact.phone}',
                  icon: Icons.person,
                ),
                const SizedBox(height: 8),
                _ContactTile(name: 'Emergency Services', subtitle: 'Call 112', icon: Icons.local_hospital),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatExpiry(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    final mins = diff.inMinutes;
    return mins > 0 ? 'in ${mins}m' : 'Expired';
  }
}

class _ScopeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _ScopeButton({required this.label, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: teal100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(color: teal50, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: teal600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: slate400)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: slate300),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;
  const _ContactTile({required this.name, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: teal100), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: teal50, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: teal700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: slate400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
