import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'services/auth_service.dart';
import 'services/quran_service.dart';
import 'services/bookmark_service.dart';
import 'services/recitation_history_service.dart';
import 'services/schedule_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

  // Initialize notification service
  await NotificationService().initialize();

  runApp(QuranyApp(prefs: prefs));
}

class QuranyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const QuranyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(prefs)),
        ChangeNotifierProvider(create: (_) => QuranService()),
        ChangeNotifierProvider(create: (_) => BookmarkService(prefs)),
        ChangeNotifierProvider(create: (_) => RecitationHistoryService(prefs)),
        ChangeNotifierProvider(create: (_) => ScheduleService(prefs)),
      ],
      child: MaterialApp(
        title: 'Qurany',
        debugShowCheckedModeBanner: false,
        theme: QuranyTheme.lightTheme,
        darkTheme: QuranyTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
      ),
    );
  }
}
