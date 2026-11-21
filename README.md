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

### Apariencia

La pantalla principal, la del recordatorio, los menus de ajustes y dias, y los editores comparten un fondo negro con acentos azul agua. El texto principal es blanco, las indicaciones secundarias son gris claro y los errores aparecen en ambar, siempre acompanados de texto. La fila del menu seleccionada tiene fondo azul oscuro; la cifra activa, fondo azul agua y texto negro. Los botones y el guardado no cambian.

La pantalla principal y el recordatorio son vistas distintas. La principal muestra el objetivo diario y el proximo aviso. El recordatorio muestra "Recuerda beber agua" y el horario, pero no calcula ni muestra la proxima alerta. Ambas comparten el encabezado, los errores y los botones. Guardar un ajuste vuelve al estado de pantalla principal; recibir un aviso nuevo selecciona la vista del recordatorio sin interrumpir un editor abierto.

`WaterView` y `ReminderView` heredan de `BaseWaterView`, no una de la otra. La base actualiza el marco compartido mediante `updateFrame`; cada vista carga su layout XML en `onLayout` mediante `setWaterLayout`, que incorpora el componente de error compartido, actualiza los datos en `onUpdate` y oculta su contenido si hay un error.

El dialogo inicial "Recuerda beber agua" y los ajustes del movil conservan la apariencia del sistema Garmin: la aplicacion no controla sus colores.

La distribucion, las fuentes y los colores iniciales se definen en [resources/layouts/](resources/layouts/). [Theme.mc](source/Style/Theme.mc) conserva los colores usados por el codigo al cambiar estados:

| Pantalla o elemento | XML |
| --- | --- |
| Principal | [water.xml](resources/layouts/screens/water.xml) |
| Recordatorio, sin proxima alerta | [reminder.xml](resources/layouts/screens/reminder.xml) |
| Error de ajustes o programacion en ambas pantallas | [settings-error.xml](resources/layouts/components/settings-error.xml) |
| Objetivo diario | [goal.xml](resources/layouts/screens/goal.xml) |
| Intervalo | [interval.xml](resources/layouts/screens/interval.xml) |
| Hora inicial y final | [time.xml](resources/layouts/screens/time.xml) |
| Encabezado de ajustes | [settings-menu-header.xml](resources/layouts/components/settings-menu-header.xml) |
| Encabezado de dias | [days-menu-header.xml](resources/layouts/components/days-menu-header.xml) |
| Fila de ambos menus | [menu-item.xml](resources/layouts/components/menu-item.xml) |

[screens/](resources/layouts/screens/) contiene layouts de pantallas completas; [components/](resources/layouts/components/) contiene piezas que se dibujan dentro de una pantalla. Los nombres de los componentes describen su funcion: `header` para encabezados e `item` para filas. Los identificadores `SettingsMenuHeaderLayout` y `DaysMenuHeaderLayout` dejan claro que esos recursos no representan menus completos. Esta distincion afecta solo a los XML y sus referencias; las clases `View` y `Menu` conservan sus nombres.

Los menus conservan el control nativo de Garmin para la lista, el desplazamiento y la seleccion; sus encabezados y filas usan XML. Los layouts se compilan en la app: cambiar un XML o la paleta requiere recompilar, no se cargan ficheros externos en el reloj.

Los XML usan componentes nativos de Garmin: `label` para cifras y textos de una linea, `text-area` para errores, rangos, proximo aviso y menus, y los `drawable-list` de [drawables.xml](resources/drawables.xml) para el fondo y el foco del menu. Las posiciones y dimensiones porcentuales se calculan respecto al contexto de dibujo, sin fijar una resolucion en pixeles. En una etiqueta con justificacion `CENTER | VCENTER`, `x` e `y` indican el centro del texto. En un area, `x="center"` la centra horizontalmente; `y` indica su borde superior y `height` reserva su espacio. La justificacion centra el texto dentro del area. El compilador exige colores literales o constantes `Graphics.COLOR_*` en los atributos nativos, no referencias a `Theme`; los valores iniciales del XML deben mantenerse en consonancia con los colores de estado del codigo:

