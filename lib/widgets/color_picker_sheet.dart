import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/theme/app_theme.dart';

// 40 preset colors — 10 per row, 4 rows
const _palette = [
  // Merah & Pink
  Color(0xFFFF1744), Color(0xFFFF4081), Color(0xFFFF6B9D), Color(0xFFE91E63),
  Color(0xFFFF6B6B), Color(0xFFE53935), Color(0xFFFF7043), Color(0xFFFF5722),
  Color(0xFFFF8A65), Color(0xFFBF360C),
  // Oranye & Kuning
  Color(0xFFFF6D00), Color(0xFFFF9100), Color(0xFFFFAB40), Color(0xFFFFC107),
  Color(0xFFFFD740), Color(0xFFFFEB3B), Color(0xFFFDD835), Color(0xFFF9A825),
  Color(0xFFE65100), Color(0xFFF57F17),
  // Hijau & Teal
  Color(0xFF00C896), Color(0xFF00BFA5), Color(0xFF1DE9B6), Color(0xFF26A69A),
  Color(0xFF43A047), Color(0xFF7CB342), Color(0xFF558B2F), Color(0xFF66BB6A),
  Color(0xFF00897B), Color(0xFF4CAF50),
  // Biru & Ungu
  Color(0xFF2979FF), Color(0xFF38BDF8), Color(0xFF0288D1), Color(0xFF304FFE),
  Color(0xFF6C63FF), Color(0xFFB06EF7), Color(0xFF7C4DFF), Color(0xFF9C27B0),
  Color(0xFFD500F9), Color(0xFF651FFF),
];

class ColorPickerSheet extends StatefulWidget {
  final Color current;

  const ColorPickerSheet({super.key, required this.current});

  static Future<Color?> show(BuildContext context, {required Color current}) {
    return showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ColorPickerSheet(current: current),
    );
  }

  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet> {
  late Color _selected;
  late double _hue;
  bool _fromSlider = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _hue = HSVColor.fromColor(widget.current).hue;
    // Detect if current color came from slider (not in palette)
    _fromSlider = !_palette.any(
      (c) => c.toARGB32() == widget.current.toARGB32(),
    );
  }

  Color get _sliderColor =>
      HSVColor.fromAHSV(1.0, _hue, 0.80, 0.90).toColor();

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift above keyboard if needed
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Pilih Warna',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  // Preview chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selected,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pratinjau',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Palette grid ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _palette.length,
                itemBuilder: (_, i) => _paletteCell(_palette[i]),
              ),
            ),

            Divider(
                color: AppColors.surfaceBorder,
                height: 1,
                indent: 16,
                endIndent: 16),

            // ── Custom / Hue slider ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Text(
                    'Custom',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_fromSlider)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _selected.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _selected.withAlpha(100)),
                      ),
                      child: Text(
                        _hexLabel(_selected),
                        style: TextStyle(
                          color: _selected,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _HueSlider(
                hue: _hue,
                onChanged: (h) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _hue = h;
                    _selected = _sliderColor;
                    _fromSlider = true;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.swipe_rounded,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Geser untuk pilih warna',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // ── Action buttons ────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Center(
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop(_selected);
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selected,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _selected.withAlpha(100),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Pilih Warna',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paletteCell(Color color) {
    final isSelected = !_fromSlider &&
        color.toARGB32() == _selected.toARGB32();
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selected = color;
          _fromSlider = false;
          _hue = HSVColor.fromColor(color).hue;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2.5)
              : Border.all(color: Colors.transparent, width: 2.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(140),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded,
                color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  String _hexLabel(Color c) {
    final hex = c.toARGB32().toRadixString(16).toUpperCase();
    return '#${hex.substring(2)}';
  }
}

// ── Hue slider ────────────────────────────────────────────────

class _HueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HueSlider({required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        const thumbR = 14.0;
        final thumbX = (hue / 360.0 * width).clamp(thumbR, width - thumbR);
        final thumbColor =
            HSVColor.fromAHSV(1.0, hue, 0.80, 0.90).toColor();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) =>
              onChanged(_xToHue(d.localPosition.dx, width)),
          onTapDown: (d) =>
              onChanged(_xToHue(d.localPosition.dx, width)),
          child: SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Rainbow bar
                Positioned(
                  left: 0,
                  right: 0,
                  top: 8,
                  bottom: 8,
                  child: CustomPaint(painter: _RainbowPainter()),
                ),
                // Thumb
                Positioned(
                  left: thumbX - thumbR,
                  child: Container(
                    width: thumbR * 2,
                    height: thumbR * 2,
                    decoration: BoxDecoration(
                      color: thumbColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: thumbColor.withAlpha(120),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                        const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _xToHue(double x, double width) =>
      (x / width * 360.0).clamp(0.0, 360.0);
}

class _RainbowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      colors: [
        for (int i = 0; i <= 12; i++)
          HSVColor.fromAHSV(1.0, i * 30.0, 0.80, 0.90).toColor(),
      ],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    final rRect = RRect.fromRectAndRadius(
        rect, Radius.circular(size.height / 2));
    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
