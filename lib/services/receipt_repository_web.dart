import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/receipt.dart';

class ReceiptRepository {
  static const String _storageKey = 'receipts_store_v1';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<Receipt>> fetchAll() async {
    final prefs = _prefs;
    if (prefs == null) {
      return [];
    }
    final payload = prefs.getString(_storageKey);
    if (payload == null || payload.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(payload);
    if (decoded is! List) {
      return [];
    }
    return decoded
        .whereType<Map>()
        .map((item) => Receipt.fromMap(Map<String, Object?>.from(item)))
        .toList();
  }

  Future<void> upsert(Receipt receipt) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final list = await fetchAll();
    final index = list.indexWhere((item) => item.id == receipt.id);
    if (index >= 0) {
      list[index] = receipt;
    } else {
      list.add(receipt);
    }
    await _saveAll(prefs, list);
  }

  Future<void> deleteByIds(List<String> ids) async {
    final prefs = _prefs;
    if (prefs == null || ids.isEmpty) {
      return;
    }
    final list = await fetchAll();
    list.removeWhere((receipt) => ids.contains(receipt.id));
    await _saveAll(prefs, list);
  }

  Future<void> close() async {}

  Future<void> _saveAll(
    SharedPreferences prefs,
    List<Receipt> receipts,
  ) async {
    final encoded = jsonEncode(
      receipts.map((receipt) => receipt.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }
}
