import 'package:flutter/material.dart';
import 'package:sentra_app/core/theme/app_theme.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitas')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: AppColors.primary.withAlpha(102),
            ),
            const SizedBox(height: 16),
            Text(
              'Riwayat Transaksi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Segera hadir',
              style: TextStyle(color: AppColors.primary.withAlpha(153)),
            ),
          ],
        ),
      ),
    );
  }
}
