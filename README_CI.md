# Acuario Tus Mascotas — CI para generar APK

## Cómo obtener un APK sin instalar nada en tu PC
1. Crea un repositorio nuevo en GitHub y sube estos archivos **manteniendo las carpetas**:
   - `pubspec.yaml`
   - `lib/main.dart`
   - `.github/workflows/build-apk.yml`
2. En GitHub, ve a **Actions** → ejecuta el workflow **Build Flutter APK** (botón *Run workflow*).
3. Espera ~5–10 minutos. Al finalizar, en la corrida verás un artefacto llamado **acuario-debug-apk**.
4. Descárgalo. Dentro está `app-debug.apk`. En tu Android, habilita *Instalar aplicaciones de orígenes desconocidos* y listo.

> Es un APK **debug** (firmado con un keystore de debug). Para publicar en Play Store o firmar en **release**, te ayudo a agregar un keystore y variables seguras al workflow.
