#!/usr/bin/env bash
# shellcheck shell=bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

###############################################################################
# Arguments
###############################################################################

[[ $# -eq 5 ]] || die "Usage: $0 <source_sha> <ksu_sha> <next_sha> <susfs_sha> <release_notes>"

SOURCE_SHA="$1"
KSU_SHA="$2"
NEXT_SHA="$3"
SUSFS_SHA="$4"
RELEASE_NOTES="$5"

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
  "source": "${SOURCE_SHA}",
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
        --notes "$RELEASE_NOTES"

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
# Update release notes
###############################################################################

msg "Updating release notes"

gh release edit Nightly \
    --title "Nightly" \
    --notes-file "$RELEASE_NOTES"

###############################################################################
# Done
###############################################################################

msg "Nightly release updated"
