import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';

import '../models/caminhada.dart';
import '../services/storage_service.dart';

class DetalhesScreen extends StatefulWidget {
  final Caminhada caminhada;
  const DetalhesScreen({super.key, required this.caminhada});

  @override
  State<DetalhesScreen> createState() => _DetalhesScreenState();
}

class _DetalhesScreenState extends State<DetalhesScreen> {
  late Caminhada _caminhada;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _caminhada = widget.caminhada;
  }

  Future<void> _tirarFoto() async {
    try {
      final foto = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 900,
        imageQuality: 60,
      );
      if (foto == null) return;
      final bytes = await foto.readAsBytes();
      final atualizada = _caminhada.copyWith(fotoBase64: base64Encode(bytes));
      await StorageService.salvar(atualizada);
      if (!mounted) return;
      setState(() => _caminhada = atualizada);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir a câmera: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _caminhada;
    final bytes = c.fotoBytes;
    final cor = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(c.titulo)),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : InkWell(
                    onTap: _tirarFoto,
                    child: Container(
                      color: cor.surfaceContainerHighest,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          const Text('Toque para tirar uma foto'),
                        ],
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  c.titulo,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Info(Icons.straighten, formatarDistancia(c.distanciaMetros),
                        'Distância'),
                    _Info(Icons.local_fire_department,
                        '${c.calorias.round()} kcal', 'Calorias'),
                    _Info(Icons.timer, formatarTempo(c.tempoMinutos), 'Tempo'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c.resumo(), textAlign: TextAlign.center),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: c.rota.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(c.rota),
                        padding: const EdgeInsets.all(40),
                      )
                    : null,
                initialCenter: c.origem,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.caminhadas',
                ),
                PolylineLayer(polylines: [
                  Polyline(
                    points: c.rota,
                    strokeWidth: 5,
                    color: Colors.blue.shade700,
                  ),
                ]),
                MarkerLayer(markers: [
                  Marker(
                    point: c.origem,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location,
                        color: Colors.blue, size: 34),
                  ),
                  Marker(
                    point: c.destino,
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
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icone;
  final String valor;
  final String rotulo;
  const _Info(this.icone, this.valor, this.rotulo);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, color: Theme.of(context).colorScheme.primary),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
