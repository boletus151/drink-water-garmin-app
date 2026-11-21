#!/bin/bash
# Internal helper sourced by the simulator launchers.
# Run in a subshell to keep configuration and cleanup traps local.
run_debug() (
    set -euo pipefail

    screen_enabled=false
    screen=goal
    if [ "$#" -eq 1 ]; then
        screen_enabled=true
        screen="$1"
    fi

    debug_dir="$(mktemp -d "${TMPDIR:-/tmp}/drink-water-debug.XXXXXX")"
    cleanup() {
        rm -f -- "$debug_dir/DebugConfig.mc" "$debug_dir/debug.jungle"
        rmdir -- "$debug_dir"
    }
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    cat > "$debug_dir/DebugConfig.mc" <<EOF
(:background)
module DebugConfig {
    const SCREEN_ENABLED = $screen_enabled;
    const SCREEN = "$screen";
    (:debug)
    const DEBUG = true;
    (:release)
    const DEBUG = false;
}
EOF

    cat > "$debug_dir/debug.jungle" <<EOF
base.sourcePath = \$(base.sourcePath);$debug_dir
base.excludeAnnotations = debugDefaults
EOF

    if [ "$screen_enabled" = true ]; then
        echo "Compilando pantalla debug: $screen con avisos acelerados."
    else
        echo "Compilando con avisos acelerados (debug)."
    fi
    make debug-build DEBUG_JUNGLE="$debug_dir/debug.jungle"
    if [ "$screen_enabled" = true ]; then
        echo "Cargando en el simulador. Espera el mensaje 'DrinkWater DEBUG: pantalla $screen'."
    else
        echo "Cargando en el simulador."
    fi
    echo "Debug: objetivo 2000 ml, consumo inicial 1800 ml."
    echo "Avisos repetidos desde el siguiente minuto, respetando el minimo de 5 minutos de Garmin."
    echo "Si solo aparece el logo de Garmin, reinicia el simulador y repite."
    echo "El comando permanece activo mientras la aplicacion esta abierta."
    make debug-run
)
