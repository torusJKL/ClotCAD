## Why

ClotCAD has no public-facing homepage or documentation website. Users who download the binary or find the repository have no centralized, versioned documentation to browse. The project needs a homepage at `clotcad.com` with generated API docs, a README-based overview, and a PDF cheatsheet — all versioned per release.

## What Changes

- Create a `homepage/` subdirectory with Staple configuration, a custom Clip template, and stylesheet
- Write `staple.ext.lisp` (thin entry point delegating to `homepage/setup.lisp`)
- Add `.github/workflows/publish-homepage.yml` — generates docs with Staple on tag push, deploys to `gh-pages` branch
- Enrich docstrings in `ops.lisp`, `ui.lisp`, `repl.lisp`, `select.lisp`, `theme.lisp`, and `lifecycle.lisp` with descriptions and examples
- Output is versioned: `https://clotcad.com/latest/` and `https://clotcad.com/v0.2.2/`
- `docs/clotcad-api.md` stays AI-only, not part of the Staple pipeline
- `docs/cheatsheet/main.typ` → `docs/cheatsheet/cheatsheet.typ` (renamed)

## Capabilities

### New Capabilities
- `versioned-docs`: Per-release documentation archives served under versioned URL paths, with `latest/` redirect
- `docstring-api`: Auto-generated API reference from source docstrings, rendered with Markdown formatting and cross-references
- `cheatsheet-pdf`: Typst-compiled cheatsheet linked from the homepage nav

### Modified Capabilities
None — no existing specs to modify.

## Impact

- **New files**: `staple.ext.lisp`, `homepage/setup.lisp`, `homepage/default.ctml`, `homepage/style.css`, `.github/workflows/publish-homepage.yml`
- **Modified files**: `ops.lisp`, `ui.lisp`, `repl.lisp`, `select.lisp`, `theme.lisp`, `lifecycle.lisp` (docstrings only)
- **Renamed**: `docs/cheatsheet/main.typ` → `docs/cheatsheet/cheatsheet.typ`
- **Dependencies**: `staple`, `staple-markdown`, `staple-server` (dev only), `typst` (CI only)
- **External**: DNS records for `clotcad.com`, GitHub Pages configuration
