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

if [ $# -ne 1 ]; then
    echo "Usage: $0 <gs201|zuma|zumapro>"
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

export KERNEL_REPO="$(get_script_dir)"

cd "$KERNEL_REPO"

##PRE-PATCHING##
#KSU
if grep -q "CONFIG_KSU=y" "$KERNEL_REPO/arch/arm64/configs/${TARGET}_defconfig"; then
echo "defconfig already patched with KSU"
else
echo "Patching defconfig with CONFIG_KSU=y"
echo "CONFIG_KSU=y" >> "$KERNEL_REPO/arch/arm64/configs/${TARGET}_defconfig"
fi

#SUS_SU
if grep -q "CONFIG_KSU_SUSFS_SUS_SU=n" "$KERNEL_REPO/arch/arm64/configs/${TARGET}_defconfig"; then
echo "defconfig already patched with KSU_SUFS_SUS_SU=n"
else
echo "Patching defconfig with CONFIG_KSU_SUSFS_SUS_SU=n"
echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> "$KERNEL_REPO/arch/arm64/configs/${TARGET}_defconfig"
fi

#SUSFS
if grep -q "CONFIG_KSU_SUSFS=y" "$KERNEL_REPO/arch/arm64/configs/${TARGET}_defconfig"; then
echo "defconfig already patched with SUSFS"
else
echo "Patching defconfig with CONFIG_KSU_SUSFS=y"
echo "CONFIG_KSU_SUSFS=y" >> "$KERNEL_REPO/arch/arm64/configs/${TARGET}_defconfig"
fi

if grep -q "CONFIG_COMPAT=y" "$KERNEL_REPO/arch/arm64/configs/${TARGET}_defconfig"; then
echo "defconfig already patched with COMPAT"
else
echo "Patching defconfig with CONFIG_COMPAT=y (fixes leaking symbols)"
echo "CONFIG_COMPAT=y" >> "$KERNEL_REPO/arch/arm64/configs/${TARGET}_defconfig"
fi

##CLONE KERNELSU AND SUSFS##
if [ ! -d "$KERNEL_REPO"/KernelSU ]; then
cd "$KERNEL_REPO"
#fetch ksu
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main
else
echo "KernelSU directory already exists. Delete and run script again to clone"
fi

##fetch anykernel
if [ ! -d "$KERNEL_REPO"/AnyKernel ]; then
cd $KERNEL_REPO
git clone --depth=1 https://github.com/Ante0/AnyKernel3 -b sultan-17-caimito AnyKernel
else
echo "AnyKernel directory already exists. Delete and run script again to clone"
fi

#fetch susfs
if [ ! -d "$KERNEL_REPO"/susfs4ksu ]; then
cd $KERNEL_REPO
git clone https://gitlab.com/simonpunk/susfs4ksu -b gki-android14-6.1 --depth=1
#copy files
else
echo "susfs4ksu directory already exists. Delete and run script again to clone"
fi

cd "$KERNEL_REPO/"

cp "$KERNEL_REPO"/susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch "$KERNEL_REPO/"
cp "$KERNEL_REPO"/susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch "$KERNEL_REPO/"KernelSU/
cp "$KERNEL_REPO"/susfs4ksu/kernel_patches/fs/* "$KERNEL_REPO"/fs/
cp "$KERNEL_REPO"/susfs4ksu/kernel_patches/include/linux/* "$KERNEL_REPO"/include/linux/

##PATCHING##
echo "Patching kernel"
cd "$KERNEL_REPO"
patch -p1 < 50_add_susfs_in_gki-android14-6.1.patch

echo "Patching KernelSU"
cd "$KERNEL_REPO"/KernelSU/
patch -p1 < 10_enable_susfs_for_ksu.patch

echo "Patching utf8"
cd "$KERNEL_REPO"
patch -p1 < utf8.patch

echo "fixing Sultan rejects (fs/open.c, fs/namespace.c and kernel/sys.c"
cd "$KERNEL_REPO"
patch -p1 < fixer.patch

echo "done!"
