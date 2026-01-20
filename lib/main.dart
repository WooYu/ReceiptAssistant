import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/receipt_controller.dart';
import 'screens/login_screen.dart';
import 'screens/receipt_list_screen.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/export_service.dart';
import 'services/ocr_service.dart';
import 'services/receipt_repository.dart';
import 'services/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService(tokenStorage: TokenStorage());
  final authController = AuthController(authService: authService);
  await authController.initialize();

  final receiptController = ReceiptController(
    repository: ReceiptRepository(),
    ocrService: OcrService(),
    categoryService: CategoryService(),
    exportService: ExportService(),
  );
  await receiptController.initialize();

  runApp(
    ReceiptApp(
      authController: authController,
      receiptController: receiptController,
    ),
  );
}

class ReceiptApp extends StatelessWidget {
  const ReceiptApp({
    super.key,
    required this.authController,
    required this.receiptController,
  });

  final AuthController authController;
  final ReceiptController receiptController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F6B5F),
      brightness: Brightness.light,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: receiptController),
      ],
      child: MaterialApp(
        title: 'Receipt Assistant',
        theme: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
          textTheme: GoogleFonts.ibmPlexSansTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
          ),
        ),
        home: const _RootScreen(),
      ),
    );
  }
}

class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    switch (authController.status) {
      case AuthStatus.checking:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.authenticated:
        return const ReceiptListScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
