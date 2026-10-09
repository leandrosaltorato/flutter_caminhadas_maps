import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RotaResultado {
  final List<LatLng> pontos;
  final double distanciaMetros;
  RotaResultado(this.pontos, this.distanciaMetros);
}

class RotaService {
  static const _base = 'https://routing.openstreetmap.de/routed-foot/route/v1/foot';

  static const double velocidadeKmH = 5.0; 
  static const double kcalPorMetro = 0.065; 

  static Future<RotaResultado> buscarRota(LatLng origem, LatLng destino) async {
    final url = Uri.parse(
      '$_base/${origem.longitude},${origem.latitude};'
      '${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=geojson',
    );
    final resp = await http.get(url).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) {
      throw Exception('Erro ao buscar rota (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('Nenhuma rota encontrada');
    }
    final rota = routes.first as Map<String, dynamic>;
    final coords = (rota['geometry']['coordinates'] as List)
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
    return RotaResultado(coords, (rota['distance'] as num).toDouble());
  }

  static double estimarCalorias(double metros) => metros * kcalPorMetro;

  static double estimarTempoMinutos(double metros) =>
      metros / (velocidadeKmH * 1000 / 60);
}
