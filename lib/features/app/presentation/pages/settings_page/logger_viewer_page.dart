import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/logger/app_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

@RoutePage()
class LoggerViewerPage extends StatelessWidget {
  const LoggerViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TalkerScreen(talker: AppLogger.talker!);
  }
}
