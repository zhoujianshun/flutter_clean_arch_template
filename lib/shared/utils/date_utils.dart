import 'package:intl/intl.dart';

/// 日期工具类
class AppDateUtils {
  AppDateUtils._();

  /// 获取智能的日期显示文本
  /// 今天显示"今天"，明天显示"明天"，其他显示星期几
  static String getSmartDateText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    // 计算日期差
    final difference = targetDate.difference(today).inDays;

    switch (difference) {
      case 0:
        return '今天';
      case 1:
        return '明天';
      case -1:
        return '昨天';
      default:
        // 其他日期显示星期几
        return getWeekdayText(date);
    }
  }

  /// 获取星期几的中文显示
  static String getWeekdayText(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  /// 获取完整的智能日期时间显示
  /// 格式：今天 14:30 或 明天 09:00 或 周三 16:45
  static String getSmartDateTimeText(DateTime dateTime) {
    final dateText = getSmartDateText(dateTime);
    final timeText = DateFormat('HH:mm').format(dateTime);
    return '$dateText $timeText';
  }

  /// 获取智能日期显示（包含具体日期）
  /// 格式：今天 12-25 或 明天 12-26 或 周三 12-27
  static String getSmartDateWithDay(DateTime date) {
    final dateText = getSmartDateText(date);
    final dayText = DateFormat('MM-dd').format(date);

    // 如果是今天或明天，可以选择是否显示具体日期
    if (dateText == '今天' || dateText == '明天') {
      return dateText; // 只显示今天/明天
      // 或者 return '$dateText $dayText'; // 显示今天 12-25
    } else {
      return '$dateText $dayText'; // 周三 12-27
    }
  }

  /// 获取相对日期文本（更详细的版本）
  static String getRelativeDateText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = targetDate.difference(today).inDays;

    if (difference == 0) {
      return '今天';
    } else if (difference == 1) {
      return '明天';
    } else if (difference == -1) {
      return '昨天';
    } else if (difference == 2) {
      return '后天';
    } else if (difference == -2) {
      return '前天';
    } else if (difference > 0 && difference <= 7) {
      // 未来一周内
      return getWeekdayText(date);
    } else if (difference < 0 && difference >= -7) {
      // 过去一周内
      return '上${getWeekdayText(date)}';
    } else {
      // 超过一周，显示具体日期
      return DateFormat('MM月dd日').format(date);
    }
  }

  /// 判断是否为今天
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// 判断今天是否在日期之前
  static bool isTodayBefore(DateTime date) {
    final now = DateTime.now();
    return now.isBefore(date);
  }

  /// 判断是否为明天
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  /// 判断是否为昨天
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  /// 获取日期范围的智能显示
  static String getDateRangeText(DateTime startDate, DateTime endDate) {
    final startText = getSmartDateText(startDate);
    final endText = getSmartDateText(endDate);

    if (startDate.day == endDate.day && startDate.month == endDate.month && startDate.year == endDate.year) {
      // 同一天
      return startText;
    } else {
      return '$startText - $endText';
    }
  }

  /// 格式化服务时间，今天和明天的话显示今天和明天，其他日期显示星期几
  static String formatServiceTime(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return '';
    }
    // weekday 如果今天和明天的话显示今天和明天，其他日期显示星期几
    // 格式化日期
    final weekday = getSmartDateText(startDate);
    final dateStr =
        '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')}（$weekday）';
    // 格式化时间
    final startTimeStr = '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';

    return '$dateStr  $startTimeStr-$endTimeStr';
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime? dateTime, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    if (dateTime == null) {
      return '';
    }
    return DateFormat(format).format(dateTime);
  }

  /// 格式化时间到时间线
  static String formatTimeToTimeline(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '昨天';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}天前';
      } else {
        return '${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
