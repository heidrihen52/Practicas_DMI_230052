# Yes, No, Maybe

Chat en Flutter con Provider, Dio y la API https://yesno.wtf/api.

- Solo los mensajes que terminan en `?` generan respuestas (se ignoran espacios al inicio y al final).
- Cada pregunta selecciona un entero aleatorio entre 0 y 9: 0–3 → Sí (40%), 4–7 → No (40%), 8–9 → Tal vez (20%). Son probabilidades independientes, no cuotas exactas por cada diez preguntas.
- La petición usa `force=yes`, `force=no` o `force=maybe` para obtener el GIF de la respuesta elegida. Referencia: https://yesno.wtf/.
- Cada mensaje conserva su fecha/hora de creación; las burbujas muestran la hora local en formato `HH:mm`.
- Los errores de conexión y de carga de GIF tienen un mensaje visible.

## Ejecutar y verificar

Desde `Practica03/yes_no_app`:

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

Las pruebas verifican los diez resultados posibles de la selección, el GIF solicitado, la detección de preguntas, los errores de red y la hora en ambas burbujas sin depender de Internet.

## Agregar el ícono cuando esté listo

El ícono actual no se modificó. Cuando tengas tu diseño:

1. Exporta una imagen PNG cuadrada de 1024 × 1024 píxeles, preferentemente con fondo sólido y margen alrededor del dibujo. Guárdala como `assets/icon/app_icon.png` dentro del proyecto.
2. Desde `Practica03/yes_no_app`, instala la herramienta:

   ```bash
   flutter pub add --dev flutter_launcher_icons
   ```

3. Crea `flutter_launcher_icons.yaml` junto a `pubspec.yaml` con este contenido:

   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/icon/app_icon.png"
     remove_alpha_ios: true
   ```

4. Genera los íconos:

   ```bash
   dart run flutter_launcher_icons
   ```

5. Detén la app y vuelve a ejecutar `flutter run`. Verifica el ícono en el lanzador del dispositivo; hot reload no actualiza los recursos nativos. Si el lanzador conserva el anterior, reinstala la app (esto puede borrar sus datos locales).

No hace falta declarar el PNG en `flutter/assets` si solo se utiliza para generar el ícono. Para generar también íconos web, agrega `web: {generate: true}` dentro de `flutter_launcher_icons`.

Documentación de la herramienta: https://pub.dev/packages/flutter_launcher_icons.
