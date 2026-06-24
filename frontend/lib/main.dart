import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'interfaces/i_data_service.dart';
import 'interfaces/i_storage_service.dart';
import 'interfaces/i_profile_repository.dart';
import 'interfaces/i_statistics_repository.dart';
import 'services/api_data_service.dart';
import 'services/storage_service.dart';
import 'repositories/profile_repository.dart';
import 'repositories/statistics_repository.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/statistics_provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Dependency Injection - création des instances (SOLID: Dependency Inversion)
  final IStorageService storageService = StorageService();
  // Branché sur le backend MACEN. Changer baseUrl selon la cible :
  // web/Chrome -> localhost:8000 | émulateur Android -> 10.0.2.2:8000
  final IDataService dataService = ApiDataService(
    baseUrl: 'http://localhost:8000',
  );
  
  // Repositories (Repository Pattern)
  final IProfileRepository profileRepository = ProfileRepository(dataService);
  final IStatisticsRepository statisticsRepository = StatisticsRepository(storageService);
  
  runApp(MyApp(
    storageService: storageService,
    profileRepository: profileRepository,
    statisticsRepository: statisticsRepository,
  ));
}

class MyApp extends StatelessWidget {
  final IStorageService storageService;
  final IProfileRepository profileRepository;
  final IStatisticsRepository statisticsRepository;

  const MyApp({
    super.key,
    required this.storageService,
    required this.profileRepository,
    required this.statisticsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // StatisticsProvider doit être créé en premier car GameProvider en dépend
        ChangeNotifierProvider(
          create: (_) => StatisticsProvider(statisticsRepository)..init(),
        ),
        // GameProvider reçoit ses dépendances via le constructeur
        ChangeNotifierProxyProvider<StatisticsProvider, GameProvider>(
          create: (context) => GameProvider(
            profileRepository,
            context.read<StatisticsProvider>(),
          )..init(),
          update: (context, statisticsProvider, previous) =>
              previous ?? GameProvider(profileRepository, statisticsProvider)..init(),
        ),
        // SettingsProvider reçoit ses dépendances via le constructeur
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService)..init(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) => MaterialApp(
          title: 'LinkedIn ou Interpol',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: child,
        ),
        child: const HomeScreen(),
      ),
    );
  }
}
