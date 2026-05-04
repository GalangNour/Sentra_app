import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentra_app/core/models/ai_insight.dart';
import 'package:sentra_app/core/services/ai_service.dart';
import 'package:sentra_app/core/services/finance_snapshot.dart';
import 'package:sentra_app/core/services/insight_service.dart';
import 'package:sentra_app/core/theme/app_theme.dart';
import 'package:sentra_app/screens/sentra_brain_screen.dart';
import 'package:sentra_app/widgets/insight_card.dart';

class InsightSection extends StatefulWidget {
  final FinanceSnapshot snapshot;

  const InsightSection({super.key, required this.snapshot});

  @override
  State<InsightSection> createState() => _InsightSectionState();
}

class _InsightSectionState extends State<InsightSection> {
  List<AiInsight> _insights = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    debugPrint('[InsightSection] _loadInsights: start');
    debugPrint('[InsightSection] AiService.isConfigured=${AiService.isConfigured}');
    debugPrint('[InsightSection] snapshot.transactions=${widget.snapshot.transactions.length}');

    final box = Hive.box('ai_insights');
    debugPrint('[InsightSection] box.keys=${box.keys.toList()}');
    debugPrint('[InsightSection] box.length=${box.length}');

    final cached = InsightService.getCached(box);
    debugPrint('[InsightSection] cached=${cached.length} insights');
    if (cached.isNotEmpty && mounted) {
      setState(() => _insights = cached);
    }

    if (!InsightService.needsRefresh(box)) {
      debugPrint('[InsightSection] cache masih fresh, skip generate');
      return;
    }

    if (!AiService.isConfigured) {
      debugPrint('[InsightSection] AiService belum dikonfigurasi, skip generate');
      return;
    }

    debugPrint('[InsightSection] mulai generate insights...');
    if (mounted) setState(() => _isLoading = true);
    final fresh = await InsightService.generateAndCache(box, widget.snapshot);
    debugPrint('[InsightSection] generate selesai: ${fresh.length} insights');
    if (mounted) {
      setState(() {
        _insights = fresh;
        _isLoading = false;
      });
    }
  }

  void _openBrain(String initialPrompt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SentraBrainScreen(
          snapshot: widget.snapshot,
          initialPrompt: initialPrompt,
        ),
      ),
    );
  }

  void _openBrainHome() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SentraBrainScreen(snapshot: widget.snapshot),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showShimmer = _isLoading && _insights.isEmpty;
    final showEmpty = !_isLoading && _insights.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Insight AI untukmu',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: _openBrainHome,
              child: Text(
                'Tanya AI',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (showEmpty)
          Text(
            'Tambah transaksi untuk mendapat insight 💡',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          )
        else if (showShimmer)
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (_, index) => _ShimmerCard(),
            ),
          )
        else
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _insights.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (_, i) => InsightCard(
                insight: _insights[i],
                index: i,
                onTap: () => _openBrain(_insights[i].tapPrompt),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Container(
          width: 200,
          height: 148,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
        ),
      ),
    );
  }
}