```xml
<label id="title" x="50%" y="14%" font="Graphics.FONT_SMALL"
       text="@Strings.AppName" color="0x55FFFF"
       justification="Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER"/>
```

Las cifras tienen centros porcentuales explicitos, que no se mueven al cambiar el valor o la seleccion. En las horas estan en el 28%, 40%, 60% y 72% del ancho, con los dos puntos en el 50%; el intervalo usa el 43% y el 57%. Su `y` es el centro vertical por la justificacion `VCENTER`. La cifra activa usa el fondo nativo del texto en azul agua, sin un drawable de seleccion propio:

```xml
<label id="digit0" x="28%" y="40%" font="Graphics.FONT_NUMBER_MILD"
       text="0" color="0xFFFFFF" background="Graphics.COLOR_TRANSPARENT"
       justification="Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER"/>
```

Los margenes y espacios de cada pantalla se ajustan en su XML. El contenido largo ocupa la zona central, mas ancha en el contorno circular del Forerunner 645. Los encabezados y filas de menu usan su propio contexto rectangular; las filas reparten la altura entre el titulo y el valor, o usan toda la altura para una entrada sin valor. La altura nativa de la fila sigue calculandose con la fuente del dispositivo, `STACK_GAP`, `MENU_PADDING` y `MENU_FOCUS_PADDING` de [Theme.mc](source/Style/Theme.mc).

`text-area`, disponible desde API 3.1, aplica los saltos de linea de forma nativa dentro del ancho y alto declarados. Los errores tienen un area mas alta y sustituyen al contenido normal. Ocultar un elemento deja su zona libre: ya no se recolocan las filas ni se reducen automaticamente las fuentes. Los textos iniciales del XML permiten entender la pantalla y se sustituyen por los valores reales en `onUpdate`. Los botones, la validacion y el guardado no cambian.

El manifiesto sigue admitiendo solo el Forerunner 645. Las posiciones se adaptan al tamano del contexto, pero los porcentajes no garantizan que cualquier texto o fuente quepa en cualquier reloj. Anadir otro dispositivo requiere incorporar su perfil y validar sus fuentes, pantalla y controles; si hace falta, se pueden definir variantes de recursos por dispositivo.

Conserva los identificadores de los elementos que actualiza el codigo: `content`, `status`, `schedule`, `toggleHint` y `menuHint` en las dos vistas principales; `errorTitle` y `errorDetail` en el componente compartido [settings-error.xml](resources/layouts/components/settings-error.xml); `next` solo en la principal; `title`, `digitN`, `range` y `confirmHint` en los editores por cifras. `setWaterLayout` combina los drawables de la pantalla y del error usando el mismo contexto de dibujo, por lo que los porcentajes y el acceso por identificador se mantienen. [LayoutView.mc](source/View/Common/LayoutView.mc) solo proporciona acceso tipado a los textos y controla que elementos dibujar, porque API 3.1 no admite la visibilidad nativa de los drawables. Ya no contiene un motor de distribucion ni componentes de dibujo propios.

### Organizacion estilo MVC

El codigo de [source/](source/) se organiza por responsabilidades:

| Carpeta | Responsabilidad |
| --- | --- |
| [App/](source/App/) | Punto de entrada, ciclo de vida y coordinacion del guardado. |
| [Model/](source/Model/) | Datos de configuracion, lectura de propiedades y validacion. |
| [Service/](source/Service/) | Calculo del calendario, registro de eventos y ejecucion en segundo plano. |
| [View/](source/View/) | Pantallas, menus, editores y sus vistas base. |
| [View/Common/](source/View/Common/) | Acceso a layouts XML y componentes visuales reutilizables. |
| [Controller/](source/Controller/) | Delegados de entrada, borradores de edicion y navegacion. |
| [Style/](source/Style/) | Paleta y constantes de apariencia. |

