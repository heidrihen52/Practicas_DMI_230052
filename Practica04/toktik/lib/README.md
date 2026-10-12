# Funciones Vdry

## Arquitectura

- `domain/entities`: video con identidad por plataforma y reglas de temporada.
- `domain/repositories`: contratos de feeds y preferencias, sin dependencias de Flutter.
- `infrastructure/datasources`: catálogo local y tres fuentes HTTP independientes: PeerTube, Internet Archive y Wikimedia Commons.
- `infrastructure/repositories`: almacenamiento con SharedPreferences, feeds de Descubrir, Para ti y Favoritos.
- `infrastructure/services`: melodías originales generadas en WAV en memoria.
- `presentation`: proveedores, pantallas, controles y reproductores.
- `config/theme`: colores, fuentes e iconos de cada temporada.
- `main.dart`: composición e inyección de implementaciones.

## Uso

Desliza verticalmente para cambiar de video; toca el video para pausar o reanudar. Desliza lateralmente o toca las pestañas para seleccionar Descubrir (plataformas intercaladas), Para ti (los 13 videos locales) y Favoritos (videos con corazón marcado). Para ti no consulta APIs; Descubrir no incluye assets locales. Favoritos reúne los corazones marcados de ambas secciones.

El corazón suma o resta exactamente un like, y guarda el contador, estado y metadatos. Favoritos comparte ese estado. Todas las escrituras se serializan para evitar perder cambios rápidos. La instalación nueva inicia con sonido habilitado. El botón de volumen conserva la preferencia entre sesiones y controla el reproductor visible. Los likes son locales al dispositivo; no se publican en las plataformas.

La paleta abre el selector de prueba persistente. Automático usa el reloj local: Halloween en octubre, Navidad en diciembre, San Valentín del 1 al 14 de febrero, Normal el resto. Se revisa al volver a la app y cada minuto. Los temas usan Roboto, Creepster, Mountains of Christmas y Dancing Script. Las fuentes de Google Fonts se descargan y se guardan en caché; la primera descarga necesita conexión. Una melodía breve se reproduce al cambiar temporada con sonido activado; mezcla audio sin quitar el foco al video. Quitar el mute no repite la melodía. El interruptor de melodía permite deshabilitarla.

El título se muestra separado de la descripción. Las descripciones se colapsan a dos líneas. `... más` expande una región con scroll vertical y barra visible; `menos` vuelve a colapsarla. El desplazamiento dentro de la descripción no avanza el feed.

## Videos externos

Los tres datasources entregan enlaces de archivos de video directos a `video_player`, sin WebViews, iframes ni controles de las plataformas. Solo se aceptan archivos con altura mayor que anchura. Se conserva la pausa por toque, volumen, scroll vertical y pestañas laterales.

Las tres APIs públicas funcionan sin API keys y tienen datasources independientes. PeerTube consulta Sepia Search (`/api/v1/search/videos`) por cascadas, playas y bosques; la API de cada instancia (`/api/v1/videos/{uuid}`) entrega archivos MP4 directos, incluidos MP4 fragmentados de HLS. Se exige formato vertical, duración hasta 90 segundos, licencia Creative Commons compatible y rendición con `hasAudio` y `hasVideo`; se prefiere ancho cercano a 480 y la playlist HLS de esa rendición. Las licencias NC se usan para este proyecto académico no comercial. No se incrusta ningún reproductor externo.

Internet Archive consulta `/metadata/{identifier}` y `/advancedsearch.php`, y construye la URL directa usando el servidor y directorio declarados por la API. Empieza con dos fichas verificadas de cascadas con archivos ligeros; continúa buscando cascadas mediante paginación. Solo admite MP4 verticales de hasta 90 segundos, con licencia Creative Commons; se muestra el encuadre completo sin recortar. Comprueba la pista sonora leyendo como máximo 64 KiB del inicio y 64 KiB del final: busca el handler MP4 `soun`, sin descargar el archivo completo. Los metadatos generales `sound` no se consideran prueba de audio en cada archivo.

Wikimedia Commons consulta `/w/api.php` con `generator=search` y `prop=videoinfo`. Busca naturaleza, cascadas, bosques, paseos, playas y flores; exige encuadre vertical, duración hasta 90 segundos y audio original declarado. Usa WebM en Android/web y QuickTime en plataformas Apple. Los tres datasources continúan sus cursores y omiten páginas sin clips adecuados; no hay límite fijo de seis videos.

La caché de metadatos persiste 24 horas en SharedPreferences. Los videos se reproducen por red, sin descargarlos al almacenamiento. El autor y su página se acreditan en la descripción; los enlaces `Autor` y `Licencia` permiten consultar la procedencia. Los enlaces remotos pueden dejar de estar disponibles; los fallos de una fuente no bloquean las demás. En web también se depende de los permisos CORS del proveedor.

