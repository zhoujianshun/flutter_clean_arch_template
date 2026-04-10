import 'package:flutter_clean_arch_template/shared/utils/date_utils.dart';

/// DateTime 扩展方法
extension DateTimeExtensions on DateTime {
  /// 获取智能日期显示文本
  /// 今天显示"今天"，明天显示"明天"，其他显示星期几
  String get smartDateText => AppDateUtils.getSmartDateText(this);

  /// 获取星期几的中文显示
  String get weekdayText => AppDateUtils.getWeekdayText(this);

  /// 获取完整的智能日期时间显示
  /// 格式：今天 14:30 或 明天 09:00 或 周三 16:45
  String get smartDateTimeText => AppDateUtils.getSmartDateTimeText(this);

  /// 获取智能日期显示（包含具体日期）
  /// 格式：今天 或 明天 或 周三 12-27
  String get smartDateWithDay => AppDateUtils.getSmartDateWithDay(this);

  /// 获取相对日期文本（更详细的版本）
  String get relativeDateText => AppDateUtils.getRelativeDateText(this);

  /// 判断是否为今天
  bool get isToday => AppDateUtils.isToday(this);

  /// 判断是否为明天
  bool get isTomorrow => AppDateUtils.isTomorrow(this);

  /// 判断是否为昨天
  bool get isYesterday => AppDateUtils.isYesterday(this);

  /// 获取与另一个日期的范围显示
  String dateRangeWith(DateTime endDate) => AppDateUtils.getDateRangeText(this, endDate);
}
