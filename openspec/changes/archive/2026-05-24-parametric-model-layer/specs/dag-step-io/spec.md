## ADDED Requirements

### Requirement: Export DAG models to STEP with metadata
The system SHALL provide `write-dag-models-to-step` that exports all models in the DAG registry to a STEP file, preserving metadata (color, name, layer) as XDE attributes.

#### Scenario: Export registry to STEP
- **WHEN** `*model-registry*` contains model `my-box` with cached shape and metadata `{:color :blue :display-name "My Box"}`
- **AND** user calls `(write-dag-models-to-step "output.step")`
- **THEN** a STEP file is written containing the model shapes with their color and name attributes

### Requirement: Import STEP into DAG model registry
The system SHALL provide `read-step-into-dag` that reads a STEP file and populates the DAG registry with models, creating simple (static) model entries for each top-level shape.

#### Scenario: Import STEP into registry
- **WHEN** user calls `(read-step-into-dag "input.step")`
- **THEN** each top-level shape in the STEP file is registered as a model in `*model-registry*`
- **AND** metadata (color, name) from XDE attributes is attached to each model
