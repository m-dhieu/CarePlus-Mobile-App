import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void navigate(String s) => ref.read(screenProvider.notifier).go(s);

    final profile = ref.watch(userProfileProvider);
    final meds = ref.watch(medicationsProvider);
    final reminders = ref.watch(remindersProvider);
    final caregivers = ref.watch(caregiversProvider);
    final journal = ref.watch(journalProvider);
    final metrics = ref.watch(metricsProvider);

    final firstName = profile.name.trim().split(RegExp(r'\s+')).first;
    final todayLabel = _formatToday(DateTime.now());
    final todaysItems = _todaysMedItems(meds, reminders);
    final nextVisit = journal.cast<JournalEntry?>().firstWhere(
          (e) => e?.type == 'Visit',
          orElse: () => null,
        );
    final conditions = meds
        .map((m) => m.condition)
        .where((c) => c.trim().isNotEmpty && c != '—')
        .toSet()
        .take(3)
        .join(' · ');

    final glucose = _metricValue(metrics, 'glucose') ??
        (profile.hba1c != '—' ? profile.hba1c : '—');
    final bp = _metricValue(metrics, 'bp') ??
        (profile.bpAvg != '—' ? profile.bpAvg : '—');
    final weight = profile.weight != '—' ? profile.weight : '—';

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
                    Text(
                      todayLabel,
                      style: TextStyle(fontSize: 11, color: slate400),
                    ),
                    Text(
                      'Hi, $firstName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: slate900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: const Icon(
                  Icons.notifications,
                  size: 16,
                  color: slate700,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => navigate('profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: teal600,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      profile.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HEALTH SCORE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: teal100,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        meds.isEmpty ? 'Add your data' : 'Your records',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      meds.isEmpty ? '—' : '${_healthScore(meds, reminders)}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6, left: 4),
                      child: Text('/100', style: TextStyle(color: teal100)),
                    ),
                  ],
                ),
                Text(
                  conditions.isEmpty
                      ? 'Complete your profile to personalize this view'
                      : conditions,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFCCFBF1)),
                ),
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
                    Text(
                      reminders.isEmpty
                          ? 'No reminders set yet'
                          : '${reminders.where((r) => r.enabled).length} active reminders',
                      style: const TextStyle(fontSize: 11, color: teal100),
                    ),
                    GestureDetector(
                      onTap: () => navigate('metrics'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'View metrics',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: teal700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _MetricCard(
                icon: Icons.water_drop,
                label: 'HbA1c / Glucose',
                value: glucose,
                delta: meds.isEmpty ? '—' : 'live',
              ),
              _MetricCard(
                icon: Icons.favorite,
                label: 'Blood Pressure',
                value: bp,
                delta: meds.isEmpty ? '—' : 'live',
              ),
              _MetricCard(
                icon: Icons.monitor_weight,
                label: 'Weight',
                value: weight,
                delta: '—',
              ),
              _MetricCard(
                icon: Icons.auto_awesome,
                label: 'Medications',
                value: '${meds.length}',
                delta: '+${reminders.where((r) => r.enabled).length}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's medications",
                style: TextStyle(fontWeight: FontWeight.w800, color: slate900),
              ),
              GestureDetector(
                onTap: () => navigate('meds'),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12,
                    color: teal600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (todaysItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No medications yet — add one from Medications.',
                style: TextStyle(fontSize: 13, color: slate400),
              ),
            )
          else
            ...todaysItems.map((m) => _MedItem(med: m)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming visits',
                style: TextStyle(fontWeight: FontWeight.w800, color: slate900),
              ),
              GestureDetector(
                onTap: () => navigate('journal'),
                child: const Text(
                  'Journal',
                  style: TextStyle(
                    fontSize: 12,
                    color: teal600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _VisitCard(entry: nextVisit, onNavigate: () => navigate('journal')),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Care team',
                style: TextStyle(fontWeight: FontWeight.w800, color: slate900),
              ),
              GestureDetector(
                onTap: () => navigate('caregivers'),
                child: const Text(
                  'Manage',
                  style: TextStyle(
                    fontSize: 12,
                    color: teal600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (caregivers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No caregivers yet — invite family from Profile.',
                style: TextStyle(fontSize: 13, color: slate400),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: caregivers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final c = caregivers[i];
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
                        const IconCircle(icon: Icons.people),
                        const SizedBox(height: 8),
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: slate900,
                          ),
                        ),
                        Text(
                          c.relation,
                          style: const TextStyle(fontSize: 11, color: slate400),
                        ),
                        Text(
                          c.role.name,
                          style: const TextStyle(fontSize: 10, color: slate300),
                        ),
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

  static String _formatToday(DateTime d) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  static int _healthScore(List<Medication> meds, List<Reminder> reminders) {
    if (meds.isEmpty) return 0;
    final enabled = reminders.where((r) => r.enabled).length;
    final base = 60 + (meds.length.clamp(0, 4) * 5);
    final bonus = enabled.clamp(0, 4) * 5;
    return (base + bonus).clamp(0, 100);
  }

  static String? _metricValue(Map<String, MetricSeries> metrics, String key) {
    final series = metrics[key];
    if (series == null || series.points.isEmpty) return null;
    final last = series.points.last;
    return '${last.value.toStringAsFixed(0)} ${series.unit}'.trim();
  }

  static List<Map<String, String>> _todaysMedItems(
    List<Medication> meds,
    List<Reminder> reminders,
  ) {
    final enabled = reminders.where((r) => r.enabled).toList()
      ..sort((a, b) {
        final am = a.time.hour * 60 + a.time.minute;
        final bm = b.time.hour * 60 + b.time.minute;
        return am.compareTo(bm);
      });
    if (enabled.isNotEmpty) {
      final now = TimeOfDay.now();
      final nowMins = now.hour * 60 + now.minute;
      return enabled.take(5).map((r) {
        final mins = r.time.hour * 60 + r.time.minute;
        final med = meds.cast<Medication?>().firstWhere(
              (m) => m?.name == r.medicationName,
              orElse: () => null,
            );
        final status = mins < nowMins - 30
            ? 'Taken'
            : mins <= nowMins + 30
                ? 'Due'
                : 'Upcoming';
        return {
          'name': r.medicationName,
          'detail': med?.dose ?? 'Scheduled',
          'time':
              '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}',
          'status': status,
        };
      }).toList();
    }
    return meds
        .take(5)
        .map(
          (m) => {
            'name': m.name,
            'detail': '${m.dose} · ${m.condition}',
            'time': '--:--',
            'status': 'Upcoming',
          },
        )
        .toList();
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

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
  });

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
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: teal50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: teal700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: positive ? teal50 : slate100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  delta,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: positive ? teal600 : slate500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 11, color: slate400)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: slate900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedItem extends StatelessWidget {
  final Map<String, String> med;
  const _MedItem({required this.med});

  @override
  Widget build(BuildContext context) {
    final status = med['status']!;
    Color statusBg;
    Color statusColor;
    if (status == 'Taken') {
      statusBg = teal50;
      statusColor = teal600;
    } else if (status == 'Due') {
      statusBg = const Color(0xFFFFFBEB);
      statusColor = const Color(0xFFD97706);
    } else {
      statusBg = slate100;
      statusColor = slate500;
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
                Text(
                  med['name']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: slate900,
                  ),
                ),
                Text(
                  med['detail']!,
                  style: const TextStyle(fontSize: 11, color: slate400),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                med['time']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: slate900,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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

class _VisitCard extends ConsumerWidget {
  final JournalEntry? entry;
  final VoidCallback onNavigate;
  const _VisitCard({required this.entry, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entry == null) {
      return GestureDetector(
        onTap: onNavigate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: teal100),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'No visits logged yet — add one in your journal.',
            style: TextStyle(fontSize: 13, color: slate400),
          ),
        ),
      );
    }

    final e = entry!;
    final parts = e.date.trim().split(RegExp(r'\s+'));
    final month = parts.isNotEmpty ? parts.first : '—';
    final day = parts.length > 1 ? parts[1] : '';

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: teal600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      month,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      day,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: slate900,
                      ),
                    ),
                    Text(
                      '${e.person} · ${e.facility}',
                      style: const TextStyle(fontSize: 11, color: slate400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onNavigate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: teal600,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                'Open journal',
                textAlign: TextAlign.center,
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
    );
  }
}
