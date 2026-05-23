## Context

The cheatsheet is a standalone Typst document in `docs/cheatsheet/`. It has no build dependencies beyond `typst` itself (fetches the boxed-sheet template from the Typst universe). Version is injected at compile time via `git describe`.

The content describes ClotCAD's own API — so the author of the cheatsheet is the same person who built ClotCAD, meaning API knowledge is first-hand.

## Goals / Non-Goals

**Goals:**
- Multi-page, readable (7.5pt), 3-column, color-coded Typst document
- Auto-versioned from git tags
- DSL section with syntax-highlighted Lisp examples
- Functions shown as signatures only (OpenSCAD style)
- Buildable with a single `just cheatsheet` command

**Non-Goals:**
- Not a tutorial or reference manual
- No descriptions, examples, or images (except DSL examples)
- No HTML/PDF served automatically — just the compile step
- Not comprehensive — daily-use functions only

## Decisions

| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| Template | boxed-sheet 0.1.2 | Color-coded sections, line titles, multi-column layout out of the box | Custom Typst — more work, reinvents layout |
| Font | Cousine (Google Fonts monospace) | Clean, readable at small sizes, Lisp-friendly | Fira Code, JetBrains Mono — Cousine ships with many Linux distros |
| Layout | 7.5pt, 3 columns, A4 | Readable text while packing ~13 sections in 4-5 pages | 5.5pt/5-col (too dense) or 9pt/2-col (too many pages) |
| Version injection | `typst --input` flag | Clean, no temp files, standard Typst pattern | `version.typ` file (temp file) or hardcoding (stale) |
| Version format | `git describe ... \| sed` | Strips hash and `-0` suffix for clean display | Raw `git describe` (includes hash), or manual bump (forgets) |
| DSL examples | Fenced `lisp` code blocks | Built-in Typst syntax highlighting, automatic keyword coloring | Raw text blocks (no highlighting), or images (heavy) |
| Language IDs for raw | `lisp` | Typst supports it natively, matches Common Lisp syntax | `common-lisp`, `scheme` — `lisp` works best in practice |
| Color palette | 6 colors: blue/green/orange/purple/teal/red | CAD-inspired, section-appropriate | 8 colors (template default), single color (monotone) |
| Signature format | `func-name(args, ...)` as raw inline | Follows OpenSCAD cheatsheet convention | Table (wastes space), description list (too verbose) |

## Risks / Trade-offs

- **Font availability**: Cousine might not be installed on all systems. Mitigation: fallback to `"Liberation Mono"` in the `#set text(font: ...)` call.
- **Typst version**: `--input` flag requires Typst ≥0.11. Mitigation: `sys.inputs.at("version", default: "dev")` gracefully degrades.
- **Content staleness**: The cheatsheet must be manually updated when APIs change. Mitigation: version string tells the reader exactly which commit the cheatsheet describes.
- **git describe failure**: If no tags exist, `git describe` fails. Mitigation: `|| echo "unknown"` fallback.
