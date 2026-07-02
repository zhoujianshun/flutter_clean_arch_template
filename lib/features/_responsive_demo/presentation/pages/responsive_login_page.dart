import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 响应式登录页示例
///
/// 演示认证页面在不同屏幕上的布局差异：
/// - **手机**：全屏表单，品牌 Logo 在顶部
/// - **平板**：左侧品牌展示区（渐变背景 + 标语）+ 右侧登录表单
///
/// 这是 SaaS/企业应用中非常经典的登录页布局。
/// 平板上的左右分栏不仅利用了大屏空间，还能展示品牌形象。
@RoutePage()
class ResponsiveLoginPage extends StatelessWidget {
  const ResponsiveLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveLayoutBuilder(
        compact: (_) => const _CompactLogin(),
        medium: (constraints) => _MediumLogin(constraints: constraints),
      ),
    );
  }
}

/// 手机布局：全屏表单
class _CompactLogin extends StatelessWidget {
  const _CompactLogin();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 60.h),
            // 品牌 Logo
            Center(
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(Icons.flutter_dash, size: 48.w, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            SizedBox(height: 32.h),
            Center(child: Text('欢迎回来', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))),
            SizedBox(height: 8.h),
            Center(child: Text('登录以继续使用', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.outline))),
            SizedBox(height: 48.h),
            _buildLoginForm(context),
          ],
        ),
      ),
    );
  }
}

/// 平板布局：左品牌展示 + 右登录表单
class _MediumLogin extends StatelessWidget {
  const _MediumLogin({required this.constraints});
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final brandFlex = ResponsiveUtils.isExpanded(constraints) ? 55 : 45;

    return Row(
      children: [
        // 左侧品牌展示区
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
                        child: const Icon(Icons.flutter_dash, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Flutter Clean Arch',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '企业级整洁架构模板\n快速构建高质量 Flutter 应用',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.85), height: 1.6),
                      ),
                      const SizedBox(height: 48),
                      // 特性标签
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildFeatureChip('Clean Architecture'),
                          _buildFeatureChip('Riverpod 3.0'),
                          _buildFeatureChip('AutoRoute'),
                          _buildFeatureChip('Freezed'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // 右侧登录表单
        Expanded(
          flex: 100 - brandFlex,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ResponsiveUtils.maxWidthFormNarrow),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('欢迎回来', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('登录以继续使用', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
                      const SizedBox(height: 48),
                      _buildLoginForm(context),
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

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }
}

// ── 共享表单组件 ──────────────────────────────────────────────────────────

Widget _buildLoginForm(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const TextField(
        decoration: InputDecoration(labelText: '邮箱地址', prefixIcon: Icon(Icons.email_outlined)),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      const TextField(
        decoration: InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.lock_outline), suffixIcon: Icon(Icons.visibility_off_outlined)),
        obscureText: true,
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(onPressed: () {}, child: const Text('忘记密码？')),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
        child: const Text('登 录'),
      ),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
        child: const Text('创建账号'),
      ),
      const SizedBox(height: 32),
      Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('其他登录方式', style: Theme.of(context).textTheme.bodySmall),
          ),
          const Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSocialButton(Icons.apple, '苹果'),
          const SizedBox(width: 24),
          _buildSocialButton(Icons.g_mobiledata, '谷歌'),
          const SizedBox(width: 24),
          _buildSocialButton(Icons.wechat, '微信'),
        ],
      ),
    ],
  );
}

Widget _buildSocialButton(IconData icon, String label) {
  return Column(
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
        child: Icon(icon, size: 28),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
