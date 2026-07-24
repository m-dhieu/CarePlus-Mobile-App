import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void navigate(String s) => ref.read(screenProvider.notifier).go(s);
    void toast(String msg) => ref.read(toastProvider.notifier).show(msg);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saturday, May 30', style: TextStyle(fontSize: 11, color: slate400)),
                    const Text('Hi, Arnold', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: slate900)),
                  ],
                ),
              ),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                child: const Icon(Icons.notifications, size: 16, color: slate700),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => navigate('profile'),
                child: Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: teal600, shape: BoxShape.circle),
                  child: const Center(child: Text('AM', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Health Score Card
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [teal600, teal700], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: teal600.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('HEALTH SCORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: teal100, letterSpacing: 1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Updated 2h ago', style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('82', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6, left: 4),
                      child: Text('/100', style: TextStyle(color: teal100)),
                    ),
                  ],
                ),
                const Text('Stable · Type 2 Diabetes · Hypertension', style: TextStyle(fontSize: 13, color: Color(0xFFCCFBF1))),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: CustomPaint(painter: _SparklinePainter()),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("You're on a 12-day streak", style: TextStyle(fontSize: 11, color: teal100)),
                    GestureDetector(
                      onTap: () => toast('Vitals logging needs a backend connection'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Log vitals', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: teal700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Metric Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _MetricCard(icon: Icons.water_drop, label: 'Blood Glucose', value: '119 mg/dL', delta: '+4%'),
              _MetricCard(icon: Icons.favorite, label: 'Blood Pressure', value: '125/82 mmHg', delta: '+2'),
              _MetricCard(icon: Icons.monitor_heart, label: 'Resting HR', value: '72 bpm', delta: '-3'),
              _MetricCard(icon: Icons.auto_awesome, label: 'Adherence', value: '95%', delta: '+6'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's medications", style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
              GestureDetector(
                onTap: () => navigate('meds'),
                child: const Text('See all', style: TextStyle(fontSize: 12, color: teal600, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...mockTodaysMeds.map((m) => _MedItem(med: m)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming visits', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
              GestureDetector(
                onTap: () => navigate('journal'),
                child: const Text('Journal', style: TextStyle(fontSize: 12, color: teal600, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _VisitCard(),
          const SizedBox(height: 20),
          const Text('Care team', style: TextStyle(fontWeight: FontWeight.w800, color: slate900)),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mockCareTeam.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final doc = mockCareTeam[i];
                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: teal100),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconCircle(icon: Icons.medical_services),
                      const SizedBox(height: 8),
                      Text(doc['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900)),
                      Text(doc['role']!, style: const TextStyle(fontSize: 11, color: slate400)),
                      Text(doc['hospital']!, style: const TextStyle(fontSize: 10, color: slate300)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white60
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final points = [
      Offset(0, size.height * 0.6),
      Offset(size.width * 0.13, size.height * 0.5),
      Offset(size.width * 0.27, size.height * 0.75),
      Offset(size.width * 0.4, size.height * 0.25),
      Offset(size.width * 0.53, size.height * 0.55),
      Offset(size.width * 0.67, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.45),
      Offset(size.width, size.height * 0.1),
    ];
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String delta;

  const _MetricCard({required this.icon, required this.label, required this.value, required this.delta});

  @override
  Widget build(BuildContext context) {
    final positive = delta.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(12),
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
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(color: teal50, shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: teal700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: positive ? teal50 : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(delta, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: positive ? teal600 : const Color(0xFFE11D48))),
              ),
            ],
          ),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 11, color: slate400)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: slate900)),
        ],
      ),
    );
  }
}

class _MedItem extends StatelessWidget {
  final Map<String, dynamic> med;
  const _MedItem({required this.med});

  @override
  Widget build(BuildContext context) {
    final status = med['status'] as String;
    Color statusBg;
    Color statusColor;
    if (status == 'Taken') {
      statusBg = teal50; statusColor = teal600;
    } else if (status == 'Due') {
      statusBg = const Color(0xFFFFFBEB); statusColor = const Color(0xFFD97706);
    } else {
      statusBg = slate100; statusColor = slate500;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: teal100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const IconCircle(icon: Icons.medication),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900)),
                Text(med['detail']!, style: const TextStyle(fontSize: 11, color: slate400)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(med['time']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: slate900)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends ConsumerWidget {
  const _VisitCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void toast(String msg) => ref.read(toastProvider.notifier).show(msg);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: teal100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: teal600, borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('JUN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    Text('20', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quarterly endocrinology review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: slate900)),
                    Text('Dr. Amara Diallo · 10:30 AM', style: TextStyle(fontSize: 11, color: slate400)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => toast('Connect a backend to prep visit details'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: teal600, borderRadius: BorderRadius.circular(50)),
                    child: const Text('Prepare visit', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => toast('Connect a backend to reschedule'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: teal100),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text('Reschedule', textAlign: TextAlign.center,
                        style: TextStyle(color: teal700, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
