import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentra_app/core/services/app_state.dart';
import 'package:sentra_app/core/services/ocr_service.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/core/utils/app_utils.dart';
import 'package:sentra_app/screens/scan_result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _flashOn = false;
  bool _permissionDenied = false;
  int _selectedModeIndex = 0;
  int _selectedCameraIndex = 0;

  final List<String> _modes = ['Struk', 'Transfer', 'Invoice', 'Manual'];

  late AnimationController _scanLineCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _scanLineAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.linear));
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _permissionDenied = true);
        return;
      }
      await _startCamera(_cameras[0]);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final ctrl = CameraController(camera, ResolutionPreset.high,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
    try {
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _controller = ctrl; _isInitialized = true; });
    } catch (e) {
      debugPrint('Camera start: $e');
      ctrl.dispose();
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isInitialized = false);
    await _controller?.dispose();
    await _startCamera(_cameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    setState(() => _flashOn = !_flashOn);
    await _controller!.setFlashMode(
        _flashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _capture() async {
    if (_controller == null || !_isInitialized || _isProcessing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);
    _scanLineCtrl.repeat();
    try {
      final XFile file = await _controller!.takePicture();
      final ParsedReceiptData parsed =
          await OcrService.processReceipt(file.path);
      if (!mounted) return;
      _scanLineCtrl.stop();
      await Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, a, __) => ScanResultScreen(data: parsed),
        transitionsBuilder: (_, a, __, child) {
          final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(position: a.drive(tween), child: child);
        },
      ));
    } on CameraException catch (e) {
      _scanLineCtrl.stop();
      if (mounted) _showError('Gagal mengambil foto: ${e.description}');
    } catch (e) {
      debugPrint('OCR error: $e');
      _scanLineCtrl.stop();
      if (mounted) _showError('Gagal memproses struk. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.expense,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _controller?.dispose();
    OcrService.close();
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _permissionDenied
          ? _buildPermissionDenied()
          : Stack(
              fit: StackFit.expand,
              children: [
                _buildPreview(),
                _buildTopBar(),
                _buildScanFrame(),
                if (_isProcessing) _buildScanLine(),
                _buildModeSelector(),
                _buildBottomControls(),
              ],
            ),
    );
  }

  Widget _buildPreview() {
    if (!_isInitialized || _controller == null) {
      return Container(color: Colors.black,
          child: CustomPaint(painter: _GridPainter()));
    }
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width *
                _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.topLeft,
              child: _iconBtn(Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop()),
            ),
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.no_photography_rounded,
                      color: AppColors.expense, size: 36),
                ),
                const SizedBox(height: 20),
                const Text('Izin Kamera Diperlukan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                const Text(
                  'Sentra membutuhkan akses kamera untuk scan struk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: openAppSettings,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Buka Pengaturan',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text('Kembali',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 14)),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _iconBtn(Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop()),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text('Scan Struk',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                Row(
                  children: [
                    if (_cameras.length > 1) ...[
                      _iconBtn(Icons.flip_camera_android_rounded,
                          onTap: _switchCamera),
                      const SizedBox(width: 8),
                    ],
                    _iconBtn(
                      _flashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: _toggleFlash,
                      active: _flashOn,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon,
      {required VoidCallback onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withAlpha(76) : Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(
              color: active
                  ? AppColors.primary.withAlpha(153)
                  : Colors.white24),
        ),
        child: Icon(icon,
            color: active ? AppColors.primaryLight : Colors.white,
            size: 20),
      ),
    );
  }

  Widget _buildScanFrame() {
    final w = MediaQuery.of(context).size.width * 0.82;
    final h = w * 1.35;
    return Center(
      child: SizedBox(
        width: w, height: h,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(w, h),
              painter: _FramePainter(
                  color: _isProcessing
                      ? AppColors.income
                      : AppColors.primary),
            ),
            Positioned(
              bottom: -52, left: 0, right: 0,
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.income),
                        ),
                        const SizedBox(width: 8),
                        Text('Memproses struk...',
                            style: TextStyle(
                                color: AppColors.income,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    )
                  : !_isInitialized
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 8),
                            const Text('Memuat kamera...',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13)),
                          ],
                        )
                      : const Text(
                          'Arahkan kamera ke struk belanja',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white60, fontSize: 13),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanLine() {
    final w = MediaQuery.of(context).size.width * 0.82;
    final h = w * 1.35;
    return Center(
      child: ClipRect(
        child: SizedBox(
          width: w, height: h,
          child: AnimatedBuilder(
            animation: _scanLineAnim,
            builder: (_, __) => Stack(
              children: [
                Positioned(
                  top: _scanLineAnim.value * h,
                  left: 0, right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        AppColors.income.withAlpha(204),
                        AppColors.income,
                        AppColors.income.withAlpha(204),
                        Colors.transparent,
                      ]),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.income.withAlpha(153),
                            blurRadius: 12, spreadRadius: 3)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: bottom + 110, left: 0, right: 0,
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _modes.length,
          itemBuilder: (_, i) {
            final sel = i == _selectedModeIndex;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedModeIndex = i);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.primary.withAlpha(230)
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color:
                          sel ? AppColors.primary : Colors.white24),
                ),
                child: Text(_modes[i],
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.white60,
                        fontSize: 13,
                        fontWeight: sel
                            ? FontWeight.w600
                            : FontWeight.w400)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
            left: 48, right: 48, top: 20, bottom: bottom + 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withAlpha(230)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _sideBtn(Icons.photo_library_outlined, onTap: () {}),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => GestureDetector(
                onTap: _isProcessing ? null : _capture,
                child: Transform.scale(
                  scale: _isProcessing ? _pulseAnim.value : 1.0,
                  child: Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isProcessing
                          ? AppColors.incomeGradient
                          : AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: (_isProcessing
                                  ? AppColors.income
                                  : AppColors.primary)
                              .withAlpha(128),
                          blurRadius: 24, spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white30, width: 2),
                      ),
                      child: Icon(
                        _isProcessing
                            ? Icons.hourglass_top_rounded
                            : Icons.camera_alt_rounded,
                        color: Colors.white, size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _sideBtn(Icons.edit_rounded,
                onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  Widget _sideBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────

class _FramePainter extends CustomPainter {
  final Color color;
  _FramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 28.0, r = 10.0;
    final paths = [
      Path()..moveTo(0, len)..lineTo(0, r)
            ..quadraticBezierTo(0, 0, r, 0)..lineTo(len, 0),
      Path()..moveTo(size.width - len, 0)
            ..lineTo(size.width - r, 0)
            ..quadraticBezierTo(size.width, 0, size.width, r)
            ..lineTo(size.width, len),
      Path()..moveTo(0, size.height - len)
            ..lineTo(0, size.height - r)
            ..quadraticBezierTo(0, size.height, r, size.height)
            ..lineTo(len, size.height),
      Path()..moveTo(size.width - len, size.height)
            ..lineTo(size.width - r, size.height)
            ..quadraticBezierTo(size.width, size.height, size.width, size.height - r)
            ..lineTo(size.width, size.height - len),
    ];
    final glow = Paint()
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (final path in paths) {
      canvas.drawPath(path, p);
      canvas.drawPath(path, glow..color = color.withAlpha(51));
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.color != color;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withAlpha(8)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
