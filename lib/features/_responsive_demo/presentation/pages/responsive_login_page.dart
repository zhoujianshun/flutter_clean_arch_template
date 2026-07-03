import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/layouts/responsive_login_compact_layout.dart';
import 'package:flutter_clean_arch_template/features/_responsive_demo/presentation/pages/layouts/responsive_login_tablet_layout.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/shared/responsive/responsive_tokens.dart';

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
        compact: (_) =>
            ResponsiveLoginCompactLayout(loginForm: _buildLoginForm(context)),
        medium: (constraints) => ResponsiveLoginTabletLayout(
          constraints: constraints,
          loginForm: _buildLoginForm(context),
        ),
      ),
    );
  }
}

// ── 共享表单组件 ──────────────────────────────────────────────────────────

Widget _buildLoginForm(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const TextField(
        decoration: InputDecoration(
          labelText: '邮箱地址',
          prefixIcon: Icon(Icons.email_outlined),
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      const TextField(
        decoration: InputDecoration(
          labelText: '密码',
          prefixIcon: Icon(Icons.lock_outline),
          suffixIcon: Icon(Icons.visibility_off_outlined),
        ),
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
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
        ),
        child: const Text('登 录'),
      ),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
        ),
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
          SizedBox(width: ResponsiveTokens.size(24, medium: 24, expanded: 24)),
          _buildSocialButton(Icons.g_mobiledata, '谷歌'),
          SizedBox(width: ResponsiveTokens.size(24, medium: 24, expanded: 24)),
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 28),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
