## Context

Staple generates HTML documentation with "Source" links that point to the definition's source file. The default `resolve-source-link` method on `system-page` (parent class of `clotcad-page`) constructs GitHub blob URLs using `asdf:system-homepage` and `current-commit` of the documented system. For symbols documented from the `:cl-occt` package, the source files live under the ClotCAD source tree (`lib/cl-occt/`) and erroneously get ClotCAD repo URLs.

## Goals / Non-Goals

**Goals:**
- Source links for cl-occt functions point to `https://github.com/torusJKL/cl-occt/blob/<pinned-commit>/src/...lisp#L<N>`
- Source links for ClotCAD functions continue to work as before
- No CI or tooling changes required

**Non-Goals:**
- Documenting the cl-occt repo as a separate Staple subsystem
- Supporting any other submodules (none planned)
- Changing the template, ASDF configuration, or CI workflow

## Decisions

| Decision | Choice | Alternatives Considered |
|----------|--------|------------------------|
| How to detect cl-occt sources | `pathname-utils:subpath-p` check against `lib/cl-occt/` | Regex on pathname string — less robust across platforms |
| Commit source | `git rev-parse HEAD:lib/cl-occt` (parent repo gitlink) | `git -C lib/cl-occt rev-parse HEAD` — gives submodule's checked-out HEAD, not the pinned commit; environment variable — requires CI changes |
| When to capture commit | `defparameter` at extension load time, cached once | Lazy computation per source link — unnecessary overhead; caching is fine since `openspec` clears the project-level cache per `generate` call |
| Mechanism | `:around` method on `staple:resolve-source-link` for `clotcad-page` | Direct method on `clotcad-page` (would bypass `system-page` logic entirely for non-cl-occt files); modifying Staple source (invasive) |

## Risks / Trade-offs

- **[Minimal]** If `lib/cl-occt/` doesn't exist (shallow clone, no submodule init), `probe-file` guard prevents error; non-cl-occt sources still work
- **[Trivial]** `git rev-parse` requires git in PATH — universally available in CI and dev environments; fallback to `"HEAD"` avoids crashes
- **[Edge case]** If the submodule commit changes between extension load and page generation, the cached commit would be stale — but Staple already resets `*current-commit-cache*` per `generate` call, so this isn't an issue
