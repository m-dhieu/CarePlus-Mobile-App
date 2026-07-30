import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // Privacy / language stay stubs; reminders row navigates to the Reminders screen.
  static const _settings = [
    {
      'icon': Icons.notifications,
      'label': 'Reminders & notifications',
      'value': 'On',
      'action': 'reminders',
      'todo':
          'OS local-notification prefs still open; schedules live on Reminders screen',
    },
    {
      'icon': Icons.shield,
      'label': 'Privacy & data sharing',
      'value': 'Managed',
      'todo':
          'surface share-token / caregiver scopes UI; backend rules already user-scoped',
    },
    {
      'icon': Icons.language,
      'label': 'Language',
      'value': 'English',
      'todo':
          'add locale picker + flutter_localizations; app is English-only today',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void back() => ref.read(screenProvider.notifier).go('home');
    final user = ref.watch(userProfileProvider);
    final meds = ref.watch(medicationsProvider);
    final conditions = meds
        .map((m) => m.condition.trim())
        .where((c) => c.isNotEmpty && c != '—')
        .toSet()
        .toList();

    return Column(
      children: [
        TopBar(
          title: 'My Profile',
          onBack: back,
          rightIcon: Icons.edit,
          onRight: () => _showEditProfileSheet(context, ref, user),
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
                    gradient: const LinearGradient(
                      colors: [teal600, teal700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: teal600.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                user.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Expanded avoids RenderFlex overflow when profile fields are filled in
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${user.age} years · ${user.bloodType} · ${user.height}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: teal100,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Patient ID · ${user.patientId}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: teal100,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white24),
                          ),
                        ),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: teal100),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const IconCircle(icon: Icons.phone),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone number',
                              style: TextStyle(fontSize: 11, color: slate400),
                            ),
                            Text(
                              user.phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: slate900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick-access feature tiles — FittedBox keeps labels from overflowing on narrow widths
                Row(
                  children: [
                    _FeatureTile(
                      icon: Icons.people,
                      label: 'Caregivers',
                      onTap: () =>
                          ref.read(screenProvider.notifier).go('caregivers'),
                    ),
                    const SizedBox(width: 12),
                    _FeatureTile(
                      icon: Icons.bar_chart,
                      label: 'Metrics',
                      onTap: () =>
                          ref.read(screenProvider.notifier).go('metrics'),
                    ),
                    const SizedBox(width: 12),
                    _FeatureTile(
                      icon: Icons.emergency,
                      label: 'Emergency',
                      onTap: () =>
                          ref.read(screenProvider.notifier).go('emergency'),
                    ),
                    const SizedBox(width: 12),
                    _FeatureTile(
                      icon: Icons.alarm,
                      label: 'Reminders',
                      onTap: () =>
                          ref.read(screenProvider.notifier).go('reminders'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Conditions',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: slate900,
                  ),
                ),
                const SizedBox(height: 8),
                if (conditions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'No conditions yet — they appear from your medications.',
                      style: TextStyle(fontSize: 13, color: slate400),
                    ),
                  )
                else
                  ...conditions.map(
                    (name) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: teal100),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const IconCircle(icon: Icons.monitor_heart),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: slate900,
                              ),
                            ),
                          ),
                          const TagChip(label: 'Active'),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Allergies',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: slate900,
                  ),
                ),
                const SizedBox(height: 8),
                if (user.allergies.isEmpty)
                  const Text(
                    'None recorded',
                    style: TextStyle(fontSize: 13, color: slate400),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.allergies
                        .map((a) => TagChip(label: a, rose: true))
                        .toList(),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Emergency contact',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: slate900,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: teal100),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const IconCircle(icon: Icons.phone),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.emergencyContact.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: slate900,
                              ),
                            ),
                            Text(
                              '${user.emergencyContact.relation} · ${user.emergencyContact.phone}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: slate400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final phone = user.emergencyContact.phone;
                          final cleaned =
                              phone.trim().replaceAll(RegExp(r'[^\d+]'), '');
                          final ok = cleaned.isNotEmpty &&
                              cleaned != '—' &&
                              await launchUrl(Uri(scheme: 'tel', path: cleaned));
                          if (!ok) {
                            ref
                                .read(toastProvider.notifier)
                                .show('No dialer available for "$phone"');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: teal600,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            'Call',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: slate900,
                  ),
                ),
                const SizedBox(height: 8),
                ..._settings.map(
                  (s) => GestureDetector(
                    onTap: () {
                      final label = s['label']! as String;
                      final todo = s['todo']! as String;
                      final action = s['action'] as String?;
                      if (action == 'reminders') {
                        debugPrint('[Care+][TODO] $label — $todo');
                        ref.read(screenProvider.notifier).go('reminders');
                        return;
                      }
                      // Remaining stubs: toast + greppable [Care+][TODO] breadcrumb
                      ref
                          .read(toastProvider.notifier)
                          .showUnfinished(
                            label,
                            detail: todo,
                            userMessage: '$label — not available yet',
                          );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: teal100),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          IconCircle(icon: s['icon'] as IconData),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s['label']! as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: slate900,
                              ),
                            ),
                          ),
                          Text(
                            s['value']! as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: slate400,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: slate300,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                        Text(
                          'Sign out',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
  ) {
    final nameCtrl = TextEditingController(
      text: user.name == 'User' ? '' : user.name,
    );
    final phoneCtrl = TextEditingController(
      text: user.phone == '—' ? '' : user.phone,
    );
    final ageCtrl = TextEditingController(
      text: user.age <= 0 ? '' : user.age.toString(),
    );
    final bloodTypeCtrl = TextEditingController(
      text: user.bloodType == '—' ? '' : user.bloodType,
    );
    final heightCtrl = TextEditingController(
      text: user.height == '—' ? '' : user.height,
    );
    final hba1cCtrl = TextEditingController(
      text: user.hba1c == '—' ? '' : user.hba1c,
    );
    final bpAvgCtrl = TextEditingController(
      text: user.bpAvg == '—' ? '' : user.bpAvg,
    );
    final weightCtrl = TextEditingController(
      text: user.weight == '—' ? '' : user.weight,
    );
    final allergiesCtrl = TextEditingController(
      text: user.allergies.join(', '),
    );
    final emergencyNameCtrl = TextEditingController(
      text: user.emergencyContact.name == '—' ? '' : user.emergencyContact.name,
    );
    final emergencyRelationCtrl = TextEditingController(
      text: user.emergencyContact.relation == '—'
          ? ''
          : user.emergencyContact.relation,
    );
    final emergencyPhoneCtrl = TextEditingController(
      text: user.emergencyContact.phone == '—'
          ? ''
          : user.emergencyContact.phone,
    );
    final saving = ValueNotifier(false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> saveProfile() async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ref.read(toastProvider.notifier).show('Name is required');
                return;
              }
              if (saving.value) return;
              setModalState(() => saving.value = true);
              try {
                await ref
                    .read(userProfileEditorProvider.notifier)
                    .save(
                      user,
                      name: name,
                      phone: phoneCtrl.text.trim(),
                      age: int.tryParse(ageCtrl.text.trim()) ?? 0,
                      bloodType: bloodTypeCtrl.text.trim().isEmpty
                          ? '—'
                          : bloodTypeCtrl.text.trim(),
                      height: heightCtrl.text.trim().isEmpty
                          ? '—'
                          : heightCtrl.text.trim(),
                      hba1c: hba1cCtrl.text.trim().isEmpty
                          ? '—'
                          : hba1cCtrl.text.trim(),
                      bpAvg: bpAvgCtrl.text.trim().isEmpty
                          ? '—'
                          : bpAvgCtrl.text.trim(),
                      weight: weightCtrl.text.trim().isEmpty
                          ? '—'
                          : weightCtrl.text.trim(),
                      allergies: allergiesCtrl.text
                          .split(',')
                          .map((v) => v.trim())
                          .where((v) => v.isNotEmpty)
                          .toList(),
                      emergencyName: emergencyNameCtrl.text.trim().isEmpty
                          ? '—'
                          : emergencyNameCtrl.text.trim(),
                      emergencyRelation:
                          emergencyRelationCtrl.text.trim().isEmpty
                          ? '—'
                          : emergencyRelationCtrl.text.trim(),
                      emergencyPhone: emergencyPhoneCtrl.text.trim().isEmpty
                          ? '—'
                          : emergencyPhoneCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                ref.read(toastProvider.notifier).show('Profile saved');
              } catch (e, st) {
                debugPrint('[Care+][Profile] save failed: $e\n$st');
                ref.read(toastProvider.notifier).show('Could not save profile');
              } finally {
                setModalState(() => saving.value = false);
              }
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: slate900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InputField(controller: nameCtrl, label: 'Full name'),
                  _InputField(
                    controller: phoneCtrl,
                    label: 'Phone number',
                    keyboardType: TextInputType.phone,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: ageCtrl,
                          label: 'Age',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InputField(
                          controller: bloodTypeCtrl,
                          label: 'Blood type',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: heightCtrl,
                          label: 'Height',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InputField(
                          controller: weightCtrl,
                          label: 'Weight',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: hba1cCtrl,
                          label: 'HbA1c',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InputField(
                          controller: bpAvgCtrl,
                          label: 'BP average',
                        ),
                      ),
                    ],
                  ),
                  _InputField(
                    controller: allergiesCtrl,
                    label: 'Allergies (comma separated)',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Emergency contact',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: slate900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InputField(controller: emergencyNameCtrl, label: 'Name'),
                  Row(
                    children: [
                      Expanded(
                        child: _InputField(
                          controller: emergencyRelationCtrl,
                          label: 'Relation',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InputField(
                          controller: emergencyPhoneCtrl,
                          label: 'Phone',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: saving.value ? null : saveProfile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: teal600,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        saving.value ? 'Saving...' : 'Save profile',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      ageCtrl.dispose();
      bloodTypeCtrl.dispose();
      heightCtrl.dispose();
      hba1cCtrl.dispose();
      bpAvgCtrl.dispose();
      weightCtrl.dispose();
      allergiesCtrl.dispose();
      emergencyNameCtrl.dispose();
      emergencyRelationCtrl.dispose();
      emergencyPhoneCtrl.dispose();
      saving.dispose();
    });
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: teal700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: slate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: slate200),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: teal100,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: slate700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
