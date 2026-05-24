## ADDED Requirements

### Requirement: Model API functions have docstrings
All public functions exported from the `:clotcad` model package (in `src/model/api.lisp`) SHALL have docstrings following the `cl-occt` convention, including `**Returns:**`, `**Example:**`, `**See also:**`, and `- **param**` bullet parameter documentation.

#### Scenario: All exported model functions gain docstrings
- **WHEN** a public function in `src/model/api.lisp` has no docstring (`resolve-shape`, `model-color`, `model-display-name`, `model-layer`, `model-ref`, `param`, `with-params`, `defmodel`, `set-param!`, `set-params!`, `write-dag-models-to-step`, `read-step-into-dag`, `help`)
- **THEN** a full docstring SHALL be added describing its purpose, parameters, return value, with an executable example

#### Scenario: Macro docstrings include expanded-form examples
- **WHEN** a macro (`with-params`, `defmodel`) is documented
- **THEN** the example SHALL show typical usage with illustrative parameter values
- **AND** the description SHALL explain what the macro expands to

### Requirement: Model API docstring examples demonstrate real usage
All `**Example:**` sections for model API functions SHALL use realistic shape names and parameter values that demonstrate the function's purpose.

#### Scenario: Examples use descriptive names
- **WHEN** an example creates a model or shape
- **THEN** it SHALL use meaningful names (e.g., `my-box`, `my-union`) rather than generic placeholders

### Requirement: `help` function docstring describes the model query system
The `help` function SHALL have a docstring that explains the interactive model help system, what topics are available, and how to use it.

#### Scenario: help function is documented
- **WHEN** a user evaluates `(describe 'help)`
- **THEN** the docstring SHALL explain that `help` displays available model commands and topics
- **AND** include an example showing `(help)` and `(help 'topic-name)`
