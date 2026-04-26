import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/services/ocr_service.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/screens/add_transaction_screen.dart';

class ScanRegionScreen extends StatefulWidget {
  final String imagePath;
  const ScanRegionScreen({super.key, required this.imagePath});

  @override
  State<ScanRegionScreen> createState() => _ScanRegionScreenState();
}

class _ScanRegionScreenState extends State<ScanRegionScreen> {
  // Selection as fractions (0.0–1.0) of the displayed image area.
  // Default: bottom ~47% of the image — where receipt totals usually appear.
  double _l = 0.03, _t = 0.50, _r = 0.97, _b = 0.97;

  bool _isProcessing = false;
  Size? _imageSize; // actual pixel dimensions of the captured image

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() => _imageSize = Size(
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          ));
      frame.image.dispose();
    }
  }

  // Returns the sub-rect inside [container] where the image is rendered
  // when using BoxFit.contain (letterboxed / pillarboxed).
  static Rect _fittedRect(Size container, Size image) {
    final cA = container.width / container.height;
    final iA = image.width / image.height;
    if (iA > cA) {
      final h = container.width / iA;
      return Rect.fromLTWH(0, (container.height - h) / 2, container.width, h);
    }
    final w = container.height * iA;
    return Rect.fromLTWH((container.width - w) / 2, 0, w, container.height);
  }

  static const double _kMin = 0.08; // minimum selection fraction

  void _updateHandle({
    double dl = 0,
    double dt = 0,
    double dr = 0,
    double db = 0,
    required Size dSize,
  }) {
    setState(() {
      final fw = 1 / dSize.width;
      final fh = 1 / dSize.height;
      _l = (_l + dl * fw).clamp(0.0, _r - _kMin);
      _t = (_t + dt * fh).clamp(0.0, _b - _kMin);
      _r = (_r + dr * fw).clamp(_l + _kMin, 1.0);
      _b = (_b + db * fh).clamp(_t + _kMin, 1.0);
    });
  }

  void _moveBox(Offset delta, Size dSize) {
    final w = _r - _l;
    final h = _b - _t;
    setState(() {
      _l = (_l + delta.dx / dSize.width).clamp(0.0, 1.0 - w);
      _r = _l + w;
      _t = (_t + delta.dy / dSize.height).clamp(0.0, 1.0 - h);
      _b = _t + h;
    });
  }

  Future<void> _scan({bool fullImage = false}) async {
    if (_isProcessing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);
    try {
      final scanPath =
          (!fullImage && _imageSize != null) ? await _cropImage() : widget.imagePath;
      final result = await OcrService.processReceipt(scanPath);
      if (!mounted) return;
      final warning = result.warning;
      await Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, a, __) => AddTransactionScreen(
          scanData: ScanPrefill(
            merchant: result.merchant,
            total: result.total,
            category: result.category,
            imagePath: result.imagePath,
            rawText: result.rawText,
            source: result.source,
            warning: result.warning,
            candidateAmounts: result.candidateAmounts,
          ),
        ),
        transitionsBuilder: (_, a, __, child) {
          final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(position: a.drive(tween), child: child);
        },
      ));
      if (warning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(warning),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      debugPrint('ScanRegion error: $e');
      if (mounted) {
        // Extract a readable message — strip the leading 'Exception: ' prefix
        final rawMsg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        final msg = rawMsg.length > 120 ? '${rawMsg.substring(0, 120)}…' : rawMsg;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.isNotEmpty ? msg : 'Gagal memproses area. Coba lagi.'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 6),
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String> _cropImage() async {
    final iSize = _imageSize!;
    final srcRect = Rect.fromLTRB(
      _l * iSize.width,
      _t * iSize.height,
      _r * iSize.width,
      _b * iSize.height,
    );
    final cropW = srcRect.width.round();
    final cropH = srcRect.height.round();

    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;

    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      src,
      srcRect,
      Rect.fromLTWH(0, 0, cropW.toDouble(), cropH.toDouble()),
      Paint(),
    );
    src.dispose();

    final cropped = await recorder.endRecording().toImage(cropW, cropH);
    final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
    cropped.dispose();

    if (data == null) throw Exception('Gagal memotong gambar');
    final dir = File(widget.imagePath).parent.path;
    final outPath = '$dir/crop_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(outPath).writeAsBytes(data.buffer.asUint8List());
    return outPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (context, constraints) {
        final containerSize = constraints.biggest;
        final iSize = _imageSize ?? const Size(3, 4); // fallback portrait ratio
        final dRect = _fittedRect(containerSize, iSize);

        final selRect = Rect.fromLTRB(
          dRect.left + _l * dRect.width,
          dRect.top + _t * dRect.height,
          dRect.left + _r * dRect.width,
          dRect.top + _b * dRect.height,
        );

        return Stack(fit: StackFit.expand, children: [
          Image.file(File(widget.imagePath), fit: BoxFit.contain),
          CustomPaint(
            size: containerSize,
            painter: _SelectionPainter(selRect),
          ),
          // Interior — drag to move the entire box
          Positioned.fromRect(
            rect: selRect,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => _moveBox(d.delta, dRect.size),
              child: const SizedBox.expand(),
            ),
          ),
          // 4 corner drag handles for resizing
          ..._buildCornerHandles(selRect, dRect.size),
          _buildTopBar(),
          _buildBottomBar(),
          if (_isProcessing) _buildLoadingOverlay(),
        ]);
      }),
    );
  }

  List<Widget> _buildCornerHandles(Rect sel, Size dSize) {
    const s = 48.0; // touch target
    const dot = 13.0; // visual dot

    Widget handle(Offset pos, void Function(Offset) onDrag) => Positioned(
          left: pos.dx - s / 2,
          top: pos.dy - s / 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => onDrag(d.delta),
            child: SizedBox(
              width: s,
              height: s,
              child: Center(
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withAlpha(160),
                          blurRadius: 10,
                          spreadRadius: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    return [
      handle(sel.topLeft,     (d) => _updateHandle(dl: d.dx, dt: d.dy, dSize: dSize)),
      handle(sel.topRight,    (d) => _updateHandle(dr: d.dx, dt: d.dy, dSize: dSize)),
      handle(sel.bottomLeft,  (d) => _updateHandle(dl: d.dx, db: d.dy, dSize: dSize)),
      handle(sel.bottomRight, (d) => _updateHandle(dr: d.dx, db: d.dy, dSize: dSize)),
    ];
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'Pilih Area Scan',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withAlpha(220)],
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Seret sudut untuk menyesuaikan area yang ingin di-scan',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _isProcessing ? null : () => _scan(fullImage: true),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Center(
                    child: Text('Scan Semua',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _isProcessing ? null : () => _scan(),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withAlpha(100),
                          blurRadius: 16,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Text('Scan Area Ini',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: AppColors.income),
          SizedBox(height: 16),
          Text('Memproses area...',
              style: TextStyle(color: Colors.white, fontSize: 14)),
        ]),
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _SelectionPainter extends CustomPainter {
  final Rect sel;
  _SelectionPainter(this.sel);

  @override
  void paint(Canvas canvas, Size size) {
    // Dim outside the selection
    canvas.drawPath(
      Path()
        ..addRect(Offset.zero & size)
        ..addRect(sel)
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withAlpha(155),
    );

    // Thin border around selection
    canvas.drawRect(
      sel,
      Paint()
        ..color = AppColors.primary.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Corner bracket accents
    final p = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 20.0, cr = 6.0;

    void corner(double cx, double cy, double sx, double sy) {
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy + sy * len)
          ..lineTo(cx, cy + sy * cr)
          ..quadraticBezierTo(cx, cy, cx + sx * cr, cy)
          ..lineTo(cx + sx * len, cy),
        p,
      );
    }

    corner(sel.left,  sel.top,     1,  1);
    corner(sel.right, sel.top,    -1,  1);
    corner(sel.left,  sel.bottom,  1, -1);
    corner(sel.right, sel.bottom, -1, -1);
  }

  @override
  bool shouldRepaint(_SelectionPainter old) => old.sel != sel;
}
