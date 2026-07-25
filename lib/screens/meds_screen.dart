import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class MedsScreen extends ConsumerWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void toast(String msg) => ref.read(toastProvider.notifier).show(msg);
    void back() => ref.read(screenProvider.notifier).go('home');
    return Column(
      children: [
        TopBar(
          title: 'Medications',
          onBack: back,
          rightIcon: Icons.add,
          onRight: () => toast('Adding meds needs a backend connection'),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adherence card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [teal600, teal700], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: teal600.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64, height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(64, 64),
                              painter: _RingPainter(progress: 0.85),
                            ),
                            const Text('85%', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ADHERENCE', style: TextStyle(fontSize: 10, letterSpacing: 1, color: teal100)),
                            Text('Excellent week', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text('26 of 28 doses on time. Keep the streak going.',
                                style: TextStyle(fontSize: 12, color: Color(0xFFCCFBF1))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Today's schedule", style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                ...mockMedsSchedule.map((block) {
                  final items = (block['items'] as List).cast<Map<String, dynamic>>();
                  final taken = items.where((i) => i['status'] != 'Upcoming').length;
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
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: slate900),
                                children: [
                                  TextSpan(
                                    text: '  ${block['time']}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: slate400),
                                  ),
                                ],
                              ),
                            ),
                            Text('$taken/${items.length} taken', style: const TextStyle(fontSize: 12, color: slate400)),
                          ],
                        ),
                        const Divider(color: slate100, height: 16),
                        ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const IconCircle(icon: Icons.medication),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900)),
                                    Text(item['detail']!, style: const TextStyle(fontSize: 11, color: slate400)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: teal50, borderRadius: BorderRadius.circular(20)),
                                child: Text(item['status']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: teal700)),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Text('All prescriptions', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: mockPrescriptions.map((p) => Container(
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
                        Text(p['name']! as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: slate900)),
                        Text(p['condition']! as String, style: const TextStyle(fontSize: 11, color: slate400)),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${p['refills']} refills', style: const TextStyle(fontSize: 11, color: slate400)),
                            GestureDetector(
                              onTap: () => toast('Requesting a ${p['name']} refill needs a backend connection'),
                              child: const Text('Request', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: teal600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
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
    final bg = Paint()..color = Colors.white24..strokeWidth = 6..style = PaintingStyle.stroke;
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
