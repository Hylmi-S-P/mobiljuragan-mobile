import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobiljuragan_mobile/widgets/merauke_location_map_picker.dart';

/// Sumber nama titik yang bisa memberi tahu pendengar, meniru
/// `BookingController` yang dipantau layar opsi rental lewat `context.watch`.
class _Lokasi extends ChangeNotifier {
  String nama = 'Bandara Mopah Merauke';
  LatLng? koordinat;

  void set(String namaBaru, LatLng koordinatBaru) {
    nama = namaBaru;
    koordinat = koordinatBaru;
    notifyListeners();
  }
}

/// Inang yang meniru layar opsi rental: nama titik disimpan di notifier dan
/// pemilih peta dibangun ulang lewat [ListenableBuilder], bukan `setState`
/// langsung. Urutan pembangunan ulang inilah yang dulu membuat peta penuh
/// tertinggal di "Memuat nama lokasi...".
class _Inang extends StatefulWidget {
  const _Inang();

  @override
  State<_Inang> createState() => _InangState();
}

class _InangState extends State<_Inang> {
  final _lokasi = _Lokasi();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: _lokasi,
          builder: (context, _) => MeraukeLocationMapPicker(
            selectedLocationName: _lokasi.nama,
            selectedCoordinates: _lokasi.koordinat,
            isWithDriver: true,
            mapHeight: 200,
            onCustomCoordinateSelected: (nama, koordinat) {
              _lokasi.set(nama, koordinat);
            },
          ),
        ),
      ),
    );
  }
}

Future<void> _ketukPeta(WidgetTester tester, Finder peta) async {
  final pos = tester.getCenter(peta) + const Offset(0, 60);
  final gesture = await tester.startGesture(pos);
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets(
    'peta penuh menampilkan nama hasil geocoding, bukan "Memuat nama lokasi..."',
    (tester) async {
      await tester.pumpWidget(const _Inang());
      await tester.pump();

      // Buka peta penuh lewat tombol "Perbesar".
      await tester.tap(find.text('Perbesar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Peta Titik Penjemputan Sopir'), findsNWidgets(2));

      await _ketukPeta(tester, find.byType(FlutterMap).last);

      // Lewati jeda debounce geocoding lalu biarkan hasilnya masuk.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Memuat nama lokasi...'),
        findsNothing,
        reason: 'label peta penuh tidak boleh tertinggal di keadaan memuat',
      );
      expect(
        find.text('Bandara Mopah Merauke'),
        findsNothing,
        reason: 'label harus berganti ke nama titik yang diketuk',
      );
      expect(
        find.textContaining('Dekat Bandara Mopah Merauke'),
        findsWidgets,
        reason: 'label harus berisi nama hasil geocoding titik yang diketuk',
      );
    },
  );
}
