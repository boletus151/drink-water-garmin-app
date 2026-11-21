#!/bin/bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [ "$#" -gt 0 ] && [[ "$1" != *=* ]]; then
    screen="$1"
    shift
else
    screen="$(cat debug-screen.conf)"
fi

case "$screen" in
    water|reminder|goalReached|goal|serving|interval|startTime|endTime|settings|days) ;;
    *)
        echo "Pantalla debug no valida: $screen" >&2
        echo "Opciones: water, reminder, goalReached, goal, serving, interval, startTime, endTime, settings, days" >&2
        exit 1
        ;;
esac

for argument in "$@"; do
    if [[ "$argument" != *=* ]]; then
        echo "Uso: ./run-debug.sh [pantalla] [VARIABLE_MAKE=valor ...]" >&2
        exit 1
    fi
done

debug_dir="$(mktemp -d "${TMPDIR:-/tmp}/drink-water-screen.XXXXXX")"
cleanup() {
    rm -f -- "$debug_dir/ScreenDebugConfig.mc" "$debug_dir/debug.jungle"
    rmdir -- "$debug_dir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cat > "$debug_dir/ScreenDebugConfig.mc" <<EOF
module ScreenDebugConfig {
    const ENABLED = true;
    const SCREEN = "$screen";
}
EOF

cat > "$debug_dir/debug.jungle" <<EOF
base.sourcePath = \$(base.sourcePath);$debug_dir
base.excludeAnnotations = screenDebugDefaults
EOF

echo "Compilando pantalla debug: $screen"
make debug-build "$@" DEBUG_JUNGLE="$debug_dir/debug.jungle"
echo "Cargando en el simulador. Espera el mensaje 'DrinkWater DEBUG: pantalla $screen'."
echo "Si solo aparece el logo de Garmin sin ese mensaje, reinicia el simulador y repite."
echo "El comando permanece activo mientras la aplicacion esta abierta."
make debug-run "$@"
