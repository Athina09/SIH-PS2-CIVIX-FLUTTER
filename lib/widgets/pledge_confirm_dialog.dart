// Ported from src/components/ui/PledgeConfirmDialog.tsx
import 'package:flutter/material.dart';
import '../data/gov_contacts.dart';
import '../theme/theme.dart';

class PledgeConfirmDialog extends StatelessWidget {
  final String projectTitle;
  final double? amount;
  final String districtId;
  final String districtName;

  const PledgeConfirmDialog({
    super.key,
    required this.projectTitle,
    this.amount,
    required this.districtId,
    required this.districtName,
  });

  static Future<void> show(
    BuildContext context, {
    required String projectTitle,
    double? amount,
    required String districtId,
    required String districtName,
  }) {
    return showDialog(
      context: context,
      builder: (_) => PledgeConfirmDialog(
        projectTitle: projectTitle,
        amount: amount,
        districtId: districtId,
        districtName: districtName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contact = govContactForDistrict(districtId, districtName);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CivixColors.rule))),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: CivixColors.sal),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Pledge recorded', style: TextStyle(fontWeight: FontWeight.w600, color: CivixColors.sal)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 13, color: CivixColors.neel),
                      children: [
                        const TextSpan(text: 'Your pledge'),
                        if (amount != null) TextSpan(text: ' of ${formatCurrency(amount!)}'),
                        const TextSpan(text: ' for '),
                        TextSpan(text: projectTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const TextSpan(text: ' has been recorded.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The concerned government officer monitoring this project will contact you directly to coordinate next steps and verification.',
                    style: TextStyle(fontSize: 12, color: CivixColors.neelSoft),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CivixColors.chuna,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CivixColors.rule),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Concerned officer', style: TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                        const SizedBox(height: 4),
                        Text(contact.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(contact.designation, style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone, size: 13, color: CivixColors.neel),
                                const SizedBox(width: 4),
                                Text(contact.phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.email_outlined, size: 13, color: CivixColors.neel),
                                const SizedBox(width: 4),
                                Text(contact.email, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it'),
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
}
