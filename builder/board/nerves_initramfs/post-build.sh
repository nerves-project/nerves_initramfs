#!/bin/sh

set -e

# Trim empty directories
#
# We're using .keep to make sure that the usr directory is around for the lib32 symlink,
# but it's not used. If you want to keep all of the directories, don't run this
# post-build script.
#
# This breaks rebuilding. To rebuild, run `mkdir -p target/usr/lib`

find "$TARGET_DIR" -name .keep -delete
find "$TARGET_DIR" -name os-release -delete
find "$TARGET_DIR" -name lib64 -delete
find "$TARGET_DIR" -name lib32 -delete
find "$TARGET_DIR" -type d -empty -delete

