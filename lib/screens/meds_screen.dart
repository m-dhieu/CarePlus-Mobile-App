import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class MedsScreen extends ConsumerWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void toast(String msg) => ref.read(toastProvider.notifier).show(msg);
    void back() => ref.read(screenProvider.notifier).go('home');

    final meds = ref.watch(medicationsProvider);
    final reminders = ref.watch(remindersProvider);
    final schedule = _buildSchedule(meds, reminders);
    final enabledCount = reminders.where((r) => r.enabled).length;
    final adherence = meds.isEmpty
        ? 0.0
        : ((enabledCount / max(meds.length, 1)).clamp(0.0, 1.0));

    return Column(
      children: [
        TopBar(
          title: 'Medications',
          onBack: back,
          rightIcon: Icons.add,
          onRight: () => _showAddDialog(context, ref, toast),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(64, 64),
                              painter: _RingPainter(progress: adherence),
                            ),
                            Text(
                              '${(adherence * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REMINDERS',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1,
                                color: teal100,
                              ),
                            ),
                            Text(
                              meds.isEmpty
                                  ? 'Add your first med'
                                  : '$enabledCount of ${meds.length} covered',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              reminders.isEmpty
                                  ? 'Create reminders so doses stay on time.'
                                  : 'Your schedule syncs with your account.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFCCFBF1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Today's schedule",
                  style: TextStyle(fontWeight: FontWeight.w800, color: slate900),
                ),
                const SizedBox(height: 8),
                if (schedule.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No schedule yet. Add a medication and reminder.',
                      style: TextStyle(fontSize: 13, color: slate400),
                    ),
                  )
                else
                  ...schedule.map((block) {
                    final items =
                        (block['items'] as List).cast<Map<String, String>>();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: teal100),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: block['label'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: slate900,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '  ${block['time']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: slate400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${items.length} dose${items.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: slate400,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: slate100, height: 16),
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const IconCircle(icon: Icons.medication),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name']!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: slate900,
                                          ),
                                        ),
                                        Text(
                                          item['detail']!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: slate400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: teal50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item['status']!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: teal700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                const Text(
                  'All prescriptions',
                  style: TextStyle(fontWeight: FontWeight.w800, color: slate900),
                ),
                const SizedBox(height: 8),
                if (meds.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No prescriptions yet. Tap + to add one.',
                      style: TextStyle(fontSize: 13, color: slate400),
                    ),
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: meds
                        .map(
                          (med) => Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: teal100),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const IconCircle(icon: Icons.medication),
                                const SizedBox(height: 8),
                                Text(
                                  med.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: slate900,
                                  ),
                                ),
                                Text(
                                  med.condition,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: slate400,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${med.refills} refills',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: slate400,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        await ref
                                            .read(medicationsProvider.notifier)
                                            .requestRefill(med.id);
                                        toast('${med.name} refill requested');
                                      },
                                      child: const Text(
                                        'Request',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: teal600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static List<Map<String, dynamic>> _buildSchedule(
    List<Medication> meds,
    List<Reminder> reminders,
  ) {
    final enabled = reminders.where((r) => r.enabled).toList()
      ..sort((a, b) {
        final am = a.time.hour * 60 + a.time.minute;
        final bm = b.time.hour * 60 + b.time.minute;
        return am.compareTo(bm);
      });
    if (enabled.isEmpty) return const [];

    String period(int hour) {
      if (hour < 12) return 'Morning';
      if (hour < 17) return 'Afternoon';
      return 'Evening';
    }

    final grouped = <String, List<Map<String, String>>>{};
    final times = <String, String>{};
    for (final r in enabled) {
      final key = period(r.time.hour);
      final med = meds.cast<Medication?>().firstWhere(
            (m) => m?.name == r.medicationName,
            orElse: () => null,
          );
      grouped.putIfAbsent(key, () => []);
      times.putIfAbsent(
        key,
        () =>
            '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}',
      );
      grouped[key]!.add({
        'name': r.medicationName,
        'detail': med?.dose ?? 'Scheduled dose',
        'status': 'Scheduled',
      });
    }

    return grouped.entries
        .map(
          (e) => {
            'label': e.key,
            'time': times[e.key],
            'items': e.value,
          },
        )
        .toList();
  }

  void _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    void Function(String) toast,
  ) {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final conditionCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add medication',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: slate900,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: doseCtrl,
              decoration: const InputDecoration(
                labelText: 'Dose (e.g. 500 mg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: conditionCtrl,
              decoration: const InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  await ref.read(medicationsProvider.notifier).add(
                        Medication(
                          id: '',
                          name: name,
                          dose: doseCtrl.text.trim().isEmpty
                              ? '—'
                              : doseCtrl.text.trim(),
                          condition: conditionCtrl.text.trim().isEmpty
                              ? '—'
                              : conditionCtrl.text.trim(),
                          refills: 0,
                        ),
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                  toast('$name saved to your account');
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final bg = Paint()
      ..color = Colors.white24
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final fg = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
