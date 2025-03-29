import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:orbit_defender/ui/menu_screen.dart';
import 'package:orbit_defender/ui/splash_screen.dart';

import 'firebase_options.dart';
import 'services/push_notification_service.dart';

void main() async {
  // Garante que os widgets Flutter estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa o Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  runApp(MyApp(analytics: analytics));
}

class MyApp extends StatefulWidget {
  final FirebaseAnalytics analytics;

  const MyApp({Key? key, required this.analytics}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _pushNotificationService = PushNotificationService();
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    // Adiciona observer para detectar mudanças no estado do app
    WidgetsBinding.instance.addObserver(this);

    // Inicializamos o serviço de notificações após o primeiro frame
    // para garantir que temos um BuildContext válido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await _pushNotificationService.initialize(context);

    await _updateToken();
  }

  // Este método é chamado quando o estado do app muda (background, foreground, etc)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Quando o app retorna do background para o foreground
      _updateToken();
    }
  }

  // Método para atualizar o token e enviá-lo para o backend se necessário
  Future<void> _updateToken() async {
    String? token = await _pushNotificationService.getToken();

    // Só atualiza se o token for diferente do anterior
    if (token != null && token != _fcmToken) {
      setState(() {
        _fcmToken = token;
      });

      print('FCM Token atualizado: $token');
      await _pushNotificationService.subscribeToTopic('all_users');

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        await _pushNotificationService.subscribeToTopic('ios_users');
      } else if (Theme.of(context).platform == TargetPlatform.android) {
        await _pushNotificationService.subscribeToTopic('android_users');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: widget.analytics);

    return MaterialApp(
      title: 'Orbit Defender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Orbitron',
      ),
      home: SplashScreen(nextScreen: const MenuScreen()),
      navigatorObservers: [observer],
    );
  }
}
