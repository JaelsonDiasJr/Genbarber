import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:genbarber/firebase_options.dart';
import 'package:genbarber/theme/app_theme.dart';
import 'package:genbarber/core/providers/auth_provider.dart';
import 'package:genbarber/models/models.dart';
import 'package:genbarber/screens/auth/login_screen.dart';
import 'package:genbarber/screens/client/client_shell.dart';
import 'package:genbarber/screens/barber/barber_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('pt_BR', null);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const GenBarberApp(),
    ),
  );
}

class GenBarberApp extends StatelessWidget {
  const GenBarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenBarber',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.state) {
      case AuthState.initial:
      case AuthState.loading:
        return const Scaffold(
          backgroundColor: Color(0xFFF0F4FF),
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text('Carregando...', style: TextStyle(color: AppTheme.textSecondary)),
            ]),
          ),
        );

      case AuthState.authenticated:
        if (auth.user?.role == UserRole.barber) return const BarberShell();
        return const ClientShell();

      case AuthState.unauthenticated:
      case AuthState.error:
        return const LoginScreen();
    }
  }
}
