import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 场景 6：Material 3 的 SliverAppBar.medium / .large
///
/// M3 新增的两个变体，无需手动配置 FlexibleSpaceBar：
/// - `SliverAppBar.medium`：折叠时标题从大缩小到正常
/// - `SliverAppBar.large`：展开区域更大，标题更突出
///
/// 业务场景：设置页、关于页、详情页等信息层级页面
@RoutePage()
class SliverM3DemoPage extends StatefulWidget {
  const SliverM3DemoPage({super.key});

  @override
  State<SliverM3DemoPage> createState() => _SliverM3DemoPageState();
}

class _SliverM3DemoPageState extends State<SliverM3DemoPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // 顶部 Tab 切换
          SafeArea(
            bottom: false,
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Medium'),
                  Tab(text: 'Large'),
                ],
              ),
            ),
          ),

          // 内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMediumExample(theme),
                _buildLargeExample(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumExample(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.medium(
          title: const Text('设置'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          ],
        ),

        // 说明
        SliverToBoxAdapter(
          child: Card(
            margin: EdgeInsets.all(16.w),
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SliverAppBar.medium', style: theme.textTheme.titleSmall),
                  SizedBox(height: 8.h),
                  const Text(
                    '• 展开时标题显示在左下方（较大字号）\n'
                    '• 折叠后标题移动到 AppBar 中央（正常字号）\n'
                    '• 无需手动配置 FlexibleSpaceBar\n'
                    '• 适用于设置页、详情页等信息层级场景',
                  ),
                ],
              ),
            ),
          ),
        ),

        // 模拟设置列表
        SliverList.list(
          children: [
            _buildSettingsSection(theme, '账号', [
              _buildSettingsTile(Icons.person_outline, '个人信息', '修改头像、昵称'),
              _buildSettingsTile(Icons.security, '账号安全', '密码、两步验证'),
              _buildSettingsTile(Icons.privacy_tip_outlined, '隐私设置', '谁可以看我'),
            ]),
            _buildSettingsSection(theme, '通用', [
              _buildSettingsTile(Icons.notifications_outlined, '通知设置', '消息推送'),
              _buildSettingsTile(Icons.language, '语言', '简体中文'),
              _buildSettingsTile(Icons.dark_mode_outlined, '深色模式', '跟随系统'),
              _buildSettingsTile(Icons.storage_outlined, '存储', '清除缓存'),
            ]),
            _buildSettingsSection(theme, '关于', [
              _buildSettingsTile(Icons.info_outline, '关于应用', 'v1.0.0'),
              _buildSettingsTile(Icons.description_outlined, '用户协议', ''),
              _buildSettingsTile(Icons.shield_outlined, '隐私政策', ''),
            ]),
          ],
        ),
      ],
    );
  }

  Widget _buildLargeExample(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('关于我们'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),

        // 说明
        SliverToBoxAdapter(
          child: Card(
            margin: EdgeInsets.all(16.w),
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SliverAppBar.large', style: theme.textTheme.titleSmall),
                  SizedBox(height: 8.h),
                  const Text(
                    '• 展开区域比 .medium 更大\n'
                    '• 标题字号更突出，适合一级页面\n'
                    '• 折叠动画由框架自动处理\n'
                    '• 适用于关于页、欢迎页等需要视觉冲击的场景',
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('medium vs large 对比',
                      style: theme.textTheme.titleSmall),
                  SizedBox(height: 8.h),
                  const Text(
                    '• .medium expandedHeight ≈ 112dp\n'
                    '• .large expandedHeight ≈ 152dp\n'
                    '• 两者都自动处理标题位移动画\n'
                    '• 切换上方 Tab 对比效果',
                  ),
                ],
              ),
            ),
          ),
        ),

        // 模拟内容
        SliverList.builder(
          itemCount: 20,
          itemBuilder: (context, index) => Card(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text('${index + 1}'),
              ),
              title: Text('团队成员 ${index + 1}'),
              subtitle: const Text('Flutter 工程师'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
      ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
