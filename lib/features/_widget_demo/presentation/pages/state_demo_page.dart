import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/content_constraint.dart';
import 'package:flutter_clean_arch_template/shared/widgets/my_circular_progress_indicator.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_easy_pop_message.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_empty_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_error_widget.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_image_placeholder.dart';
import 'package:flutter_clean_arch_template/shared/widgets/states/app_loading_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class StateDemoPage extends StatelessWidget {
  const StateDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('状态页 State Widgets')),
      body: ContentConstraint(
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // AppLoadingIndicator
            _SectionTitle('AppLoadingIndicator', '加载指示器（3种尺寸）'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const AppLoadingIndicator(),
                        SizedBox(height: 8.h),
                        const Text('Widget 级'),
                      ],
                    ),
                    Column(
                      children: [
                        const AppLoadingIndicator(size: 32),
                        SizedBox(height: 8.h),
                        const Text('Page 级'),
                      ],
                    ),
                    Column(
                      children: [
                        const AppButtonLoadingIndicator(
                          color: Colors.blue,
                        ),
                        SizedBox(height: 8.h),
                        const Text('Button 级'),
                      ],
                    ),
                    Column(
                      children: [
                        const MyCircularProgressIndicator(),
                        SizedBox(height: 8.h),
                        const Text('Circular'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Card(
              child: SizedBox(
                height: 120.h,
                child: const AppPageLoadingIndicator(message: '正在加载数据...'),
              ),
            ),
            SizedBox(height: 16.h),

            // AppImagePlaceholder
            _SectionTitle('AppImagePlaceholder', '图片占位符'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    SizedBox(
                      width: 80.w,
                      height: 80.w,
                      child: const AppImagePlaceholder(),
                    ),
                    SizedBox(
                      width: 60.w,
                      height: 60.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: const AppImagePlaceholder(),
                      ),
                    ),
                    ClipOval(
                      child: SizedBox(
                        width: 50.w,
                        height: 50.w,
                        child: const AppImagePlaceholder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // AppSimpleErrorWidget
            _SectionTitle('AppSimpleErrorWidget', '简化版错误提示'),
            AppSimpleErrorWidget(
              message: '数据加载失败，请检查网络连接',
              onRetry: () =>
                  MyEasyPopMessage.showInfoUnawaited('点击了重试'),
            ),
            SizedBox(height: 16.h),

            // AppErrorWidget
            _SectionTitle('AppErrorWidget', '完整错误页面'),
            Card(
              child: SizedBox(
                height: 300.h,
                child: AppErrorWidget(
                  error: 'NetworkException: Connection timeout',
                  description: '当前网络异常，请刷新试试',
                  isCenter: true,
                  onRetry: () =>
                      MyEasyPopMessage.showInfoUnawaited('点击了重试'),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // AppNetworkErrorWidget
            _SectionTitle('AppNetworkErrorWidget', '网络错误专用组件'),
            Card(
              child: SizedBox(
                height: 300.h,
                child: AppNetworkErrorWidget(
                  onRetry: () =>
                      MyEasyPopMessage.showInfoUnawaited('点击了重试'),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // AppEmptyWidget
            _SectionTitle('AppEmptyWidget', '空状态（多种类型）'),
            Card(
              child: SizedBox(
                height: 240.h,
                child: const AppEmptyWidget(type: AppEmptyWidgetType.normal),
              ),
            ),
            SizedBox(height: 8.h),
            Card(
              child: SizedBox(
                height: 240.h,
                child: const AppEmptyWidget(
                  type: AppEmptyWidgetType.messageCenter,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Card(
              child: SizedBox(
                height: 240.h,
                child: const AppEmptyWidget(
                  type: AppEmptyWidgetType.orderList,
                ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
