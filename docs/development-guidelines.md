# Development guidelines

Framework: Flutter. Environment: middle.

## Responsive UI — required

Prefer `Expanded`, `Flexible`, `LayoutBuilder`, `MediaQuery`, `FractionallySizedBox`, `AspectRatio`, `Wrap`, and fluid grids plus scrolling when content is taller than the screen. Layout should respond to short phones, different aspect ratios, orientation and accessibility font scaling.

Do not use hardcoded screen widths/heights, arbitrary minimum/maximum constraints or fixed-size containers as the layout foundation. For CSS/web surfaces, prefer `flex`, `grid`, `%`, `rem`, `em`, `svh`/`dvh`/`vh`; avoid `px`, `min-w/h`, `max-w/h` and fixed-position screen layouts. Flutter uses logical pixels rather than CSS units: tiny constants for border radii, icon primitives, control gaps and touch-target accessibility are acceptable but should not determine overall device layout.

## Change classification

Purely visual/UI changes (spacing, typography, styling, layout, colors) do NOT require a changelog unless they change behavior, logic, accessibility semantics, data, routing, or contracts. Mixed changes count as logical. Record logical changes in `docs/change-log/` using `YYYYMMDD_HHMM_...` (no seconds).

## Delivery rules

Deliver **only changed/new files in a layered patch ZIP**, never the full repository unless explicitly requested. Read `docs/AI-rules.md` before creating an archive. No personal credentials, generated artifacts or unchanged files.

## Quality

Read surrounding code, preserve compatibility and test on real target devices. Never claim checks passed without running them. Separate command transport success from actual device behavior. Keep credentials out of Git and logs.
