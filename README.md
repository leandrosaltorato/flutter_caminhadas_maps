# App Caminhadas

Aplicativo Flutter para registrar e acompanhar caminhadas, usando **geolocalização (GPS)**, **mapas (flutter_map + OpenStreetMap)**, **rotas (OSRM)**, **câmera** e **armazenamento local**.

> Adicione aqui os prints do aplicativo (Splash, Home, Nova caminhada, Modal Salvar, Detalhes) em `assets/prints/`.

## Requisitos atendidos

| Requisito | Onde |
|---|---|
| RF001 – Splash com animação de entrada e saída | `lib/screens/splash_screen.dart` |
| RF002 – Home com menu lateral (Splash, tema claro/escuro, Sair), lista e botão [+] | `lib/screens/home_screen.dart` |
| RF003 – Nova caminhada: destino no mapa, trajeto, distância, calorias e tempo | `lib/screens/nova_caminhada_screen.dart` |
| RF003.2 – Botão Salvar abre **Modal** pedindo o título e grava localmente | `_abrirModalSalvar()` |
| RF004 – Detalhes com mapa, distância, calorias, tempo, título e foto | `lib/screens/detalhes_screen.dart` |
| RF004.1 – Sem foto: ícone de câmera abre a câmera e salva a foto | `_tirarFoto()` |

## Estimativas

- **Distância:** retornada pela API OSRM (perfil de pedestres).
- **Tempo:** distância ÷ 5 km/h (velocidade média de caminhada).
- **Calorias:** ~0,065 kcal por metro (≈ 65 kcal/km, pessoa de ~70 kg). Os valores podem ser ajustados em `lib/services/rota_service.dart`.

## Como executar

```bash
# 1. Gerar as pastas de plataforma (android/, web/ ...) dentro desta pasta
flutter create . --project-name caminhadas --platforms=android,web

# 2. Baixar as dependências
flutter pub get

# 3. Rodar (navegador ou emulador)
flutter run -d chrome
flutter run
```

### Permissões (Android)

Depois do `flutter create .`, edite `android/app/src/main/AndroidManifest.xml` e adicione, dentro de `<manifest>` (antes de `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

> No emulador, defina uma localização em *Extended controls → Location*. Se o GPS não estiver disponível, o app usa a Av. Paulista (SP) como ponto de partida.

### Ícone do aplicativo

O ícone está em `assets/icon.png`. Para aplicá-lo:

```bash
dart run flutter_launcher_icons
```

### Gerar o APK

```bash
flutter build apk --release
```

[![Baixar APK](https://img.shields.io/badge/Baixar-APK-22C55E?style=for-the-badge&logo=android&logoColor=white)](app-release.apk)

## Estrutura

```
lib/
├── main.dart                    
├── models/caminhada.dart         
├── services/
│   ├── rota_service.dart         
│   └── storage_service.dart      
└── screens/
    ├── splash_screen.dart
    ├── home_screen.dart
    ├── nova_caminhada_screen.dart
    └── detalhes_screen.dart
```
