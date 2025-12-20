import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/receipt_controller.dart';
import '../models/receipt.dart';
import '../widgets/receipt_image.dart';

class ReceiptEditScreen extends StatefulWidget {
  const ReceiptEditScreen({
    super.key,
    required this.receipt,
    required this.isNew,
  });

  final Receipt receipt;
  final bool isNew;

  @override
  State<ReceiptEditScreen> createState() => _ReceiptEditScreenState();
}

class _ReceiptEditScreenState extends State<ReceiptEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _totalController;
  late TextEditingController _notesController;
  late ReceiptCategory _category;
  late DateTime _purchaseDate;
  late String _currency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.receipt.merchantName,
    );
    _totalController = TextEditingController(
      text: widget.receipt.totalAmount.toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: widget.receipt.notes);
    _category = widget.receipt.category;
    _purchaseDate = widget.receipt.purchaseDate;
    _currency = widget.receipt.currency;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _totalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? '确认收据' : '编辑收据'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveReceipt,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.receipt.imagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: buildReceiptImage(
                    widget.receipt.imagePath,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: '商户名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入商户名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalController,
                      decoration: const InputDecoration(
                        labelText: '金额',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入金额';
                        }
                        if (double.tryParse(value) == null) {
                          return '金额格式不正确';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: '币种',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                        DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _currency = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReceiptCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: '类型',
                  border: OutlineInputBorder(),
                ),
                items: ReceiptCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  '日期: ${_purchaseDate.toLocal().toString().split(' ').first}',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '备注',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      setState(() => _purchaseDate = date);
    }
  }

  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final controller = context.read<ReceiptController>();
    final total = double.parse(_totalController.text.trim());
    final updated = widget.receipt.copyWith(
      merchantName: _merchantController.text.trim(),
      totalAmount: total,
      currency: _currency,
      purchaseDate: _purchaseDate,
      category: _category,
      notes: _notesController.text.trim(),
    );
    await controller.upsertReceipt(updated);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    Navigator.pop(context);
  }
}
