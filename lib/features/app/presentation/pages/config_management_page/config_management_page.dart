import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/env/app_config.dart';

@RoutePage()
class ConfigManagementPage extends StatelessWidget {
  const ConfigManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final info = AppConfig.getEnvironmentInfo();

    return Scaffold(
      appBar: AppBar(title: const Text('Config Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: info.entries.map((e) {
          final value = e.value is Map ? e.value.toString() : e.value.toString();
          return ListTile(
            title: Text(e.key),
            subtitle: Text(value),
          );
        }).toList(),
      ),
    );
  }
}
