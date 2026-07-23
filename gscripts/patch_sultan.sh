#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

######################################################
# shellcheck source=config.sh
######################################################
source "${SCRIPT_DIR}/config.sh"

if [ $# -ne 2 ]; then
    echo "Usage: $0 <gs201|zuma|zumapro> <stock|ksu|ksu-susfs|ksu-next|ksu-next-susfs"
    exit 1
fi

######################################################


######################################################
#SWITCHES
######################################################

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

######################################################

######################################################
# VARIABLES
######################################################

readonly KERNEL_REPO="${REPO_ROOT}"
readonly PATCHES_REPO="https://github.com/Ante0/kernel_patches"

######################################################

######################################################
# HELPERS
######################################################

clone_anykernel() {
	msg "Cloning AnyKernel"

	git clone \
		--depth=1 \
		-b "${ANYKERNEL_BRANCH_PREFIX}-${TARGET}" \
		"${ANYKERNEL_REPO}" \
		AnyKernel
}

clone_kernel_patches() {
	msg "Cloning kernel patches"

	git clone \
		--depth=1 \
		"${PATCHES_REPO}" \
		kernel_patches
}

clone_susfs() {
	msg "Cloning SUSFS"

	git clone \
		--depth=1 \
		-b "${SUSFS_BRANCH}" \
		"${SUSFS_REPO}"
}

install_ksu() {
	msg "Cloning KernelSU"

	curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main
}

install_ksu_next() {
	msg "Cloning KernelSU-Next"

	curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s dev
}

patch_utf8() {
	msg "Patching UTF8"

	patch -p1 < "$KERNEL_REPO"/kernel_patches/common/unicode_bypass_fix_6.1+.patch || true
}

patch_scopemin() {
	msg "Patching Scope Min 1.6"

	patch -p1 < "$KERNEL_REPO"/kernel_patches/next/scope_min_manual_hooks_v1.6.patch || true
}

apply_patch() {
	local dir="$1"
	local patchfile="$2"

	patch -d "$dir" -p1 < "$patchfile"
}

apply_patch_optional() {
	local dir="$1"
	local patchfile="$2"

	if ! apply_patch "$dir" "$patchfile"; then
		warn "Patch $(basename "$patchfile") applied with rejects (continuing)."
	fi
}

##COPY SUSFS only used in functions
copy_susfs() {
        cp "$KERNEL_REPO"/susfs4ksu/kernel_patches/fs/* "$KERNEL_REPO"/fs/
        cp "$KERNEL_REPO"/susfs4ksu/kernel_patches/include/linux/* "$KERNEL_REPO"/include/linux/
}
##

patch_susfs_ksu() {
	msg "Copying susfs libs"
	copy_susfs
	msg "Applying SUSFS kernel patch"
	apply_patch_optional \
		"$KERNEL_REPO" \
		"$KERNEL_REPO/susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch"

	msg "Applying SUSFS KernelSU patch"
	apply_patch_optional \
		"$KERNEL_REPO/KernelSU" \
		"$KERNEL_REPO/susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch"
}

patch_susfs_ksu_next() {
	msg "Copying sufs libs"
	copy_susfs

	msg "Applying SUSFS KernelSU-Next integration"

	apply_patch_optional \
		"$KERNEL_REPO/KernelSU-Next" \
		"$KERNEL_REPO/susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch"

	apply_patch_optional \
                "$KERNEL_REPO/KernelSU-Next" \
                "$KERNEL_REPO/susfs4ksu/kernel_patches/KernelSU/50_enable_susfs_for_ksu.patch"

	msg "Applying KernelSU-Next compatibility fixes"

	apply_patch_optional \
		"$KERNEL_REPO/KernelSU-Next" \
		"$KERNEL_REPO/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_Kbuild.patch"

	apply_patch_optional \
		"$KERNEL_REPO/KernelSU-Next" \
		"$KERNEL_REPO/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_init.c.patch"

	apply_patch_optional \
                "$KERNEL_REPO/KernelSU-Next" \
                "$KERNEL_REPO/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_kernel_umount.c.patch"

        apply_patch_optional \
                "$KERNEL_REPO/KernelSU-Next" \
        	"$KERNEL_REPO/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_setuid_hook.c.patch"

        apply_patch_optional \
                "$KERNEL_REPO/KernelSU-Next" \
                "$KERNEL_REPO/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_sucompat.c.patch"

        apply_patch_optional \
                "$KERNEL_REPO/KernelSU-Next" \
                "$KERNEL_REPO/kernel_patches/next/susfs_fix_patches/v2.2.0/fix_supercall.c.patch"

        apply_patch_optional \
                "$KERNEL_REPO/KernelSU-Next" \
                "$KERNEL_REPO/kernel_patches/next/susfs_fix_patches/v2.2.0/ksu_toolkit.patch"

        apply_patch_optional \
                "$KERNEL_REPO/KernelSU-Next" \
                "$KERNEL_REPO/kernel_patches/next/susfs_fix_patches/v2.2.0/overwrite_hook_mode.patch"
}

patch_sultan() {
	msg "Applying Sultan specific patches (fs/open.c, fs/namespace.c and kernel/sys.c)"
	apply_patch_optional \
		"$KERNEL_REPO" \
		"$KERNEL_REPO/kernel_patches/sultan/fixer.patch"
}

######################################################

#clone kernel_patches
clone_kernel_patches

case "$VARIANT" in
    stock)
        ;;
    ksu)
        install_ksu
	patch_scopemin
	patch_utf8
	msg "$TARGET $VARIANT done"
        ;;
    ksu-susfs)
	install_ksu
	clone_susfs
	patch_utf8
	patch_susfs_ksu
	patch_sultan
	msg "$TARGET $VARIANT done"
        ;;
    ksu-next)
        install_ksu_next
	patch_scopemin
	patch_utf8
	echo "$TARGET $VARIANT done"
        ;;
    ksu-next-susfs)
	install_ksu_next
	clone_susfs
	patch_utf8
	patch_susfs_ksu_next
	patch_sultan
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

##fetch anykernel
cd "$KERNEL_REPO"
clone_anykernel
