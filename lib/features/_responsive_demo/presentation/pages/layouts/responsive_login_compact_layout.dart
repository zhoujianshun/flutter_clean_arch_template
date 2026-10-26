import 'package:flutter/material.dart';
class ResponsiveLoginCompactLayout extends StatelessWidget {
  const ResponsiveLoginCompactLayout({required this.loginForm, super.key});

  final Widget loginForm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        key: const PageStorageKey<String>('responsive_login_compact_scroll'),
        padding: EdgeInsets.symmetric(
          horizontal: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 60,
            ),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: Icon(
                  Icons.flutter_dash,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(
              height: 32,
            ),
            Center(
              child: Text(
                '欢迎回来',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                '登录以继续使用',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            SizedBox(
              height: 48,
            ),
            loginForm,
          ],
        ),
      ),
    );
  }
}
