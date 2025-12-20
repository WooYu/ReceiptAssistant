import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/receipt_controller.dart';
import 'screens/receipt_list_screen.dart';
import 'services/category_service.dart';
import 'services/export_service.dart';
import 'services/ocr_service.dart';
import 'services/receipt_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = ReceiptController(
    repository: ReceiptRepository(),
    ocrService: OcrService(),
    categoryService: CategoryService(),
    exportService: ExportService(),
  );
  await controller.initialize();
  runApp(ReceiptApp(controller: controller));
}

class ReceiptApp extends StatelessWidget {
  const ReceiptApp({super.key, required this.controller});

  final ReceiptController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F6B5F),
      brightness: Brightness.light,
    );
    return ChangeNotifierProvider.value(
      value: controller,
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
        home: const ReceiptListScreen(),
      ),
    );
  }
}
