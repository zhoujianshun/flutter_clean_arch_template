import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/responsive/adaptive_builder.dart';
import 'package:flutter_clean_arch_template/shared/responsive/breakpoints.dart';

/// 响应式聊天/对话示例
///
/// 演示即时通讯界面的两种经典布局：
/// - **手机**：联系人列表 → 点击进入全屏对话页
/// - **平板**：左侧联系人列表 + 右侧对话窗口，并排显示
///
/// 与 Master-Detail 类似，但对话场景有独特的 UI 要素：
/// 输入框固定在底部、消息气泡左右对齐、在线状态等。
@RoutePage()
class ResponsiveChatPage extends StatefulWidget {
  const ResponsiveChatPage({super.key});

  @override
  State<ResponsiveChatPage> createState() => _ResponsiveChatPageState();
}

class _ResponsiveChatPageState extends State<ResponsiveChatPage> {
  int? _selectedContact;

  static const _contacts = [
    _Contact(
      name: '张三',
      avatar: '张',
      lastMessage: '好的，明天见！',
      time: '10:30',
      unread: 2,
      online: true,
      messages: [
        _Message(text: '你好！最近项目进展怎么样？', isMe: false, time: '10:20'),
        _Message(text: '还不错，正在做平板适配的功能', isMe: true, time: '10:22'),
        _Message(
          text: '用的什么方案？ScreenUtil 还是 responsive_framework？',
          isMe: false,
          time: '10:23',
        ),
        _Message(
          text: '用的 LayoutBuilder + ScreenUtil 组合方案，渐进式增强',
          isMe: true,
          time: '10:25',
        ),
        _Message(text: '这种方案不错，折叠屏也能支持', isMe: false, time: '10:26'),
        _Message(text: '是的，基于可用空间而非设备类型来做判断', isMe: true, time: '10:28'),
        _Message(text: '好的，明天见！', isMe: false, time: '10:30'),
      ],
    ),
    _Contact(
      name: '李四',
      avatar: '李',
      lastMessage: '设计稿已更新',
      time: '09:15',
      unread: 0,
      online: true,
      messages: [
        _Message(text: '平板版聊天页的设计稿发你了', isMe: false, time: '09:10'),
        _Message(text: '收到，我看下', isMe: true, time: '09:12'),
        _Message(text: '这次左边列表选中态的高亮再明显一些', isMe: false, time: '09:13'),
        _Message(text: '好的，我用 M3 的 selectedTileColor 处理', isMe: true, time: '09:14'),
        _Message(text: '设计稿已更新', isMe: false, time: '09:15'),
      ],
    ),
    _Contact(
      name: '产品群',
      avatar: '产',
      lastMessage: '王五：下周发版计划确认',
      time: '昨天',
      unread: 5,
      online: false,
      messages: [
        _Message(text: '王五：下周三发版，大家抓紧自测', isMe: false, time: '昨天 16:20'),
        _Message(text: '收到', isMe: true, time: '昨天 16:22'),
        _Message(text: '王五：回归范围包括平板和折叠屏布局', isMe: false, time: '昨天 16:25'),
        _Message(text: '李四：聊天页的选中态修复我下午提 PR', isMe: false, time: '昨天 16:30'),
        _Message(text: '王五：下周发版计划确认', isMe: false, time: '昨天 16:35'),
      ],
    ),
    _Contact(
      name: '王五',
      avatar: '王',
      lastMessage: '收到，我看一下',
      time: '昨天',
      unread: 0,
      online: false,
      messages: [
        _Message(text: 'Master-Detail 那页在平板上滚动有点卡', isMe: false, time: '昨天 14:00'),
        _Message(text: '可能是列表没有用 builder 构造', isMe: true, time: '昨天 14:05'),
        _Message(text: '收到，我看一下', isMe: false, time: '昨天 14:10'),
      ],
    ),
    _Contact(
      name: '赵六',
      avatar: '赵',
      lastMessage: '[图片]',
      time: '前天',
      unread: 0,
      online: true,
      messages: [
        _Message(text: '给你看下折叠屏展开的效果图', isMe: false, time: '前天 11:00'),
        _Message(text: '[图片]', isMe: false, time: '前天 11:01'),
        _Message(text: '展开态走 expanded 分栏，比例正好', isMe: true, time: '前天 11:20'),
      ],
    ),
    _Contact(
      name: '技术群',
      avatar: '技',
      lastMessage: '孙七：Flutter 4.0 要来了',
      time: '前天',
      unread: 12,
      online: false,
      messages: [
        _Message(text: '孙七：Flutter 4.0 要来了', isMe: false, time: '前天 20:00'),
        _Message(text: 'stable 渠道什么时候切？', isMe: false, time: '前天 20:05'),
        _Message(text: '先等 beta 稳定几周再说', isMe: true, time: '前天 20:10'),
        _Message(text: '孙七：Dart 3.12 的 pattern 也更完善了', isMe: false, time: '前天 20:15'),
      ],
    ),
    _Contact(
      name: '孙七',
      avatar: '孙',
      lastMessage: '周末一起吃饭？',
      time: '3天前',
      unread: 0,
      online: false,
      messages: [
        _Message(text: '周末一起吃饭？', isMe: false, time: '3天前 18:30'),
        _Message(text: '可以，老地方？', isMe: true, time: '3天前 18:35'),
        _Message(text: '行，周六中午', isMe: false, time: '3天前 18:36'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('聊天示例')),
      body: AdaptiveLayoutBuilder(
        compact: (_) => _buildContactList(context, isCompact: true),
        medium: (constraints) => _buildSplitLayout(context, constraints),
      ),
    );
  }

  /// 联系人列表
  Widget _buildContactList(BuildContext context, {required bool isCompact}) {
    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _ContactTile(
          contact: contact,
          isSelected: !isCompact && _selectedContact == index,
          onTap: () {
            if (isCompact) {
              _pushChatPage(context, contact);
            } else {
              setState(() => _selectedContact = index);
            }
          },
        );
      },
    );
  }

  /// 平板布局：联系人 + 对话窗口
  Widget _buildSplitLayout(BuildContext context, BoxConstraints constraints) {
    final contactWidth = ResponsiveBreakpoints.isExpanded(constraints)
        ? 360.0
        : 300.0;

    return Row(
      children: [
        SizedBox(
          width: contactWidth,
          child: _buildContactList(context, isCompact: false),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedContact != null
              ? Column(
                  children: [
                    // 联系人头部：明确标识当前对话对象
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Text(
                                  _contacts[_selectedContact!].avatar,
                                ),
                              ),
                              if (_contacts[_selectedContact!].online)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _contacts[_selectedContact!].name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_contacts[_selectedContact!].online) ...[
                            const SizedBox(width: 8),
                            Text(
                              '在线',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.green),
                            ),
                          ],
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                setState(() => _selectedContact = null),
                            icon: const Icon(Icons.close),
                            tooltip: '关闭对话',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _ChatPanel(
                        contact: _contacts[_selectedContact!],
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '选择一个对话',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  /// 手机模式：使用 Navigator.push 打开全屏对话页
  ///
  /// 此处有意保留原生 Navigator.push 而非 AutoRoute，原因：
  /// 1. 对话页是页面内部的临时视图，不是全局导航目的地
  /// 2. 接收的 [_Contact] 是页面私有数据类，不适合作为路由参数序列化
  /// 3. 不需要 deep link、路由守卫等 AutoRoute 特性
  ///
  /// 如果业务中需要支持 deep link 或路由守卫，应参考 [MasterDetailPage]
  /// 将详情页提取为独立的 @RoutePage 并通过 context.router.push() 导航。
  void _pushChatPage(BuildContext context, _Contact contact) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Text(contact.name),
                  if (contact.online) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            body: _ChatPanel(contact: contact),
          ),
        ),
      ),
    );
  }
}

