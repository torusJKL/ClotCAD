## 1. Project Scaffolding

- [x] 1.1 Create `staple.ext.lisp` with thin delegation to `homepage/setup.lisp`
- [x] 1.2 Create `homepage/setup.lisp` with `clotcad-page` class, template override, package list, image list, and docstring formatting method
- [x] 1.3 Create `homepage/default.ctml` — light-mode Clip template with nav bar (Home, API Reference, Cheatsheet), logo, content area, version footer
- [x] 1.4 Create `homepage/style.css` — standalone Fluent-inspired stylesheet
- [x] 1.5 Copy `share/icons/ClotCAD-logo.svg` to `homepage/images/logo.svg`
- [x] 1.6 Create `homepage/images/screenshot.png` placeholder (user provides actual screenshot)
- [x] 1.7 Rename `docs/cheatsheet/main.typ` → `docs/cheatsheet/cheatsheet.typ`
- [x] 1.8 Create `.github/workflows/publish-homepage.yml` — CI workflow triggered on tag push `v*`: checkout, system deps, OCCT cache restore, build viewer, SBCL+Quicklisp+Staple generate, Typst compile, deploy to gh-pages branch with versioned paths

## 2. Docstring Enrichment

- [x] 2.1 Add docstrings with examples to `ops.lisp`: `def`, `show`, `hide`, `toggle`, `show-defs`, `toggle-defs`, `cut`, `fuse`, `common`, `section`, `translate`, `rotate`, `make-prism`, `make-revol`, `make-compound`, `make-part`, `write-step`, `write-stl`
- [x] 2.2 Add docstrings with examples to `ui.lisp`: `show-grid`, `show-axis`, `toggle-grid`, `toggle-axis`, `show-viewcube`, `toggle-viewcube`, `show-viewcube-axes`, `toggle-viewcube-axes`, `set-view`, `current-view`, `fit-view`, `set-view-aa`, `show-repl`, `show-scene-tree`, `toggle-repl`, `toggle-scene-tree`
- [x] 2.3 Add docstrings with examples to `repl.lisp`: `cancel-import`, `replay-speed`, `result-export`, `export-repl-history`, `set-repl-history-key`, `set-repl-submit-key`
- [x] 2.4 Add docstrings with examples to `lifecycle.lisp`: `start-viewer`, `stop-viewer`, `bootstrap`
- [x] 2.5 Add examples to existing docstrings in `select.lisp`: `select`, `deselect`, `clear-selection`, `selected-shapes`, `apply-selection-schemes`
- [x] 2.6 Add examples to existing docstrings in `theme.lisp`: `apply-theme`, `set-accent`, `theme-dark`, `theme-light`, `theme-auto`, `set-font-size`

## 3. Local Verification

- [x] 3.1 Start SBCL, load `:staple-markdown` and `:staple`, run `staple:generate` to `homepage/output/`
- [x] 3.2 Open generated HTML in browser — verify template renders correctly, nav works, logo displays
- [x] 3.3 Verify definitions index includes all expected symbols from `:clotcad`, `:clotcad-user`, and `:cl-occt`
- [x] 3.4 Verify docstrings render with Markdown formatting and cross-references

## 4. DNS & Deployment

- [ ] 4.1 Configure DNS A records for `clotcad.com` → GitHub Pages IPs
- [ ] 4.2 Configure GitHub repo Settings → Pages → custom domain `clotcad.com`
- [ ] 4.3 Push a tag, verify CI generates docs and deploys to gh-pages branch
- [ ] 4.4 Verify `https://clotcad.com/` redirects to `https://clotcad.com/latest/`
- [ ] 4.5 Verify `https://clotcad.com/v0.X.X/` serves documentation for that version
- [ ] 4.6 Verify HTTPS is active (Let's Encrypt auto-provisioned)
