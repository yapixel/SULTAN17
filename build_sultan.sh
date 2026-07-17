#!/bin/bash

set -e


get_script_dir()
{
    local SOURCE_PATH="${BASH_SOURCE[0]}"
    local SYMLINK_DIR
    local SCRIPT_DIR
    # Resolve symlinks recursively
    while [ -L "$SOURCE_PATH" ]; do
        # Get symlink directory
        SYMLINK_DIR="$( cd -P "$( dirname "$SOURCE_PATH" )" >/dev/null 2>&1 && pwd )"
        # Resolve symlink target (relative or absolute)
        SOURCE_PATH="$(readlink "$SOURCE_PATH")"
        # Check if candidate path is relative or absolute
        if [[ $SOURCE_PATH != /* ]]; then
            # Candidate path is relative, resolve to full path
            SOURCE_PATH=$SYMLINK_DIR/$SOURCE_PATH
        fi
    done
    # Get final script directory path from fully resolved source path
    SCRIPT_DIR="$(cd -P "$( dirname "$SOURCE_PATH" )" >/dev/null 2>&1 && pwd)"
    echo "$SCRIPT_DIR"
}

KERNEL_ROOT="$(get_script_dir)"
TOOLCPATH="$KERNEL_ROOT/toolchains/gcc-14.2.0-nolibc/aarch64-linux/bin"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <gs201|zuma|zumapro|clean>"
    exit 1
fi

case "$1" in
    gs201|zuma|zumapro)
        TARGET="$1"
        ;;
    clean)
        echo "Cleaning build tree..."

        rm -rf out/

        echo "Done."
        exit 0
        ;;
    *)
        echo "Error: '$1' is not a valid target."
        echo "Valid targets are: gs201, zuma, zumapro, clean"
        exit 1
        ;;
esac

make \
    CROSS_COMPILE="$TOOLCPATH/aarch64-linux-" \
    CC="$TOOLCPATH/aarch64-linux-gcc" \
    -j"$(nproc)" \
    "${TARGET}_defconfig"

make \
    CROSS_COMPILE="$TOOLCPATH/aarch64-linux-" \
    CC="$TOOLCPATH/aarch64-linux-gcc" \
    -j"$(nproc)"

if [ -f $KERNEL_ROOT/AnyKernel/Image.lz4 ] || [ -f $KERNEL_ROOT/AnyKernel/dtb ]; then
    	echo "Removing old Image.lz4 and dtb from AnyKernel"
    	rm -f $KERNEL_ROOT/AnyKernel/Image.lz4 AnyKernel/dtb
fi


if [ -f "$KERNEL_ROOT/out/arch/arm64/boot/Image.lz4" ]; then
	cp "$KERNEL_ROOT/out/arch/arm64/boot/Image.lz4" "$KERNEL_ROOT/AnyKernel/Image.lz4"
	cat "$KERNEL_ROOT"/out/google-devices/"$TARGET"/dts/*.dtb > "$KERNEL_ROOT/AnyKernel/dtb"

	else
	echo "BUILD FAILED or INTERRUPTED"
fi
