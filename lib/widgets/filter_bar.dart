import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/filters.dart';
import '../models/receipt.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.filters,
    required this.onTimeFilterChanged,
    required this.onStatusFilterChanged,
    required this.onCategoryFilterChanged,
  });

  final ReceiptFilters filters;
  final void Function(TimeFilter filter, DateTimeRange? range)
      onTimeFilterChanged;
  final void Function(StatusFilter filter) onStatusFilterChanged;
  final void Function(ReceiptCategory? category) onCategoryFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          PopupMenuButton<TimeFilter>(
            onSelected: (value) async {
              if (value == TimeFilter.custom) {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  initialDateRange: filters.customRange,
                );
                onTimeFilterChanged(value, range);
              } else {
                onTimeFilterChanged(value, null);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TimeFilter.all,
                child: Text('全部'),
              ),
              const PopupMenuItem(
                value: TimeFilter.lastMonth,
                child: Text('近一月'),
              ),
              const PopupMenuItem(
                value: TimeFilter.custom,
                child: Text('自定义'),
              ),
            ],
            child: _FilterChip(
              label: '时间: ${_timeLabel(filters)}',
              icon: Icons.calendar_today,
            ),
          ),
          PopupMenuButton<StatusFilter>(
            onSelected: onStatusFilterChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: StatusFilter.all,
                child: Text('全部'),
              ),
              const PopupMenuItem(
                value: StatusFilter.exported,
                child: Text('已导出'),
              ),
              const PopupMenuItem(
                value: StatusFilter.unexported,
                child: Text('未导出'),
              ),
            ],
            child: _FilterChip(
              label: '状态: ${filters.statusFilter.label}',
              icon: Icons.verified_outlined,
            ),
          ),
          PopupMenuButton<ReceiptCategory?>(
            onSelected: onCategoryFilterChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('全部'),
              ),
              for (final category in ReceiptCategory.values)
                PopupMenuItem(
                  value: category,
                  child: Text(category.label),
                ),
            ],
            child: _FilterChip(
              label: '类型: ${filters.categoryFilter?.label ?? "全部"}',
              icon: Icons.category_outlined,
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(ReceiptFilters filters) {
    if (filters.timeFilter == TimeFilter.custom &&
        filters.customRange != null) {
      final formatter = DateFormat('MM/dd');
      final start = formatter.format(filters.customRange!.start);
      final end = formatter.format(filters.customRange!.end);
      return '${filters.timeFilter.label} $start-$end';
    }
    return filters.timeFilter.label;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
