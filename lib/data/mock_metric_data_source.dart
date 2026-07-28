import '../models/models.dart';
import 'metric_data_source.dart';

class MockMetricDataSource
    implements MetricDataSource {

  final Map<String, MetricSeries> _metrics = {

    'glucose': MetricSeries(
      label: 'Glucose',
      unit: 'mg/dL',
      points: [
        MetricPoint(
          date: DateTime(2026, 6, 1),
          value: 120,
        ),
        MetricPoint(
          date: DateTime(2026, 6, 8),
          value: 115,
        ),
        MetricPoint(
          date: DateTime(2026, 6, 15),
          value: 110,
        ),
      ],
    ),

    'bp_sys': MetricSeries(
      label: 'Systolic BP',
      unit: 'mmHg',
      points: [
        MetricPoint(
          date: DateTime(2026, 6, 1),
          value: 128,
        ),
        MetricPoint(
          date: DateTime(2026, 6, 8),
          value: 124,
        ),
      ],
    ),

    'bp_dia': MetricSeries(
      label: 'Diastolic BP',
      unit: 'mmHg',
      points: [
        MetricPoint(
          date: DateTime(2026, 6, 1),
          value: 82,
        ),
        MetricPoint(
          date: DateTime(2026, 6, 8),
          value: 80,
        ),
      ],
    ),

    'hr': MetricSeries(
      label: 'Heart Rate',
      unit: 'bpm',
      points: [
        MetricPoint(
          date: DateTime(2026, 6, 1),
          value: 72,
        ),
        MetricPoint(
          date: DateTime(2026, 6, 8),
          value: 75,
        ),
      ],
    ),

    'weight': MetricSeries(
      label: 'Weight',
      unit: 'kg',
      points: [
        MetricPoint(
          date: DateTime(2026, 6, 1),
          value: 78,
        ),
        MetricPoint(
          date: DateTime(2026, 6, 8),
          value: 77.5,
        ),
      ],
    ),

    'hba1c': MetricSeries(
      label: 'HbA1c',
      unit: '%',
      points: [
        MetricPoint(
          date: DateTime(2026, 6, 1),
          value: 7.1,
        ),
        MetricPoint(
          date: DateTime(2026, 6, 15),
          value: 6.8,
        ),
      ],
    ),

  };

  Future<Map<String, MetricSeries>> getMetrics() async {
    return _metrics;
  }

  Future<void> addMetric(
    String key,
    MetricPoint point,
  ) async {
    final existing = _metrics[key];
    if (existing == null) return;
    _metrics[key] = existing.copyWith(
      points: [
        ...existing.points,
        point,
      ],
    );
  }
}

class MetricDataSource {
}

