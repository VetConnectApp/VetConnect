import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/treatment_model.dart';
import '../theme.dart';
import 'glass_card.dart';

class TreatmentListItem extends StatelessWidget {
  final TreatmentModel treatment;
  final VoidCallback? onFlagDeletion;
  final bool showActions;

  const TreatmentListItem({
    super.key,
    required this.treatment,
    this.onFlagDeletion,
    this.showActions = true,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppTheme.successGreen;
      case 'Rejected':
        return AppTheme.errorRed;
      default:
        return AppTheme.warningOrange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Approved':
        return '✅ Approved';
      case 'Rejected':
        return '❌ Rejected';
      default:
        return '⏳ Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = treatment.date != null
        ? DateFormat('dd MMM yyyy').format(treatment.date!)
        : 'New';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  '🐄 Tag: ${treatment.animalTagId}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(treatment.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(treatment.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(treatment.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Details
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13, color: cs.onSurface.withOpacity(0.4)),
              const SizedBox(width: 5),
              Text(dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      )),
              const SizedBox(width: 12),
              Icon(Icons.medical_services_outlined,
                  size: 13, color: cs.onSurface.withOpacity(0.4)),
              const SizedBox(width: 5),
              Text(treatment.urgency,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            treatment.notes,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.8),
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Prescription chips
          if (treatment.prescription.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: treatment.prescription
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '💊 ${p.medicine}: ${p.dosage}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          // Next due date
          if (treatment.nextDueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: AppTheme.warningOrange),
                const SizedBox(width: 5),
                Text(
                  'Next due: ${DateFormat('dd MMM yyyy').format(treatment.nextDueDate!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.warningOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          // Deletion flag
          if (treatment.deletionRequest) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🗑 Deletion Requested: ${treatment.deletionReason}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.errorRed,
                ),
              ),
            ),
          ],
          // Flag for deletion button (vet view)
          if (showActions &&
              !treatment.deletionRequest &&
              treatment.status != 'Approved' &&
              onFlagDeletion != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onFlagDeletion,
                icon: const Icon(Icons.flag_outlined,
                    size: 15, color: AppTheme.errorRed),
                label: const Text('Flag for Deletion',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.errorRed)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
