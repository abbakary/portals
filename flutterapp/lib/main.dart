import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/config/app_config.dart';
import 'core/storage/offline_queue.dart';
import 'core/storage/token_store.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/session_controller.dart';
import 'features/inspections/data/inspections_repository.dart';
import 'features/inspections/data/models.dart';
import 'features/inspections/presentation/customer_home_screen.dart';
import 'features/inspections/presentation/inspector_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.current;
  final tokenStore = TokenStore();
  final apiClient = ApiClient(config: config, tokenStore: tokenStore);
  final offlineQueue = await OfflineQueueService.init();

  runApp(AppRoot(
    config: config,
    tokenStore: tokenStore,
    apiClient: apiClient,
    offlineQueue: offlineQueue,
  ));
}

class AppRoot extends StatelessWidget {
  const AppRoot({
    required this.config,
    required this.tokenStore,
    required this.apiClient,
    required this.offlineQueue,
    super.key,
  });

  final AppConfig config;
  final TokenStore tokenStore;
  final ApiClient apiClient;
  final OfflineQueueService offlineQueue;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<TokenStore>.value(value: tokenStore),
        Provider<ApiClient>.value(value: apiClient),
        Provider<OfflineQueueService>.value(value: offlineQueue),
        ProxyProvider2<ApiClient, OfflineQueueService, InspectionsRepository>(
          update: (_, api, queue, __) => InspectionsRepository(apiClient: api, offlineQueueService: queue),
        ),
        ProxyProvider2<ApiClient, TokenStore, AuthRepository>(
          update: (_, api, tokens, __) => AuthRepository(apiClient: api, tokenStore: tokens),
        ),
        ChangeNotifierProvider<SessionController>(
          create: (context) => SessionController(context.read<AuthRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Fleet Inspection',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B5876)),
          useMaterial3: true,
        ),
        home: const _RootNavigator(),
      ),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        if (!session.isAuthenticated) {
          return const LoginScreen();
        }
        final profile = session.profile!;
        if (profile.isInspector) {
          return InspectorHomeScreen(profile: profile);
        }
        if (profile.isCustomer) {
          return CustomerHomeScreen(profile: profile);
        }
        return _UnsupportedRoleScreen(profile: profile);
      },
    );
  }
}

class _UnsupportedRoleScreen extends StatelessWidget {
  const _UnsupportedRoleScreen({required this.profile});

  final PortalProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Inspection')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.desktop_windows_outlined, size: 48),
              const SizedBox(height: 12),
              Text('Hello ${profile.fullName}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Admin features are available on the web portal.\nPlease use the inspector or customer role in the app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<SessionController>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
