import 'dart:io';

/// Interactive setup script for the Flutter Clean Architecture Template.
///
/// Usage: dart run tool/setup.dart
///
/// This script will:
/// 1. Ask for project name, organization, and display name
/// 2. Replace package names in all Dart files
/// 3. Update Android and iOS configurations
/// 4. Clean up template-specific files
/// 5. Run flutter pub get
void main() async {
  print('');
  print('========================================');
  print(' Flutter Clean Arch Template Setup');
  print('========================================');
  print('');

  final projectName = _prompt(
    'Project name (snake_case, e.g. my_awesome_app)',
    validator: _validateSnakeCase,
  );

  final orgName = _prompt(
    'Organization (reverse domain, e.g. com.example)',
    defaultValue: 'com.example',
    validator: _validateOrgName,
  );

  final displayName = _prompt(
    'App display name (e.g. My Awesome App)',
    defaultValue: _snakeCaseToTitle(projectName),
  );

  final description = _prompt(
    'App description',
    defaultValue: 'A new Flutter project built with Clean Architecture.',
  );

  print('');
  print('Configuration:');
  print('  Project name:  $projectName');
  print('  Organization:  $orgName');
  print('  Display name:  $displayName');
  print('  Description:   $description');
  print('');

  final confirm = _prompt('Proceed? (y/n)', defaultValue: 'y');
  if (confirm.toLowerCase() != 'y') {
    print('Setup cancelled.');
    exit(0);
  }

  print('');
  print('Setting up project...');

  const templateName = 'flutter_clean_arch_template';
  const templateOrg = 'com.example';
  final applicationId = '${orgName.replaceAll('.', '.')}.$projectName';

  // 1. Replace package name in Dart files
  print('  Replacing package names in Dart files...');
  await _replaceInFiles(
    'lib',
    'package:$templateName/',
    'package:$projectName/',
    extensions: ['.dart'],
  );

  // 2. Update pubspec.yaml
  print('  Updating pubspec.yaml...');
  await _replaceInFile(
    'pubspec.yaml',
    {
      'name: $templateName': 'name: $projectName',
      "description: 'A production-ready Flutter project template with Clean Architecture, Riverpod, and Feature-First structure.'":
          "description: '$description'",
    },
  );

  // 3. Update Android configuration
  print('  Updating Android configuration...');
  final buildGradle = File('android/app/build.gradle.kts');
  if (buildGradle.existsSync()) {
    var content = buildGradle.readAsStringSync();
    content = content.replaceAll(
      '$templateOrg.${templateName.replaceAll('_', '')}',
      applicationId.replaceAll('_', ''),
    );
    content = content.replaceAll(
      'namespace = "$templateOrg.${templateName.replaceAll('_', '')}"',
      'namespace = "${applicationId.replaceAll('_', '')}"',
    );
    buildGradle.writeAsStringSync(content);
  }

  // Also update AndroidManifest
  final androidManifest = File('android/app/src/main/AndroidManifest.xml');
  if (androidManifest.existsSync()) {
    var content = androidManifest.readAsStringSync();
    content = content.replaceAll(templateName, projectName);
    androidManifest.writeAsStringSync(content);
  }

  // 4. Update iOS configuration
  print('  Updating iOS configuration...');
  final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
  if (pbxproj.existsSync()) {
    var content = pbxproj.readAsStringSync();
    content = content.replaceAll(
      '$templateOrg.flutterCleanArchTemplate',
      '$orgName.${_snakeCaseToCamel(projectName)}',
    );
    pbxproj.writeAsStringSync(content);
  }

  // Update Info.plist display name
  final infoPlist = File('ios/Runner/Info.plist');
  if (infoPlist.existsSync()) {
    var content = infoPlist.readAsStringSync();
    content = content.replaceAll('flutter_clean_arch_template', displayName);
    infoPlist.writeAsStringSync(content);
  }

  // 5. Update MaterialApp title in main.dart
  print('  Updating app title...');
  await _replaceInFile(
    'lib/main.dart',
    {"title: 'Flutter Clean Arch'": "title: '$displayName'"},
  );

  // 6. Update l10n
  await _replaceInFile(
    'lib/l10n/app_zh_CN.arb',
    {'"appTitle": "Flutter Clean Arch"': '"appTitle": "$displayName"'},
  );
  await _replaceInFile(
    'lib/l10n/app_en.arb',
    {'"appTitle": "Flutter Clean Arch"': '"appTitle": "$displayName"'},
  );

  // 7. Run flutter pub get
  print('  Running flutter pub get...');
  final result = await Process.run('flutter', ['pub', 'get']);
  if (result.exitCode != 0) {
    print('  Warning: flutter pub get failed. Run it manually.');
    print('  ${result.stderr}');
  }

  // 8. Self-cleanup
  print('  Cleaning up setup files...');
  final setupFile = File('tool/setup.dart');
  if (setupFile.existsSync()) {
    setupFile.deleteSync();
  }
  final toolDir = Directory('tool');
  if (toolDir.existsSync() && toolDir.listSync().isEmpty) {
    toolDir.deleteSync();
  }

  print('');
  print('========================================');
  print(' Setup complete!');
  print('========================================');
  print('');
  print('Next steps:');
  print('  1. Run: dart run build_runner build --delete-conflicting-outputs');
  print('  2. Run: flutter run');
  print('');
  print('Happy coding!');
}

String _prompt(String message, {String? defaultValue, String? Function(String)? validator}) {
  while (true) {
    final defaultStr = defaultValue != null ? ' [$defaultValue]' : '';
    stdout.write('$message$defaultStr: ');
    final input = stdin.readLineSync()?.trim() ?? '';
    final value = input.isEmpty ? (defaultValue ?? '') : input;

    if (value.isEmpty) {
      print('  This field is required.');
      continue;
    }

    if (validator != null) {
      final error = validator(value);
      if (error != null) {
        print('  $error');
        continue;
      }
    }

    return value;
  }
}

String? _validateSnakeCase(String value) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) {
    return 'Must be snake_case (lowercase letters, numbers, underscores, starting with a letter).';
  }
  if (value.contains('__')) {
    return 'Must not contain consecutive underscores.';
  }
  return null;
}

String? _validateOrgName(String value) {
  if (!RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$').hasMatch(value)) {
    return 'Must be reverse domain notation (e.g. com.example).';
  }
  return null;
}

String _snakeCaseToTitle(String input) {
  return input.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

String _snakeCaseToCamel(String input) {
  final parts = input.split('_');
  return parts.first + parts.skip(1).map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join();
}

Future<void> _replaceInFiles(
  String directory,
  String from,
  String to, {
  List<String> extensions = const ['.dart'],
}) async {
  final dir = Directory(directory);
  if (!dir.existsSync()) return;

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && extensions.any((ext) => entity.path.endsWith(ext))) {
      var content = entity.readAsStringSync();
      if (content.contains(from)) {
        content = content.replaceAll(from, to);
        entity.writeAsStringSync(content);
      }
    }
  }
}

Future<void> _replaceInFile(String path, Map<String, String> replacements) async {
  final file = File(path);
  if (!file.existsSync()) return;

  var content = file.readAsStringSync();
  for (final entry in replacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }
  file.writeAsStringSync(content);
}
