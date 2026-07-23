import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    void back() => ref.read(screenProvider.notifier).go('profile');

    return Column(
      children: [
        TopBar(
          title: 'Reminders',
          onBack: back,
          rightIcon: Icons.add,
          onRight: () => _showAddDialog(context, ref),
        ),
        Expanded(
          child: reminders.isEmpty
              ? const Center(child: Text('No reminders yet', style: TextStyle(color: slate400)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: reminders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ReminderCard(reminder: reminders[i]),
                ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final meds = ref.read(medicationsProvider);
    String selected = meds.first.name;
    TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);
    final days = List.filled(7, true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: slate900)),
              const SizedBox(height: 20),
              const Text('Medication', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: teal700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: slate200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: meds.map((m) => DropdownMenuItem(value: m.name, child: Text(m.name))).toList(),
                onChanged: (v) => setS(() => selected = v!),
              ),
              const SizedBox(height: 16),
              const Text('Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: teal700)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: time);
                  if (picked != null) setS(() => time = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: slate200), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: teal600),
                      const SizedBox(width: 8),
                      Text(time.format(ctx), style: const TextStyle(fontWeight: FontWeight.w700, color: slate900)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: teal700)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return GestureDetector(
                    onTap: () => setS(() => days[i] = !days[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: days[i] ? teal600 : teal50,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(labels[i],
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                color: days[i] ? Colors.white : teal700)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  ref.read(remindersProvider.notifier).add(Reminder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    medicationName: selected,
                    time: time,
                    days: List.from(days),
                  ));
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: teal600, borderRadius: BorderRadius.circular(50)),
                  child: const Text('Save reminder', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: reminder.enabled ? teal100 : slate200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: reminder.enabled ? teal50 : slate100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication, size: 20, color: reminder.enabled ? teal600 : slate400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.medicationName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: slate900)),
                Text(reminder.time.format(context),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: reminder.enabled ? teal600 : slate400)),
                Text(reminder.daysLabel, style: const TextStyle(fontSize: 11, color: slate400)),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: reminder.enabled,
                activeThumbColor: teal600,
                onChanged: (_) => ref.read(remindersProvider.notifier).toggle(reminder.id),
              ),
              GestureDetector(
                onTap: () => ref.read(remindersProvider.notifier).remove(reminder.id),
                child: const Icon(Icons.delete_outline, size: 18, color: slate400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
