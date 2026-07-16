#!/bin/bash

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

export KERNEL_REPO="$(get_script_dir)"

cd $KERNEL_REPO

##PRE-PATCHING##
#KSU
if grep -q CONFIG_KSU=y $KERNEL_REPO/arch/arm64/configs/zumapro_defconfig; then
echo "defconfig already patched with KSU"
else
echo "Patching defconfig with CONFIG_KSU=y"
echo CONFIG_KSU=y >> $KERNEL_REPO/arch/arm64/configs/zumapro_defconfig
fi

#SUS_SU
if grep -q CONFIG_KSU_SUSFS_SUS_SU=n $KERNEL_REPO/arch/arm64/configs/zumapro_defconfig; then
echo "defconfig already patched with KSU_SUFS_SUS_SU=n"
else
echo "Patching defconfig with CONFIG_KSU_SUSFS_SUS_SU=n"
echo CONFIG_KSU_SUSFS_SUS_SU=n >> $KERNEL_REPO/arch/arm64/configs/zumapro_defconfig
fi

#SUSFS
if grep -q CONFIG_KSU_SUSFS=y $KERNEL_REPO/arch/arm64/configs/zumapro_defconfig; then
echo "defconfig already patched with SUSFS"
else
echo "Patching defconfig with CONFIG_KSU_SUSFS=y"
echo CONFIG_KSU_SUSFS=y >> $KERNEL_REPO/arch/arm64/configs/zumapro_defconfig
fi

if grep -q CONFIG_COMPAT=y $KERNEL_REPO/arch/arm64/configs/zumapro_defconfig; then
echo "defconfig already patched with COMPAT"
else
echo "Patching defconfig with CONFIG_COMPAT=y (fixes leaking symbols)"
echo CONFIG_COMPAT=y >> $KERNEL_REPO/arch/arm64/configs/zumapro_defconfig
fi

##CLONE KERNELSU AND SUSFS##
cd $KERNEL_REPO
#fetch ksu
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main

##fetch anykernel
git clone https://github.com/Ante0/AnyKernel3 -b sultan-17-caimito AnyKernel

#fetch susfs
git clone https://gitlab.com/simonpunk/susfs4ksu -b gki-android14-6.1 --depth=1
#copy files
cd $KERNEL_REPO/susfs4ksu/

cp ./kernel_patches/50_add_susfs_in_gki-android14-6.1.patch $KERNEL_REPO/
cp ./kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch $KERNEL_REPO/KernelSU/
cp ./kernel_patches/fs/* $KERNEL_REPO/fs/
cp ./kernel_patches/include/linux/* $KERNEL_REPO/include/linux/

##PATCHING##
cd $KERNEL_REPO
patch -p1 < 50_add_susfs_in_gki-android14-6.1.patch

cd $KERNEL_REPO/KernelSU/
patch -p1 < 10_enable_susfs_for_ksu.patch

echo "Patching utf8"
cd $KERNEL_REPO
patch -p1 < utf8.patch

echo "fixing Sultan rejects (fs/open.c, fs/namespace.c and kernel/sys.c"
patch -p1 < fixer.patch

echo "done!"
