# SULTAN17 Git History Semantic Cleanup — Phase 1 Audit

## 1. Baseline and kernel version

Inspection was performed against the locally available remote-tracking refs; no refs were changed.

| Reference | Commit | Tree |
|---|---|---|
| `origin/17.0.0-cp2a` | `66f534731842e30bb79b4ce6be6cc04456f1d194` | `2d3b66f21867e2429f01b223f5deb2b8c16eca5b` |
| `origin/17.0.0-cp2a-clean` | `5880ff0e65abe2314204a908ee1c14abe0f4c9e5` | `fdbc73c2a71f2139d61af1e991ab950a8b0ce513` |
| merge-base | `66f534731842e30bb79b4ce6be6cc04456f1d194` | — |

The source Makefile resolves to Linux **6.1.162**:

```text
VERSION = 6
PATCHLEVEL = 1
SUBLEVEL = 162
```

## 2. History topology

* `17.0.0-cp2a` is a linear history: 770 commits, no merge commits.
* `17.0.0-cp2a-clean` is exactly one commit on top of the original tip: `5880ff0e65abe2314204a908ee1c14abe0f4c9e5`.
* The cleanup commit deletes exactly these 11 paths and no kernel source paths:
  * `.github/workflows/auto.yml`
  * `.github/workflows/build.yml`
  * `.github/workflows/clean.yml`
  * `.github/workflows/manual.yml`
  * `gscripts/build.sh`
  * `gscripts/check-upstream.sh`
  * `gscripts/clean.sh`
  * `gscripts/config.sh`
  * `gscripts/package.sh`
  * `gscripts/patch_sultan.sh`
  * `gscripts/release-nightly.sh`
* The removable work begins as root-level builder/patch files, then moves into `.github/workflows/` and `gscripts/` on `046f18b245e7da316959dfe794cc03f542880b56`.
* It is not a contiguous tail. Legitimate kernel commits occur between the builder commits, including BBRv3, defconfig, scheduler, and power-domain changes.
* 119 commits are classified DROP below. The other 651 commits are KEEP. No SPLIT commit was found.

## 3. KEEP classification

KEEP is the default for every commit on `origin/17.0.0-cp2a` not in the DROP list below. Diff/path inspection found these to be kernel or legitimate repository history, including:

* Linux/Android Common Kernel, Google, Pixel, Tensor/gs201/zuma/zumapro, and Sultan changes.
* Android 17 / CP2A and Linux 6.1.162 updates.
* Scheduler, performance, memory, filesystem, networking, driver, compiler/LTO, and power-domain work.
* Legitimate defconfig changes, including `04f2e34afc67238e686ee4a6f9d760bf27a6bad7`, `638aa8e2595673d7f8fc7124fa1e19aef407819e`, `944fb5ef916651348dc6329aaf6636dbfc12413b`, and `f124bb1e3ba67284078bf8e91dea6e676a1ddc43`.
* Native BBRv3 work, including `cb3c0151b25d6b7ee75143bd866cbf5c425bcc3b` and its defconfig follow-up.
* Native power-domain fixes `dbea25f484577c6db47ae2e033e62960600b2174` and `a0c0d9083c9a5e46df4cd88b1ff14a91a1ff021c`.

Keyword-only matches such as `TARGET_BUILD_VARIANT` in the Qualcomm driver history and legitimate kernel `variant`/defconfig changes were inspected as candidates and retained. A patch target such as `fs/open.c` or `kernel/sys.c` was not treated as KSU integration merely because an external patch script referenced it.

## 4. DROP classification

Every DROP commit is exclusively builder, patching, packaging, watcher, workflow, root/hide variant, KSU/KernelSU/KernelSU-Next, SUSFS, NoMount, or VPNHide infrastructure. The DROP set is the following exact set of commit SHAs (listed in SHA order for compactness):

