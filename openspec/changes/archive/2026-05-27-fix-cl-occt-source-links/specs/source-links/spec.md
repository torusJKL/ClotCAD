## ADDED Requirements

### Requirement: Source links route to correct repository
The Staple documentation generator SHALL route "Source" links for documented symbols to the correct GitHub repository and commit SHA based on the symbol's source file location.

#### Scenario: cl-occt source file link
- **WHEN** generating a documentation page for a symbol whose source file resides under `lib/cl-occt/`
- **THEN** the source link SHALL point to `https://github.com/torusJKL/cl-occt/blob/<gitlink-commit>/<relative-path>#L<line>`

#### Scenario: ClotCAD source file link
- **WHEN** generating a documentation page for a symbol whose source file resides in the main repository (not under `lib/cl-occt/`)
- **THEN** the source link SHALL point to `https://github.com/torusJKL/ClotCAD/blob/<clotcad-commit>/<relative-path>#L<line>`

### Requirement: cl-occt commit comes from parent repo gitlink
The cl-occt commit used in source link URLs SHALL be the pinned submodule commit stored in the parent repository's git tree at `HEAD:lib/cl-occt`.

#### Scenario: Commit resolution at generation time
- **WHEN** Staple loads the extension file during documentation generation
- **THEN** the cl-occt commit SHALL be resolved by running `git rev-parse HEAD:lib/cl-occt` from the project root

#### Scenario: Fallback when git is unavailable
- **WHEN** the `git rev-parse` command fails (e.g., git not in PATH, not a git repository)
- **THEN** the cl-occt commit SHALL fall back to `"HEAD"` to avoid crashing documentation generation
