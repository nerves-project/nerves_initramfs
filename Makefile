# Convenience for testing locally

all: check

check: build
	cd tests && ./run_tests.sh

repl: build
	cd tests && ./repl.sh

target:
	cd builder && ./build-all.sh

build:
	$(MAKE) -C src
	$(MAKE) -C tests/fixture

clean:
	$(MAKE) -C src clean
	$(MAKE) -C tests/fixture clean

help:
	@echo "nerves_initramfs Makefile targets"
	@echo "---------------------------------"
	@echo
	@echo "build  - Build nerves_initramfs for the host"
	@echo "check  - Run the unit tests on the host (default target)"
	@echo "repl   - Start up a repl on the host"
	@echo "clean  - Clean up the host build and tests"
	@echo "target - Build nerves_initramfs for all configured targets"

.PHONY: all check repl clean help