// ── 子组件 ────────────────────────────────────────────────────────────────

class _Contact {
  const _Contact({
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.online,
    this.messages,
  });

  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unread;
  final bool online;

  /// 该联系人的对话内容；null 时 [_ChatPanel] 使用默认消息。
  final List<_Message>? messages;
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });
  final _Contact contact;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      // 选中态背景绘制在 ListTile 自己的 Material 上，
      // 避免外层 ColoredBox 遮挡水波纹（Flutter 框架会对此报异常）
      selected: isSelected,
      selectedTileColor: colorScheme.secondaryContainer,
      selectedColor: colorScheme.onSecondaryContainer,
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            child: Text(
              contact.avatar,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          if (contact.online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        contact.name,
        style: TextStyle(
          fontWeight: contact.unread > 0 || isSelected
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        contact.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(contact.time, style: Theme.of(context).textTheme.bodySmall),
          if (contact.unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${contact.unread}',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 对话面板（手机和平板共用）
class _ChatPanel extends StatelessWidget {
  const _ChatPanel({required this.contact});
  final _Contact contact;

  @override
  Widget build(BuildContext context) {
    final messages =
        contact.messages ??
        const <_Message>[
          _Message(text: '你好！最近项目进展怎么样？', isMe: false, time: '10:20'),
          _Message(text: '还不错，正在做平板适配的功能', isMe: true, time: '10:22'),
          _Message(text: '这种方案不错，折叠屏也能支持', isMe: false, time: '10:26'),
          _Message(text: '好的，明天见！', isMe: false, time: '10:30'),
        ];

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: messages.length,
            itemBuilder: (context, index) =>
                _MessageBubble(message: messages[index]),
          ),
        ),
        // 底部输入框
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline),
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {},
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Message {
  const _Message({required this.text, required this.isMe, required this.time});
  final String text;
  final bool isMe;
  final String time;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 14,
              child: Text('友', style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isMe
                          ? Colors.white70
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
