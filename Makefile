# Convenience for testing locally


all:
	$(MAKE) -C src
	$(MAKE) -C tests/fixture
	cd tests && ./run_tests.sh

clean:
	$(MAKE) -C src clean
	$(MAKE) -C tests/fixture clean

