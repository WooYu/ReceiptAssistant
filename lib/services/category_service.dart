import '../models/receipt.dart';

class CategoryService {
  ReceiptCategory inferCategory(RecognizedReceipt recognized) {
    final hint = recognized.categoryHint.trim().toLowerCase();
    if (hint.isNotEmpty) {
      final mapped = _mapCategoryHint(hint);
      if (mapped != null) {
        return mapped;
      }
    }

    final combined = [
      recognized.merchantName,
      recognized.rawText,
      hint,
    ].join(' ').toLowerCase();

    if (_containsAny(combined, ['verizon', 'att', 't-mobile', 'comcast'])) {
      return ReceiptCategory.communications;
    }
    if (_containsAny(
      combined,
      ['hospital', 'clinic', 'pharmacy', 'cvs', 'walgreens'],
    )) {
      return ReceiptCategory.medical;
    }
    if (_containsAny(
      combined,
      ['uber', 'lyft', 'taxi', 'metro', 'train', 'bus'],
    )) {
      return ReceiptCategory.transportation;
    }
    if (_containsAny(
      combined,
      ['restaurant', 'cafe', 'coffee', 'starbucks', 'diner'],
    )) {
      return ReceiptCategory.dining;
    }

    return ReceiptCategory.other;
  }

  ReceiptCategory? _mapCategoryHint(String hint) {
    if (_containsAny(hint, ['communication', 'phone', 'internet'])) {
      return ReceiptCategory.communications;
    }
    if (_containsAny(hint, ['medical', 'health', 'pharmacy'])) {
      return ReceiptCategory.medical;
    }
    if (_containsAny(hint, ['transport', 'travel', 'ride', 'taxi'])) {
      return ReceiptCategory.transportation;
    }
    if (_containsAny(hint, ['meal', 'food', 'restaurant', 'dining'])) {
      return ReceiptCategory.dining;
    }
    return null;
  }

  bool _containsAny(String input, List<String> tokens) {
    return tokens.any(input.contains);
  }
}
