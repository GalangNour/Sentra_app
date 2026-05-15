import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/services/quick_parse_service.dart';
import 'package:sentra_app/core/services/voice_input_service.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/screens/multi_parse_result_screen.dart';
import 'package:sentra_app/screens/quick_parse_result_screen.dart';

class QuickInputScreen extends StatefulWidget {
  const QuickInputScreen({super.key, this.autoStartVoice = false});

  final bool autoStartVoice;

  @override
  State<QuickInputScreen> createState() => _QuickInputScreenState();
}

class _QuickInputScreenState extends State<QuickInputScreen>
    with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _voice = VoiceInputService();

  bool _hasText = false;
  bool _loading = false;
  bool _useAI = true;
  bool _isListening = false;
  bool _speechAvailable = false;
  double _soundLevel = 0.0;
  bool _isButtonPressed = false;

  late final AnimationController _waveCtrl;
  late final AnimationController _loadingCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _loadingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _initVoice();
  }

  Future<void> _initVoice() async {
    final available = await _voice.init();
    if (!mounted) return;
    setState(() => _speechAvailable = available);
    if (available && widget.autoStartVoice) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _toggleVoice();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _waveCtrl.dispose();
    _loadingCtrl.dispose();
    _voice.cancel();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      HapticFeedback.selectionClick();
      await _voice.stop();
      setState(() {
        _isListening = false;
        _soundLevel = 0;
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _isListening = true);
      await _voice.startListening(
        onResult: _onVoiceResult,
        onError: _onVoiceError,
        onSoundLevel: (level) {
          if (mounted) setState(() => _soundLevel = level.clamp(0.0, 10.0));
        },
      );
    }
  }

  void _onVoiceResult(String text, bool isFinal) {
    if (!mounted) return;
    _ctrl.text = text;
    _ctrl.selection = TextSelection.collapsed(offset: text.length);
    if (isFinal) {
      setState(() {
        _isListening = false;
        _soundLevel = 0;
      });
      if (text.isNotEmpty) HapticFeedback.selectionClick();
    }
  }

  void _onVoiceError(String error) {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _soundLevel = 0;
    });
    if (error != 'error_speech_timeout' && error != 'error_no_match') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Suara tidak terdeteksi, coba lagi'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    if (_isListening) {
      await _voice.stop();
      setState(() {
        _isListening = false;
        _soundLevel = 0;
      });
    }

    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    if (_useAI) _loadingCtrl.repeat();

    try {
      final results = await QuickParseService.parse(text, useAI: _useAI);
      if (!mounted) return;
      if (results.length == 1) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuickParseResultScreen(parsed: results.first),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MultiParseResultScreen(transactions: results),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses: ${e.toString()}'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        _loadingCtrl.stop();
        _loadingCtrl.reset();
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(),
                    if (_speechAvailable) ...[
                      const SizedBox(height: 16),
                      _buildMicSection(),
                    ],
                    const SizedBox(height: 24),
                    _buildExamples(),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 2),
          ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
            child: const Text(
              'Ketik Cepat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          _buildAIToggle(),
        ],
      ),
    );
  }

  Widget _buildAIToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _useAI = !_useAI);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _togglePill(
              icon: Icons.auto_awesome_rounded,
              label: 'AI',
              active: _useAI,
              color: AppColors.primary,
            ),
            const SizedBox(width: 2),
            _togglePill(
              icon: Icons.edit_rounded,
              label: 'Manual',
              active: !_useAI,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _togglePill({
    required IconData icon,
    required String label,
    required bool active,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? color.withAlpha(30) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: active ? color : AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? color : AppColors.textMuted,
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ceritakan transaksimu',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (_useAI)
              Text(
                'AI akan menganalisis otomatis',
                style: TextStyle(color: AppColors.primaryLight, fontSize: 11),
              )
            else
              Text(
                'Parsing lokal, instan',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hasText
                  ? (_useAI ? AppColors.primary : AppColors.textSecondary)
                      .withAlpha(120)
                  : AppColors.surfaceBorder,
            ),
            boxShadow: _hasText
                ? [
                    BoxShadow(
                      color:
                          (_useAI ? AppColors.primary : AppColors.textSecondary)
                              .withAlpha(20),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: null,
            minLines: 5,
            textInputAction: TextInputAction.newline,
            enabled: !_loading,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: _useAI
                  ? 'Contoh: kemarin beli kopi 15rb, bensin 30k'
                  : 'Contoh: beli kopi 15rb',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                height: 1.6,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMicSection() {
    return GestureDetector(
      onTap: _loading ? null : _toggleVoice,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _isListening
              ? AppColors.expense.withAlpha(18)
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isListening
                ? AppColors.expense.withAlpha(160)
                : AppColors.surfaceBorder,
          ),
          boxShadow: _isListening
              ? [
                  BoxShadow(
                    color: AppColors.expense.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? AppColors.expense
                        : AppColors.surfaceElevated,
                    border: Border.all(
                      color: _isListening
                          ? AppColors.expense
                          : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color:
                        _isListening ? Colors.white : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isListening ? 'Mendengarkan...' : 'Gunakan suara',
                      style: TextStyle(
                        color: _isListening
                            ? AppColors.expense
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _isListening
                          ? 'Ketuk untuk berhenti'
                          : 'Ucapkan transaksimu',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (!_isListening)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isListening
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildWaveform(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    const barCount = 28;
    const maxBarHeight = 32.0;
    const minBarHeight = 3.0;

    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (context, _) {
        final t = _waveCtrl.value;
        // Normalize sound level 0–10 → 0.0–1.0, with floor so bars never flat
        final energy = (_soundLevel / 10.0).clamp(0.05, 1.0);

        return SizedBox(
          height: maxBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barCount, (i) {
              // Each bar gets a unique wave phase
              final phase = (i / barCount) * 2 * pi;
              final wave = (sin(t * 2 * pi + phase) + 1) / 2; // 0.0 – 1.0
              final height =
                  minBarHeight + wave * energy * (maxBarHeight - minBarHeight);

              // Color: center bars slightly brighter
              final center = (barCount - 1) / 2;
              final dist = (i - center).abs() / center;
              final alpha = (255 * (1.0 - dist * 0.5)).round();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  width: 3,
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withAlpha(alpha),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildExamples() {
    final examples = _useAI
        ? const [
            ('kemarin beli kopi 15rb, bensin 30k', 'Multi · 2 transaksi'),
            ('gajian bulan ini 5jt', 'Pemasukan · Gaji'),
            ('bayar listrik 200.000 dan nonton netflix', 'Multi · 2 transaksi'),
          ]
        : const [
            ('beli kopi 15rb', 'Pengeluaran · Makanan'),
            ('gajian bulan ini 5jt', 'Pemasukan · Gaji'),
            ('bayar listrik 200.000', 'Pengeluaran · Tagihan'),
            ('nonton bioskop 120rb', 'Pengeluaran · Hiburan'),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTOH PENULISAN',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ...examples.map((e) => _exampleTile(e.$1, e.$2)),
      ],
    );
  }

  Widget _exampleTile(String input, String hint) {
    return GestureDetector(
      onTap: _loading
          ? null
          : () {
              HapticFeedback.selectionClick();
              _ctrl.text = input;
              _ctrl.selection = TextSelection.collapsed(offset: input.length);
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"$input"',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.north_west_rounded,
              size: 13,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final active = _hasText && !_loading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _isButtonPressed = true) : null,
        onTapUp: active
            ? (_) {
                setState(() => _isButtonPressed = false);
                _submit();
              }
            : null,
        onTapCancel: () => setState(() => _isButtonPressed = false),
        child: AnimatedScale(
          scale: _isButtonPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: _loading && _useAI
              ? _buildAILoadingButton()
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: active ? AppColors.primaryGradient : null,
                    color: active ? null : AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(90),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: _loading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Memproses...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_useAI) ...[
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: active ? Colors.white : AppColors.textMuted,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              _useAI ? 'Analisis dengan AI' : 'Lanjut',
                              style: TextStyle(
                                color: active ? Colors.white : AppColors.textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: active ? Colors.white : AppColors.textMuted,
                              size: 18,
                            ),
                          ],
                        ),
                ),
        ),
      ),
    );
  }

  Widget _buildAILoadingButton() {
    return AnimatedBuilder(
      animation: _loadingCtrl,
      builder: (context, _) {
        final t = _loadingCtrl.value;
        final shimmer = (t * 2 - 0.5).clamp(0.0, 1.0);
        final glowAlpha = (80 + sin(t * 2 * pi) * 30).round().clamp(50, 110);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primaryLight,
                AppColors.primaryDark,
              ],
              stops: [
                (shimmer - 0.35).clamp(0.0, 1.0),
                shimmer.clamp(0.0, 1.0),
                (shimmer + 0.35).clamp(0.0, 1.0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(glowAlpha),
                blurRadius: 24 + sin(t * 2 * pi) * 6,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: t * 2 * pi,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Menganalisis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _buildAnimatedDots(t),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDots(double t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = ((t - i / 3) % 1.0 + 1.0) % 1.0;
        final opacity = (sin(phase * pi)).clamp(0.2, 1.0);
        return Opacity(
          opacity: opacity,
          child: const Text(
            '.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }),
    );
  }
}
