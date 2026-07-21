#!/usr/bin/env bash
# shellcheck shell=bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

###############################################################################
# Upstream repositories
###############################################################################

declare -Ar REPOS=(
    [kernelsu]="tiann/KernelSU"
    [kernelsu_next]="KernelSU-Next/KernelSU-Next"
    [susfs]="simonpunk/susfs4ksu"
)

declare -Ar BRANCHES=(
    [kernelsu]="${KSU_BRANCH}"
    [kernelsu_next]="${KSU_NEXT_BRANCH}"
    [susfs]="${SUSFS_BRANCH}"
)

###############################################################################
# Helpers
###############################################################################

latest_sha() {
    gh api \
        "repos/${REPOS[$1]}/commits/${BRANCHES[$1]}" \
        --jq '.sha'
}

###############################################################################
# Read previous nightly.json
###############################################################################

TMP="$(mktemp -d)"
JSON_FILE="${TMP}/nightly.json"

if gh release view Nightly >/dev/null 2>&1; then

    ASSET_URL=$(
        gh api repos/${GITHUB_REPOSITORY}/releases/tags/Nightly \
            --jq '.assets[]
                | select(.name=="nightly.json")
                | .url'
    )

    if [[ -n "${ASSET_URL:-}" ]]; then
        gh api \
            -H "Accept: application/octet-stream" \
            "${ASSET_URL}" > "${JSON_FILE}"
    fi
fi

###############################################################################
# Current SHAs
###############################################################################

NEW_KSU="$(latest_sha kernelsu)"
NEW_NEXT="$(latest_sha kernelsu_next)"
NEW_SUSFS="$(latest_sha susfs)"

###############################################################################
# First run
###############################################################################

if [[ ! -f "${JSON_FILE}" ]]; then

    msg "First nightly run detected."

    VARIANTS=(
        ksu
        ksu-susfs
        ksu-next
        ksu-next-susfs
    )

else

    OLD_KSU="$(jq -r '.kernelsu' "${JSON_FILE}")"
    OLD_NEXT="$(jq -r '.kernelsu_next' "${JSON_FILE}")"
    OLD_SUSFS="$(jq -r '.susfs' "${JSON_FILE}")"

    VARIANTS=()

    if [[ "${OLD_KSU}" != "${NEW_KSU}" ]]; then
        VARIANTS+=(ksu ksu-susfs)
    fi

    if [[ "${OLD_NEXT}" != "${NEW_NEXT}" ]]; then
        VARIANTS+=(ksu-next ksu-next-susfs)
    fi

    if [[ "${OLD_SUSFS}" != "${NEW_SUSFS}" ]]; then
        VARIANTS+=(ksu-susfs ksu-next-susfs)
    fi

    mapfile -t VARIANTS < <(
        printf "%s\n" "${VARIANTS[@]}" | sort -u
    )

fi

###############################################################################
# Generate matrix
###############################################################################

JSON='{"include":['
FIRST=true

for TARGET in "${TARGETS[@]}"; do
    for VARIANT in "${VARIANTS[@]}"; do

        if $FIRST; then
            FIRST=false
        else
            JSON+=","
        fi

        JSON+="{\"target\":\"${TARGET}\",\"variant\":\"${VARIANT}\"}"

    done
done

JSON+="]}"

###############################################################################
# Outputs
###############################################################################

{
    echo "matrix=$JSON"
    echo "ksu_sha=$NEW_KSU"
    echo "next_sha=$NEW_NEXT"
    echo "susfs_sha=$NEW_SUSFS"
} >> "$GITHUB_OUTPUT"

msg "Generated matrix"

echo "$JSON"
