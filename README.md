# Bebe agua

Aplicacion Connect IQ para **Forerunner 645 (sin Music)**, escrita en Monkey C con el SDK oficial de Garmin. Version inicial: **0.1.0**.

## Funciones

- Objetivo diario configurable: 50 a 10000 ml, informativo; no registra consumo.
- Intervalo configurable: 5 a 1440 minutos.
- Horario del mismo dia, con inicio anterior al fin.
- Seleccion independiente de los siete dias de la semana.
- Activacion/desactivacion persistente sin perder los ajustes.
- Configuracion desde el reloj y desde los ajustes de Connect IQ en el movil.
- Avisos autonomos en segundo plano, sin conexion al telefono.

El primer aviso corresponde a la hora inicial. Los siguientes mantienen la cadencia desde esa hora. La hora final se incluye **solo si coincide con la cadencia**. Por ejemplo, 09:00 a 10:00 cada 17 minutos produce 09:00, 09:17, 09:34 y 09:51.

## Limitaciones del Forerunner 645

El aviso es el **dialogo del sistema que solicita abrir la aplicacion**, con el texto "Recuerda beber agua". Aceptarlo abre la aplicacion; descartarlo no desactiva futuros avisos. No se solicita vibracion, sonido ni encendido de la iluminacion.

No es una notificacion moderna ni una pantalla personalizada superpuesta a la esfera. El firmware controla cuando muestra el dialogo y puede posponerlo o impedirlo durante otras actividades. No se garantiza puntualidad de alarma.

La aplicacion descarta eventos con mas de 60 segundos de retraso y no reproduce avisos atrasados. El horario se interpreta con precision de minutos: el minuto final completo esta incluido. No solicita avisos fuera de esos minutos o en dias excluidos; Garmin controla cuando presenta un dialogo ya solicitado. Garmin exige al menos cinco minutos entre ejecuciones en segundo plano. Si la siguiente ranura queda demasiado cerca, se aplaza dentro de la tolerancia de 60 segundos; si no es posible, se omite para conservar la cadencia y respetar el limite.

Mientras hay recordatorios activados se realizan comprobaciones aproximadamente cada hora (hasta 65 minutos para no desplazar un aviso cercano), aunque el siguiente aviso sea otro dia, para revisar la hora y los ajustes. Esto tiene un coste de bateria que debe medirse en el dispositivo. Desactivar los avisos elimina el evento temporal.

Se usa la hora local del reloj. Se omiten horas inexistentes al cambiar al horario de verano y no se repite un aviso en una hora duplicada. Tras cambiar la zona horaria, la adaptacion puede tardar hasta aproximadamente 65 minutos; abrir y cerrar la aplicacion recalcula inmediatamente la programacion.

## Uso en el reloj

1. Abre **Bebe agua** desde la lista de aplicaciones, al menos una vez despues de instalar.
2. Pulsa **START** en la pantalla principal para activar/desactivar.
3. Pulsa **UP** (o manten UP/MENU) para abrir los ajustes.
4. Usa **UP/DOWN** y **START** para seleccionar una opcion.
5. En un editor numerico, UP aumenta, DOWN disminuye y START guarda. BACK cancela.
6. En "Dias activos", START cambia el estado del dia seleccionado.
7. Sal con BACK para volver a la esfera. Los recordatorios continuan.

Horas y minutos se editan por separado. Un horario invalido o ningun dia seleccionado muestra un error en la pantalla principal y suspende la programacion hasta corregirlo. Cambiar varios campos puede dejar un estado temporalmente invalido: termina de editar ambos extremos antes de salir.

## Desarrollo y compilacion

Requisitos:

