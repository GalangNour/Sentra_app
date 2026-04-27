import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/services/quick_parse_service.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/screens/multi_parse_result_screen.dart';
import 'package:sentra_app/screens/quick_parse_result_screen.dart';

class QuickInputScreen extends StatefulWidget {
  const QuickInputScreen({super.key});

  @override
  State<QuickInputScreen> createState() => _QuickInputScreenState();
}

class _QuickInputScreenState extends State<QuickInputScreen> {
  final _ctrl = TextEditingController();
  bool _hasText = false;
  bool _loading = false;
  bool _useAI = true;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    try {
      final results = await QuickParseService.parse(text, useAI: _useAI);
      if (!mounted) return;
      if (results.length == 1) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => QuickParseResultScreen(parsed: results.first)),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MultiParseResultScreen(transactions: results)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal memproses: ${e.toString()}'),
        backgroundColor: AppColors.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
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
                  ? (_useAI ? AppColors.primary : AppColors.textSecondary).withAlpha(120)
                  : AppColors.surfaceBorder,
            ),
            boxShadow: _hasText
                ? [
                    BoxShadow(
                      color: (_useAI ? AppColors.primary : AppColors.textSecondary).withAlpha(20),
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
            Icon(Icons.north_west_rounded, size: 13, color: AppColors.textMuted),
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
        onTap: active ? _submit : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: active ? AppColors.primaryGradient : null,
            color: active ? null : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [BoxShadow(color: AppColors.primary.withAlpha(90), blurRadius: 20, offset: const Offset(0, 6))]
                : null,
          ),
          child: _loading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _useAI ? 'Menganalisis...' : 'Memproses...',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_useAI) ...[
                      Icon(Icons.auto_awesome_rounded, color: active ? Colors.white : AppColors.textMuted, size: 16),
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
                    Icon(Icons.arrow_forward_rounded, color: active ? Colors.white : AppColors.textMuted, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}
