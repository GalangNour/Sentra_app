import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/services/ai_context_builder.dart';
import 'package:sentra_app/core/services/ai_service.dart';
import 'package:sentra_app/core/services/finance_snapshot.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/widgets/chat_bubbles/index.dart';

class SentraBrainScreen extends StatefulWidget {
  const SentraBrainScreen({
    super.key,
    required this.snapshot,
    this.initialPrompt,
    this.initialParsed,
  });

  final FinanceSnapshot snapshot;
  final String? initialPrompt;
  final Map<String, dynamic>? initialParsed;

  @override
  State<SentraBrainScreen> createState() => _SentraBrainScreenState();
}

class _SentraBrainScreenState extends State<SentraBrainScreen> {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _systemContext;

  static const List<Map<String, dynamic>> _suggestionsData = [
    {
      'text': 'Bulan ini uang habis dimana?',
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'text': 'Bisa nabung motor kapan?',
      'icon': Icons.savings_rounded,
    },
    {
      'text': 'Pengeluaran makan berapa?',
      'icon': Icons.restaurant_rounded,
    },
    {
      'text': 'Aman ambil cicilan iPhone?',
      'icon': Icons.phone_iphone_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _systemContext = AiContextBuilder.build(widget.snapshot);
    if (widget.initialParsed != null) {
      _messages.add(ChatMessage(
        role: 'assistant',
        text: jsonEncode(widget.initialParsed),
        parsed: widget.initialParsed,
        timestamp: DateTime.now(),
      ));
    } else if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialPrompt!);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;
    HapticFeedback.mediumImpact();
    _controller.clear();

    if (!AiService.isConfigured) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'error',
          text: 'API Key belum dikonfigurasi. Isi geminiApiKey di lib/env.dart',
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
      return;
    }

    // Build history before adding new message (skip errors)
    final history = _messages
        .where((m) => m.role != 'error')
        .toList();

    setState(() {
      _messages.add(ChatMessage(
        role: 'user',
        text: trimmed,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await AiService.sendMessage(
        systemContext: _systemContext,
        history: history,
        userMessage: trimmed,
      );
      if (!mounted) return;
      final parsed = AiService.parseResponse(reply);
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          text: reply,
          parsed: parsed,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          role: 'error',
          text: e.toString().replaceFirst('Exception: ', ''),
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _retryLastMessage() {
    HapticFeedback.selectionClick();
    int lastUserIdx = -1;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'user') {
        lastUserIdx = i;
        break;
      }
    }
    if (lastUserIdx < 0) return;
    final text = _messages[lastUserIdx].text;
    setState(() => _messages.removeRange(lastUserIdx, _messages.length));
    _sendMessage(text);
  }

  void _clearConversation() {
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.clear();
    });
  }

  bool get _showSuggestions => _messages.isEmpty && !_isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!AiService.isConfigured) _buildApiKeyBanner(),
          Expanded(child: _buildChatArea()),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        color: AppColors.surface,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 2),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sentra Brain',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'AI Financial Assistant',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: _clearConversation,
                  tooltip: 'Reset percakapan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withAlpha(30),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'API Key belum dikonfigurasi. Isi geminiApiKey di lib/env.dart',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    final items = <Widget>[];

    if (_showSuggestions) {
      items.add(_buildSuggestions());
    } else {
      for (int i = 0; i < _messages.length; i++) {
        items.add(_buildBubble(_messages[i], i));
      }
    }

    if (_isLoading) items.add(_buildTypingIndicator());

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: items,
    );
  }

  Widget _animatedBubble({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (_, v, w) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: w),
      ),
      child: child,
    );
  }

  Widget _buildBubble(ChatMessage msg, int index) {
    if (msg.role == 'user') {
      return _animatedBubble(
        index: index,
        child: ChatBubbleText(
          text: msg.text,
          timestamp: msg.timestamp,
          isUser: true,
        ),
      );
    }
    if (msg.role == 'error') {
      return _animatedBubble(
        index: index,
        child: _buildErrorBubble(msg),
      );
    }
    return _animatedBubble(
      index: index,
      child: ChatBubbleFactory(
        parsed: msg.parsed ?? {'type': 'text', 'text': msg.text},
        timestamp: msg.timestamp,
        onSendMessage: _sendMessage,
        onSaveData: (_) {},
      ),
    );
  }

  Widget _buildErrorBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.expense.withAlpha(30),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: AppColors.expense.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.expense,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            msg.text,
                            style: const TextStyle(
                              color: AppColors.expense,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _retryLastMessage,
                      child: Text(
                        'Coba lagi →',
                        style: TextStyle(
                          color: AppColors.info,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatTime(msg.timestamp),
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: const _TypingDots(),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hai Sobat Sentra! 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ada yang bisa aku bantu hari ini?',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ..._suggestionsData.asMap().entries.map((entry) {
            return _buildSuggestionCard(entry.value, entry.key);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> data, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 100),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - v)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _sendMessage(data['text'] as String);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  data['icon'] as IconData,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  data['text'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Tanya apa saja...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (_, value, child) {
        final canSend = value.text.trim().isNotEmpty && !_isLoading;
        return GestureDetector(
          onTap: canSend ? () => _sendMessage(_controller.text) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: canSend ? AppColors.primaryGradient : null,
              color: canSend ? null : AppColors.surfaceElevated,
            ),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: canSend ? Colors.white : AppColors.textMuted,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final raw = (_anim.value - i * 0.22).clamp(0.0, 1.0);
            final bounce = raw < 0.5 ? raw * 2 : (1 - raw) * 2;
            return Container(
              margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
              child: Transform.translate(
                offset: Offset(0, -5 * bounce),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