- [SDK oficial Connect IQ](https://developer.garmin.com/connect-iq/sdk/) y perfil **Forerunner 645**, descargado con SDK Manager.
- Java 17.
- VS Code con la extension oficial **Monkey C** (`garmin.monkey-c`).
- Clave privada de desarrollador en formato DER, fuera del proyecto.

En este entorno se han instalado las herramientas en `~/.local/share/drink-water-tools/`. El Makefile permite reemplazar las rutas; no requiere cambios globales ni sudo:

```sh
make build
make test-build

# Para otras ubicaciones:
make build SDK_HOME="/ruta/al/sdk" JAVA_HOME="/ruta/al/jdk/Contents/Home" \
  DEVELOPER_KEY="/ruta/privada/developer_key.der"
```

La compilacion usa comprobacion estricta de tipos (`-l 3`) y avisos del compilador. El resultado instalable es [bin/drink-water.prg](bin/drink-water.prg).

Para ejecutar pruebas, abre primero el simulador oficial incluido en el SDK, acepta sus permisos de macOS si los solicita y ejecuta:

```sh
make test
```

Las pruebas Monkey C estan en [tests/ScheduleTests.mc](tests/ScheduleTests.mc). Comprueban apertura/refresco de menus, limites inclusivos, cadencia, dias excluidos, configuracion invalida, salto a la siguiente semana, descarte de avisos antiguos, separacion minima y comprobaciones que no desplazan recordatorios.

En macOS, `monkeydo` de los SDK recientes puede devolver codigo 1 incluso con todas las pruebas aprobadas. El objetivo `test` exige el resumen oficial `PASSED (passed=N, failed=0, errors=0)` con al menos una prueba, informa de esa anomalia y rechaza cualquier otro error. La salida completa queda en `bin/test-output.log`.

Para ejecutar la aplicacion en el simulador abierto:

```sh
export JAVA_HOME="$HOME/.local/share/drink-water-tools/java/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
"$HOME/.local/share/drink-water-tools/sdk/bin/monkeydo" bin/drink-water.prg fr645
```

Para probar el servicio, configura un horario cercano y un intervalo de cinco minutos, sal de la aplicacion y utiliza los controles de eventos en segundo plano del simulador. Verifica tambien que descartar el dialogo no impide los siguientes avisos.

## Instalacion en el reloj

1. Compila con `make build`.
2. Conecta el Forerunner 645 por USB.
3. Copia `bin/drink-water.prg` a `GARMIN/APPS` en el reloj.
4. Expulsa el reloj de forma segura.
5. Abre Bebe agua, configura los ajustes y vuelve a la esfera.

La configuracion desde el reloj funciona sin publicar la aplicacion. La configuracion desde el movil depende de que Connect IQ disponga de los metadatos de ajustes; para distribuirlos utiliza el paquete oficial:

```sh
make package
```

Esto genera `bin/drink-water.iq`. La publicacion en Connect IQ Store, incluida una beta, es un paso separado y requiere la cuenta de desarrollador y la revision de Garmin. No se publica automaticamente.

## Mantenimiento

- [Config.mc](source/Config.mc): lectura y validacion centralizada de propiedades.
- [Schedule.mc](source/Schedule.mc): calendario local y registro de eventos.
- [WaterService.mc](source/WaterService.mc): ejecucion en segundo plano y solicitud de apertura.
- [DrinkWaterApp.mc](source/DrinkWaterApp.mc): ciclo de vida y persistencia del ultimo aviso.
- [WaterView.mc](source/WaterView.mc) y [SettingsView.mc](source/SettingsView.mc): interfaz por botones.
- [resources/](resources/): textos, propiedades, ajustes e icono.

El esquema de ajustes esta versionado mediante `schemaVersion=1`. Los identificadores de propiedades y el ID del manifiesto deben mantenerse estables para conservar ajustes e identidad al actualizar. Si cambia el esquema, incorpora una migracion explicita en primer plano; una version desconocida se muestra como error, no se reemplaza silenciosamente.

El Forerunner 645 admite API 3.1: el servicio no escribe en Storage ni en Properties. Devuelve el ultimo aviso con `Background.exit` y el primer plano lo persiste. Los textos usados por el servicio tienen alcance `background`.

Antes de cada entrega:

1. Ejecuta compilacion estricta y pruebas.
2. Verifica dialogos aceptados/descartados, interruptor, dias excluidos y horario final.
3. Prueba reinicio, cambio de hora/zona, No molestar y una actividad deportiva.
4. Mide memoria y bateria en el reloj real.
5. Prueba actualizar sin perder ajustes.
6. Actualiza la version y etiqueta la entrega en Git; guarda la clave privada de forma segura fuera del repositorio.

No hay servidor, analitica ni recogida de datos de consumo. Un aviso no confirma que hayas bebido ni calcula recomendaciones medicas.

## Validacion de esta entrega

- Compilacion estricta sin avisos con SDK oficial **9.3.0**, perfil **fr645 (3.1.6)**.
- **9 pruebas aprobadas**, sin fallos ni errores, en el simulador oficial.
- Verificados en el simulador: pantalla sin recortes, interruptor, apertura de ajustes, edicion y guardado del objetivo e intervalo.
- Observado un aviso autonomo a la hora prevista con la aplicacion cerrada: "Background Process Wake / Recuerda beber agua"; descartado correctamente.
- Generados el ejecutable USB y el paquete Connect IQ.

Pendiente de validar en un Forerunner 645 fisico: comportamiento del firmware durante actividades y No molestar, reinicios, cambios de hora y consumo real de bateria. No se ha instalado ni publicado automaticamente.

## Referencias oficiales

- [Background](https://developer.garmin.com/connect-iq/api-docs/Toybox/Background.html)
- [Properties](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Properties.html)
- [Storage](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html)
- [Pruebas unitarias](https://developer.garmin.com/connect-iq/core-topics/unit-testing/)
