import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/filters.dart';
import '../models/receipt.dart';
import '../services/category_service.dart';
import '../services/export_service.dart';
import '../services/ocr_service.dart';
import '../services/receipt_repository.dart';

class ReceiptController extends ChangeNotifier {
  ReceiptController({
    required ReceiptRepository repository,
    required OcrService ocrService,
    required CategoryService categoryService,
    required ExportService exportService,
  })  : _repository = repository,
        _ocrService = ocrService,
        _categoryService = categoryService,
        _exportService = exportService;

  final ReceiptRepository _repository;
  final OcrService _ocrService;
  final CategoryService _categoryService;
  final ExportService _exportService;

  final Set<String> _selectedIds = {};
  List<Receipt> _receipts = [];
  ReceiptFilters _filters = const ReceiptFilters();
  bool _isBusy = false;
  String? _lastError;

  List<Receipt> get receipts => List.unmodifiable(_receipts);
  ReceiptFilters get filters => _filters;
  bool get isBusy => _isBusy;
  String? get lastError => _lastError;

  List<Receipt> get filteredReceipts {
    final now = DateTime.now();
    return _receipts.where((receipt) {
      switch (_filters.timeFilter) {
        case TimeFilter.all:
          break;
        case TimeFilter.lastMonth:
          final cutoff = now.subtract(const Duration(days: 30));
          if (receipt.purchaseDate.isBefore(cutoff)) {
            return false;
          }
          break;
        case TimeFilter.custom:
          final range = _filters.customRange;
          if (range != null) {
            if (receipt.purchaseDate.isBefore(range.start) ||
                receipt.purchaseDate.isAfter(range.end)) {
              return false;
            }
          }
          break;
      }

      switch (_filters.statusFilter) {
        case StatusFilter.all:
          break;
        case StatusFilter.exported:
          if (receipt.status != ReceiptStatus.exported) {
            return false;
          }
          break;
        case StatusFilter.unexported:
          if (receipt.status != ReceiptStatus.unexported) {
            return false;
          }
          break;
      }

      final categoryFilter = _filters.categoryFilter;
      if (categoryFilter != null && receipt.category != categoryFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  bool get hasSelection => _selectedIds.isNotEmpty;

  List<Receipt> get selectedReceipts => _receipts
      .where((receipt) => _selectedIds.contains(receipt.id))
      .toList();

  bool isSelected(String id) => _selectedIds.contains(id);

  Future<void> initialize() async {
    await _repository.init();
    await refresh();
  }

  Future<void> refresh() async {
    _setBusy(true);
    _receipts = await _repository.fetchAll();
    _sortReceipts();
    _setBusy(false);
  }

  void updateFilters(ReceiptFilters filters) {
    _filters = filters;
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelection(String receiptId) {
    if (_selectedIds.contains(receiptId)) {
      _selectedIds.remove(receiptId);
    } else {
      _selectedIds.add(receiptId);
    }
    notifyListeners();
  }

  void selectAllFiltered() {
    _selectedIds
      ..clear()
      ..addAll(filteredReceipts.map((receipt) => receipt.id));
    notifyListeners();
  }

  Future<Receipt?> createDraftFromImage(ImageSource source) async {
    _setBusy(true);
    _lastError = null;
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) {
        _setBusy(false);
        return null;
      }

      final recognized = await _ocrService.recognize(image);
      final category = _categoryService.inferCategory(recognized);
      final receipt = Receipt.draft(
        merchantName: recognized.merchantName,
        totalAmount: recognized.totalAmount,
        currency: recognized.currency,
        purchaseDate: recognized.purchaseDate,
        category: category,
        imagePath: image.path,
        rawText: recognized.rawText,
      );
      _setBusy(false);
      return receipt;
    } catch (error) {
      _lastError = error.toString();
      _setBusy(false);
      return null;
    }
  }

  Future<void> upsertReceipt(Receipt receipt) async {
    final updatedReceipt = receipt.copyWith(updatedAt: DateTime.now());
    await _repository.upsert(updatedReceipt);
    final index = _receipts.indexWhere((item) => item.id == receipt.id);
    if (index >= 0) {
      _receipts[index] = updatedReceipt;
    } else {
      _receipts.add(updatedReceipt);
    }
    _sortReceipts();
    notifyListeners();
  }

  Future<void> exportSelected() async {
    final receipts = selectedReceipts;
    if (receipts.isEmpty) {
      return;
    }
    _setBusy(true);
    _lastError = null;
    try {
      await _exportService.exportAndShare(receipts);
      final now = DateTime.now();
      for (final receipt in receipts) {
        final updated = receipt.copyWith(
          status: ReceiptStatus.exported,
          exportedAt: now,
          updatedAt: now,
        );
        await _repository.upsert(updated);
        final index = _receipts.indexWhere((item) => item.id == updated.id);
        if (index >= 0) {
          _receipts[index] = updated;
        }
      }
      clearSelection();
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _setBusy(false);
    }
  }

  void _sortReceipts() {
    _receipts.sort(
      (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
    );
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}
