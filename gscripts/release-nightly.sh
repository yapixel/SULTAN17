#!/usr/bin/env bash
# shellcheck shell=bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

###############################################################################
# Arguments
###############################################################################

[[ $# -eq 3 ]] || die "Usage: $0 <ksu_sha> <next_sha> <susfs_sha>"

KSU_SHA="$1"
NEXT_SHA="$2"
SUSFS_SHA="$3"

###############################################################################
# Verify build output
###############################################################################

shopt -s nullglob

FILES=("${DIST_DIR}"/*.zip)

(( ${#FILES[@]} )) || die "No ZIP files found in ${DIST_DIR}"

###############################################################################
# Create nightly.json
###############################################################################

cat > "${DIST_DIR}/nightly.json" <<EOF
{
  "kernelsu": "${KSU_SHA}",
  "kernelsu_next": "${NEXT_SHA}",
  "susfs": "${SUSFS_SHA}"
}
EOF

###############################################################################
# Create release if necessary
###############################################################################

if ! gh release view Nightly >/dev/null 2>&1; then

    msg "Creating Nightly release"

    gh release create Nightly \
        --title "Nightly" \
        --notes "Automated nightly kernel builds."

fi

###############################################################################
# Upload packages
###############################################################################

msg "Uploading kernel packages"

gh release upload Nightly \
    "${DIST_DIR}"/*.zip \
    --clobber

###############################################################################
# Upload nightly.json
###############################################################################

msg "Uploading nightly.json"

gh release upload Nightly \
    "${DIST_DIR}/nightly.json" \
    --clobber

###############################################################################
# Done
###############################################################################

msg "Nightly release updated"
