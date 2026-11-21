SDK_HOME ?= $(HOME)/.local/share/drink-water-tools/sdk
JAVA_HOME ?= $(HOME)/.local/share/drink-water-tools/java/Contents/Home
DEVELOPER_KEY ?= $(HOME)/.local/share/drink-water-tools/developer_key.der
export JAVA_HOME
export PATH := $(JAVA_HOME)/bin:$(PATH)

.PHONY: build test-build test package

build:
	mkdir -p bin
	"$(SDK_HOME)/bin/monkeyc" -f monkey.jungle -d fr645 -o bin/drink-water.prg -y "$(DEVELOPER_KEY)" -l 3 -w

test-build:
	mkdir -p bin
	"$(SDK_HOME)/bin/monkeyc" -f monkey.jungle -d fr645 -o bin/drink-water-tests.prg -y "$(DEVELOPER_KEY)" -l 3 -w -t

test: test-build
	@status=0; \
	"$(SDK_HOME)/bin/monkeydo" bin/drink-water-tests.prg fr645 -t > bin/test-output.log 2>&1 || status=$$?; \
	cat bin/test-output.log; \
	if ! grep -Eq '^PASSED \(passed=[1-9][0-9]*, failed=0, errors=0\)$$' bin/test-output.log; then \
		echo "No se ha confirmado una suite completa sin fallos." >&2; exit 1; \
	fi; \
	if [ "$$status" -eq 1 ]; then \
		echo "Aviso: monkeydo devolvio 1 pese al resumen PASSED (problema conocido del SDK en macOS)." >&2; \
	elif [ "$$status" -ne 0 ]; then \
		echo "monkeydo termino con un error inesperado: $$status" >&2; exit "$$status"; \
	fi

package:
	mkdir -p bin
	"$(SDK_HOME)/bin/monkeyc" -f monkey.jungle -e -o bin/drink-water.iq -y "$(DEVELOPER_KEY)" -l 3 -w -r
