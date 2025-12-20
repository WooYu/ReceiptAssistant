import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/receipt_controller.dart';
import '../models/filters.dart';
import '../models/receipt.dart';
import '../widgets/filter_bar.dart';
import '../widgets/receipt_list_item.dart';
import 'receipt_edit_screen.dart';

class ReceiptListScreen extends StatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  String? _shownError;

  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiptController>(
      builder: (context, controller, child) {
        _showErrorIfNeeded(controller);
        return Scaffold(
          appBar: AppBar(
            title: const Text('收据助手'),
            actions: [
              IconButton(
                onPressed:
                    controller.hasSelection ? controller.exportSelected : null,
                icon: const Icon(Icons.email_outlined),
                tooltip: '导出到邮箱',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'select_all') {
                    controller.selectAllFiltered();
                  } else if (value == 'clear') {
                    controller.clearSelection();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'select_all',
                    child: Text('全选筛选结果'),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('清空选择'),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (controller.isBusy)
                const LinearProgressIndicator(minHeight: 2),
              FilterBar(
                filters: controller.filters,
                onTimeFilterChanged: (filter, range) {
                  controller.updateFilters(
                    controller.filters.copyWith(
                      timeFilter: filter,
                      customRange: filter == TimeFilter.custom ? range : null,
                    ),
                  );
                },
                onStatusFilterChanged: (filter) {
                  controller.updateFilters(
                    controller.filters.copyWith(statusFilter: filter),
                  );
                },
                onCategoryFilterChanged: (category) {
                  controller.updateFilters(
                    controller.filters.copyWith(categoryFilter: category),
                  );
                },
              ),
              Expanded(
                child: _buildList(controller),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddSheet(context),
            child: const Icon(Icons.add_a_photo),
          ),
          bottomNavigationBar: controller.hasSelection
              ? BottomAppBar(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Text('已选择 ${controller.selectedReceipts.length}'),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: controller.exportSelected,
                          icon: const Icon(Icons.file_upload_outlined),
                          label: const Text('导出'),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildList(ReceiptController controller) {
    final receipts = controller.filteredReceipts;
    if (receipts.isEmpty) {
      return const Center(
        child: Text('暂无收据，请拍照导入。'),
      );
    }
    return ListView.separated(
      itemCount: receipts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return ReceiptListItem(
          receipt: receipt,
          selected: controller.isSelected(receipt.id),
          onSelected: (_) => controller.toggleSelection(receipt.id),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReceiptEditScreen(
                  receipt: receipt,
                  isNew: false,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showErrorIfNeeded(ReceiptController controller) {
    final error = controller.lastError;
    if (error == null || error == _shownError) {
      return;
    }
    _shownError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    });
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('拍照导入'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册导入'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }
    final controller = context.read<ReceiptController>();
    final draft = await controller.createDraftFromImage(source);
    if (!mounted || draft == null) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptEditScreen(receipt: draft, isNew: true),
      ),
    );
  }
}
