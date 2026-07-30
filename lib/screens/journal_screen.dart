import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/journal_constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  String _tab = 'All';

  @override
  Widget build(BuildContext context) {
    void toast(String msg) => ref.read(toastProvider.notifier).show(msg);
    void back() => ref.read(screenProvider.notifier).go('home');
    final all = ref.watch(journalProvider);
    final entries = _tab == 'All'
        ? all
        : all.where((e) => e.type == tabToType[_tab]).toList();

    return Column(
      children: [
        TopBar(
          title: 'Treatment Journal',
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF99F6E4)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat(value: '${all.length}', label: 'Entries'),
                      _Stat(
                        value: '${all.where((e) => e.type == 'Visit').length}',
                        label: 'Visits',
                      ),
                      _Stat(
                        value: '${all.map((e) => e.facility).toSet().length}',
                        label: 'Facilities',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: journalTabs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final t = journalTabs[i];
                      final active = _tab == t;
                      return GestureDetector(
                        onTap: () => setState(() => _tab = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: active ? teal600 : Colors.transparent,
                            border: active ? null : Border.all(color: slate200),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : slate500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No journal entries yet',
                        style: TextStyle(color: slate400),
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      Positioned(
                        left: 19,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 1, color: teal100),
                      ),
                      Column(
                        children: entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: teal50,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: teal100),
                                        ),
                                        child: Icon(
                                          e.icon,
                                          size: 16,
                                          color: teal700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.date,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: slate400,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: teal100),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              e.type.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: teal700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                e.facility,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: slate400,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          e.title,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: slate900,
                                          ),
                                        ),
                                        Text(
                                          e.person,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: slate400,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          e.note,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: slate700,
                                            height: 1.5,
                                          ),
                                        ),
                                        if (e.tags.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            children: e.tags
                                                .map((t) => TagChip(label: t))
                                                .toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    void Function(String) toast,
  ) {
    final titleCtrl = TextEditingController();
    final facilityCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'Visit';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New journal entry',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: slate900,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Visit', child: Text('Visit')),
                    DropdownMenuItem(value: 'Lab', child: Text('Lab')),
                    DropdownMenuItem(
                      value: 'Prescription',
                      child: Text('Prescription'),
                    ),
                    DropdownMenuItem(
                      value: 'Procedure',
                      child: Text('Procedure'),
                    ),
                  ],
                  onChanged: (v) => setS(() => type = v ?? type),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: facilityCtrl,
                  decoration: InputDecoration(
                    labelText: 'Facility',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: personCtrl,
                  decoration: InputDecoration(
                    labelText: 'Doctor / person',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) {
                      toast('Title is required');
                      return;
                    }
                    final now = DateTime.now();
                    final months = [
                      'JAN',
                      'FEB',
                      'MAR',
                      'APR',
                      'MAY',
                      'JUN',
                      'JUL',
                      'AUG',
                      'SEP',
                      'OCT',
                      'NOV',
                      'DEC',
                    ];
                    await ref
                        .read(journalProvider.notifier)
                        .add(
                          JournalEntry(
                            id: now.millisecondsSinceEpoch.toString(),
                            type: type,
                            date:
                                '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]}',
                            facility: facilityCtrl.text.trim().isEmpty
                                ? 'Not specified'
                                : facilityCtrl.text.trim(),
                            title: title,
                            person: personCtrl.text.trim().isEmpty
                                ? '—'
                                : personCtrl.text.trim(),
                            note: noteCtrl.text.trim(),
                            tags: const [],
                            icon: switch (type) {
                              'Lab' => Icons.science,
                              'Prescription' => Icons.medication,
                              'Procedure' => Icons.monitor_heart,
                              _ => Icons.medical_services,
                            },
                          ),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    toast('Journal entry saved');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Save entry',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: slate900,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: slate400)),
      ],
    );
  }
}
