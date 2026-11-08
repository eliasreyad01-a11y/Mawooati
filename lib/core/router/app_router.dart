import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/motion/app_motion.dart';
import 'package:mawoonati/core/sections.dart';
import 'package:mawoonati/core/settings/settings_provider.dart';
import 'package:mawoonati/core/session/session_gate.dart';
import 'package:mawoonati/features/alerts/alerts_screen.dart';
import 'package:mawoonati/features/ai/meal_planner_screen.dart';
import 'package:mawoonati/features/ai/recipes_screen.dart';
import 'package:mawoonati/features/family/backup_screen.dart';
import 'package:mawoonati/features/family/family_screen.dart';
import 'package:mawoonati/features/inventory/barcode_screen.dart';
import 'package:mawoonati/features/inventory/consumption_screen.dart';
import 'package:mawoonati/features/inventory/storage_screen.dart';
import 'package:mawoonati/features/inventory/waste_screen.dart';
import 'package:mawoonati/features/money/budget_screen.dart';
import 'package:mawoonati/features/money/invoices_screen.dart';
import 'package:mawoonati/features/money/prices_screen.dart';
import 'package:mawoonati/features/money/reports_screen.dart';
import 'package:mawoonati/features/money/shopping_screen.dart';
import 'package:mawoonati/features/notes/notes_screen.dart';
import 'package:mawoonati/features/notes/reminders_screen.dart';
import 'package:mawoonati/features/auth/forgot_password_screen.dart';
import 'package:mawoonati/features/auth/login_screen.dart';
import 'package:mawoonati/features/auth/signup_screen.dart';
import 'package:mawoonati/features/household/setup_household_screen.dart';
import 'package:mawoonati/features/session/loading_screen.dart';
import 'package:mawoonati/features/common/coming_soon_screen.dart';
import 'package:mawoonati/features/home/home_screen.dart';
import 'package:mawoonati/features/inventory/inventory_screen.dart';
import 'package:mawoonati/features/more/more_screen.dart';
import 'package:mawoonati/features/settings/settings_screen.dart';
import 'package:mawoonati/features/shell/app_shell.dart';
import 'package:mawoonati/features/splash/splash_screen.dart';

/// انتقال Fade + Slide قصير؛ يصبح فورياً عند تقليل الحركة.
CustomTransitionPage<void> _page(Ref ref, GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.normal,
    reverseTransitionDuration: AppMotion.normal,
    transitionsBuilder: (context, animation, secondary, child) {
      if (ref.read(settingsProvider).reduceMotion ||
          MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      final curved = CurvedAnimation(parent: animation, curve: AppMotion.standard);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

const _authPaths = {'/login', '/signup', '/forgot'};

/// منطق التوجيه حسب حالة الجلسة. شاشة البداية ('/') لا تُعاد توجيهها.
String? sessionRedirect(SessionGate g, String loc) {
  if (loc == '/') return null;
  // تسجيل الدخول اختياري: الزائر يستخدم التطبيق بدون حساب.
  if (!g.signedIn) return null;
  if (g.hasHousehold == null) return loc == '/loading' ? null : '/loading';
  if (!g.hasHousehold!) return loc == '/setup' ? null : '/setup';
  if (_authPaths.contains(loc) || loc == '/setup' || loc == '/loading') return '/home';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final gate = ref.watch(sessionGateProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: gate,
    redirect: (context, state) => sessionRedirect(gate, state.matchedLocation),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupHouseholdScreen()),
      GoRoute(path: '/loading', builder: (_, __) => const LoadingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/barcode', builder: (_, __) => const BarcodeScreen()),
      GoRoute(path: '/consumption', builder: (_, __) => const ConsumptionScreen()),
      GoRoute(path: '/storage', builder: (_, __) => const StorageScreen()),
      GoRoute(path: '/waste', builder: (_, __) => const WasteScreen()),
      GoRoute(path: '/invoices', builder: (_, __) => const InvoicesScreen()),
      GoRoute(path: '/shopping/daily', builder: (_, __) => const ShoppingScreen(period: 'daily')),
      GoRoute(path: '/shopping/monthly', builder: (_, __) => const ShoppingScreen(period: 'monthly')),
      GoRoute(path: '/budget', builder: (_, __) => const BudgetScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(path: '/prices', builder: (_, __) => const PricesScreen()),
      GoRoute(path: '/notes', builder: (_, __) => const NotesScreen()),
      GoRoute(path: '/reminders', builder: (_, __) => const RemindersScreen()),
      GoRoute(path: '/recipes', builder: (_, __) => const RecipesScreen()),
      GoRoute(path: '/meals', builder: (_, __) => const MealPlannerScreen()),
      GoRoute(path: '/family', builder: (_, __) => const FamilyScreen()),
      GoRoute(path: '/backup', builder: (_, __) => const BackupScreen()),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => _page(ref, state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/coming/:id',
        pageBuilder: (_, state) => _page(
          ref,
          state,
          ComingSoonScreen(section: sectionById(state.pathParameters['id']!)),
        ),
      ),
    ],
  );
});
