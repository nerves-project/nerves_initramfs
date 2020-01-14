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
TEST_ROOTFS=$TESTS_DIR/work/rootfs
RESULTS=$WORK/results

INIT=$TESTS_DIR/../src/init
FIXTURE=$TESTS_DIR/fixture/init_fixture.so


# Collect the tests from the commandline
TESTS=$*
if [ -z "$TESTS" ]; then
    TESTS=$(ls $TESTS_DIR/[0-9][0-9][0-9]_*)
fi

if [ ! -f "$INIT" ]; then echo "Build $INIT first"; exit 1; fi
if [ ! -f "$FIXTURE" ]; then echo "Build $FIXTURE first"; exit 1; fi

# Host-specific options
case $(uname -s) in
    Darwin)
	    # Not -d?
        BASE64_DECODE=-D

        SED=/usr/local/bin/gsed
        [ -e $SED ] || ( echo "Please run 'brew install gnu-sed' to install gsed"; exit 1 )
        ;;
    *)
	    SED=sed
        BASE64_DECODE=-d
        ;;
esac

base64_decode() {
    base64 $BASE64_DECODE
}

base64_decodez() {
    base64 $BASE64_DECODE | zcat
}

run() {
    TEST=$1
    CONFIG=$TEST_ROOTFS/nerves_initramfs.conf
    POST_TEST_CHECK=$WORK/post-test.sh
    CMDLINE_FILE=$WORK/$TEST.cmdline
    EXPECTED=$WORK/$TEST.expected

    echo Running $TEST...

    # Setup a fake root directory to simulate init boot
    rm -fr "$WORK"
    mkdir -p "$TEST_ROOTFS"
    source "$TESTS_DIR/init_fixture.sh"

    # Run the test script to setup files for the test
    source "$TESTS_DIR/$TEST"

    if [ -e "$CMDLINE_FILE" ]; then
        CMDLINE=$(cat "$CMDLINE_FILE")
    else
        CMDLINE=
    fi

    # Run init
    # NOTE: Call 'exec' so that it's possible to set argv0, but that means we
    #       need a subshell - hence the parentheses.
    (LD_PRELOAD=$FIXTURE DYLD_INSERT_LIBRARIES=$FIXTURE WORK=$TEST_ROOTFS exec -a /init $INIT $CMDLINE) 2> $RESULTS.raw

    # Trim the results of known lines that vary between runs
    # The calls to sed fixup differences between getopt implementations.
    cat "$RESULTS.raw" | \
        grep -v "Starting init" | \
        $SED -e "s/\`/'/g" \
        > "$RESULTS"

    # check results
    diff -w "$RESULTS" "$EXPECTED"
    if [ $? != 0 ]; then
        echo "$TEST: Results didn't match expected!"
        exit 1
    fi

    if [ -f "$POST_TEST_CHECK" ]; then
        if ! bash "$POST_TEST_CHECK"; then
            echo "$TEST: The post-test check failed!"
            exit 1
        fi
    fi
}

# Test command line arguments
for TEST_CONFIG in $TESTS; do
    TEST=$(/usr/bin/basename "$TEST_CONFIG" .expected)
    run "$TEST"
done

rm -fr "$WORK"
echo Pass!
exit 0
