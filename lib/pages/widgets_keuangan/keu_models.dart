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
  final String docId;
  final String keterangan;
  final DateTime tanggal;
  final int masuk;
  final int keluar;
  final String notaUrl;

  final String notaFileId; // NEW

  const BaseRow({
    required this.docId,
    required this.keterangan,
    required this.tanggal,
    required this.masuk,
    required this.keluar,
    required this.notaUrl,
    required this.notaFileId, // NEW
  });
}

class RowWithSaldo extends BaseRow {
  final int saldoKas;

  const RowWithSaldo({
    required super.docId,
    required super.keterangan,
    required super.tanggal,
    required super.masuk,
    required super.keluar,
    required super.notaUrl,
    required super.notaFileId, // NEW
    required this.saldoKas,
  });

  factory RowWithSaldo.fromBase(BaseRow b, {required int saldoKas}) {
    return RowWithSaldo(
      docId: b.docId,
      keterangan: b.keterangan,
      tanggal: b.tanggal,
      masuk: b.masuk,
      keluar: b.keluar,
      notaUrl: b.notaUrl,
      notaFileId: b.notaFileId, // NEW
      saldoKas: saldoKas,
    );
  }
}