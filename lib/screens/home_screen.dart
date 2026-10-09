import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/caminhada.dart';
import '../services/storage_service.dart';
import 'detalhes_screen.dart';
import 'nova_caminhada_screen.dart';
import 'splash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Caminhada> _caminhadas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final lista = await StorageService.listar();
    if (!mounted) return;
    setState(() {
      _caminhadas = lista;
      _carregando = false;
    });
  }

  Future<void> _abrir(Widget tela) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
    _carregar(); 
  }

  Future<void> _alternarTema() async {
    final escuro = temaNotifier.value == ThemeMode.dark;
    temaNotifier.value = escuro ? ThemeMode.light : ThemeMode.dark;
    await StorageService.gravarTema(!escuro);
  }

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Caminhadas')),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: const Text('Menu'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.slideshow),
                title: const Text('Splash'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SplashScreen()));
                },
              ),
              ListTile(
                leading: Icon(escuro ? Icons.light_mode : Icons.dark_mode),
                title: Text(escuro ? 'Tema claro' : 'Tema escuro'),
                onTap: () {
                  Navigator.pop(context);
                  _alternarTema();
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Sair'),
                onTap: () => SystemNavigator.pop(),
              ),
            ],
          ),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _caminhadas.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma caminhada cadastrada.\nToque em [+] para adicionar.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _caminhadas.length,
                  itemBuilder: (_, i) => _CardCaminhada(
                    caminhada: _caminhadas[i],
                    onTap: () => _abrir(DetalhesScreen(caminhada: _caminhadas[i])),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrir(const NovaCaminhadaScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CardCaminhada extends StatelessWidget {
  final Caminhada caminhada;
  final VoidCallback onTap;
  const _CardCaminhada({required this.caminhada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bytes = caminhada.fotoBytes;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined,
                          size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caminhada.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatarDistancia(caminhada.distanciaMetros),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
