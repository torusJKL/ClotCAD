## ADDED Requirements

### Requirement: Multi-form evaluation

The REPL SHALL evaluate all complete S-expressions in the input buffer, not just the first one.

#### Scenario: Two simple forms on one line

- **WHEN** user enters `(+ 1 2) (+ 3 4)` and presses Enter
- **THEN** both `(+ 1 2)` and `(+ 3 4)` are evaluated
- **THEN** the output contains `3` and `7`

#### Scenario: Multiple forms with defs

- **WHEN** user enters `(def :b1 (make-box 10 10 10)) (def :s1 (make-sphere 10))` and presses Enter
- **THEN** both `:b1` and `:s1` are defined and available in `*displayed-models*`

#### Scenario: Incomplete form after complete forms

- **WHEN** user enters `(+ 1 2) (+ 3` and presses Enter
- **THEN** `(+ 1 2)` is evaluated and produces `3`
- **THEN** the incomplete input `(+ 3` is accumulated in `*repl-accumulator*`
- **THEN** entering `4)` on the next line evaluates `(+ 3 4)` and produces `7`

#### Scenario: Error in one form does not block subsequent forms

- **WHEN** user enters `(+ 1 2) (error "oops") (+ 3 4)` and presses Enter
- **THEN** `(+ 1 2)` is evaluated
- **THEN** the error `"oops"` is reported in the output
- **THEN** `(+ 3 4)` is evaluated and `7` appears in the output

#### Scenario: Single form still works

- **WHEN** user enters `(make-box 10 20 30)` and presses Enter
- **THEN** the form is evaluated and a shape is returned (existing behavior preserved)

#### Scenario: Empty input produces no output

- **WHEN** user enters only whitespace and presses Enter
- **THEN** nothing is evaluated and no output is generated
