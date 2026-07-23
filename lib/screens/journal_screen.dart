import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
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
    final entries = _tab == 'All'
        ? mockJournal
        : mockJournal.where((e) => e['type'] == tabToType[_tab]).toList();

    return Column(
      children: [
        TopBar(
          title: 'Treatment Journal',
          onBack: back,
          rightIcon: Icons.add,
          onRight: () => toast('Adding entries needs a backend connection'),
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
                      _Stat(value: '45', label: 'Visits'),
                      _Stat(value: '3', label: 'Hospitals'),
                      _Stat(value: '6', label: 'Years tracked'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: journalTabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final t = journalTabs[i];
                      final active = _tab == t;
                      return GestureDetector(
                        onTap: () => setState(() => _tab = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? teal600 : Colors.transparent,
                            border: active ? null : Border.all(color: slate200),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: active ? Colors.white : slate500)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Positioned(
                      left: 19,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 1, color: teal100),
                    ),
                    Column(
                      children: entries.asMap().entries.map((entry) {
                        final e = entry.value;
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
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: teal50,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: teal100),
                                      ),
                                      child: Icon(e['icon'] as IconData, size: 16, color: teal700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(e['date'] as String,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 9, color: slate400, height: 1.2)),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text((e['type'] as String).toUpperCase(),
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: teal700, letterSpacing: 0.5)),
                                          Text(e['facility'] as String,
                                              style: const TextStyle(fontSize: 10, color: slate400)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(e['title'] as String,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: slate900)),
                                      Text(e['person'] as String,
                                          style: const TextStyle(fontSize: 11, color: slate400)),
                                      const SizedBox(height: 8),
                                      Text(e['note'] as String,
                                          style: const TextStyle(fontSize: 12, color: slate700, height: 1.5)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: (e['tags'] as List<String>)
                                            .map((t) => TagChip(label: t))
                                            .toList(),
                                      ),
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
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: slate900)),
        Text(label, style: const TextStyle(fontSize: 11, color: slate400)),
      ],
    );
  }
}
