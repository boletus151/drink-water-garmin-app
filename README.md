# Bebe agua

Aplicacion Connect IQ para **Forerunner 645 (sin Music)**, escrita en Monkey C con el SDK oficial de Garmin. Version: **0.5.0**.

## Funciones

- Objetivo diario configurable: 50 a 10000 ml, informativo; no registra consumo.
- Intervalo configurable: 15 a 60 minutos, editado cifra a cifra en el reloj.
- Horario del mismo dia, con inicio anterior al fin; cada extremo se edita en una pantalla HH:MM, cifra a cifra.
- Seleccion independiente de los siete dias de la semana: `day1` es lunes, `day2` martes, hasta `day7` domingo.
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

En el reloj, hora y minutos se editan juntos en "Hora inicial" y "Hora final". Un horario invalido o ningun dia seleccionado muestra un error en la pantalla principal y suspende la programacion hasta corregirlo. Cambiar ambos extremos puede dejar un estado temporalmente invalido: termina de editarlos antes de salir.

### Editor del intervalo

Las dos cifras se muestran en la misma pantalla. La cifra seleccionada aparece resaltada:

1. UP/DOWN cambia las decenas entre 0 y 9; START confirma y selecciona las unidades.
2. UP/DOWN cambia las unidades; START guarda el numero completo.
3. Solo se guardan valores entre **15 y 60**. Un valor fuera de rango muestra un error y permite corregirlo.
4. BACK desde las unidades vuelve a las decenas; BACK desde las decenas cancela sin guardar.

Por ejemplo, para 15 minutos selecciona primero **1**, pulsa START, selecciona **5** y pulsa START de nuevo. El objetivo diario conserva su editor anterior.

Al actualizar, se mantienen las propiedades existentes. Si un intervalo antiguo esta fuera de 15 a 60, los avisos se suspenden y la pantalla principal muestra un error. Al abrir el editor se propone el limite mas cercano con un aviso; no se cambia el valor guardado hasta confirmar ambas cifras.

### Editores de hora inicial y final

**Hora inicial** y **Hora final** muestran la hora completa en formato **HH:MM** (por ejemplo, **09:30**), tanto en el menu como en el editor.

- Las horas admiten **00 a 23** y los minutos **00 a 59**.
- UP/DOWN cambia la cifra resaltada; START avanza por las cuatro cifras y, al confirmar la ultima, guarda hora y minutos juntos.
- Solo se pueden seleccionar cifras validas: decenas de hora 0-2, unidades de hora 0-3 si las decenas son 2 (0-9 en otro caso), decenas de minutos 0-5 y unidades de minutos 0-9. UP/DOWN recorre esos rangos de forma circular.
- Si al cambiar las decenas de hora a 2 las unidades superan 3, se ponen a 0; por ejemplo, 19:30 pasa a 20:30.
- BACK vuelve a la cifra anterior; desde la primera cancela sin guardar ninguna parte de la hora.

La regla de inicio anterior al fin no cambia: si al editar los extremos el horario queda temporalmente invalido, los avisos se suspenden hasta corregirlo.

Cada extremo se guarda como un unico numero de minutos desde medianoche: `startTime` y `endTime`, entre 0 y 1439. Por ejemplo, 09:30 se guarda como 570. En el reloj siempre se muestra y edita HH:MM. En los ajustes de Connect IQ del movil se introduce ese numero de minutos; el SDK no ofrece un tipo de ajuste de hora HH:MM y se evita almacenar o parsear texto.

**Al actualizar desde una version con horas y minutos separados, vuelve a configurar el inicio y el fin.** No hay migracion: las propiedades antiguas dejan de utilizarse y los valores predeterminados nuevos son 09:00 y 21:00. El objetivo, intervalo y dias activos conservan sus propiedades.

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

### Depurar con VS Code

1. Abre la carpeta **drink-water_v1** como carpeta de trabajo de VS Code, no solo la carpeta Garmin que la contiene.
2. Selecciona un SDK activo en SDK Manager y configura en los ajustes personales de la extension Monkey C:
   - `monkeyC.javaPath`: carpeta raiz del JDK; en este entorno, `~/.local/share/drink-water-tools/java/Contents/Home` (usa la ruta absoluta en VS Code).
   - `monkeyC.developerKeyPath`: ruta absoluta a la clave DER privada, fuera del repositorio.
   - `monkeyC.typeCheckLevel`: `Strict`.
3. En **Ejecutar y depurar**, elige **Depurar Bebe agua (Forerunner 645)** y pulsa **F5**.
4. La extension oficial compila el proyecto y lo ejecuta en el simulador del 645. La configuracion [launch.json](.vscode/launch.json) detiene la ejecucion al iniciar.
5. Coloca puntos de interrupcion en los archivos Monkey C, continua con F5 y usa los botones del reloj simulado para reproducir el comportamiento.

