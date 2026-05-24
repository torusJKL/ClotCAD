## ADDED Requirements

### Requirement: Per-release documentation archive
The system SHALL publish a snapshot of the generated documentation for each tagged release.

#### Scenario: Tag push triggers documentation generation
- **WHEN** a git tag matching `v*` is pushed
- **THEN** the CI workflow SHALL run Staple to generate documentation
- **THEN** the output SHALL be published to the `gh-pages` branch under a path named `/v<semver>/`

### Requirement: Latest version alias
The system SHALL maintain a `/latest/` path that points to the most recent release's documentation.

#### Scenario: Latest alias mirrors newest release
- **WHEN** a new tag is published
- **THEN** the CI workflow SHALL copy the just-generated docs to `/latest/` as well

### Requirement: Root redirect
The root URL `https://clotcad.com/` SHALL redirect to `https://clotcad.com/latest/`.

#### Scenario: Browser visits root
- **WHEN** a user visits `https://clotcad.com/`
- **THEN** they SHALL be redirected to `https://clotcad.com/latest/`

### Requirement: Old versions remain accessible
Previously published documentation versions SHALL NOT be removed when a new version is published.

#### Scenario: Accessing old version
- **WHEN** a user visits `https://clotcad.com/v0.1.0/`
- **THEN** the full documentation for version 0.1.0 SHALL be served

### Requirement: Custom domain serving
The documentation SHALL be served from the custom domain `clotcad.com` via GitHub Pages.

#### Scenario: DNS resolution
- **WHEN** a browser resolves `clotcad.com`
- **THEN** the DNS A records SHALL point to the four GitHub Pages IP addresses
- **THEN** HTTPS SHALL be enforced via GitHub's auto-provisioned Let's Encrypt certificates
