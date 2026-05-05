import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentra_app/core/models/scan_prefill.dart';
import 'package:sentra_app/core/services/ocr_service.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/screens/add_transaction_screen.dart';

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

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
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
      // Always start with the back camera (index 0)
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras[0],
      );
      await _startCamera(back);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final ctrl = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _controller = ctrl;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera start: $e');
      ctrl.dispose();
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    setState(() => _flashOn = !_flashOn);
    await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _capture() async {
    if (_controller == null || !_isInitialized || _isProcessing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);
    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;
      final result = await OcrService.processReceipt(file.path);
      if (!mounted) return;
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, a, secondary) => AddTransactionScreen(
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
          transitionsBuilder: (_, a, secondary, child) {
            final tween = Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(position: a.drive(tween), child: child);
          },
        ),
      );
      if (result.warning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.warning!),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on CameraException catch (e) {
      if (mounted) _showError('Gagal mengambil foto: ${e.description}');
    } catch (e) {
      debugPrint('Capture error: $e');
      final rawMsg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      final msg = rawMsg.length > 120 ? '${rawMsg.substring(0, 120)}…' : rawMsg;
      if (mounted) _showError(msg.isNotEmpty ? msg : 'Gagal memproses foto. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.expense,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(),
                ),
                if (_isProcessing) _buildProcessingOverlay(),
                _buildBottomControls(),
              ],
            ),
    );
  }

  Widget _buildPreview() {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: CustomPaint(painter: _GridPainter()),
      );
    }
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height:
                MediaQuery.of(context).size.width *
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
              child: _iconBtn(
                Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.no_photography_rounded,
                    color: AppColors.expense,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Izin Kamera Diperlukan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sentra membutuhkan akses kamera untuk scan struk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
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
                      child: Text(
                        'Buka Pengaturan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    'Kembali',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _iconBtn(
              Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'Scan Struk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _iconBtn(
              _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              onTap: _toggleFlash,
              active: _flashOn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withAlpha(180),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.income),
            SizedBox(height: 16),
            Text(
              'Memproses foto...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 48,
          right: 48,
          top: 24,
          bottom: bottom + 32,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withAlpha(230)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isProcessing)
              const Text(
                'Arahkan kamera ke struk belanja',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 13),
              )
            else
              const SizedBox(height: 18),
            const SizedBox(height: 16),
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => GestureDetector(
                  onTap: _isProcessing ? null : _capture,
                  child: Transform.scale(
                    scale: _isProcessing ? _pulseAnim.value : 1.0,
                    child: Container(
                      width: 76,
                      height: 76,
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
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 2),
                        ),
                        child: Icon(
                          _isProcessing
                              ? Icons.hourglass_top_rounded
                              : Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(
    IconData icon, {
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withAlpha(76) : Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppColors.primary.withAlpha(153) : Colors.white24,
          ),
        ),
        child: Icon(
          icon,
          color: active ? AppColors.primaryLight : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
