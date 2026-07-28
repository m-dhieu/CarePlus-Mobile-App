import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_metric_data_source.dart';
import '../models/models.dart';

final metricDataSourceProvider =
    Provider<MetricDataSource>((ref) {
  return MockMetricDataSource();
});

final metricRepositoryProvider =
    Provider<MetricRepository>((ref) {
  return MetricRepository(
    dataSource:
        ref.read(metricDataSourceProvider),
  );
});

class MetricRepository {
}

class MetricsNotifier
    extends AsyncNotifier<Map<String, MetricSeries>> {
  @override
  Future<Map<String, MetricSeries>> build() async {
    final repository =
        ref.read(metricRepositoryProvider);
    return repository.getMetrics();
  }
  Future<void> addMetric(
    String key,
    MetricPoint point,
  ) async {
    await ref
        .read(metricRepositoryProvider)
        .addMetric(
          key,
          point,
        );
    ref.invalidateSelf();
  }
}

final metricsProvider =
    AsyncNotifierProvider<
        MetricsNotifier,
        Map<String, MetricSeries>>(
          MetricsNotifier.new,
        );

