import 'package:flutter/material.dart';

/// Daftar horizontal yang bisa digeser, dengan gradasi tipis di tepi kanan atau
/// kiri selama masih ada isi di luar layar.
///
/// Tujuannya bukan hiasan: baris chip yang terpotong begitu saja di tepi layar
/// terbaca sebagai layout rusak, bukan sebagai daftar yang bisa digeser.
class DaftarGeserHorizontal extends StatefulWidget {
  const DaftarGeserHorizontal({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  /// Isi daftar, biasanya berupa [Row] dengan `mainAxisSize.min`.
  final Widget child;

  final EdgeInsetsGeometry padding;

  @override
  State<DaftarGeserHorizontal> createState() => _DaftarGeserHorizontalState();
}

class _DaftarGeserHorizontalState extends State<DaftarGeserHorizontal> {
  final ScrollController _controller = ScrollController();

  bool _adaKiri = false;
  bool _adaKanan = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_perbaruiTepi);
    WidgetsBinding.instance.addPostFrameCallback((_) => _perbaruiTepi());
  }

  @override
  void didUpdateWidget(covariant DaftarGeserHorizontal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _perbaruiTepi());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _perbaruiTepi() {
    if (!mounted || !_controller.hasClients) return;
    final posisi = _controller.position;
    final adaKiri = posisi.pixels > 0.5;
    final adaKanan = posisi.pixels < posisi.maxScrollExtent - 0.5;
    if (adaKiri == _adaKiri && adaKanan == _adaKanan) return;
    setState(() {
      _adaKiri = adaKiri;
      _adaKanan = adaKanan;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      // Gradasi hanya memudarkan piksel yang memang di tepi; isi di tengah
      // tetap utuh karena warnanya tetap hitam penuh.
      shaderCallback: (Rect batas) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            _adaKiri ? Colors.transparent : Colors.black,
            Colors.black,
            Colors.black,
            _adaKanan ? Colors.transparent : Colors.black,
          ],
          stops: const <double>[0, 0.05, 0.95, 1],
        ).createShader(batas);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        clipBehavior: Clip.hardEdge,
        child: widget.child,
      ),
    );
  }
}
