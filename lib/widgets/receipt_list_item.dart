import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receipt.dart';

class ReceiptListItem extends StatelessWidget {
  const ReceiptListItem({
    super.key,
    required this.receipt,
    required this.selected,
    required this.onSelected,
    required this.onTap,
  });

  final Receipt receipt;
  final bool selected;
  final ValueChanged<bool?> onSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy-MM-dd').format(receipt.purchaseDate);
    return ListTile(
      leading: Checkbox(
        value: selected,
        onChanged: onSelected,
      ),
      title: Text(receipt.merchantName.isEmpty
          ? 'Unknown Merchant'
          : receipt.merchantName),
      subtitle: Text(
        '$dateText · ${receipt.category.label} · ${receipt.status.label}',
      ),
      trailing: Text(
        '${receipt.currency} ${receipt.totalAmount.toStringAsFixed(2)}',
      ),
      onTap: onTap,
    );
  }
}
