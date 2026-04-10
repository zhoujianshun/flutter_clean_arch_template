import 'package:flutter/services.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';

class ClipboardUtils {
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await MyEasyPopMessage.showSuccess('复制成功');
  }
}
