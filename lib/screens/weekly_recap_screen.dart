import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentra_app/core/repositories/recap_repository.dart';
import 'package:sentra_app/core/services/recap_service.dart';
import 'package:sentra_app/core/utils/app_utils.dart';

class WeeklyRecapScreen extends StatefulWidget {
  const WeeklyRecapScreen({
    super.key,
    required this.recapData,
    required this.recapRepository,
  });

  final RecapData recapData;
  final RecapRepository recapRepository;

  @override
  State<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends State<WeeklyRecapScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 5;

  late AnimationController _counterController;
  late Animation<double> _counterAnim;

  @override
  void initState() {
    super.initState();
    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _counterAnim = CurvedAnimation(parent: _counterController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.selectionClick();
    if (page == 1) _counterController.forward(from: 0);
  }

  void _goNext() {
    if (_currentPage < _totalPages - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _dismiss();
    }
  }

  Future<void> _dismiss() async {
    await widget.recapRepository.markSeen();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) async {
        await widget.recapRepository.markSeen();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF080B14),
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildSlide1(),
                  _buildSlide2(),
                  _buildSlide3(),
                  _buildSlide4(),
                  _buildSlide5(),
                ],
              ),
              // Skip button
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: TextButton(
                      onPressed: _dismiss,
                      child: Text(
                        'Lewati',
                        style: TextStyle(
                          color: Colors.white.withAlpha(153),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Page indicator
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildDots(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: i == _currentPage ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: i == _currentPage
                ? Colors.white
                : Colors.white.withAlpha(60),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ─── Slide wrappers ─────────────────────────────────────

  Widget _slide({required Gradient gradient, required Widget child}) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        bottom: false,
        child: child,
      ),
    );
  }

  // ─── Slide 1: Intro ──────────────────────────────────────

  Widget _buildSlide1() {
    return _slide(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1040), Color(0xFF080B14)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withAlpha(100),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 32),
            const Text(
              'Rekap Mingguan\nKamu Siap!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ini ringkasan keuanganmu\ndalam 7 hari terakhir',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 56),
            GestureDetector(
              onTap: _goNext,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withAlpha(40),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Sekarang',
                      style: TextStyle(
                        color: Color(0xFF080B14),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF080B14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ─── Slide 2: Total pengeluaran ──────────────────────────

  Widget _buildSlide2() {
    final data = widget.recapData;
    final isUp = data.changePercent >= 0;
    final changeColor = isUp ? const Color(0xFFFF6B6B) : const Color(0xFF00C896);

    return _slide(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          isUp ? const Color(0xFF1A0808) : const Color(0xFF081A10),
          const Color(0xFF080B14),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 64, 32, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pengeluaran\nMinggu Ini',
              style: TextStyle(
                color: Colors.white.withAlpha(160),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _counterAnim,
              builder: (_, _) {
                return Text(
                  Fmt.full(data.thisWeekExpense * _counterAnim.value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: changeColor.withAlpha(35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: changeColor.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: changeColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${data.changePercent.abs().toStringAsFixed(1)}% vs minggu lalu',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (data.lastWeekExpense > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Minggu lalu: ${Fmt.full(data.lastWeekExpense)}',
                style: TextStyle(
                  color: Colors.white.withAlpha(90),
                  fontSize: 14,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Tidak ada data minggu lalu',
                style: TextStyle(
                  color: Colors.white.withAlpha(90),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _goNext,
              child: _nextButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Slide 3: Kategori terboros ──────────────────────────

  Widget _buildSlide3() {
    final data = widget.recapData;

    return _slide(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0E0A1C), Color(0xFF080B14)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 64, 32, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kategori\nTerboros',
              style: TextStyle(
                color: Colors.white.withAlpha(160),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            if (data.top3Categories.isEmpty)
              Text(
                'Tidak ada pengeluaran\nminggu ini.',
                style: TextStyle(
                  color: Colors.white.withAlpha(128),
                  fontSize: 18,
                  height: 1.5,
                ),
              )
            else ...[
              // Top category featured
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: data.top3Categories.first.color.withAlpha(35),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: data.top3Categories.first.color.withAlpha(80),
                      ),
                    ),
                    child: Icon(
                      data.top3Categories.first.icon,
                      color: data.top3Categories.first.color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.top3Categories.first.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          Fmt.full(data.top3Categories.first.amount),
                          style: TextStyle(
                            color: data.top3Categories.first.color,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Progress bars top 3
              ...data.top3Categories.asMap().entries.map((e) {
                final cat = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(cat.icon, color: cat.color, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            Fmt.compact(cat.amount),
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cat.percentage.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withAlpha(18),
                          valueColor: AlwaysStoppedAnimation(cat.color.withAlpha(200)),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            GestureDetector(onTap: _goNext, child: _nextButton()),
          ],
        ),
      ),
    );
  }

  // ─── Slide 4: Hari paling boros ──────────────────────────

  Widget _buildSlide4() {
    final data = widget.recapData;

    return _slide(
      gradient: const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF0A1222), Color(0xFF080B14)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 64, 32, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hari Paling\nBoros',
              style: TextStyle(
                color: Colors.white.withAlpha(160),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (data.busiestDayName != null) ...[
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFFB547), Color(0xFFFF8C42)],
                ).createShader(b),
                child: Text(
                  data.busiestDayName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Text(
                Fmt.full(data.busiestDayAmount),
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else
              Text(
                'Tidak ada\ndata minggu ini',
                style: TextStyle(
                  color: Colors.white.withAlpha(128),
                  fontSize: 28,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 28),
            if (data.biggestTransaction != null) ...[
              Text(
                'Transaksi Terbesar',
                style: TextStyle(
                  color: Colors.white.withAlpha(110),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.biggestTransaction!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Fmt.full(data.biggestTransaction!.amount),
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            GestureDetector(onTap: _goNext, child: _nextButton()),
          ],
        ),
      ),
    );
  }

  // ─── Slide 5: Closing ────────────────────────────────────

  Widget _buildSlide5() {
    final data = widget.recapData;

    return _slide(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF060E20), Color(0xFF100520)],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF38BDF8)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withAlpha(100),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sentra Brain Berkata...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withAlpha(22)),
              ),
              child: Text(
                '"${data.closingLine}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(220),
                  fontSize: 16,
                  height: 1.7,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF38BDF8)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withAlpha(80),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Selanjutnya',
            style: TextStyle(
              color: Colors.white.withAlpha(220),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, color: Colors.white.withAlpha(220), size: 16),
        ],
      ),
    );
  }
}
