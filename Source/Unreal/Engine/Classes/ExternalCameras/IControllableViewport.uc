interface IControllableViewport
	native;

// =============================================================================
// IControllableViewport
//
// An IControllableViewport is an interface for an object that accepts control 
// from the player and can issue commands from viewports location and rotation.
//
// =============================================================================

simulated function OnBeginControlling();
simulated function OnEndControlling();
// What state to put the player into.  This state should be a substate of ControllingViewport, or 
// at the very least put the player into a ControllingViewport substate after it's done.
simulated function name   GetControllingStateName();

// Returns true when this viewport is being controlled
simulated function bool   ShouldControlViewport();

// Return true when this viewport can issue commands
simulated function bool   CanIssueCommands();

// Accept input, NOTE this will only be called while this viewport is controlling the player (ie ShouldControlViewport is true)
simulated function        SetInput(int dMouseX, int dMouseY);

// CalcView function that this viewport uses, the commandinterfaces uses this to find out what location and rotation to 
// issue commands through
simulated function        ViewportCalcView(out Vector CameraLocation, out Rotator CameraRotation);

simulated function        HandleFire();
simulated function        HandleAltFire();
simulated function        HandleReload();

simulated function IControllableThroughViewport GetCurrentControllable();
