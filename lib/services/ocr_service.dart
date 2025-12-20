import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../models/receipt.dart';

class OcrService {
  Future<RecognizedReceipt> recognize(XFile imageFile) async {
    if (ApiConfig.ocrEndpoint.isEmpty || ApiConfig.ocrApiKey.isEmpty) {
      return RecognizedReceipt(
        merchantName: 'Unknown Merchant',
        totalAmount: 0,
        currency: 'USD',
        purchaseDate: DateTime.now(),
        categoryHint: '',
        rawText: '',
      );
    }

    final uri = Uri.parse(ApiConfig.ocrEndpoint);
    final bytes = await imageFile.readAsBytes();
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${ApiConfig.ocrApiKey}'
      ..fields['model'] = ApiConfig.ocrModel
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OCR failed: ${response.statusCode}');
    }

    final payload = jsonDecode(response.body);
    final receiptData = _findReceiptNode(payload);
    final merchant = _readString(
      receiptData,
      ['merchant_name', 'merchant', 'vendor', 'store_name'],
    );
    final total = _readDouble(receiptData, ['total', 'amount', 'total_amount']);
    final currency =
        _readString(receiptData, ['currency', 'currency_code'], fallback: 'USD');
    final date = _readDate(receiptData, ['date', 'purchase_date', 'datetime']);
    final categoryHint =
        _readString(receiptData, ['category', 'expense_type', 'type']);
    final rawText = _readString(receiptData, ['raw_text', 'text', 'ocr_text']);

    return RecognizedReceipt(
      merchantName: merchant.isEmpty ? 'Unknown Merchant' : merchant,
      totalAmount: total,
      currency: currency.isEmpty ? 'USD' : currency,
      purchaseDate: date ?? DateTime.now(),
      categoryHint: categoryHint,
      rawText: rawText,
      rawData: receiptData,
    );
  }

  Map<String, Object?> _findReceiptNode(Object? payload) {
    if (payload is Map<String, Object?>) {
      if (payload['receipt'] is Map<String, Object?>) {
        return payload['receipt'] as Map<String, Object?>;
      }
      if (payload['data'] is Map<String, Object?>) {
        return payload['data'] as Map<String, Object?>;
      }
      return payload;
    }
    return {};
  }

  String _readString(Map<String, Object?> data, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  double _readDouble(Map<String, Object?> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      }
    }
    return 0;
  }

  DateTime? _readDate(Map<String, Object?> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
