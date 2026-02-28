import 'package:intl/intl.dart';

class KeuFormat {
  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  static final _tanggalFmt = DateFormat('d MMMM y', 'id_ID');

  String rupiah(num value) => _rupiah.format(value);

  String tanggal(DateTime dt) => _tanggalFmt.format(dt);
}