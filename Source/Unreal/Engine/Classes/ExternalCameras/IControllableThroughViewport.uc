interface IControllableThroughViewport;

// =============================================================================
// IControllableThroughViewport
//
// Interface for Actors that can be controlled through a viewport. Currently used
// by the ExternalViewportManager.
//
// =============================================================================

// Owner of the viewport while rendered.
simulated function Actor      GetViewportOwner();

// Name that this controllable class is a subset of, used for filters.
simulated function string     GetViewportType();

// Name to display in the viewport
simulated function string     GetViewportName();

// Extra string description for added info
simulated function string     GetViewportDescription();

// Location to render from, and give commands through
simulated function Vector     GetViewportLocation();

// Rotation to render from, and give commands through
simulated function Rotator    GetViewportDirection();

// Return the original rotation...
simulated function Rotator    GetOriginalDirection();

// For controlling...
simulated function float      GetViewportPitchSpeed();

// For controlling...
simulated function float      GetViewportYawSpeed();

// Called to allow the viewport to modify mouse acceleration
simulated function            AdjustMouseAcceleration( out Vector MouseAccel );

// Called whenever the mouse is moving (and this controllable is being controlled)
simulated function            OnMouseAccelerated( out Vector MouseAccel );

// Possibly offset from the controlled direction
simulated function            OffsetViewportRotation( out Rotator ViewportRotation );

// Notifications for beginning controlling
simulated function            OnBeginControlling();

// Notifications for ending controlling
simulated function            OnEndControlling();

// The amount of degrees that the camera can pitch when controlled
simulated function float      GetViewportPitchClamp();

// The amount of degrees that the camera can yaw when controlled
simulated function float      GetViewportYawClamp();

// Allow the implementor to do something with a new rotation
simulated function            SetRotationToViewport(Rotator inNewRotation);

// True if this viewport should be drawn
simulated function bool       ShouldDrawViewport();

// Should this view have a reticle?
simulated function bool       ShouldDrawReticle();

// Optionally return an overlay for the viewport
simulated function Material   GetViewportOverlay();

// Returns the FOV to render the viewport
simulated function float      GetFOV();

// Allow implementor to handle Reload()ing
simulated function            HandleReload();

// Allow implementor to handle Fire()ing
simulated function            HandleFire();

// Allow implementor to handle AltFire()ing
simulated function            HandleAltFire();

// True if this viewport is allowed to issue commands
simulated function bool       CanIssueCommands();