Para los editores por cifras, coloca puntos de interrupcion en `DigitView.change` o `DigitView.confirm`, en [SettingsView.mc](source/SettingsView.mc). `TimeView.save` guarda la hora completa.

No ejecutes al mismo tiempo `run-simulator.sh` y una sesion de depuracion sobre el mismo simulador. Las rutas personales y la clave no forman parte de `launch.json`; `.vscode/settings.json` permanece excluido de Git.

Para ejecutar pruebas, abre primero el simulador oficial incluido en el SDK, acepta sus permisos de macOS si los solicita y ejecuta:

```sh
make test
```

Las pruebas Monkey C estan en [tests/ScheduleTests.mc](tests/ScheduleTests.mc). Comprueban apertura/refresco de menus, limites inclusivos, cadencia, dias excluidos, configuracion invalida, salto a la siguiente semana, descarte de avisos antiguos, separacion minima y comprobaciones que no desplazan recordatorios.

En macOS, `monkeydo` de los SDK recientes puede devolver codigo 1 incluso con todas las pruebas aprobadas. El objetivo `test` exige el resumen oficial `PASSED (passed=N, failed=0, errors=0)` con al menos una prueba, informa de esa anomalia y rechaza cualquier otro error. La salida completa queda en `bin/test-output.log`.

Para ejecutar la aplicacion en el simulador abierto:

```sh
./run-simulator.sh
```

El [script](run-simulator.sh) configura Java mediante el Makefile y carga el ejecutable existente; no abre el simulador ni recompila. Deja la terminal abierta mientras pruebas. Si has cambiado el codigo, ejecuta `make build` antes.

Tambien funciona desde otra carpeta usando su ruta, por ejemplo `./drink-water_v1/run-simulator.sh` desde la carpeta Garmin. Puedes pasar las mismas rutas alternativas que al Makefile: `./run-simulator.sh SDK_HOME="/ruta/al/sdk" JAVA_HOME="/ruta/al/jdk/Contents/Home"`.

Para probar el servicio, configura un horario cercano y un intervalo de 15 minutos, sal de la aplicacion y utiliza los controles de eventos en segundo plano del simulador. Verifica tambien que descartar el dialogo no impide los siguientes avisos.

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

El esquema de ajustes actual es `schemaVersion=3`, con `startTime` y `endTime` en minutos desde medianoche. Los dias siguen el orden lunes-domingo en propiedades, menus y ajustes del movil. El calendario de Garmin usa domingo=1; [Schedule.mc](source/Schedule.mc) convierte esa numeracion al indice interno lunes=0.

No hay migraciones ni copias temporales. Se aceptan los marcadores de version 1, 2 y 3, pero siempre se leen las propiedades actuales; las cuatro propiedades antiguas de hora/minuto se ignoran. Si actualizas desde una version donde `day1` era domingo, **revisa y configura de nuevo los dias activos**: los valores se conservan, pero su significado cambia.

Mantener identificadores de propiedades conserva sus ajustes al actualizar; un cambio de identificador sin migracion requiere reconfigurar el ajuste, como ocurre con el horario en esta entrega. El ID del manifiesto debe mantenerse estable para conservar la identidad de la aplicacion. Una version desconocida se muestra como error, no se reemplaza silenciosamente.

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
- En una entrega anterior se aprobaron **18 pruebas**, sin fallos ni errores. Las pruebas de horario se han actualizado para la seleccion restringida de cifras y el almacenamiento en minutos desde medianoche; no se han ejecutado en esta mejora, a peticion de la usuaria.
- Verificados en la entrega anterior: pantalla sin recortes, interruptor, apertura de ajustes, edicion y guardado del objetivo e intervalo.
- Observado en la entrega anterior un aviso autonomo a la hora prevista con la aplicacion cerrada: "Background Process Wake / Recuerda beber agua"; descartado correctamente.
- En la mejora anterior se comprobo el aviso de intervalo antiguo fuera de rango. Los horarios usan ahora dos editores HH:MM; la comprobacion visual del resaltado y los botones queda disponible para prueba manual.
- Generados el ejecutable USB y el paquete Connect IQ.

Pendiente de validar en un Forerunner 645 fisico: comportamiento del firmware durante actividades y No molestar, reinicios, cambios de hora y consumo real de bateria. No se ha instalado ni publicado automaticamente.

## Referencias oficiales

- [Background](https://developer.garmin.com/connect-iq/api-docs/Toybox/Background.html)
- [Properties](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Properties.html)
- [Storage](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/Storage.html)
- [Pruebas unitarias](https://developer.garmin.com/connect-iq/core-topics/unit-testing/)
