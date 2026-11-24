# v0.6.6.9.17.5 — Driver Portrait Restoration (DRAFT)

Base: f868db4d032d5a38c0685afcf4756a9877a6c37a. PR #26 source: c554b333dff67fa9820e52da826174b27e77b583.

Local pack contract: assets/portraits_2012/{hud,profile}/<driver_slug>_<kind>_2012.png. 24 identities, 48 textures; no images included in this commit. Reuse normalized path and cache from a local-only adapter, keep original helmet when missing. No network downloads. Restart and import after installing the official pack. License for actual edited photographs remains unverified; do not upload binaries.

Local strict regression command (after installing pack and importing Godot):

    godot --path . --rendering-method gl_compatibility --script res://tests/driver_hud_identity_09175_test.gd -- --require-real-portraits

The normal CI without the user pack exercises fallback and cannot certify real portraits. Strict mode checks 24+24 resources, dimensions, texture reuse and HUD/radio/profile binding. No claim of visual approval or full race QA. Drive download reported two ZIPs; local execution unavailable (container and Python startup ClientError). CRC/SHA checks, real photos, benchmarks, actual race regressions and complete ZIP remain BLOCKED or NOT_RUN. No release/merge. Do not mark stable until user approval.
