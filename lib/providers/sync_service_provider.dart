import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/sync/services/firestore_sync_service.dart';

final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  return FirestoreSyncService();
});
