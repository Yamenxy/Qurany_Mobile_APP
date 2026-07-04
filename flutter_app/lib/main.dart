import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';



import 'config/theme.dart';

import 'config/routes.dart';

import 'config/constants.dart';

import 'services/auth_service.dart';

import 'services/quran_service.dart';

import 'services/bookmark_service.dart';

import 'services/recitation_history_service.dart';

import 'services/recitation_api_service.dart';

import 'services/schedule_service.dart';

import 'services/notification_service.dart';

import 'services/learning_plan_service.dart';

import 'services/khatmah_service.dart';

import 'services/al_bazzi_service.dart';
import 'services/qiraat_service.dart';

import 'services/prayer_times_service.dart';

import 'services/tafsir_service.dart';



void main() async {

  WidgetsFlutterBinding.ensureInitialized();



  await SystemChrome.setPreferredOrientations([

    DeviceOrientation.portraitUp,

    DeviceOrientation.portraitDown,

  ]);



  final prefs = await SharedPreferences.getInstance();

  // Analysis-server address saved from Settings (LAN IPs change per network,
  // so this must be editable at runtime, not just at build time).
  AppConstants.recitationApiUserOverride =
      prefs.getString(AppConstants.recitationApiPrefsKey);



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

        ChangeNotifierProvider(create: (_) => TafsirService()),

        ChangeNotifierProvider(create: (_) => BookmarkService(prefs)),

        ChangeNotifierProvider(create: (_) => RecitationHistoryService(prefs)),

        ChangeNotifierProvider(create: (_) => ScheduleService(prefs)),

        ChangeNotifierProvider(create: (_) => LearningPlanService(prefs)),

        ChangeNotifierProvider(create: (_) => KhatmahService(prefs)),

        ChangeNotifierProvider(create: (_) => QiraatService(prefs)),

        ChangeNotifierProvider(create: (_) => PrayerTimesService(prefs)),

        Provider(create: (_) => AlBazziService()),

        Provider(

          create: (_) => RecitationApiService(),

          dispose: (_, service) => service.dispose(),

        ),

      ],

      child: MaterialApp(

        title: 'Qurany',

        debugShowCheckedModeBanner: false,

        locale: const Locale('ar'),

        supportedLocales: const [Locale('ar')],

        localizationsDelegates: const [

          GlobalMaterialLocalizations.delegate,

          GlobalWidgetsLocalizations.delegate,

          GlobalCupertinoLocalizations.delegate,

        ],

        theme: QuranyTheme.lightTheme,

        darkTheme: QuranyTheme.darkTheme,

        themeMode: ThemeMode.light,

        initialRoute: AppRoutes.splash,

        onGenerateRoute: AppRoutes.generateRoute,

        builder: (context, child) => Directionality(

          textDirection: TextDirection.rtl,

          child: child!,

        ),

      ),

    );

  }

}