Consulta `../API_CREDENTIALS.md` para documentar al profesor los endpoints públicos. Se retiraron Pexels/Pixabay y los ejemplos de claves inventadas. Los favoritos anteriores conservan sus datos; las fuentes directas siguen siendo reproducibles y los antiguos embeds de YouTube/Vimeo/Dailymotion se excluyen. Los nuevos favoritos conservan autor y enlaces de atribución/licencia.

El datasource local enumera automáticamente todos los MP4 de `assets/videos`, los ordena por nombre numérico y combina sus metadatos con el catálogo existente. Este checkout contiene 13 MP4 y los 13 se muestran exclusivamente en Para ti, sin esperar a las APIs; los videos futuros agregados a la carpeta también se detectan al recompilar. No se alteraron los MP4 originales. Se agregaron variantes de reproducción H.264 a 720p y 30 fps en `assets/videos/playback`: el Nokia 5.1 Plus no puede decodificar los originales 4K. `LocalVideoPlaybackService` define el contrato y `BundledVideoPlaybackService` resuelve la variante disponible desde el manifest; se inyecta en `main.dart`. El reproductor mantiene la URL original como identidad del video, así que likes y favoritos previos siguen funcionando. Si un video futuro no tiene variante, se usa su original. Las 13 copias conservan duración, encuadre y el mismo número de pistas de audio. `tool/generate_playback_variants.swift` permite regenerarlas en macOS con AVFoundation: reemplaza únicamente las copias de `playback`, sin tocar los originales. Se puede compilar con `swiftc -parse-as-library tool/generate_playback_variants.swift -o /tmp/vdry-converter` y ejecutar `/tmp/vdry-converter` desde la raíz del proyecto.

Se conservaron únicamente sus pistas originales: `1`, `2`, `9` y `10` tienen audio; `3` a `8`, `11`, `12` y `13` no lo tienen. No se añade música a los silenciosos. Las tres fuentes nuevas filtran por audio original. La preferencia de mute existente se conserva; el icono de volumen permite activarlo/desactivarlo.

## Verificación

```sh
flutter analyze
flutter test
flutter build web
```

Las pruebas cubren límites de fechas, persistencia y reactivación de likes, escrituras concurrentes, temporada forzada, fuentes HTTP, aislamiento de errores, aislamiento de Para ti, favoritos compartidos y descripciones expandibles. Las pruebas del reproductor comprueban el uso de una URL de red y las órdenes de pausa, reproducción y volumen mediante una plataforma simulada. La prueba real opcional `flutter test test/public_api_live_check_test.dart --dart-define=VERIFY_PUBLIC_APIS=true` verifica las tres APIs sin credenciales; verifica que cada fuente entregue clips. La reproducción final requiere comprobación en dispositivo.

La implementación está en `lib`. Los archivos de dependencias, registradores generados por Flutter, permisos de red de macOS y las pruebas se actualizan fuera de `lib` por necesidades del framework.

## Icono de la app por temporada

Se usan los PNG existentes: `vdry_launcher.png` para Normal, `vdry-halloween.png` para Halloween, `vdry-Christmas.png` para Navidad y `vdry-valentines.png` para San Valentín. Los cuatro tienen lienzo cuadrado opaco de 1024 × 1024; las temporadas llenan el lienzo con la misma proporción del icono base, sin marcos ni esquinas redondeadas incrustadas. Los originales anteriores se conservan en `assets/icons/originals`. El splash y el selector muestran el mismo icono. El modo automático, el override persistente, el regreso a la app y el cambio de fecha sincronizan también el icono del sistema.

`domain/services/app_icon_service.dart` define el contrato; `infrastructure/services` implementa el canal nativo y el favicon web. Android registra cuatro `activity-alias` y habilita solo el elegido. Los aliases apuntan a una `LauncherActivity` efímera (sin interfaz ni tarea en Recents), que abre o retoma `MainActivity` en su propia tarea estable. Así el cambio de alias no deshabilita el componente de la sesión abierta. Halloween, Navidad y San Valentín tienen recursos adaptativos en Android 8+, con fondo negro opaco y artwork al 68% de la capa de 108 dp para que el launcher aplique su máscara sin envolver un PNG legacy con un círculo blanco. Los PNG de `mipmap-*` se conservan como fallback para Android anterior a 8. iOS registra los catálogos alternativos Halloween, Christmas y Valentines en las configuraciones de Xcode y usa `setAlternateIconName`; el sistema puede mostrar su aviso de cambio. Las operaciones se serializan, se evitan cambios repetidos y los errores permiten reintentar.

Los recursos de launcher se generaron en los tamaños nativos a partir de los PNG originales. Para verlos en una instalación existente es necesario recompilar e instalar la app; hot reload no incorpora los nuevos registros nativos. El icono se sincroniza cuando la app se ejecuta, sin tareas de fondo mientras está cerrada. En web cambia el favicon de la pestaña; el icono de una PWA ya instalada depende del navegador y su manifest. En escritorio cambia el icono dentro de la interfaz, pero no el launcher del sistema.

