## ADDED Requirements

### Requirement: Thread-first macro (->)
The system SHALL provide a `->` macro that threads an initial value as the first argument of each subsequent form, producing a single nested expression.

#### Scenario: Basic thread-first pipeline
- **WHEN** evaluating `(-> 1 (+ 2) (* 3) (- 4))`
- **THEN** the result SHALL be `5` (expanding to `(- (* (+ 1 2) 3) 4)`)

#### Scenario: Thread-first with symbol forms
- **WHEN** evaluating `(-> 5 sqrt float)` where `sqrt` and `float` are symbols
- **THEN** the result SHALL be `2.236068` (expanding to `(float (sqrt 5))`)

#### Scenario: Thread-first single form
- **WHEN** evaluating `(-> 42 list)`
- **THEN** the result SHALL be `(42)`

#### Scenario: Thread-first no forms
- **WHEN** evaluating `(-> :foo)`
- **THEN** the result SHALL be `:foo`

#### Scenario: Thread-first expansion correctness
- **WHEN** macroexpanding `(-> x (f a b) (g c))`
- **THEN** the expansion SHALL be `(g (f x a b) c)`

### Requirement: Thread-last macro (->>)
The system SHALL provide a `->>` macro that threads an initial value as the last argument of each subsequent form, producing a single nested expression.

#### Scenario: Basic thread-last pipeline
- **WHEN** evaluating `(->> (1 2 3) (mapcar #'1+) (remove-if #'evenp))`
- **THEN** the result SHALL be `(3)` (expanding to `(remove-if #'evenp (mapcar #'1+ '(1 2 3)))`)

#### Scenario: Thread-last symbol forms
- **WHEN** evaluating `(->> 3 (expt 2))`
- **THEN** the result SHALL be `8` (expanding to `(expt 2 3)`)

#### Scenario: Thread-last single form
- **WHEN** evaluating `(->> 5 (list 1 2))`
- **THEN** the result SHALL be `(1 2 5)`

#### Scenario: Thread-last expansion correctness
- **WHEN** macroexpanding `(->> x (f a b) (g c))`
- **THEN** the expansion SHALL be `(g c (f a b x))`

### Requirement: Thread-as macro (as->)
The system SHALL provide an `as->` macro that threads a value through a series of forms using a named binding, where each form's result is bound to that name for the next form.

#### Scenario: Basic thread-as pipeline
- **WHEN** evaluating `(as-> (list :foo :bar) v (mapcar #'symbol-name v) (first v) (char v 0))`
- **THEN** the result SHALL be `#\F`

#### Scenario: Thread-as single form
- **WHEN** evaluating `(as-> 10 x (* x 2))`
- **THEN** the result SHALL be `20`

#### Scenario: Thread-as no forms
- **WHEN** evaluating `(as-> :foo v)`
- **THEN** the result SHALL be `:foo`

### Requirement: Package exports
The `->`, `->>`, and `as->` symbols SHALL be exported from both the `clotcad.impl` and `clotcad` packages, making them accessible from `clotcad-user`.

#### Scenario: Symbols accessible in clotcad-user
- **WHEN** checking `(find-symbol "->" :clotcad-user)`
- **THEN** the result SHALL be a symbol accessible in `clotcad-user`

#### Scenario: Symbols exported from clotcad
- **WHEN** checking `(find-symbol "AS->" :clotcad)`
- **THEN** the second value SHALL be `:external`
