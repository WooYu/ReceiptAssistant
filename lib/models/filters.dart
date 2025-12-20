import 'package:flutter/material.dart';

import 'receipt.dart';

enum TimeFilter { all, lastMonth, custom }

enum StatusFilter { all, exported, unexported }

extension TimeFilterLabel on TimeFilter {
  String get label {
    switch (this) {
      case TimeFilter.all:
        return '全部';
      case TimeFilter.lastMonth:
        return '近一月';
      case TimeFilter.custom:
        return '自定义';
    }
  }
}

extension StatusFilterLabel on StatusFilter {
  String get label {
    switch (this) {
      case StatusFilter.all:
        return '全部';
      case StatusFilter.exported:
        return '已导出';
      case StatusFilter.unexported:
        return '未导出';
    }
  }
}

class ReceiptFilters {
  const ReceiptFilters({
    this.timeFilter = TimeFilter.all,
    this.customRange,
    this.statusFilter = StatusFilter.all,
    this.categoryFilter,
  });

  static const _unset = Object();

  final TimeFilter timeFilter;
  final DateTimeRange? customRange;
  final StatusFilter statusFilter;
  final ReceiptCategory? categoryFilter;

  ReceiptFilters copyWith({
    TimeFilter? timeFilter,
    Object? customRange = _unset,
    StatusFilter? statusFilter,
    Object? categoryFilter = _unset,
  }) {
    return ReceiptFilters(
      timeFilter: timeFilter ?? this.timeFilter,
      customRange: customRange == _unset
          ? this.customRange
          : customRange as DateTimeRange?,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter == _unset
          ? this.categoryFilter
          : categoryFilter as ReceiptCategory?,
    );
  }
}
