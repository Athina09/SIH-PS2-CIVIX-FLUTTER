// Ported from src/App.tsx route tree.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import '../screens/landing/landing_screen.dart';
import '../screens/landing/login_screen.dart';
import '../screens/landing/role_login_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/project/public_project_screen.dart';
import '../screens/citizen/citizen_shell.dart';
import '../screens/citizen/citizen_home_screen.dart';
import '../screens/citizen/report_wizard_screen.dart';
import '../screens/citizen/channel_simulators_screen.dart';
import '../screens/citizen/village_wall_screen.dart';
import '../screens/citizen/issue_detail_screen.dart';
import '../screens/citizen/my_reports_screen.dart';
import '../screens/citizen/scan_qr_screen.dart';
import '../screens/government/gov_shell.dart';
import '../screens/government/control_room_screen.dart';
import '../screens/government/inbox_screen.dart';
import '../screens/government/duplicate_merger_screen.dart';
import '../screens/government/issue_workbench_screen.dart';
import '../screens/government/service_twin_board_screen.dart';
import '../screens/government/systemic_challenges_screen.dart';
import '../screens/government/equity_screen.dart';
import '../screens/government/project_portfolio_screen.dart';
import '../screens/government/capability_gaps_screen.dart';
import '../screens/government/audit_log_screen.dart';
import '../screens/university/uni_shell.dart';
import '../screens/university/uni_home_screen.dart';
import '../screens/university/challenge_detail_screen.dart';
import '../screens/university/team_builder_screen.dart';
import '../screens/university/uni_profile_screen.dart';
import '../screens/industry/industry_shell.dart';
import '../screens/industry/opportunities_screen.dart';
import '../screens/industry/industry_portfolio_screen.dart';
import '../screens/council/council_screen.dart';
import '../screens/project/live_project_record_screen.dart';
import '../screens/knowledge/knowledge_graph_screen.dart';
import '../screens/scale/scale_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import 'require_role.dart';

const _guardedPrefixes = {
  '/citizen': 'citizen',
  '/gov': 'government',
  '/uni': 'university',
  '/industry': 'industry',
  '/council': 'council',
};

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      for (final e in _guardedPrefixes.entries) {
        if (path == e.key || path.startsWith('${e.key}/')) {
          return requireRoleRedirect(ref, e.value);
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/login/:role', builder: (context, state) => RoleLoginScreen(role: state.pathParameters['role']!)),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/p/:projectId', builder: (context, state) => PublicProjectScreen(projectId: state.pathParameters['projectId']!)),

      ShellRoute(
        builder: (context, state, child) => CitizenShell(child: child),
        routes: [
          GoRoute(path: '/citizen', builder: (c, s) => const CitizenHomeScreen()),
          GoRoute(path: '/citizen/report', builder: (c, s) => const ReportWizardScreen()),
          GoRoute(path: '/citizen/channels', builder: (c, s) => const ChannelSimulatorsScreen()),
          GoRoute(path: '/citizen/wall', builder: (c, s) => const VillageWallScreen()),
          GoRoute(path: '/citizen/wall/:issueId', builder: (c, s) => IssueDetailScreen(issueId: s.pathParameters['issueId']!)),
          GoRoute(path: '/citizen/my-reports', builder: (c, s) => const MyReportsScreen()),
          GoRoute(path: '/citizen/scan', builder: (c, s) => const ScanQRScreen()),
        ],
      ),

      ShellRoute(
        builder: (context, state, child) => GovShell(child: child),
        routes: [
          GoRoute(path: '/gov', builder: (c, s) => const ControlRoomScreen()),
          GoRoute(path: '/gov/inbox', builder: (c, s) => const InboxScreen()),
          GoRoute(path: '/gov/duplicates', builder: (c, s) => const DuplicateMergerScreen()),
          GoRoute(path: '/gov/issues/:id', builder: (c, s) => IssueWorkbenchScreen(issueId: s.pathParameters['id']!)),
          GoRoute(path: '/gov/services', builder: (c, s) => const ServiceTwinBoardScreen()),
          GoRoute(path: '/gov/systemic', builder: (c, s) => const SystemicChallengesScreen()),
          GoRoute(path: '/gov/equity', builder: (c, s) => const EquityScreen()),
          GoRoute(path: '/gov/projects', builder: (c, s) => const ProjectPortfolioScreen()),
          GoRoute(path: '/gov/capability-gaps', builder: (c, s) => const CapabilityGapsScreen()),
          GoRoute(path: '/gov/audit', builder: (c, s) => const AuditLogScreen()),
        ],
      ),

      ShellRoute(
        builder: (context, state, child) => UniShell(child: child),
        routes: [
          GoRoute(path: '/uni', builder: (c, s) => const UniHomeScreen()),
          GoRoute(path: '/uni/challenges/:id', builder: (c, s) => ChallengeDetailScreen(issueId: s.pathParameters['id']!)),
          GoRoute(path: '/uni/team-builder/:issueId', builder: (c, s) => TeamBuilderScreen(issueId: s.pathParameters['issueId']!)),
          GoRoute(path: '/uni/profile', builder: (c, s) => const UniProfileScreen()),
        ],
      ),

      ShellRoute(
        builder: (context, state, child) => IndustryShell(child: child),
        routes: [
          GoRoute(path: '/industry', builder: (c, s) => const OpportunitiesScreen()),
          GoRoute(path: '/industry/opportunities', builder: (c, s) => const OpportunitiesScreen()),
          GoRoute(path: '/industry/portfolio', builder: (c, s) => const IndustryPortfolioScreen()),
        ],
      ),

      GoRoute(path: '/council', builder: (c, s) => const CouncilScreen()),
      GoRoute(path: '/projects/:id', builder: (c, s) => LiveProjectRecordScreen(projectId: s.pathParameters['id']!)),
      GoRoute(path: '/knowledge', builder: (c, s) => const KnowledgeGraphScreen()),
      GoRoute(path: '/scale', builder: (c, s) => const ScaleScreen()),
      GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen()),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
    ],
    errorBuilder: (context, state) => const _NotFoundScreen(),
  );
});

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('This page does not exist.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => context.go('/'), child: const Text('Back to home')),
          ]),
        ),
      );
}
