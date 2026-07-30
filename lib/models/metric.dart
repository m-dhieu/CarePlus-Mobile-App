// metric model

class MetricPoint {
  final DateTime date;
  final double value;
  const MetricPoint({
    required this.date,
    required this.value,
  });
  factory MetricPoint.fromMap(
    Map<String, dynamic> map,
  ) {
    return MetricPoint(
      date: DateTime.parse(
        map['date'],
      ),
      value: (map['value'] ?? 0).toDouble(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'value': value,
    };
  }
}

class MetricSeries {
  final String label;
  final String unit;
  final List<MetricPoint> points;
  const MetricSeries({
    required this.label,
    required this.unit,
    required this.points,
  });
  double get latest =>
      points.isEmpty
          ? 0
          : points.last.value;
  double get min =>
      points.isEmpty
          ? 0
          : points
              .map((p) => p.value)
              .reduce(
                (a, b) => a < b ? a : b,
              );
  double get max =>
      points.isEmpty
          ? 0
          : points
              .map((p) => p.value)
              .reduce(
                (a, b) => a > b ? a : b,
              );
  MetricSeries copyWith({
    String? label,
    String? unit,
    List<MetricPoint>? points,
  }) {
    return MetricSeries(
      label: label ?? this.label,
      unit: unit ?? this.unit,
      points: points ?? this.points,
    );
  }
  factory MetricSeries.fromMap(
    Map<String, dynamic> map,
  ) {
    return MetricSeries(
      label: map['label'] ?? '',
      unit: map['unit'] ?? '',
      points:
          (map['points'] as List<dynamic>? ?? [])
              .map(
                (e) => MetricPoint.fromMap(e),
              )
              .toList(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'unit': unit,
      'points': points
          .map(
            (p) => p.toMap(),
          )
          .toList(),
    };
  }
}

