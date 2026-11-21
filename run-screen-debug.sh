#!/bin/bash
# Usage: ./run-screen-debug.sh <screen-name>
# Preview the required screen on fr645 in an open simulator; always accelerated.
# Set SDK_HOME, JAVA_HOME, and DEVELOPER_KEY through the environment.
# Uses saved app data without changing normal build settings.
# For other models, see run-simulator.sh.
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [ "$#" -ne 1 ]; then
    echo "Uso: ./run-screen-debug.sh pantalla" >&2
    exit 1
fi

case "$1" in
    water|reminder|goalReached|goal|serving|interval|startTime|endTime|settings|days) ;;
    *)
        echo "Pantalla debug no valida: $1" >&2
        echo "Opciones: water, reminder, goalReached, goal, serving, interval, startTime, endTime, settings, days" >&2
        exit 1
        ;;
esac

source ./z_debug-launch-helper.sh
run_debug "$1"
