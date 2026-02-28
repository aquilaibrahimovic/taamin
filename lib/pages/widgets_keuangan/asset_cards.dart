import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../widgets/common.dart';
import 'keu_helpers.dart';

class KeuAssetCards extends StatelessWidget {
  final int kasLatest;
  final int tabungan;
  final int deposito;
  final int saldoTotal;

  final bool isAdmin;
  final DocumentReference<Map<String, dynamic>> metaRef;
  final String Function(num) formatRupiah;

  const KeuAssetCards({
    super.key,
    required this.kasLatest,
    required this.tabungan,
    required this.deposito,
    required this.saldoTotal,
    required this.isAdmin,
    required this.metaRef,
    required this.formatRupiah,
  });

  Future<void> _editMoneyField({
    required BuildContext context,
    required String title,
    required String fieldName,
    required int currentValue,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: currentValue.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Ubah $title'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Masukkan angka, contoh: 87656000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final v = KeuHelpers.parseMoney(controller.text);
                Navigator.pop(ctx, v);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      await metaRef.set({fieldName: result}, SetOptions(merge: true));
      messenger.showSnackBar(SnackBar(content: Text('$title berhasil diperbarui')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  Widget _moneyCard({
    required BuildContext context,
    required String title,
    required String valueText,
    required Color bgColor,
    VoidCallback? onEdit,
  }) {
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InfoCard.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(InfoCard.paddingAll),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      valueText,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                tooltip: 'Ubah $title',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _moneyCard(
          context: context,
          title: 'Kas',
          valueText: formatRupiah(kasLatest),
          bgColor: c.accent2a.withAlpha(64),
        ),
        const SizedBox(height: 12),
        _moneyCard(
          context: context,
          title: 'Tabungan',
          valueText: formatRupiah(tabungan),
          bgColor: c.accent2a.withAlpha(64),
          onEdit: isAdmin
              ? () => _editMoneyField(
            context: context,
            title: 'Tabungan',
            fieldName: 'tabungan',
            currentValue: tabungan,
          )
              : null,
        ),
        const SizedBox(height: 12),
        _moneyCard(
          context: context,
          title: 'Deposito',
          valueText: formatRupiah(deposito),
          bgColor: c.accent2a.withAlpha(64),
          onEdit: isAdmin
              ? () => _editMoneyField(
            context: context,
            title: 'Deposito',
            fieldName: 'deposito',
            currentValue: deposito,
          )
              : null,
        ),
        const SizedBox(height: 12),
        _moneyCard(
          context: context,
          title: 'Saldo',
          valueText: formatRupiah(saldoTotal),
          bgColor: c.accent2a.withAlpha(96),
        ),
      ],
    );
  }
}