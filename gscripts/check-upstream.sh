#!/usr/bin/env bash
# shellcheck shell=bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

###############################################################################
# Upstream repositories
###############################################################################

###############################################################################
# Helpers
###############################################################################

repo_path() {
    local repo="$1"

    repo="${repo#https://}"
    repo="${repo#*/}"
    repo="${repo%.git}"

    printf '%s\n' "$repo"
}

github_sha() {
    local repo
    repo="$(repo_path "$1")"

    gh api \
        "repos/${repo}/commits/$2" \
        --jq '.sha'
}

gitlab_sha() {
    local repo
    repo="$(repo_path "$1")"
    repo="${repo//\//%2F}"

    curl -fsSL \
        "https://gitlab.com/api/v4/projects/${repo}/repository/branches/$2" \
        | jq -r '.commit.id'
}

###############################################################################
# Read previous nightly.json
###############################################################################

TMP="$(mktemp -d)"
JSON_FILE="${TMP}/nightly.json"

LOCAL_JSON="${SCRIPT_DIR}/nightly.json"

if [[ -f "$LOCAL_JSON" ]]; then
    JSON_FILE="$LOCAL_JSON"
fi

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

NEW_KSU="$(github_sha "$KSU_REPO" "$KSU_BRANCH")"
NEW_NEXT="$(github_sha "$KSU_NEXT_REPO" "$KSU_NEXT_BRANCH")"
NEW_SUSFS="$(gitlab_sha "$SUSFS_REPO" "$SUSFS_BRANCH")"

###############################################################################
# First run
###############################################################################

if [[ ! -f "${JSON_FILE}" ]]; then

    msg "First nightly run detected."

    BUILD_VARIANTS=(
        ksu
        ksu-susfs
        ksu-next
        ksu-next-susfs
    )

else

    OLD_KSU="$(jq -r '.kernelsu' "${JSON_FILE}")"
    OLD_NEXT="$(jq -r '.kernelsu_next' "${JSON_FILE}")"
    OLD_SUSFS="$(jq -r '.susfs' "${JSON_FILE}")"

    BUILD_VARIANTS=()

    if [[ "${OLD_KSU}" != "${NEW_KSU}" ]]; then
        BUILD_VARIANTS+=(ksu ksu-susfs)
    fi

    if [[ "${OLD_NEXT}" != "${NEW_NEXT}" ]]; then
        BUILD_VARIANTS+=(ksu-next ksu-next-susfs)
    fi

    if [[ "${OLD_SUSFS}" != "${NEW_SUSFS}" ]]; then
        BUILD_VARIANTS+=(ksu-susfs ksu-next-susfs)
    fi

if ((${#BUILD_VARIANTS[@]} > 0)); then
    mapfile -t BUILD_VARIANTS < <(
        printf "%s\n" "${BUILD_VARIANTS[@]}" | sort -u
    )
fi

fi

if ((${#BUILD_VARIANTS[@]} == 0)); then
    msg "No upstream changes detected."
else
    msg "Detected changes for: ${BUILD_VARIANTS[*]}"
fi

###############################################################################
# Generate matrix
###############################################################################

if ((${#BUILD_VARIANTS[@]} == 0)); then
    JSON='{"include":[]}'
else
    JSON='{"include":['
    FIRST=true

    for TARGET in "${TARGETS[@]}"; do
        for VARIANT in "${BUILD_VARIANTS[@]}"; do

            if $FIRST; then
                FIRST=false
            else
                JSON+=","
            fi

            JSON+="{\"target\":\"${TARGET}\",\"variant\":\"${VARIANT}\"}"

        done
    done

    JSON+="]}"
fi

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
