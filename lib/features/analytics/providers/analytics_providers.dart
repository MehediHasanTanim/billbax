import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder — implemented in Phase 4.
final selectedAnalyticsYearProvider = StateProvider<int>(
  (ref) => DateTime.now().year,
);