```text
0212f29007eb5f4dbf8f72a724aaf00cf521cced 046f18b245e7da316959dfe794cc03f542880b56 077c6948406a370793c9596fb0b2c1894775ffa6 09a3bcda3223aaff41a2b14d7409a4525aa1d834 09ba03d5083f6fdc3e64ee23b8ac1a3046279f90 09dc51883d6977a4e4cc3e84794cc9a8b7b26d8e 0bedd17547dc7a5645955aa9b95dae40c372d7f5 0ca2012b4cf406b6537171071d32d27f711e3731 0f950ccb4cb0f56b4f17a75e13dc6c3064c40d60 0f9ef35c4bb5b1384aa65f71876e34c7cbc3e214 119d42815789527c6f2fe99f4fd11677bdae34dc 13ee32bba54052c0080c7dade758855a53ddeaa3 14ba39f4b7299bac2be126cb3fe350211b43f61e 1650881ffb60b4a59ce0b7275b11efc4004a9575 192fd0e3c671f8faa1f69ad851eb2e5df6e3be5e 1b4d894ea041b1e4072e0f44d0f98a0f3b039f98 1bb815bc86fecbcdc6e5441507c1bf26cea09768 20ae0005e68e1b25f51a3a0612f31f4fc809d9e4 266fd97f9550f74f20f1f90e0dc054df05563936 2b25142552a677daf9ad324d0452460f03163461 2cb0e90f19200f6021fb6a63afaf110b494e3eae 30612dfc55477e236a902dcafed1ce162acac659 3068b52ab3517efa142e46e63f98f883e9549da5 321fed08b334dc7b5287e83241b383d9d34a16e2 3325f32646a3345ed8d1163ab0596f5c457f8967 3352c2858c18d93eb58e4853313f293d9eda6d64 3416ea41374083fa536494b15ba44f929703c614 3732331faf202ff885e0dc83a794955f772887ba 378c6cbc0fcb9c8346bc4d55df8a4e4be7b4c52c 39beb160e4dce594df4c07429672eb2e1570e824 3c348d573c637fe17f7df82184d2962946156da1 3c6bffb73c30b6663ae11cc1796603031d8961bf 3e365febfcae9d243b3120b121a6a0ddd9d96610 3fee0b8d631c11b745b13c990e2f793429d7beb2 4773449d109b15772a26b71620cb44ab6e873b34 48e4036b65d6ec1e238aa51504a57b37e39321cf 4eb43f2dbc5dc6f7f100b9c8334d2045ff8afb0c 4fff7e00e8cd800d947acd82ae06e6f58ef063d4 5072f870d498b26daecc8bdcc0217da9c4b86a23 51ad5f495098929bd620e7a0f14517736380276f 52baa726459a4882f65dc1a29ad11fbd8af7d2f1 5461fe399e08fc01ec631bae9c3c5d757047e5ec 55731941d7cd6ca2db155090cb00fc6e86cd1f5f 61b51d5eafb1225b2b98f9e544662dc3c375dc0e 63c2fd4a4c151cb8564d174e57d9ec1cde4aa952 6501a9bc1eff4ff2b0e2d3b8db03310259d95e40 66f534731842e30bb79b4ce6be6cc04456f1d194 675ca4fa3a16af98875570648d301b20d5b38570 692993b656c2411e4fdaec39449146aff38d809e 6a6bde2ab4bdf86a9b7a4031a7a5bb2049d3396e 6a99eaeda62877df8b0ccc46c4c9cf04cd842e69 6f21274adc1e5d7226996e77d3dcfc8abd57abf9 800f4578e3503a8a06d04b68625ffc068182bec6 806cf79421f3a43609bf4f89cf8954412c328b7c 8190a25c35d8657ac1387cc4bbfd968069424a00 831a74b4910a4171ac5af2583c942824c96d96bf 837d0cffc4174f0311c75d6692d3942dd5aa6838 854bb7a7fada6c0d0448e35dd2a5366690c6a471 870abaf07b7a89e6356eb505d9e450093925ec0c 8a737c8182fe0f16c7dc75064bd9eb1e0c4c6f77 8bb38a42865ce90c209e035dfa78dcd3fe2fcd60 8e1dbce4a9459ef56b21512c539a409595c1d912 8f8aab2e390c2b22170eb2c4f58be10adfa621f0 9059f9556567b1cea5138e4d22f121b302f70b70 9172872d4c71c43076220e9e5b385d056039027a 9185abec1782feeee7f3b5e5ca42f8a07aab5d1d 92a1e92196c62a9caa5cf7c5deb29790bb277503 93a82698758628678c4b724c3efeda1029da215f 95a9f530fee1d55bb2ece2011998bf858dcb65e7 9724ce73c15b0afdc47b99864614f744b4031d9b 976bc55a8c3b52a3448b7d5de3b1359cf14a26c8 9783e6168211a35c476693ebc83645b97d24abc7 9adbf464013632795a52680b9667789476ffb7d8 9ecc829f4f1c11ab08557beca142f9881c185962 9fdfb91dfe2f0baefdc29654136b9c8b4879d010 a186b757052e4c0671464cceea750b5c0b62f0a9 a206da42d5fea2de198cabb161b69be4f42a4ec6 a3787e0bf62e8f98eab065201344c51cac34be42 a3864d889fe6293c1b3abb62cd3646cfc8b47692 a5cf1884ec612ca54444a634df1ba95f1f9d2733 a6be3d51b1c7d659d2a56c3b36edda79946c3204 aa3df9842ea1ae7f87de61f3f7da7c0413917320 ac4d8df7fe789d9859287687696e56f240795a22 acebc48e7eba59eb0793e3c9269e95e7d6d62cbf ad331e766fddcbc5f1c3104d6be2f8d6823de54d b1e6c4f982e73790130802825532291a3e1d8eea b2355ecafb2c83581b5122e43996b16d8236f660 b3439e05ef7b5eda13d8402f1e6379f36324ef3e b51dffa67b5e6a986cd502c425c8c551cceeb1a2 b5463bbc912b8e96d6d0a44731c341d778ba451e b54680e015300ee9c8176d8a5193c1849f84c390 b9261d242f04b46b7d402f9fe2fe919b6de625a6 c02cb2d2f129ba472e235d821cc63fb6a4307cee c054b3e9968789d32ea2548c6731bb129731901b c5d8e18d31122915cb7d1989e29b06eed7459b71 c5e5bf4c242f8b42fe647fbd6e9b05d2cd0074bd cb33d2a30449348a70ee304950aa5c03c7ebb2c9 cb9b6b9b875de042c40cbbdab003a9774d6a2793 d0baa7c1ffc063faf274f45d90fbce62fec3996a d52fabe226443556aa90736a73e6f006dc070c44 d760ae2187e492944bea2062816dfa19ea35f4a3 d811fcbfd34903e8ba2a7b95282b9725ab0cadf5 d8bcfc64646d21db3cc861586d1e84d7562f0340 d9c11173f21c26cf346aaf077fdc1e897e76823c da4244013f35596f3a65d61eb0fe329090031f1c dae68080f0207c2b1fda98c7a5d87181d2be103d db81852e1d00ad5c9c370c78ed5adf51c9308c71 dfa6e45034fd03d23e4310f09d6603f64de4a26a dfdd460794a0e5eeaef211c88e3559cbab17ed9c e1ba5a26346a96b6143817a90d2c5aa9c9bbe792 e4284321e345357a34a5e9a4818a77adcb7c9bf7 e54474d1ccfc0431c65b637353b5537551f72ffe e64687576b59eb7107fe3ff027e8d172b4e4dbdb f04726f051ebd035249c94456617c256b8b584e8 f23fcf019a56da2f0883d789015580edfb94ee8f f50e59822436c6e386d7336b20f533970aa16edc fb04ee691b5e5d9486d3f1a55c7f7a0dd64471fb fbf8bfc5b7b1d7a59675d76ce0940ca4a5ca80e3 fc27c43e9dd832755a0378db8af1c7524a2dd97e
```

