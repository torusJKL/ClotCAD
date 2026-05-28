# face-based-reference-frames Specification

## Purpose
TBD - created by archiving change face-based-reference-frames. Update Purpose after archive.
## Requirements
### Requirement: make-frame-on-face constructs a coordinate frame
The system SHALL provide `(make-frame-on-face face &key u v point)` that returns a coordinate frame object. The frame has an origin and orthonormal X, Y, Z axes derived from the face's geometry.

#### Scenario: Frame from planar face center
- **WHEN** user calls `(make-frame-on-face (top-face :my-box))`
- **THEN** the system returns a frame with:
  - Origin = center of the face
  - Z-axis = face outward normal
  - X-axis = face U-direction at center
  - Y-axis = cross product Z × X (right-handed)
  - All axes are unit vectors

#### Scenario: Frame at specific UV parameters
- **WHEN** user calls `(make-frame-on-face (top-face :my-box) :u 0.0 :v 0.0)`
- **THEN** the system returns a frame whose origin is at the (u=0, v=0) point on the face

#### Scenario: Frame at a 3D point
- **WHEN** user calls `(make-frame-on-face (top-face :my-box) :point '(5 5 10))`
- **THEN** the system projects the 3D point onto the face surface and constructs the frame at the nearest point

#### Scenario: On non-planar face — tangent plane at center
- **WHEN** user calls `(make-frame-on-face (cylindrical-face :my-cylinder))`
- **THEN** the system returns a frame whose Z-axis is the surface normal at the center, X/Y are the tangent plane axes

#### Scenario: On non-planar face without specifying point — succeeds
- **WHEN** user calls `(make-frame-on-face some-cylindrical-face)`
- **THEN** the system succeeds and returns a tangent plane frame at the face center

### Requirement: Frame object has accessors
The system SHALL provide accessors `frame-origin`, `frame-x-axis`, `frame-y-axis`, `frame-z-axis` on frame objects. Each returns a list of three double-float coordinates.

#### Scenario: Access frame components
- **WHEN** user binds `f` to `(make-frame-on-face (top-face :my-box))`
- **THEN** `(frame-origin f)` returns `(5.0 10.0 10.0)`, `(frame-z-axis f)` returns `(0.0 0.0 1.0)`

### Requirement: frame-to-location converts frame to OCCT location
The system SHALL provide `(frame-to-location frame)` that converts a frame to an OCCT `gp_Trsf` (via the existing `make-location` mechanism), suitable for use with `move-shape`.

#### Scenario: Convert frame to location
- **WHEN** user calls `(frame-to-location (make-frame-on-face (top-face :my-box)))`
- **THEN** the system returns a location handle that, when applied, positions a shape at the face origin with the face's orientation

### Requirement: frame-on-plane provides a frame from simple parameters
The system SHALL provide `(make-frame-on-plane origin-x origin-y origin-z normal-x normal-y normal-z &key up-x up-y up-z)` for constructing frames without a face reference.

#### Scenario: Frame on XY plane
- **WHEN** user calls `(make-frame-on-plane 0 0 0 0 0 1)`
- **THEN** the system returns a frame at the origin with Z = (0 0 1), X and Y in the XY plane

#### Scenario: Frame with custom up direction
- **WHEN** user calls `(make-frame-on-plane 0 0 0 1 0 0 :up-x 0 :up-y 0 :up-z 1)`
- **THEN** the system returns a frame with Z = (1 0 0) and Y approximating (0 0 1)

