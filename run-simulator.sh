#!/bin/bash
# Usage: ./run-simulator.sh [debug]
# Build and run on fr645 in an open simulator; debug enables accelerated reminders.
# Set SDK_HOME, JAVA_HOME, and DEVELOPER_KEY through the environment.
# Other models: download the profile, add its ID to manifest.xml, and update
# matching compile/load device IDs in the Makefile. Check layout and controls.
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != debug ]; }; then
    echo "Uso: ./run-simulator.sh [debug]" >&2
    exit 1
fi

if [ "$#" -eq 0 ]; then
    make build
    exec make run
fi

source ./z_debug-launch-helper.sh
run_debug