Important inspected examples:

* `2cb0e90f19200f6021fb6a63afaf110b494e3eae` adds only KSU/SUSFS patch and GCC/AnyKernel scripts.
* `1650881ffb60b4a59ce0b7275b11efc4004a9575` and `48e4036b65d6ec1e238aa51504a57b37e39321cf` add only external patch files.
* `046f18b245e7da316959dfe794cc03f542880b56` only relocates the unwanted scripts into `gscripts/`.
* The VPNHide and NoMount commits alter only the patch/build infrastructure, not native kernel source.
* Workflow commits only automate those scripts, build variants, watchers, release notes, or packaging.

## 5. SPLIT classification

**None found.** The apparent source-related references in `patch_sultan.sh` are patch targets, not source changes in those commits. No DROP commit contains a wanted kernel hunk requiring extraction.

## 6. Dependency analysis

The DROP commits form one infrastructure dependency chain:

1. root `patch_sultan.sh`/`build_sultan.sh` and external `.patch` files are introduced;
2. workflows and `gscripts/` invoke and evolve them;
3. later changes add KSU/KSU-Next/SUSFS variants, NoMount, VPNHide, watcher logic, and packaging;
4. the final original commit `66f534731842e30bb79b4ce6be6cc04456f1d194` adds `clean.yml`, still only in the same removable infrastructure.

