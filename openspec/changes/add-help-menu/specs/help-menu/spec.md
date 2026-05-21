## ADDED Requirements

### Requirement: Help menu with About item
The system SHALL provide a Help menu in the menu bar with an "About ClotCAD" action that opens an About dialog.

#### Scenario: Help menu exists
- **WHEN** the application starts
- **THEN** the menu bar SHALL contain a "Help" menu

#### Scenario: About item visible in Help menu
- **WHEN** the user opens the "Help" menu
- **THEN** the menu SHALL contain an "About ClotCAD" action

### Requirement: About dialog content
The About dialog SHALL display the ClotCAD logo, application name, a brief description, and clickable links to dependency source repositories.

#### Scenario: Dialog shows logo and app name
- **WHEN** the user clicks "About ClotCAD"
- **THEN** a dialog SHALL open displaying the ClotCAD logo SVG and the application name "ClotCAD"

#### Scenario: Dialog shows description
- **WHEN** the About dialog is open
- **THEN** the dialog SHALL contain a short text describing ClotCAD as a CAD application built on OCCT

#### Scenario: Dialog shows dependency links
- **WHEN** the About dialog is open
- **THEN** the dialog SHALL contain text links to at least the ClotCAD, OCCT, and Qt project source repositories

#### Scenario: Links open in browser
- **WHEN** the user clicks a link in the About dialog
- **THEN** the system SHALL open the link in the default web browser

### Requirement: Dialog dismiss behavior
The About dialog SHALL be modal and closed by the user with a Close button or window manager close.

#### Scenario: Dialog is modal
- **WHEN** the About dialog is open
- **THEN** the dialog SHALL be modal (blocks interaction with the main window)

#### Scenario: Dialog closes
- **WHEN** the user clicks the Close button or presses Escape
- **THEN** the dialog SHALL close and return focus to the main window
