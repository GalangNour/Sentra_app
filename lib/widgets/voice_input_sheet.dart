import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/services/quick_parse_service.dart';
import 'package:sentra_app/core/services/voice_input_service.dart';
import 'package:sentra_app/core/theme/app_theme.dart';

class VoiceInputSheet extends StatefulWidget {
  const VoiceInputSheet({super.key});

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet>
    with SingleTickerProviderStateMixin {
  final _voice = VoiceInputService();

  // Ring buffer — stores last N normalized sound levels (0.0–1.0)
  static const _barCount = 36;
  final _levels = List<double>.filled(_barCount, 0.0);
  int _levelHead = 0;

  String _transcript = '';
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _loading = false;

  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _initAndStart();
  }

  Future<void> _initAndStart() async {
    final available = await _voice.init();
    if (!mounted) return;
    setState(() => _speechAvailable = available);
    if (available) await _startListening();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _levels.fillRange(0, _barCount, 0.0);
      _levelHead = 0;
    });
    await _voice.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _transcript = text);
        if (isFinal) setState(() => _isListening = false);
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
      onSoundLevel: (level) {
        if (!mounted) return;
        setState(() {
          _levels[_levelHead] = (level.clamp(0.0, 10.0) / 10.0);
          _levelHead = (_levelHead + 1) % _barCount;
        });
      },
    );
  }

  Future<void> _restart() async {
    HapticFeedback.selectionClick();
    await _voice.stop();
    setState(() => _transcript = '');
    await _startListening();
  }

  Future<void> _analyze() async {
    if (_transcript.isEmpty || _loading) return;
    HapticFeedback.mediumImpact();
    if (_isListening) {
      await _voice.stop();
      setState(() => _isListening = false);
    }
    setState(() => _loading = true);
    try {
      final results = await QuickParseService.parse(_transcript, useAI: true);
      if (!mounted) return;
      Navigator.of(context).pop(results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal menganalisis, coba lagi'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _voice.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildStatusRow(),
          const SizedBox(height: 28),
          _buildWaveform(),
          const SizedBox(height: 28),
          _buildTranscript(),
          const SizedBox(height: 32),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.surfaceBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening
                  ? AppColors.primary.withAlpha(30)
                  : AppColors.surfaceCard,
              border: Border.all(
                color: _isListening
                    ? AppColors.primary.withAlpha(120)
                    : AppColors.surfaceBorder,
              ),
            ),
            child: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
              color:
                  _isListening ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _loading
                        ? 'Menganalisis...'
                        : _isListening
                            ? 'Sedang mendengarkan'
                            : _transcript.isEmpty
                                ? 'Siap mendengarkan'
                                : 'Selesai merekam',
                    key: ValueKey(_loading
                        ? 'load'
                        : _isListening
                            ? 'listen'
                            : _transcript.isEmpty
                                ? 'ready'
                                : 'done'),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isListening
                      ? 'Ucapkan transaksimu sekarang'
                      : _transcript.isEmpty
                          ? 'Ketuk mic untuk mencoba lagi'
                          : 'Periksa teks lalu analisis',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    const maxH = 64.0;
    const minH = 3.0;

    return SizedBox(
      height: maxH,
      child: AnimatedBuilder(
        animation: _waveCtrl,
        builder: (_, __) {
          final t = _waveCtrl.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_barCount, (i) {
              // History bar from ring buffer
              final bufIdx = (_levelHead + i) % _barCount;
              final historical = _levels[bufIdx];

              // Idle breathing overlay
              final phase = (i / _barCount) * 2 * pi;
              final breath = (sin(t * 2 * pi + phase) + 1) / 2;
              final idle = breath * 0.12;

              final normalized = (historical + idle).clamp(0.0, 1.0);
              final barH = minH + normalized * (maxH - minH);

              // Center bars are brighter
              final center = (_barCount - 1) / 2.0;
              final proximity = 1.0 - ((i - center).abs() / center) * 0.5;
              final alpha = (255 * proximity * (historical > 0.05 ? 1.0 : 0.4)).round().clamp(0, 255);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  width: 4,
                  height: barH,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(alpha),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildTranscript() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _transcript.isEmpty
            ? Text(
                key: const ValueKey('hint'),
                _isListening
                    ? 'Menunggu suara...'
                    : _speechAvailable
                        ? 'Belum ada suara terdeteksi'
                        : 'Perangkat tidak mendukung suara',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              )
            : Container(
                key: const ValueKey('transcript'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  '"$_transcript"',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
      ),
    );
  }

  Widget _buildButtons() {
    final canAnalyze = _transcript.isNotEmpty && !_loading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Restart button
          GestureDetector(
            onTap: _loading ? null : _restart,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: _loading
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ulang',
                    style: TextStyle(
                      color: _loading
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Analyze button
          Expanded(
            child: GestureDetector(
              onTap: canAnalyze ? _analyze : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: canAnalyze ? AppColors.primaryGradient : null,
                  color: canAnalyze ? null : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: canAnalyze
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: canAnalyze
                                  ? Colors.white
                                  : AppColors.textMuted,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Analisis dengan AI',
                              style: TextStyle(
                                color: canAnalyze
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
