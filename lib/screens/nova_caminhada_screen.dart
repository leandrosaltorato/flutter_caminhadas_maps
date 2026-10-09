import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/caminhada.dart';
import '../services/rota_service.dart';
import '../services/storage_service.dart';

class NovaCaminhadaScreen extends StatefulWidget {
  const NovaCaminhadaScreen({super.key});

  @override
  State<NovaCaminhadaScreen> createState() => _NovaCaminhadaScreenState();
}

class _NovaCaminhadaScreenState extends State<NovaCaminhadaScreen> {
  static const _padrao = LatLng(-23.5613, -46.6565);

  final _mapController = MapController();
  LatLng? _origem;
  LatLng? _destino;
  RotaResultado? _rota;
  bool _buscandoRota = false;
  bool _carregandoGps = true;

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
  }

  Future<void> _obterLocalizacao() async {
    LatLng posicao = _padrao;
    String? aviso;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        aviso = 'GPS desativado. Usando localização padrão.';
      } else {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          aviso = 'Permissão de localização negada. Usando localização padrão.';
        } else {
          final p = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high),
          ).timeout(const Duration(seconds: 15));
          posicao = LatLng(p.latitude, p.longitude);
        }
      }
    } catch (_) {
      aviso = 'Não foi possível obter o GPS. Usando localização padrão.';
    }
    if (!mounted) return;
    setState(() {
      _origem = posicao;
      _carregandoGps = false;
    });
    _mapController.move(posicao, 16);
    if (aviso != null) _mensagem(aviso);
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _selecionarDestino(LatLng ponto) async {
    if (_origem == null || _buscandoRota) return;
    setState(() {
      _destino = ponto;
      _rota = null;
      _buscandoRota = true;
    });
    try {
      final rota = await RotaService.buscarRota(_origem!, ponto);
      if (!mounted) return;
      setState(() => _rota = rota);
      _ajustarMapa(rota.pontos);
    } catch (e) {
      if (!mounted) return;
      _mensagem('Não foi possível traçar o trajeto: $e');
      setState(() => _destino = null);
    } finally {
      if (mounted) setState(() => _buscandoRota = false);
    }
  }

  void _ajustarMapa(List<LatLng> pontos) {
    if (pontos.length < 2) return;
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(pontos),
      padding: const EdgeInsets.all(48),
    ));
  }

  Caminhada _montarCaminhada(String titulo) {
    final metros = _rota!.distanciaMetros;
    return Caminhada(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: titulo,
      origem: _origem!,
      destino: _destino!,
      rota: _rota!.pontos,
      distanciaMetros: metros,
      calorias: RotaService.estimarCalorias(metros),
      tempoMinutos: RotaService.estimarTempoMinutos(metros),
    );
  }

  Future<void> _abrirModalSalvar() async {
    final previa = _montarCaminhada('');
    final controller = TextEditingController();
    final titulo = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? erro;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(previa.resumo(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Título da caminhada',
                    border: const OutlineInputBorder(),
                    errorText: erro,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final t = controller.text.trim();
                  if (t.isEmpty) {
                    setLocal(() => erro = 'Informe um título');
                    return;
                  }
                  Navigator.pop(ctx, t);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (titulo == null) return;

    await StorageService.salvar(_montarCaminhada(titulo));
    if (!mounted) return;
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    final rota = _rota;
    String instrucao = 'Clique no destino da sua caminhada';
    if (_carregandoGps) instrucao = 'Obtendo sua localização...';
    if (_buscandoRota) instrucao = 'Traçando o trajeto...';
    if (rota != null) {
      instrucao = _montarCaminhada('').resumo(passado: false);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nova caminhada')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(child: Text(instrucao)),
                if (rota != null) ...[
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _abrirModalSalvar,
                    child: const Text('Salvar'),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _padrao,
                    initialZoom: 15,
                    onTap: (_, ponto) => _selecionarDestino(ponto),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.caminhadas',
                    ),
                    if (rota != null)
                      PolylineLayer(polylines: [
                        Polyline(
                          points: rota.pontos,
                          strokeWidth: 5,
                          color: Colors.blue.shade700,
                        ),
                      ]),
                    MarkerLayer(markers: [
                      if (_origem != null)
                        Marker(
                          point: _origem!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.my_location,
                              color: Colors.blue, size: 34),
                        ),
                      if (_destino != null)
                        Marker(
                          point: _destino!,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 44),
                        ),
                    ]),
                    const RichAttributionWidget(attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ]),
                  ],
                ),
                if (_carregandoGps || _buscandoRota)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
