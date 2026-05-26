## Context

Currently, `apropos` in `:clotcad` does substring matching against exported symbols from `:cl-occt` and `:clotcad` packages. It requires the user to know approximately what they're looking for. There is no way to discover what capabilities exist without prior knowledge.

SBCL's `sb-introspect` provides `find-definition-source`, which returns a `definition-source` struct containing the `:pathname` where each function was defined. This makes it possible to derive a function's source file at runtime, and from the filename derive its category.

The file-to-category map lives in clotcad's codebase (not cl-occt), so cl-occt remains a pure library with no awareness of this system. Adding a new file to cl-occt requires only one line in the map to appear in the category tree.

## Goals / Non-Goals

**Goals:**
- `apropos` with no argument prints the category tree (all function groups with counts and representative function names)
- `apropos :<keyword>` prints full details of a matching category (all functions with signatures and docstrings)
- Category lookup uses partial case-insensitive matching against display names and filename stems
- `apropos` with a string or bare symbol retains existing substring search behavior
- `:packages` accepts both a single designator (e.g. `:cl-occt`) and a list (`'(:cl-occt :clotcad)`)
- Keywords matching no category return nil / "no category found" — no fallthrough
- Covers both `:cl-occt` and `:clotcad` exports
- Updates `docs/clotcad-api.md` with the new usage

**Non-Goals:**
- Not modifying cl-occt's source code
- Not a visual/gallery browser in the 3D viewport
- Not `context-of` shape-aware filtering (future work)
- Not a separate `browse` command — all discovery goes through `apropos`

## Decisions

### Decision 1: Category derivation from source files via sb-introspect

The category of each function is derived at runtime by calling `sb-introspect:find-definition-source` on the function, extracting the pathname, then mapping the filename stem (e.g. "fillet" from `fillet.lisp`) to a display name via a lookup table.

The lookup table lives in `src/viewer/introspect.lisp` as a `defparameter` alist:

```lisp
(defparameter *category-display-names*
  '((:primitives . "Primitives")
    (:booleans . "Booleans")
    (:fillet . "Fillets")
    (:chamfer . "Chamfers")
    (:io . "File I/O")
    ...)
```

Files without an entry use their stem directly (capitalized) as the display name — `io.lisp` → "Io" if no entry exists.

The category-function index is built lazily on first `(apropos)` call and cached.

**Alternatives considered:**
- Manual hardcoded groups in `help` — rejected because it drifts from the actual API
- Docstring annotation parsing — rejected because it's convention-based and easy to forget

### Decision 2: Keywords always mean category lookup

When `apropos` receives a keyword symbol, it exclusively tries to match it against categories. If no category matches, it returns nil / prints "no category found". It never falls through to substring search on function names.

This keeps the two modes (category lookup and substring search) cleanly separated. The user can distinguish intent by the type of the first argument.

**Alternatives considered:**
- Keywords as substring search fallthrough — rejected because it conflates modes and produces confusing output

### Decision 3: Partial case-insensitive matching on categories

The category lookup `(apropos :fillet)` converts the keyword to a string and searches for it as a substring against both the display name ("Fillets") and the filename stem ("fillet"), case-insensitively. This means `:file` matches "File I/O", `:face` matches both "Faces" (Construction) and "Face Filling", etc.

**Alternatives considered:**
- Exact match — rejected because it's fragile with multi-word display names
- Only match against filename stems — rejected because stems like "io" are too cryptic

### Decision 4: :packages accepts both single and list

The `:packages` keyword argument coerces its value to a list before processing:

```lisp
(defun %coerce-packages (packages)
  (cond
    ((null packages) nil)
    ((eq packages t) t)
    ((listp packages) packages)
    (t (list packages))))
```

This allows both `:packages :cl-occt` and `:packages '(:cl-occt :clotcad)`.

### Decision 5: Lazy cache, refreshable

The category-function index is built on first `(apropos)` call and cached in a global variable. A separate `(apropos-rebuild)` function (not exported or advertised) can force a rebuild. Since the index is derived from compiled functions in the live image, it's consistent for the session duration.

### Decision 6: Compact mode for GUI REPL

The GUI REPL in the Qt window passes eval results through a C `char result[4096]` buffer (`wrap/repl_panel.cpp:147`). The full category tree with function names (~6000+ chars) exceeds this limit and gets truncated.

The tree output detects the GUI context by checking `(typep *standard-output* 'string-stream)` — the eval-string callback binds `*standard-output*` to a string stream to capture output, while Slynk and Alive LSP use their own socket/emacs streams.

In compact mode (GUI REPL), each category line shows only the display name and function count — no function names. Total output ~2000 chars, safely within 4096. In full mode (remote REPLs), representative function names are included as before.

**Alternatives considered:**
- Special variable — rejected because it requires manual coordination and can be forgotten
- Thread-name detection — rejected as fragile
- Always-compact — rejected because Slynk/Alive users benefit from seeing function names

## Risks / Trade-offs

- **Risks: sb-introspect dependency**: `sb-introspect` is part of SBCL but not loaded by default. The system needs `(require :sb-introspect)` before using category features. **Mitigation**: load it at clotcad startup, or wrap in `ignore-errors` and degrade gracefully (fall back to old `apropos` if unavailable).
- **Performance on first call**: Introspecting every exported function from `:cl-occt` (~390 symbols) on the first `(apropos)` call. With cached source locations in compiled functions, this should be fast (<50ms). **Mitigation**: cache the result; subsequent calls are instant.
- **Partial match ambiguity**: `:face` matches both "Faces" (Construction) and "Face Filling". **Mitigation**: when multiple categories match, show a filtered tree listing all matches with their function counts, letting the user drill into a specific one.
- **GUI buffer limit**: The C++ REPL buffer is 4096 bytes. **Mitigation**: `typep` detection of string-stream output to switch to compact mode automatically.
