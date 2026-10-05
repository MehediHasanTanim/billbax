import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';

/// Placeholder — implemented in Phase 5.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