Los layouts se organizan en [resources/layouts/screens/](resources/layouts/screens/) y [resources/layouts/components/](resources/layouts/components/); las pruebas permanecen en [tests/](tests/). Las carpetas no introducen nuevos modulos ni cambian los nombres de las clases. Los recursos XML se referencian por su identificador, no por su ruta. `monkey.jungle` conserva `source` como ruta raiz de codigo y `resources` como raiz de recursos; el compilador incluye sus subcarpetas.

- **Modelo compartido:** `Config` y `Schedule` mantienen la configuracion y el calendario; `DrinkWaterApp.save` persiste los cambios y recalcula los avisos.
- **Vista:** carga el XML, lee los datos y actualiza textos, colores y elementos mostrados. No modifica ni guarda el borrador del editor.
- **Controlador:** es el delegado de entrada de Garmin. Mantiene el borrador, responde a los botones, valida, confirma o cancela, guarda y gestiona la navegacion.

Cada pantalla tiene su vista y controlador en archivos propios:

| Pantalla | Vista | Controlador |
| --- | --- | --- |
| Principal | [WaterView.mc](source/View/WaterView.mc) | [WaterController.mc](source/Controller/WaterController.mc) |
| Recordatorio | [ReminderView.mc](source/View/ReminderView.mc) | [ReminderController.mc](source/Controller/ReminderController.mc) |
| Ajustes | [SettingsMenu.mc](source/View/SettingsMenu.mc) | [SettingsController.mc](source/Controller/SettingsController.mc) |
| Dias activos | [DaysMenu.mc](source/View/DaysMenu.mc) | [DaysController.mc](source/Controller/DaysController.mc) |
| Objetivo diario | [GoalView.mc](source/View/GoalView.mc) | [GoalController.mc](source/Controller/GoalController.mc) |
| Intervalo | [IntervalView.mc](source/View/IntervalView.mc) | [IntervalController.mc](source/Controller/IntervalController.mc) |
| Hora inicial y final | [TimeView.mc](source/View/TimeView.mc) | [TimeController.mc](source/Controller/TimeController.mc) |

Las dos horas reutilizan la misma logica, vista y layout [time.xml](resources/layouts/screens/time.xml). El controlador aporta el titulo y el valor; `DigitView.onUpdate` actualiza esos datos sin duplicar la estructura visual. Los controladores base de numeros y cifras comparten el comportamiento de edicion; las vistas base comparten solo el dibujo. `BaseWaterController` reutiliza los botones de principal y recordatorio. `BaseSettingsMenu` y `MenuVisuals` reutilizan el refresco y los elementos visuales de los menus.

Al abrir un editor, la vista recibe el mismo controlador que Garmin utiliza como delegado:

```monkeyc
var controller = new IntervalController(text(Rez.Strings.Interval), 15);
var view = new IntervalView(controller);
WatchUi.pushView(view, controller, WatchUi.SLIDE_UP);
```

No hay un framework MVC adicional ni copias del modelo por pantalla. Los cambios de organizacion no alteran los botones, las reglas de validacion ni el guardado.

### Prueba rapida del aviso

La constante `Config.DEBUG` en [Config.mc](source/Model/Config.mc) esta en `true` para pruebas. Al abrir la app con los avisos activados y una configuracion valida, solicita un unico aviso de prueba **60 segundos despues de abrir**, aunque sea fuera del horario o de los dias activos. Sal inmediatamente con BACK para probarlo con la aplicacion cerrada. Salir o editar ajustes no reinicia la cuenta atras; desactivar los avisos cancela el evento. Abrir de nuevo la app inicia otra prueba, tambien al abrirla desde un aviso.

Si el servicio se ha ejecutado recientemente, la prueba se aplaza hasta cumplir los cinco minutos minimos de Garmin. La pantalla principal muestra esa hora en "Proximo" y la consola informa de la espera en segundos. El firmware sigue controlando cuando presenta el dialogo; no se garantiza una alarma exacta. Se descarta un evento con mas de 60 segundos de retraso y despues continua el calendario normal.

