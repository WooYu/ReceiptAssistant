import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/receipt.dart';

class ExportService {
  Future<void> exportAndShare(List<Receipt> receipts) async {
    if (receipts.isEmpty) {
      return;
    }
    final csv = _buildCsv(receipts);
    final bytes = utf8.encode(csv);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'receipts_$timestamp.csv';
    final subject = receipts.length > 1
        ? 'Receipt export (${receipts.length})'
        : 'Receipt export';
    final file = XFile.fromData(
      bytes,
      name: fileName,
      mimeType: 'text/csv',
    );
    try {
      await Share.shareXFiles(
        [file],
        subject: subject,
        text: 'Exported receipts attached.',
      );
    } catch (_) {
      await Share.share(csv, subject: subject);
    }
  }

  String _buildCsv(List<Receipt> receipts) {
    final buffer = StringBuffer();
    buffer.writeln(
      'id,merchant,total,currency,date,category,status,notes,image_path',
    );
    for (final receipt in receipts) {
      buffer.writeln([
        receipt.id,
        _escape(receipt.merchantName),
        receipt.totalAmount.toStringAsFixed(2),
        receipt.currency,
        DateFormat('yyyy-MM-dd').format(receipt.purchaseDate),
        receipt.category.label,
        receipt.status.label,
        _escape(receipt.notes),
        _escape(receipt.imagePath),
      ].join(','));
    }
    return buffer.toString();
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
