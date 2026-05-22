## ADDED Requirements

### Requirement: Alive LSP server starts on port 4006
The system SHALL start an Alive LSP server listening on TCP port 4006 when `bootstrap` is called (distribution) or when `start.lisp` is loaded (development).

#### Scenario: Bootstrap starts Alive LSP server
- **WHEN** `bootstrap` is called
- **THEN** an Alive LSP server SHALL be started on port 4006

#### Scenario: Development script starts Alive LSP server
- **WHEN** `start.lisp` is loaded
- **THEN** an Alive LSP server SHALL be started on port 4006

### Requirement: Alive LSP runs in a dedicated thread
The Alive LSP server SHALL run in its own SBCL thread, separate from the main/UI thread.

#### Scenario: Thread created for Alive LSP
- **WHEN** `bootstrap` or `start.lisp` starts Alive LSP
- **THEN** a new SBCL thread named `"alive-lsp"` SHALL be created

#### Scenario: Thread keeps running
- **WHEN** the Alive LSP thread is created
- **THEN** it SHALL loop with `(sleep 1)` to stay alive after starting the server

### Requirement: Default package is cl-occt-user
All evaluations from the LSP client SHALL default to the `cl-occt-user` package.

#### Scenario: Package binding set
- **WHEN** the Alive LSP thread is initialized
- **THEN** the evaluation environment SHALL use the `cl-occt-user` package

#### Scenario: Default package threaded through server start
- **WHEN** `alive/server:start` is called with `:default-package "CL-OCCT-USER"`
- **THEN** the eval handler SHALL use `CL-OCCT-USER` instead of `CL-USER` as the fallback when the client omits the package parameter

### Requirement: alive-lsp source is patched for default-package support
The alive-lsp source in `lib/alive-lsp/` SHALL be patched to accept a `:default-package` parameter in `alive/server:start`, thread it through the state struct, and use it in the eval handler.

#### Scenario: state struct has default-package slot
- **WHEN** `state:create` is called with `:default-package`
- **THEN** the returned state object SHALL have that value accessible via `state:default-package`

#### Scenario: eval handler uses state's default-package
- **WHEN** an eval request arrives without a `:package` parameter in its params
- **THEN** the handler SHALL use `(state:default-package state)` instead of the hardcoded `"cl-user"`

### Requirement: Graceful fallback when Alive LSP unavailable
The system SHALL NOT crash if Alive LSP is not available. It SHALL warn and continue without the LSP server.

#### Scenario: Alive LSP not loaded
- **WHEN** `bootstrap` is called but Alive LSP is not available
- **THEN** a warning SHALL be printed
- **THEN** the viewer SHALL start without an Alive LSP server

#### Scenario: Alive LSP not loaded (development)
- **WHEN** `start.lisp` is loaded but Alive LSP is not available
- **THEN** the script SHALL print a warning
- **THEN** the viewer SHALL start without an Alive LSP server

### Requirement: Alive LSP is quickloaded at core build time
The `make-core.lisp` script SHALL quickload `:alive-lsp` so it is available in the distribution core dump without network access.

#### Scenario: Core dump loads Alive LSP
- **WHEN** `make-core.lisp` is executed
- **THEN** `(ql:quickload :alive-lsp :silent t)` SHALL be called

### Requirement: Alive LSP is cloned as a local dependency
The system SHALL clone the alive-lsp repository to `lib/alive-lsp/` for reproducible builds and offline availability.

#### Scenario: Clone via justfile
- **WHEN** `just alive-lsp` is run
- **THEN** the alive-lsp repository SHALL be cloned to `lib/alive-lsp/` if not already present

#### Scenario: Justfile dependency
- **WHEN** `just core` is run
- **THEN** it SHALL first ensure `just alive-lsp` has been run

### Requirement: alive-lsp is pinned to a specific commit
The alive-lsp clone SHALL be pinned to a specific commit or tag so that local patches are reproducible and upstream changes don't break the build.

#### Scenario: justfile pins the commit
- **WHEN** `just alive-lsp` clone completes
- **THEN** the working tree SHALL be checked out at a specific commit or tag
- **THEN** any future `just alive-lsp` on an existing clone SHALL check out the same commit

### Requirement: LSP repository is in ASDF central registry
The `make-core.lisp` and `start.lisp` scripts SHALL push `lib/alive-lsp/` to `asdf:*central-registry*` so that alive-lsp can be loaded via Quicklisp or directly.

#### Scenario: make-core.lisp adds central registry
- **WHEN** `make-core.lisp` is executed
- **THEN** `(push (merge-pathnames #P"lib/alive-lsp/" (truename ".")) asdf:*central-registry*)` SHALL be called before quickloading

#### Scenario: start.lisp adds central registry
- **WHEN** `start.lisp` is loaded
- **THEN** `(push (merge-pathnames #P"lib/alive-lsp/" (truename ".")) asdf:*central-registry*)` SHALL be called before quickloading

### Requirement: LSP client can connect
The Alive LSP server SHALL accept LSP connections from compatible editors (VS Code with alive-lsp extension, Emacs with lsp-mode, etc.).

#### Scenario: Editor connects to Alive LSP
- **WHEN** an LSP client connects to port 4006
- **THEN** the LSP handshake SHALL complete
- **THEN** completion requests SHALL return results in the `cl-occt-user` package context
