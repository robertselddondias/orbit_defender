import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  // Singleton pattern
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Canal para Android
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'Notificações Importantes',
    description: 'Este canal é usado para notificações importantes',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  // Função para processar mensagens em segundo plano
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    print('Mensagem em background: ${message.notification?.title}');
    // O processamento é mínimo, pois o código é executado em um isolate separado
  }

  // Inicializar o serviço
  Future<void> initialize(BuildContext context) async {
    // 1. Configurar handlers
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    // 2. Configurar notificações locais
    await _setupLocalNotifications();

    // 3. Solicitar permissões
    await _requestPermissions();

    // 4. Configurar handlers para diferentes estados do app
    _configureHandlers(context);

    // 5. Verificar se o app foi aberto por notificação
    await _checkInitialMessage(context);
  }

  // Configurar plugin de notificações locais
  Future<void> _setupLocalNotifications() async {
    // Configuração para Android
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuração para iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Inicializar plugin
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Criar canal de notificação para Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // Solicitar permissões
  Future<bool> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    // Para iOS, precisamos de permissões adicionais para notificações locais
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    print('Permissões de notificação: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Configurar handlers para diferentes estados do app
  void _configureHandlers(BuildContext context) {
    // 1. App em foreground (aberto e ativo)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 2. App em background (minimizado) e usuário clica na notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationOpened(message, context);
    });

    // 3. Para notificações locais (apenas para iOS, Android usa o onMessageOpenedApp)
    _localNotifications.getNotificationAppLaunchDetails().then((details) {
      if (details != null && details.didNotificationLaunchApp) {
        _handleLocalNotificationOpened(details.notificationResponse, context);
      }
    });
  }

  // Verificar se o app foi aberto por notificação
  Future<void> _checkInitialMessage(BuildContext context) async {
    // Verificar notificação remota que abriu o app
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpened(initialMessage, context);
    }
  }

  // Processar mensagem recebida com app em foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('Mensagem em foreground recebida: ${message.notification?.title}');

    // Exibir notificação local quando app está aberto
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Nova mensagem',
        body: message.notification!.body ?? '',
        payload: json.encode(message.data),
      );
    }
  }

  // Processar clique em notificação que abre o app
  void _handleNotificationOpened(RemoteMessage message, BuildContext context) {
    print('Notificação aberta pelo usuário: ${message.notification?.title}');

    // Aqui você realiza a navegação com base no payload
    _navigateBasedOnPayload(message.data, context);
  }

  // Processar clique em notificação local
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print('Notificação local clicada: ${response.payload}');

    // Decodificar payload e navegar
    if (response.payload != null) {
      try {
        Map<String, dynamic> data = json.decode(response.payload!);
        // Use o context mais atual disponível para navegação
        // Isso geralmente é feito com um NavigationService global ou um GlobalKey
        // para acesso ao Navigator
      } catch (e) {
        print('Erro ao decodificar payload: $e');
      }
    }
  }

  // Processar clique em notificação local que abriu o app
  void _handleLocalNotificationOpened(NotificationResponse? response, BuildContext context) {
    if (response?.payload != null) {
      try {
        Map<String, dynamic> data = json.decode(response!.payload!);
        _navigateBasedOnPayload(data, context);
      } catch (e) {
        print('Erro ao decodificar payload local: $e');
      }
    }
  }

  // Exibir notificação local
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      styleInformation: const BigTextStyleInformation(''),
    );

    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // ID único
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Navegar para tela específica com base no payload
  void _navigateBasedOnPayload(Map<String, dynamic> data, BuildContext context) {
    // Exemplo de navegação baseada em tipo de notificação
    String? type = data['type'];
    String? id = data['id'];

    if (type == null) return;

    switch (type) {
      case 'chat':
        if (id != null) {
          Navigator.of(context).pushNamed('/chat', arguments: {'chatId': id});
        }
        break;
      case 'order':
        if (id != null) {
          Navigator.of(context).pushNamed('/order-details', arguments: {'orderId': id});
        }
        break;
      case 'promotion':
        Navigator.of(context).pushNamed('/promotions');
        break;
      default:
        Navigator.of(context).pushNamed('/notifications');
    }
  }

  // Obter token FCM
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Assinar tópico para receber notificações específicas
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Cancelar assinatura do tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
