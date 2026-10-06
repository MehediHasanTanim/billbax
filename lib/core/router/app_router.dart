import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/bills/data/models/bill_account.dart';
import '../../features/bills/presentation/screens/add_bill_screen.dart';
import '../../features/bills/presentation/screens/bill_detail_screen.dart';
import '../../features/bills/presentation/screens/home_screen.dart';
import '../../features/payments/presentation/screens/payment_history_screen.dart';
import '../../features/payments/presentation/screens/payment_redirect_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/add-bill',
        builder: (_, state) => AddBillScreen(
          existingAccount: state.extra as BillAccount?,
        ),
      ),
      GoRoute(
        path: '/bill/:id',
        builder: (_, state) =>
            BillDetailScreen(billId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/pay/:billId',
        builder: (_, state) => PaymentRedirectScreen(
          billId: state.pathParameters['billId']!,
        ),
      ),
      GoRoute(
        path: '/history/:billId',
        builder: (_, state) => PaymentHistoryScreen(
          billId: state.pathParameters['billId']!,
        ),
      ),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return OtpScreen(
            phone: extra['phone'] ?? '',
            verificationId: extra['verificationId'] ?? '',
          );
        },
      ),
    ],
  );
});
