import 'dart:convert';
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

class Caminhada {
  final String id;
  final String titulo;
  final LatLng origem;
  final LatLng destino;
  final List<LatLng> rota;
  final double distanciaMetros;
  final double calorias;
  final double tempoMinutos;
  final String? fotoBase64;

  Caminhada({
    required this.id,
    required this.titulo,
    required this.origem,
    required this.destino,
    required this.rota,
    required this.distanciaMetros,
    required this.calorias,
    required this.tempoMinutos,
    this.fotoBase64,
  });

  Uint8List? get fotoBytes =>
      fotoBase64 == null ? null : base64Decode(fotoBase64!);

  String resumo({bool passado = true}) {
    final verbo = passado ? 'Caminhou' : 'Vai percorrer';
    return '$verbo uma distancia de ${formatarDistancia(distanciaMetros)} '
        'queimando ${calorias.round()} calorias '
        'em aproximadamente ${formatarTempo(tempoMinutos)}';
  }

  Caminhada copyWith({String? fotoBase64}) => Caminhada(
        id: id,
        titulo: titulo,
        origem: origem,
        destino: destino,
        rota: rota,
        distanciaMetros: distanciaMetros,
        calorias: calorias,
        tempoMinutos: tempoMinutos,
        fotoBase64: fotoBase64 ?? this.fotoBase64,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'origem': [origem.latitude, origem.longitude],
        'destino': [destino.latitude, destino.longitude],
        'rota': rota.map((p) => [p.latitude, p.longitude]).toList(),
        'distanciaMetros': distanciaMetros,
        'calorias': calorias,
        'tempoMinutos': tempoMinutos,
        'fotoBase64': fotoBase64,
      };

  factory Caminhada.fromJson(Map<String, dynamic> json) {
    LatLng ll(dynamic p) =>
        LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble());
    return Caminhada(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      origem: ll(json['origem']),
      destino: ll(json['destino']),
      rota: (json['rota'] as List).map(ll).toList(),
      distanciaMetros: (json['distanciaMetros'] as num).toDouble(),
      calorias: (json['calorias'] as num).toDouble(),
      tempoMinutos: (json['tempoMinutos'] as num).toDouble(),
      fotoBase64: json['fotoBase64'] as String?,
    );
  }
}

String formatarDistancia(double metros) {
  if (metros >= 1000) return '${(metros / 1000).toStringAsFixed(2)} km';
  return '${metros.round()} m';
}

String formatarTempo(double minutos) {
  final m = minutos.round();
  if (m < 60) return '$m min';
  return '${m ~/ 60} h ${m % 60} min';
}
