import 'package:uuid/uuid.dart';

enum ReceiptStatus { exported, unexported }

enum ReceiptCategory { communications, medical, transportation, dining, other }

extension ReceiptCategoryLabel on ReceiptCategory {
  String get label {
    switch (this) {
      case ReceiptCategory.communications:
        return '通讯费';
      case ReceiptCategory.medical:
        return '医疗票据';
      case ReceiptCategory.transportation:
        return '交通';
      case ReceiptCategory.dining:
        return '餐饮';
      case ReceiptCategory.other:
        return '其他';
    }
  }
}

extension ReceiptStatusLabel on ReceiptStatus {
  String get label {
    switch (this) {
      case ReceiptStatus.exported:
        return '已导出';
      case ReceiptStatus.unexported:
        return '未导出';
    }
  }
}

ReceiptCategory parseReceiptCategory(String? value) {
  if (value == null || value.isEmpty) {
    return ReceiptCategory.other;
  }
  return ReceiptCategory.values.firstWhere(
    (category) => category.name == value,
    orElse: () => ReceiptCategory.other,
  );
}

ReceiptStatus parseReceiptStatus(String? value) {
  if (value == null || value.isEmpty) {
    return ReceiptStatus.unexported;
  }
  return ReceiptStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => ReceiptStatus.unexported,
  );
}

class Receipt {
  Receipt({
    required this.id,
    required this.merchantName,
    required this.totalAmount,
    required this.currency,
    required this.purchaseDate,
    required this.category,
    required this.status,
    required this.imagePath,
    required this.rawText,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.exportedAt,
  });

  final String id;
  final String merchantName;
  final double totalAmount;
  final String currency;
  final DateTime purchaseDate;
  final ReceiptCategory category;
  final ReceiptStatus status;
  final String imagePath;
  final String rawText;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? exportedAt;

  factory Receipt.draft({
    required String merchantName,
    required double totalAmount,
    required String currency,
    required DateTime purchaseDate,
    required ReceiptCategory category,
    required String imagePath,
    required String rawText,
  }) {
    final now = DateTime.now();
    return Receipt(
      id: const Uuid().v4(),
      merchantName: merchantName,
      totalAmount: totalAmount,
      currency: currency,
      purchaseDate: purchaseDate,
      category: category,
      status: ReceiptStatus.unexported,
      imagePath: imagePath,
      rawText: rawText,
      notes: '',
      createdAt: now,
      updatedAt: now,
      exportedAt: null,
    );
  }

  Receipt copyWith({
    String? id,
    String? merchantName,
    double? totalAmount,
    String? currency,
    DateTime? purchaseDate,
    ReceiptCategory? category,
    ReceiptStatus? status,
    String? imagePath,
    String? rawText,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? exportedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      category: category ?? this.category,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      rawText: rawText ?? this.rawText,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exportedAt: exportedAt ?? this.exportedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'merchant_name': merchantName,
      'total_amount': totalAmount,
      'currency': currency,
      'purchase_date': purchaseDate.toIso8601String(),
      'category': category.name,
      'status': status.name,
      'image_path': imagePath,
      'raw_text': rawText,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'exported_at': exportedAt?.toIso8601String(),
    };
  }

  static Receipt fromMap(Map<String, Object?> map) {
    return Receipt(
      id: map['id'] as String,
      merchantName: (map['merchant_name'] as String?) ?? '',
      totalAmount: ((map['total_amount'] as num?) ?? 0).toDouble(),
      currency: (map['currency'] as String?) ?? 'USD',
      purchaseDate: DateTime.tryParse(map['purchase_date'] as String? ?? '') ??
          DateTime.now(),
      category: parseReceiptCategory(map['category'] as String?),
      status: parseReceiptStatus(map['status'] as String?),
      imagePath: (map['image_path'] as String?) ?? '',
      rawText: (map['raw_text'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
      exportedAt: map['exported_at'] == null
          ? null
          : DateTime.tryParse(map['exported_at'] as String? ?? ''),
    );
  }
}

class RecognizedReceipt {
  RecognizedReceipt({
    required this.merchantName,
    required this.totalAmount,
    required this.currency,
    required this.purchaseDate,
    required this.categoryHint,
    required this.rawText,
    this.rawData,
  });

  final String merchantName;
  final double totalAmount;
  final String currency;
  final DateTime purchaseDate;
  final String categoryHint;
  final String rawText;
  final Map<String, Object?>? rawData;
}
