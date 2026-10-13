# APIs públicas utilizadas por Vdry

Las tres integraciones activas no requieren credenciales, registro ni claves inventadas. Se retiraron Pexels y Pixabay. `Heidrhen`/`adrian230052` identifica el proyecto académico en su documentación y User-Agent; no es una API key.

| API | Endpoints | Reproducción |
| --- | --- | --- |
| PeerTube / Sepia Search | `https://sepiasearch.org/api/v1/search/videos` y `https://{instancia}/api/v1/videos/{uuid}` | MP4 directo declarado por la instancia, con audio y video; preferencia por rendiciones ligeras y HLS |
| Internet Archive | `https://archive.org/metadata/{identifier}` y `https://archive.org/advancedsearch.php` | MP4 en el servidor/directorio de la respuesta; audio comprobado en el handler `soun` |
| Wikimedia Commons | `https://commons.wikimedia.org/w/api.php` | Variantes WebM con audio en Android/web; QuickTime en Apple |

Cada API tiene su propio datasource en `lib/infrastructure/datasources`, implementa el contrato del dominio y se inyecta mediante `VideoPostsRepositoryImpl` en `lib/main.dart`. Se usa `video_player` para reproducir archivos; no se muestran controles de plataformas externas.

## Secciones y contenido

- **Para ti:** exclusivamente los 13 MP4 de `assets/videos`, en orden numérico; funciona sin consultar APIs.
- **Descubrir:** exclusivamente videos de las tres APIs, intercalados y paginados, sin límite fijo de seis.
- **Favoritos:** videos marcados de cualquiera de las dos secciones; persiste likes y metadatos.

Se buscan grabaciones cortas de naturaleza y paisajes en formato vertical, con sonido original y enlaces de atribución/licencia. El catálogo depende de la disponibilidad de los proveedores. Los videos remotos se muestran completos sin recortar; los clips con licencia NC son para este uso académico no comercial. La información HTTP se conserva durante 24 horas en SharedPreferences; los archivos remotos se reproducen por red. En web también se depende de CORS y de los codecs del navegador.

Internet Archive empieza consultando dos fichas verificadas: `Flickr-22002602029` (100 Story Waterfall, CC BY-NC-ND 2.0) e `img-9763_202610` (winter waterfall videos, CC BY-NC-ND 4.0). Después sigue la búsqueda pública paginada de cascadas. No se incluyen los anteriores videos de demostración de software.

Los 13 archivos locales conservan sus pistas originales: `1`, `2`, `9` y `10` tienen audio; los otros nueve permanecen silenciosos por indicación del usuario. Las variantes de reproducción en `assets/videos/playback` conservan la identidad de los videos y sus favoritos. Se mantiene el ajuste de compatibilidad del Nokia 5.1 Plus.

## Documentación oficial para explicar la integración

- [PeerTube: API REST](https://docs.joinpeertube.org/api/rest-getting-started)
- [PeerTube: búsqueda pública Sepia Search](https://docs.joinpeertube.org/use/search)
- [Internet Archive: lectura de metadatos](https://archive.org/developers/md-read.html)
- [Internet Archive: búsqueda avanzada](https://archive.org/advancedsearch.php)
- [Wikimedia: información de videos y variantes](https://www.mediawiki.org/wiki/Extension:TimedMediaHandler/API)

Para ejecutar: `flutter run`. No se necesita `--dart-define-from-file` ni un archivo de claves.

La comprobación real se puede repetir con `flutter test test/public_api_live_check_test.dart --dart-define=VERIFY_PUBLIC_APIS=true`. Es opcional para evitar que las pruebas ordinarias dependan de internet.

## Carga y reproducción optimizadas

Descubrir entrega resultados progresivamente: una API lenta no retiene los videos que ya respondieron otras fuentes. PeerTube usa la playlist HLS de una rendición cercana a ancho 480 cuando está disponible; Wikimedia prioriza altura 480. Internet Archive excluye MP4 con bitrate medio superior a 4 Mbps y empieza con archivos pequeños. Se conservan las tres APIs y el sonido original.

`RemoteVideoPreloader` prepara solo el controlador actual y el siguiente, sin reproducir audio, y reutiliza el siguiente al avanzar. Libera los anteriores y los de pestañas inactivas. La precarga es en memoria; no crea una caché de archivos persistente. El tiempo de inicialización se limita a 25 segundos. El almacenamiento persistente de likes y favoritos no cambia. La velocidad final sigue dependiendo de la disponibilidad y latencia del servidor de cada video.