Para volver al comportamiento normal, cambia `const DEBUG = false;`, ejecuta `make build` y carga de nuevo el ejecutable. **Desactiva DEBUG antes de distribuir o usar la app normalmente.** No modifica tus ajustes ni requiere un nuevo esquema de propiedades.

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

La carpeta [bin/](bin/) contiene archivos generados, no fuentes: ejecutables, metadatos de ajustes, caches e intermedios del compilador. Las compilaciones pueden dejar intermedios de archivos movidos o eliminados; esas caches se pueden borrar y regenerar con `make build`. `make test-build` regenera los binarios de pruebas y `make package` regenera el paquete de distribucion.

### Depurar con VS Code

1. Abre la carpeta **drink-water_v1** como carpeta de trabajo de VS Code, no solo la carpeta Garmin que la contiene.
2. Selecciona un SDK activo en SDK Manager y configura en los ajustes personales de la extension Monkey C:
   - `monkeyC.javaPath`: carpeta raiz del JDK; en este entorno, `~/.local/share/drink-water-tools/java/Contents/Home` (usa la ruta absoluta en VS Code).
   - `monkeyC.developerKeyPath`: ruta absoluta a la clave DER privada, fuera del repositorio.
   - `monkeyC.typeCheckLevel`: `Strict`.
3. En **Ejecutar y depurar**, elige **Depurar Bebe agua (Forerunner 645)** y pulsa **F5**.
4. La extension oficial compila el proyecto y lo ejecuta en el simulador del 645. La configuracion [launch.json](.vscode/launch.json) detiene la ejecucion al iniciar.
5. Coloca puntos de interrupcion en los archivos Monkey C, continua con F5 y usa los botones del reloj simulado para reproducir el comportamiento.

Para los editores por cifras, coloca puntos de interrupcion en `DigitController.change` o `DigitController.confirm`, en [DigitController.mc](source/Controller/DigitController.mc). `TimeController.save`, en [TimeController.mc](source/Controller/TimeController.mc), guarda la hora completa.

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

- [Config.mc](source/Model/Config.mc): lectura y validacion centralizada de propiedades.
- [Schedule.mc](source/Service/Schedule.mc): calendario local y registro de eventos.
- [WaterService.mc](source/Service/WaterService.mc): ejecucion en segundo plano y solicitud de apertura.
- [DrinkWaterApp.mc](source/App/DrinkWaterApp.mc): ciclo de vida y persistencia del ultimo aviso.
- [BaseWaterView.mc](source/View/BaseWaterView.mc): marco y ciclo de visibilidad compartidos.
- [LayoutView.mc](source/View/Common/LayoutView.mc): acceso tipado a elementos XML y dibujo compatible con API 3.1.
- [Theme.mc](source/Style/Theme.mc): colores de estado, espaciado y rellenos del menu; el fondo de foco se define en [drawables.xml](resources/drawables.xml).
- [WaterView.mc](source/View/WaterView.mc): pantalla principal.
- [WaterController.mc](source/Controller/WaterController.mc) y [ReminderController.mc](source/Controller/ReminderController.mc): controladores de las vistas principales.
- [ReminderView.mc](source/View/ReminderView.mc): pantalla del recordatorio, sin proxima alerta.
- [SettingsMenu.mc](source/View/SettingsMenu.mc) y [DaysMenu.mc](source/View/DaysMenu.mc): menus independientes.
- [SettingsController.mc](source/Controller/SettingsController.mc) y [DaysController.mc](source/Controller/DaysController.mc): seleccion, apertura de editores y cambio de dias.
- [NumberView.mc](source/View/NumberView.mc) y [DigitView.mc](source/View/DigitView.mc): dibujo compartido de los editores.
- [NumberController.mc](source/Controller/NumberController.mc) y [DigitController.mc](source/Controller/DigitController.mc): edicion, validacion y botones compartidos.
- [GoalView.mc](source/View/GoalView.mc), [IntervalView.mc](source/View/IntervalView.mc) y [TimeView.mc](source/View/TimeView.mc): vistas de editores, con sus controladores en [Controller/](source/Controller/).
- [MenuVisuals.mc](source/View/Common/MenuVisuals.mc): encabezados y filas XML de los menus.
- [resources/](resources/): layouts XML, textos, propiedades, ajustes e icono.

