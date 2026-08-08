import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown when a list has no items (empty cart, no search results, etc.)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A label/value row used in bill & cart summaries.
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isBold ? 17 : 14,
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      color: isBold ? AppTheme.textDark : AppTheme.textMuted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            value,
            style: style.copyWith(
              color: isBold ? AppTheme.primaryBlue : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status pill used for bill history (Paid / Refunded etc.)
class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isPaid = status.toLowerCase() == 'paid';
    final Color color = isPaid ? AppTheme.successGreen : AppTheme.dangerRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