### Arranque estable con Flutter

La actividad `MainActivity` declara una entrada MAIN/LAUNCHER que requiere el scheme `${applicationId}.flutter`. Flutter la encuentra en el APK y la abre con un intent explícito. La consulta normal del launcher no tiene URI, así que no muestra un segundo icono. Esto permite ejecutar `flutter run` incluso cuando `NormalIcon` quedó deshabilitado al seleccionar Halloween o Navidad; actualizar una APK conserva esos estados de componentes. No es necesario desinstalar ni borrar preferencias para corregir el arranque.

## Splash por temporada

Las preferencias se leen antes de `runApp`. Las pestañas permanecen disponibles mientras carga la red. La carga inicial de cada feed muestra `SeasonSplash` con el PNG de la temporada efectiva, tanto en modo automático como forzado. En Android, `MainActivity` lee el mismo JSON de `FlutterSharedPreferences` y la fecha local para dibujar el icono antes del primer frame de Flutter. La ventana del sistema en Android 12+ comienza con fondo neutro e icono transparente para evitar que aparezca el icono predeterminado de la actividad estable. Al entregar esa ventana a la app, se dibuja el PNG de la temporada guardada y se desvanece en una transición de 300 ms hacia Flutter. No se deshabilita esa actividad ni se borra el almacenamiento.

El launch screen estático de iOS tiene fondo neutro; la imagen dinámica aparece en la carga de Flutter. No se puede evaluar almacenamiento desde un storyboard de arranque. Los cambios nativos del splash requieren recompilar e instalar; hot reload no es suficiente.

Referencias del splash: https://developer.android.com/develop/ui/views/launch/splash-screen

## Diseño y controles de reproducción

Se conserva el video a pantalla completa del diseño original, sin AppBar, logo ni nombre en el feed. Solo se superpone una fila con Descubrir, Para ti, Favoritos y el botón de temas. El nombre visible es Vdry; se conserva el nombre interno del paquete `toktik` y las claves persistidas.

`FullScreenPlayer` reproduce los MP4 con `video_player`, recibe el toque para pausar/reanudar y conserva la pausa al cambiar el volumen. Mute/unmute solo modifica el volumen: no envía órdenes de play/pause ni reanuda por el refresco de fecha. Pausa al salir al fondo y libera el reproductor al cambiar de video. No existe ningún SDK de reproductor externo en esta implementación.

## Compatibilidad Nokia 5.1 Plus / Android 10

El Nokia reportaba `Decoder init failed: OMX.MTK.VIDEO.DECODER.AVC` y `setting nBufferCountActual ... failed`, incluso para las variantes 720p a 30 fps. El driver rechaza los buffers de `ImageReaderSurfaceProducer` del motor Flutter. En `MainActivity.onCreate`, antes de crear el motor, se selecciona la ruta `SurfaceTexture` mediante `FlutterRenderer.debugForceSurfaceProducerGlTextures` y se desactiva Impeller por intent para usar OpenGLES/Skia. La condición se limita a `Build.MODEL == Nokia 5.1 Plus` y API 29; los demás dispositivos siguen con la selección normal del motor.

El selector es una API de diagnóstico del embedding disponible en el SDK utilizado. Se usa aquí como ajuste de compatibilidad para un dispositivo con defecto confirmado y necesita revisarse al actualizar Flutter. No debe activarse con un contexto Vulkan: por eso la misma condición fuerza `enable-impeller=false`. El código de Flutter documenta esta prueba para identificar dispositivos con defectos de HardwareBuffer; su detección automática actual contempla Huawei, pero no este Nokia.

Validación: APK instalada sobre la existente, reproducción visible del video local de flores en Para ti, volumen habilitado y 18 inicializaciones de reproductor sin errores de decodificación en la sesión corregida. No se borraron preferencias ni favoritos. Referencia del motor: https://github.com/flutter/flutter/issues/166481 y https://github.com/flutter/flutter/blob/master/engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/renderer/FlutterRenderer.java

## Carga y reproducción optimizadas

Descubrir entrega resultados progresivamente: una API lenta no retiene los videos que ya respondieron otras fuentes. PeerTube usa la playlist HLS de una rendición cercana a ancho 480 cuando está disponible; Wikimedia prioriza altura 480. Internet Archive excluye MP4 con bitrate medio superior a 4 Mbps y empieza con archivos pequeños. Se conservan las tres APIs y el sonido original.

`RemoteVideoPreloader` prepara solo el controlador actual y el siguiente, sin reproducir audio, y reutiliza el siguiente al avanzar. Libera los anteriores y los de pestañas inactivas. La precarga es en memoria; no crea una caché de archivos persistente. El tiempo de inicialización se limita a 25 segundos. El almacenamiento persistente de likes y favoritos no cambia. La velocidad final sigue dependiendo de la disponibilidad y latencia del servidor de cada video.
