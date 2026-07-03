import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';

class ResponsiveLoginCompactLayout extends StatelessWidget {
  const ResponsiveLoginCompactLayout({required this.loginForm, super.key});

  final Widget loginForm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('responsive_login_compact_scroll'),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveTokens.size(24, medium: 24, expanded: 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: ResponsiveTokens.size(60, medium: 60, expanded: 60),
            ),
            Center(
              child: Container(
                width: ResponsiveTokens.size(80, medium: 80, expanded: 80),
                height: ResponsiveTokens.size(80, medium: 80, expanded: 80),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    ResponsiveTokens.size(20, medium: 20, expanded: 20),
                  ),
                ),
                child: Icon(
                  Icons.flutter_dash,
                  size: ResponsiveTokens.size(48, medium: 48, expanded: 48),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(
              height: ResponsiveTokens.size(32, medium: 32, expanded: 32),
            ),
            Center(
              child: Text(
                '欢迎回来',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: ResponsiveTokens.size(8, medium: 8, expanded: 8)),
            Center(
              child: Text(
                '登录以继续使用',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            SizedBox(
              height: ResponsiveTokens.size(48, medium: 48, expanded: 48),
            ),
            loginForm,
          ],
        ),
      ),
    );
  }
}
