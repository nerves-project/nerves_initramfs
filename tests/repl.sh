#!/bin/bash

# "readlink -f" implementation for BSD
# This code was extracted from the Elixir shell scripts
readlink_f () {
    cd "$(dirname "$1")" > /dev/null
    filename="$(basename "$1")"
    if [ -h "$filename" ]; then
        readlink_f "$(readlink "$filename")"
    else
        echo "`pwd -P`/$filename"
    fi
}

TESTS_DIR=$(dirname $(readlink_f $0))

WORK=$TESTS_DIR/work

INIT=$TESTS_DIR/../src/init
FIXTURE=$TESTS_DIR/fixture/init_fixture.so

CHAINED_INIT=$TESTS_DIR/fake_init

# Just in case there are some leftover from a previous test, clear it out
rm -fr $WORK

if [ ! -f $INIT ]; then echo "Build $INIT first"; exit 1; fi
if [ ! -f $FIXTURE ]; then echo "Build $FIXTURE first"; exit 1; fi

run() {
    CMDLINE=$*
    CONFIG=$WORK/nerves_initramfs.conf

    # Setup a fake root directory to simulate init boot
    rm -fr $WORK
    source "$TESTS_DIR/init_fixture.sh"

    # Run the test script to setup files for the test
    cat >$CONFIG <<EOF
        run_repl = true
EOF

    # Run init
    # NOTE: Call 'exec' so that it's possible to set argv0, but that means we
    #       need a subshell - hence the parentheses.
    (LD_PRELOAD=$FIXTURE DYLD_INSERT_LIBRARIES=$FIXTURE WORK=$WORK exec -a /init $INIT $CMDLINE)
}

run

rm -fr $WORK
exit 0
