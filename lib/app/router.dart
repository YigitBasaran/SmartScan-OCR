import 'package:go_router/go_router.dart';
import 'package:smartscanocr/features/documents/presentation/screens/document_detail_screen.dart';
import 'package:smartscanocr/features/documents/presentation/screens/library_screen.dart';
import 'package:smartscanocr/features/scanner/presentation/review_launch_action.dart';
import 'package:smartscanocr/features/scanner/presentation/screens/review_screen.dart';
import 'package:smartscanocr/features/settings/presentation/screens/settings_screen.dart';

/// Application routes.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LibraryScreen()),
    GoRoute(
      path: '/review',
      builder: (context, state) {
        final action = state.extra is ReviewLaunchAction
            ? state.extra! as ReviewLaunchAction
            : ReviewLaunchAction.none;
        return ReviewScreen(launchAction: action);
      },
    ),
    GoRoute(
      path: '/document/:id',
      builder: (context, state) =>
          DocumentDetailScreen(documentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