No KEEP commit depends on these paths for its source-tree content. Kernel commits between infrastructure commits modify independent tracked kernel paths. Removing the DROP commits therefore requires replaying later KEEP commits with their infrastructure-only changes omitted, not removing source hunks from kernel commits.

## 7. Safest reconstruction strategy

Do not use the existing cleanup commit as a substitute for historical cleanup. In Phase 2, create a new reconstruction from the immutable parent of the original history and replay original commits in chronological order, preserving every commit not in the DROP set and omitting every DROP commit. For any replay conflict, stop and inspect the parent/diff; do not resolve by accepting infrastructure changes blindly.

The expected final tree is the authoritative clean tree, not merely a matching diff or file count.

## 8. Exact Phase 2 validation gates

At each checkpoint and before delivery:

```sh
git status --short
git rev-parse 17.0.0-cp2a^{tree}
git rev-parse origin/17.0.0-cp2a-clean^{tree}
git rev-parse <rebuilt>^{tree}
git diff --exit-code <rebuilt> origin/17.0.0-cp2a-clean
git diff --name-status <rebuilt> origin/17.0.0-cp2a-clean
git ls-tree -r --name-only <rebuilt> | grep -E '^(\.github/workflows|gscripts)/' || true
git show <rebuilt>:Makefile | head -8
```

The decisive gate is exact tree SHA equality:

```text
git rev-parse <rebuilt>^{tree}
== git rev-parse origin/17.0.0-cp2a-clean^{tree}
== fdbc73c2a71f2139d61af1e991ab950a8b0ce513
```

Also verify that `17.0.0-cp2a` and both remote refs remain unchanged, and that no push or force-push occurred.

## 9. Ordered proposed reconstruction sequence

The source sequence is the original first-parent/linear order:

```text
git rev-list --reverse origin/17.0.0-cp2a
```

Replay each SHA in that order, except the exact DROP set in section 4. This is safer than using a contiguous range because legitimate commits are interleaved. The first retained history ends immediately before `2cb0e90f19200f6021fb6a63afaf110b494e3eae`; later retained commits continue around the DROP SHAs through `66f534731842e30bb79b4ce6be6cc04456f1d194`. Do not replay `66f534731842e30bb79b4ce6be6cc04456f1d194`; it is the final DROP workflow commit. Preserve all other actual SHAs, including the legitimate kernel commits identified in section 3.

For an auditable ordered input in Phase 2, generate the replay list without changing refs:

```sh
DROP='[the exact 119 SHAs in section 4]'
git rev-list --reverse origin/17.0.0-cp2a |
  while read sha; do
    case " $DROP " in *" $sha "*) ;; *) printf '%s\n' "$sha" ;; esac
  done
```

The sequence must be reviewed against `git show --stat`, `git show --name-status`, and `git show` for every candidate before applying it.

## 10. Scope confirmation

This was audit-only. No history rewrite, rebase, reset, branch reconstruction, commit, push, force-push, kernel build, compilation, linker invocation, packaging, device test, emulator/QEMU test, module test, or build-script execution was performed. Repository scripts were inspected only as text.
