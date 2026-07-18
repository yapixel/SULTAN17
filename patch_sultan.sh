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

if [ $# -ne 2 ]; then
    echo "Usage: $0 <gs201|zuma|zumapro> <stock|ksu|ksu-susfs|ksu-next|ksu-next-susfs"
    exit 1
fi

case "$1" in
    gs201|zuma|zumapro)
        TARGET="$1"
        ;;
    *)
        echo "Error: '$1' is not a valid target."
	echo "This will select the correct defconfig"
        echo "Valid targets are: gs201, zuma, zumapro"
        exit 1
        ;;
esac

case "$2" in
    stock|ksu|ksu-susfs|ksu-next|ksu-next-susfs)
        VARIANT="$2"
        ;;
    *)
        echo "Error: '$2' is not a valid variant."
        echo "Usage: $0 <gs201|zuma|zumapro> <stock|ksu|ksu-susfs|ksu-next|ksu-next-susfs"
        exit 1
        ;;
esac

export KERNEL_REPO="$(get_script_dir)"

cd "$KERNEL_REPO"

#clone kernel_patches
git clone https://github.com/Ante0/kernel_patches --depth=1

case "$VARIANT" in
    stock)
        ;;
    ksu)
        # KernelSU only
	cd "$KERNEL_REPO"
	#fetch ksu
	curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main

	echo "Patching utf8"
	cd "$KERNEL_REPO"
	patch -p1 < "$KERNEL_REPO"/kernel_patches/common/unicode_bypass_fix_6.1+.patch || true

	echo "$TARGET $VARIANT done"
        ;;
    ksu-susfs)
        # KernelSU
        # SUSFS
	##CLONE KERNELSU AND SUSFS##
	cd "$KERNEL_REPO"
	#fetch ksu
	curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main

	#fetch susfs
	cd "$KERNEL_REPO"
	git clone https://gitlab.com/simonpunk/susfs4ksu -b gki-android14-6.1 --depth=1

	cd "$KERNEL_REPO/"

	cp "$KERNEL_REPO"/susfs4ksu/kernel_patches/fs/* "$KERNEL_REPO"/fs/
	cp "$KERNEL_REPO"/susfs4ksu/kernel_patches/include/linux/* "$KERNEL_REPO"/include/linux/

	##PATCHING##
	echo "Patching kernel"
	cd "$KERNEL_REPO"
	if ! patch -p1 < "$KERNEL_REPO"/susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch; then
		echo "Some SUSFS hunks failed (expected). Continuing..."
	fi
	echo "Patching KernelSU"
	cd "$KERNEL_REPO"/KernelSU/
	if ! patch -p1 < "$KERNEL_REPO"/susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch; then
		echo "Some SUSFS hunks failed (expected). Continuing..."
	fi

	echo "Patching utf8"
	cd "$KERNEL_REPO"
	patch -p1 < "$KERNEL_REPO"/kernel_patches/common/unicode_bypass_fix_6.1+.patch || true

	echo "fixing Sultan rejects (fs/open.c, fs/namespace.c and kernel/sys.c"
	cd "$KERNEL_REPO"
	patch -p1 < "$KERNEL_REPO"/kernel_patches/sultan/fixer.patch || true

	echo "$TARGET $VARIANT done"
        ;;
    ksu-next)
        # KernelSU Next
        cd "$KERNEL_REPO"
        curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s dev

	#Scope min manual hooks
	patch -p1 < "$KERNEL_REPO"/kernel_patches/next/scope_min_manual_hooks_v1.6.patch

	#utf8 patch
	patch -p1 < "$KERNEL_REPO"/kernel_patches/common/unicode_bypass_fix_6.1+.patch || true

	echo "$TARGET $VARIANT done"
        ;;
    ksu-next-susfs)
        # KernelSU Next
	cd "$KERNEL_REPO"
	curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s dev

	# SUSFS
	#fetch susfs
	git clone https://gitlab.com/simonpunk/susfs4ksu -b gki-android14-6.1 --depth=1

	cp "$KERNEL_REPO"/susfs4ksu/kernel_patches/fs/* "$KERNEL_REPO"/fs/
	cp "$KERNEL_REPO"/susfs4ksu/kernel_patches/include/linux/* "$KERNEL_REPO"/include/linux/

	##PATCHING##
	echo "Patching kernel"

	if ! patch -p1 < "$KERNEL_REPO"/susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch; then
		echo "Some SUSFS hunks failed (expected). Continuing..."
	fi

	echo "Patching KernelSU"
	cd "$KERNEL_REPO"/KernelSU-Next/
	if ! patch -p1 < "$KERNEL_REPO"/susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch; then
		echo "Some SUSFS hunks failed (expected). Continuing..."
	fi

	echo "Patching utf8"
	cd "$KERNEL_REPO"
	patch -p1 < "$KERNEL_REPO"/kernel_patches/common/unicode_bypass_fix_6.1+.patch || true

	echo "fixing KSU-Next-specific patches using Wildjames fix repo."
	cd "$KERNEL_REPO"/KernelSU-Next/
	patch -p1 < "$KERNEL_REPO"/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_Kbuild.patch || true
	patch -p1 < "$KERNEL_REPO"/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_init.c.patch || true
	patch -p1 < "$KERNEL_REPO"/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_kernel_umount.c.patch || true
	patch -p1 < "$KERNEL_REPO"/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_setuid_hook.c.patch || true
	patch -p1 < "$KERNEL_REPO"/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_sucompat.c.patch || true
	patch -p1 < "$KERNEL_REPO"/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_supercall.c.patch || true
	patch -p1 < "$KERNEL_REPO"/kernel_patches/next/susfs_fix_patches/v2.2.0/ksu_toolkit.patch || true
	patch -p1 < "$KERNEL_REPO"/kernel_patches/next/susfs_fix_patches/v2.2.0/overwrite_hook_mode.patch || true


	echo "fixing Sultan rejects (fs/open.c, fs/namespace.c and kernel/sys.c"
	cd "$KERNEL_REPO"
	patch -p1 < "$KERNEL_REPO"/kernel_patches/sultan/fixer.patch || true

	echo "$TARGET $VARIANT done"
        ;;
esac

##Patch Defconfig##

DEFCONFIG="$KERNEL_REPO/arch/arm64/configs/${TARGET}_defconfig"

if [[ "$VARIANT" != "stock" ]]; then
#KSU
        if ! grep -q "^CONFIG_KSU=y$" "$DEFCONFIG"; then
                echo "CONFIG_KSU=y" >> "$DEFCONFIG"
        fi

#SUS_SU
        if [[ "$VARIANT" == *"-susfs" ]]; then
                if ! grep -q "^CONFIG_KSU_SUSFS_SUS_SU=n$" "$DEFCONFIG"; then
                        echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> "$DEFCONFIG"
                fi
                if ! grep -q "^CONFIG_KSU_SUSFS=y$" "$DEFCONFIG"; then
                        echo "CONFIG_KSU_SUSFS=y" >> "$DEFCONFIG"
                fi
	fi
fi

#FOR ALL VARIANTS
if ! grep -q "^CONFIG_COMPAT=y$" "$DEFCONFIG"; then
        echo "CONFIG_COMPAT=y" >> "$DEFCONFIG"
fi


##fetch anykernel
cd "$KERNEL_REPO"
git clone --depth=1 https://github.com/Ante0/AnyKernel3 -b sultan-17-caimito AnyKernel
