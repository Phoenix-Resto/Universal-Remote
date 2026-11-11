# Patch ZIP delivery — mandatory delta-only workflow

## Scope and baseline

- **Always deliver a layered patch ZIP, not a full project ZIP**, unless the user explicitly asks for a complete archive. A patch contains **only newly added or modified files** compared with the provided/current base repository revision.
- Preserve repository-relative paths inside the ZIP (for example, `lib/services/samsung_tv_remote.dart`); no extra root folder and no untouched files or empty directory placeholders.
- Review the user's latest uploaded repository or known base before selecting files. Do not overwrite unrelated local work. When the base is ambiguous or local uncommitted changes exist, state the assumed base; ask permission before destructive choices.
- Include a changelog in `docs/change-log/YYYYMMDD_HHMM_short-description.md` for logical/behavioral changes; no seconds in changelog filenames. **Pure visual/UI styling changes do not get changelogs**. Mixed UI + behavioral changes do.
- Include detailed root-cause, attempted fixes, verified outcome, and prevention in `docs/solving-mistakes/` for meaningful solved issues; do not create a "solved" report for untested fixes.
- Represent deletions explicitly in `deletions.txt` (relative paths), never by omission. If nothing is deleted, omit the file.
- Exclude `.git/`, `.secrets/`, API keys, pairing tokens, `.env` secrets, SDK/dependency folders, build/coverage output, IDE caches and any personal machine state.
- Provide the ZIP plus a concise manifest of changed/new files and exact overlay steps. Verify archive contents and no credential files before delivery.

## Responsive UI requirement for every implementation

- **Do not hardcode fixed UI widths, heights, minimum widths/heights, or maximum widths/heights** as a layout strategy. Avoid CSS `px`, `min-width`, `min-height`, `max-width`, `max-height`, fixed absolute positioning and non-adaptive screen-specific dimensions.
- On web use `flex`, `grid`, `%`, `rem`, `em`, `vh`/`svh`/`dvh`, fluid fractions, intrinsic sizing and content-driven wrapping. Prefer relative spacing and accessible typography. Fixed border widths and small icon primitives are allowed only with justification, not for overall structure.
- On Flutter (which uses logical pixels, not CSS units), achieve the same fluid behavior using `Expanded`, `Flexible`, `Wrap`, `LayoutBuilder`, `MediaQuery`, `FractionallySizedBox`, `AspectRatio`, scrolling and adaptive text; prefer proportional/content-driven dimensions over hardcoded `SizedBox(width/height)` for overall structure.
- Check compact screens, landscape orientations, text scaling and overflow; functionality must remain usable without clipping.

## Application order

For a new Flutter repository, generate necessary SDK-owned scaffolding first using `flutter create --platforms android .`; **then** overlay the layered patch so generated defaults do not overwrite patched files. Do not delete existing code or credentials to apply a patch.
