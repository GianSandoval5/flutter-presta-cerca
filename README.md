<!-- mobile-factory:hero -->
<div align="center">
<h1>Presta Cerca</h1>
<p><strong>Compartir es multiplicar.</strong></p>
<p>Inventario y préstamos de objetos para hogares y comunidades.</p>
<p><a href="https://github.com/GianSandoval5/flutter-presta-cerca/actions/workflows/ci.yml"><img src="https://github.com/GianSandoval5/flutter-presta-cerca/actions/workflows/ci.yml/badge.svg" alt="CI"></a> <a href="LICENSE"><img src="https://img.shields.io/badge/licencia-MIT-126e71" alt="MIT"></a> <img src="https://img.shields.io/badge/framework-Flutter-126e71" alt="Flutter"></p>
<p><a href="#funciones">Funciones</a> · <a href="#instalación">Instalación</a> · <a href="#mobilelab">MobileLab</a> · <a href="#pruebas">Pruebas</a> · <a href="CONTRIBUTING.md">Contribuir</a></p>
</div>

https://github.com/GianSandoval5/flutter-presta-cerca

## Funciones

- Inicio: disponibilidad, préstamos activos y vencidos.
- Objetos: búsqueda, filtro de disponibilidad, detalle.
- Alta y edición: nombre y categoría obligatorios.
- Detalle: historial, devolución y eliminación confirmada solo sin préstamo activo.
- Préstamo: alias y fecha de devolución válida; impide prestar dos veces un mismo objeto.
- Historial: devoluciones registradas.

Material 3 con navegación, estados vacíos, carga y recuperación de errores. Datos sintéticos; no introducir datos personales reales. No hay capturas verificadas ni notificaciones.

## Instalación

Flutter estable ([release notes](https://docs.flutter.dev/release/release-notes)), Dart >=3.13, Material UI 1.11.1, http ^1.6.0, Java 17 y Android SDK. El publicador registra el SDK y versiones efectivas en FACTORY_PROVENANCE.json.

```sh
git clone https://github.com/GianSandoval5/flutter-presta-cerca.git
cd flutter-presta-cerca
flutter doctor
flutter pub get
flutter run --dart-define=MOBILELAB_URL=http://10.0.2.2:4566
```

## MobileLab

[MobileLab 1.1.0](https://github.com/GianSandoval5/MobileLab/releases/tag/v1.1.0) es un sandbox local de desarrollo y CI; no hay servicio cloud ni backend de producción conectado. Descarga el CLI apropiado y verifica su SHA-256 con SHA256SUMS de la release antes de ejecutarlo; instala el binario en PATH. Desde la raíz:

```sh
mobilelab --version
mobilelab start
mobilelab db status
```

Mantén el proceso ejecutándose. [Data API](https://github.com/GianSandoval5/MobileLab/blob/master/docs/data-api.md): GET /api/items lista; PUT /api/items/{id} crea o reemplaza; DELETE /api/items/{id} elimina. Cada documento contiene id, name, category y loans (borrower, due, returned). Configuración en mobilelab.yaml y mobilelab/data.yaml; semillas demo. El primer inicio siembra SQLite y siguientes preservan cambios. No hace falta SDK de eventos. No versionar data.db, historial interno, .state.json ni credenciales.

Android emulador: 10.0.2.2; iOS simulador: 127.0.0.1; Android USB: adb reverse tcp:4566 tcp:4566 y URL loopback; dispositivo físico por LAN privada: configura la IP del host, escucha 0.0.0.0 solo en red confiable. HTTP es exclusivamente para desarrollo. iOS/web no se declaran compilados.

## Pruebas

```sh
dart format lib test tool
flutter analyze
flutter test --coverage
MOBILELAB_BIN=/ruta/mobilelab python3 scripts/verify_mobilelab.py
flutter build apk --debug
```

El script usa puerto libre, configuración y semillas en directorio temporal, ejecuta las pruebas del adaptador Dart frente al CLI real, reinicia y comprueba persistencia. No altera la base del usuario. CI repite verificaciones con auditoría del publicador; los resultados efectivos están en FACTORY_PROVENANCE.json.

## Arquitectura

lib/features/lending/domain contiene modelo y contrato; data contiene DTO y cliente HTTP; presentation contiene controlador observable y pantallas. main.dart inyecta repositorio y cliente. Los tests usan MockClient y memoria; la app usa MobileLab como fuente principal.

Para producción, define contrato OpenAPI, implementa ItemRepository con HTTPS, autenticación y autorización por miembro, control de concurrencia y transacciones en servidor; sustituye la inyección en main.dart. El sandbox presupone un operador y no tiene sincronización offline ni permisos por usuario. Tras timeout refrescar antes de reintentar.

Roadmap: reservas, notificaciones y conflictos concurrentes. Inspiración conceptual: [Leihbase](https://leihbase.org/) y [Circulate](https://github.com/chicago-tool-library/circulate); código y diseño originales.

## Autor

Gian Sandoval — Arquitecto Mobile. [GitHub](https://github.com/GianSandoval5) · [LinkedIn](https://www.linkedin.com/in/giansandoval/) · [Web](https://giansandoval.com). Si te resulta útil, ¡deja una ⭐! Código original bajo licencia MIT.


## Conecta con Gian Sandoval

Si este proyecto te sirve, deja una ⭐ en el repositorio para apoyar la serie de proyectos abiertos.

- GitHub: https://github.com/GianSandoval5
- LinkedIn: https://www.linkedin.com/in/giansandoval/
- Web: https://giansandoval.com

**Gian Sandoval — Arquitecto Mobile**
