# Patch delivery and UI guidelines

- Deliver a **layer-only ZIP** containing **only changed/new repository-relative files**. Never include the full repository unless explicitly requested.
- Preserve folder paths when extracting patches. Never overwrite unrelated work.
- No `.secrets/`, Samsung authorization tokens, keystores, APKs, compiled builds, generated caches or `.git/` in a patch.
- Include logical change logs and outcome/mistake reports where behavior is changed; pure cosmetic tweaks alone do not require change logs.
- Prefer responsive Flutter `Flexible`, `Expanded`, `LayoutBuilder`, `AspectRatio`, proportional parent constraints, `Wrap`, and scrolling. Avoid fixed screen dimensions, absolute placements, arbitrary minimum and maximum width/height clamps.
- Flutter uses logical pixels, not CSS; small constants for paddings, radii and minimum accessible tap targets are permitted. On web, prefer `flex`, `grid`, `%`, `em`, `rem`, `svh` and `dvh` rather than fixed `px`/`min-w`/`max-w` layouts.
- Before shipment, review `AGENTS.md` and `docs/AI-rules.md`; run available tests and clearly state which checks could not be executed.