En [Schedule.mc](source/Service/Schedule.mc), `localClockSeconds` representa los campos de fecha/hora local para hacer calculos de calendario, y `momentFromLocalClock` los convierte en un instante real, teniendo en cuenta los cambios de hora. `next` calcula el siguiente aviso; `earliestAllowedTime` comparte la espera minima entre debug y el calendario normal; `respectMinimumSpacing` aplaza u omite un aviso cuando es necesario. `eventTime` combina esas reglas con las comprobaciones periodicas, sin cambiar la cadencia.

El esquema de ajustes actual es `schemaVersion=3`, con `startTime` y `endTime` en minutos desde medianoche. Los dias siguen el orden lunes-domingo en propiedades, menus y ajustes del movil. El calendario de Garmin usa domingo=1; [Schedule.mc](source/Service/Schedule.mc) convierte esa numeracion al indice interno lunes=0.

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

- Correccion del ajuste circular: se elimina el rectangulo inscrito que hacia fallar la pantalla principal del 645. Se comprueba el contorno por fila y se anade una regresion para contenido alto sin recortes. Aplicacion y pruebas compiladas sin avisos; las pruebas no se han ejecutado. La usuaria confirma que, tras ejecutar de nuevo el script en el simulador del 645, la pantalla principal se muestra correctamente.

- XML nativo con posiciones relativas: los ocho layouts usan etiquetas, areas de texto y fondos compilados por Garmin; las horas inicial y final comparten `time.xml`. Eliminado el motor de distribucion propio; actualizadas las pruebas de posicion y zonas de error. Compilacion estricta de aplicacion y fuentes de pruebas sin avisos, sin ejecutar tests. Pendiente de comprobar visualmente la compilacion final en el simulador; el control automatizado de su ventana ha quedado bloqueado.
- Distribucion automatica (anterior al XML nativo): compilacion estricta de aplicacion sin avisos. Los nueve layouts no contienen coordenadas; se han anadido casos de centrado, redistribucion de elementos ocultos y resaltado de cifras con distintos tamanos de buffer. No se han ejecutado las pruebas, a peticion de la usuaria; pendiente de comprobacion visual y validacion en otros perfiles.

- Organizacion MVC: compilacion estricta sin avisos y **25 pruebas aprobadas**; las pruebas de edicion ejercitan ahora los controladores y las de renderizado conectan cada vista XML con su controlador. Se mantienen el guardado, la cancelacion, la seleccion de cifras y la programacion de avisos.
- Layouts XML: compilacion estricta sin avisos y **25 pruebas aprobadas**. Se renderizan en buffers completos las pantallas principal, recordatorio, objetivo, intervalo y ambas horas; tambien los encabezados y filas de menus con cambios de tamano. Se comprueba que el recordatorio no contiene `next` y que los elementos ocultos no se dibujan. Pendiente de revision visual en el reloj o simulador.
- Separacion de vistas: compilacion estricta y paquete sin avisos; **22 pruebas aprobadas**, incluida la seleccion de la vista del recordatorio y el retorno a la principal al guardar. Pendiente de comprobacion visual al aceptar el dialogo de Garmin.
- Modo DEBUG: compilacion estricta y paquete generados sin avisos; **21 pruebas aprobadas**, incluidas la espera exacta de 60 segundos, el limite minimo de Garmin, la desactivacion del modo y la conservacion/caducidad del plazo. La presentacion real del aviso sigue pendiente de prueba manual.
- Mejora de color: compilacion estricta de aplicacion y pruebas sin avisos; **18 pruebas aprobadas**, sin fallos ni errores. La comprobacion visual de la nueva paleta queda pendiente: la automatizacion del simulador fue bloqueada por la proteccion de foco de macOS.
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
