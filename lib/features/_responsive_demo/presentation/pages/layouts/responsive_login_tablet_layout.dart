import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/layout_semantics.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';

class ResponsiveLoginTabletLayout extends StatelessWidget {
  const ResponsiveLoginTabletLayout({
    required this.constraints,
    required this.loginForm,
    super.key,
  });

  final BoxConstraints constraints;
  final Widget loginForm;

  @override
  Widget build(BuildContext context) {
    final masterRatio = LayoutSemantics.masterPaneRatio(constraints);
    final brandFlex = (masterRatio * 100).round();

    return Row(
      children: [
        Expanded(
          flex: brandFlex,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.flutter_dash,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Flutter Clean Arch',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '企业级整洁架构模板\n快速构建高质量 Flutter 应用',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _FeatureChip(label: 'Clean Architecture'),
                          _FeatureChip(label: 'Riverpod 3.0'),
                          _FeatureChip(label: 'AutoRoute'),
                          _FeatureChip(label: 'Freezed'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 100 - brandFlex,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: ResponsiveTokens.maxWidthFormNarrow,
                ),
                child: SingleChildScrollView(
                  key: const PageStorageKey<String>(
                    'responsive_login_tablet_scroll',
                  ),
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '欢迎回来',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '登录以继续使用',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 48),
                      loginForm,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
