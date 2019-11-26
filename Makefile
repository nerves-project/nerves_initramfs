# Convenience for testing locally

all: check

check: build
	cd tests && ./run_tests.sh

repl: build
	cd tests && ./repl.sh

build:
	$(MAKE) -C src
	$(MAKE) -C tests/fixture

clean:
	$(MAKE) -C src clean
	$(MAKE) -C tests/fixture clean

.PHONY: all check repl clean
