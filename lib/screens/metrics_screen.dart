import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

class MetricsScreen extends ConsumerWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsProvider);
    void back() => ref.read(screenProvider.notifier).go('profile');

    final keys = ['glucose', 'bp_sys', 'bp_dia', 'hr', 'weight', 'hba1c'];

    return Column(
      children: [
        TopBar(title: 'Health Metrics', onBack: back, rightIcon: Icons.download_outlined,
            onRight: () => ref.read(toastProvider.notifier).show('Export needs a backend connection')),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: keys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) {
              final series = metrics[keys[i]]!;
              return _MetricCard(series: series);
            },
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final MetricSeries series;
  const _MetricCard({required this.series});

  @override
  Widget build(BuildContext context) {
    final latest = series.latest;
    final min = series.min;
    final max = series.max;

    return Container(
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
              Text(series.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: slate900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: teal50, borderRadius: BorderRadius.circular(20)),
                child: Text('${latest.toStringAsFixed(latest % 1 == 0 ? 0 : 1)} ${series.unit}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: teal700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _LinePainter(points: series.points, min: min, max: max),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Min: ${min.toStringAsFixed(min % 1 == 0 ? 0 : 1)} ${series.unit}',
                  style: const TextStyle(fontSize: 11, color: slate400)),
              Text('Max: ${max.toStringAsFixed(max % 1 == 0 ? 0 : 1)} ${series.unit}',
                  style: const TextStyle(fontSize: 11, color: slate400)),
              Text('${series.points.length} weeks', style: const TextStyle(fontSize: 11, color: slate400)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<MetricPoint> points;
  final double min;
  final double max;
  const _LinePainter({required this.points, required this.min, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final range = (max - min).abs();
    final effectiveRange = range < 0.001 ? 1.0 : range;

    final linePaint = Paint()
      ..color = teal600
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = teal600..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final y = size.height - ((points[i].value - min) / effectiveRange) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw last point dot
    final lastX = size.width;
    final lastY = size.height - ((points.last.value - min) / effectiveRange) * size.height;
    canvas.drawCircle(Offset(lastX, lastY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
