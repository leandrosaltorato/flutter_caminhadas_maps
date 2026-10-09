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
    if (mounted) setState(() => _carregandoGps = true);
    LatLng? posicao;
    String? aviso;
    SnackBarAction? acao;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        aviso = 'GPS desativado. Ative a localização do celular.';
        acao = SnackBarAction(
          label: 'ATIVAR',
          onPressed: Geolocator.openLocationSettings,
        );
      } else {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.deniedForever) {
          aviso = 'Permissão de localização bloqueada. Libere nas configurações do app.';
          acao = SnackBarAction(
            label: 'ABRIR',
            onPressed: Geolocator.openAppSettings,
          );
        } else if (perm == LocationPermission.denied) {
          aviso = 'Permissão de localização negada.';
        } else {
          try {
            final p = await Geolocator.getCurrentPosition(
              locationSettings:
                  const LocationSettings(accuracy: LocationAccuracy.high),
            ).timeout(const Duration(seconds: 20));
            posicao = LatLng(p.latitude, p.longitude);
          } catch (_) {
            // Fallback: última posição conhecida ou precisão menor
            Position? p;
            try {
              p = await Geolocator.getLastKnownPosition();
            } catch (_) {}
            p ??= await Geolocator.getCurrentPosition(
              locationSettings:
                  const LocationSettings(accuracy: LocationAccuracy.low),
            ).timeout(const Duration(seconds: 15));
            posicao = LatLng(p.latitude, p.longitude);
          }
        }
      }
    } catch (e) {
      aviso = 'Não foi possível obter o GPS ($e).';
    }
    if (!mounted) return;
    setState(() {
      _origem = posicao ?? _origem ?? _padrao;
      _carregandoGps = false;
    });
    _mapController.move(_origem!, 16);
    if (posicao == null) {
      _mensagem('${aviso ?? 'Sem localização.'} Usando local padrão.',
          acao: acao);
    }
  }

  void _mensagem(String texto, {SnackBarAction? acao}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        action: acao,
        duration: const Duration(seconds: 8),
      ));
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

  /// RF003.2 - Modal pedindo o título da caminhada.
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
    Navigator.pop(context); // volta para a Home
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
                Positioned(
                  bottom: 24,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'minha_localizacao',
                    tooltip: 'Minha localização',
                    onPressed: _obterLocalizacao,
                    child: const Icon(Icons.my_location),
                  ),
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
