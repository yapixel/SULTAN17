# SULTAN17 History Reconstruction Report

## Baseline

- Original source branch: `17.0.0-cp2a`
- Original source SHA: `66f534731842e30bb79b4ce6be6cc04456f1d194`
- Original source tree: `2d3b66f21867e2429f01b223f5deb2b8c16eca5b`
- Previous clean SHA: `5880ff0e65abe2314204a908ee1c14abe0f4c9e5`
- Target clean tree: `fdbc73c2a71f2139d61af1e991ab950a8b0ce513`
- Audit SHA: `f8e9ef566113fafc9a4d18c3f6442ec1e75d29ee`

## Reconstruction

- Reconstructed branch: `reconstruct/sultan17-cp2a-clean`
- Reconstructed SHA: `c838fdfb1615813f8cd0d34d37043fbabcbbe404`
- Reconstructed tree: `fdbc73c2a71f2139d61af1e991ab950a8b0ce513`
- Original commit count: 770
- DROP commits omitted: 119
- KEEP commits replayed: 651
- Reconstructed history commit count: 651
- SPLIT commits: 0
- Conflicts: 0
- Empty commits: 0
- Changed classifications: none
- Unresolved ambiguities: none

The original-to-reconstructed SHA mapping is recorded locally at:

```text
/tmp/sultan17-sha-map.tsv
```

The mapping contains 651 entries, in replay order.

## Validation

Exact tree identity passed:

```text
c838fdfb1615813f8cd0d34d37043fbabcbbe404^{tree}
fdbc73c2a71f2139d61af1e991ab950a8b0ce513
```

`git diff --exit-code HEAD origin/17.0.0-cp2a-clean` passed with no differences. The reconstructed tree contains no `.github/workflows/` or `gscripts/` paths. The Makefile remains Linux 6.1.162 (`VERSION = 6`, `PATCHLEVEL = 1`, `SUBLEVEL = 162`). The requested local integration-residue search returned no matches.

The original source branch and audit branch remained unchanged during reconstruction. The existing clean branch remained unchanged before delivery.

No kernel build, compilation, packaging, module build, emulator test, QEMU test, or device test was performed.
