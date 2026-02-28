class FridayAgg {
  final int weekIndex; // 1..5
  final bool exists;
  final int masuk;
  final int keluar;

  const FridayAgg({
    required this.weekIndex,
    required this.exists,
    required this.masuk,
    required this.keluar,
  });
}

class BaseRow {
  final String keterangan;
  final DateTime tanggal;
  final int masuk;
  final int keluar;
  final String notaUrl;

  const BaseRow({
    required this.keterangan,
    required this.tanggal,
    required this.masuk,
    required this.keluar,
    required this.notaUrl,
  });
}

class RowWithSaldo extends BaseRow {
  final int saldoKas;

  const RowWithSaldo({
    required super.keterangan,
    required super.tanggal,
    required super.masuk,
    required super.keluar,
    required super.notaUrl,
    required this.saldoKas,
  });

  factory RowWithSaldo.fromBase(BaseRow b, {required int saldoKas}) {
    return RowWithSaldo(
      keterangan: b.keterangan,
      tanggal: b.tanggal,
      masuk: b.masuk,
      keluar: b.keluar,
      notaUrl: b.notaUrl,
      saldoKas: saldoKas,
    );
  }
}