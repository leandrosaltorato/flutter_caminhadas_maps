import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/caminhada.dart';

class StorageService {
  static const _chave = 'caminhadas';
  static const _chaveTema = 'tema_escuro';

  static Future<List<Caminhada>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chave);
    if (texto == null) return [];
    final lista = jsonDecode(texto) as List;
    return lista
        .map((e) => Caminhada.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _gravar(List<Caminhada> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _chave, jsonEncode(lista.map((c) => c.toJson()).toList()));
  }

  static Future<void> salvar(Caminhada c) async {
    final lista = await listar();
    final i = lista.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      lista[i] = c;
    } else {
      lista.insert(0, c);
    }
    await _gravar(lista);
  }

  static Future<bool> temaEscuro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveTema) ?? false;
  }

  static Future<void> gravarTema(bool escuro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveTema, escuro);
  }
}
