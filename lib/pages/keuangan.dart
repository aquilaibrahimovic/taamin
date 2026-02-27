import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../app_theme.dart';

class KeuanganPage extends StatelessWidget {
  const KeuanganPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Keuangan',
      children: [
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Keuangan (mockup)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              const _MoneyRow(label: 'Saldo Saat Ini', value: 'Rp 12.500.000'),
              const SizedBox(height: 6),
              const _MoneyRow(label: 'Pemasukan Bulan Ini', value: 'Rp 4.100.000'),
              const SizedBox(height: 6),
              const _MoneyRow(label: 'Pengeluaran Bulan Ini', value: 'Rp 900.000'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Transaksi Terakhir'),
        const InfoCard(
          child: Column(
            children: [
              _TransactionItem(
                title: 'Infaq Jumat',
                subtitle: 'Pemasukan',
                amount: '+ Rp 1.250.000',
              ),
              Divider(),
              _TransactionItem(
                title: 'Listrik & air',
                subtitle: 'Pengeluaran',
                amount: '- Rp 350.000',
              ),
              Divider(),
              _TransactionItem(
                title: 'Donasi jamaah',
                subtitle: 'Pemasukan',
                amount: '+ Rp 500.000',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final String value;
  const _MoneyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;

  const _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = amount.trim().startsWith('+');
    final c = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle),
            ],
          ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isIncome ? c.yesColor : c.noColor,
          ),
        ),
      ],
    );
  }
}