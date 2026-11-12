import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/dio_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/upload/data/repositories/upload_repository.dart';
import 'features/upload/presentation/bloc/upload_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Core Services
  final tokenStorage = TokenStorage();

  // Reference for AuthBloc to receive interceptor session expired notifications
  AuthBloc? authBloc;

  final dioClient = DioClient(
    tokenStorage: tokenStorage,
    onSessionExpired: () {
      authBloc?.add(const AuthSessionExpiredEvent());
    },
  );

  final authRepository = AuthRepository(
    dioClient: dioClient,
    tokenStorage: tokenStorage,
  );

  final uploadRepository = UploadRepository(
    dioClient: dioClient,
  );

  authBloc = AuthBloc(authRepository: authRepository)..add(const AuthCheckRequested());
  final uploadBloc = UploadBloc(uploadRepository: uploadRepository);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TokenStorage>.value(value: tokenStorage),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<UploadRepository>.value(value: uploadRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<UploadBloc>.value(value: uploadBloc),
        ],
        child: const MediaCaptureApp(),
      ),
    ),
  );
}

class MediaCaptureApp extends StatelessWidget {
  const MediaCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Capture & Upload',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
