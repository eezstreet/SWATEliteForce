class Door extends NavigationPoint
	abstract
    native;


// Needed by SwatDoor, but has to go here because we notice when it changes
// from ADoor's PostNetReceive.
enum DoorPosition
{
    DoorPosition_Closed,
    DoorPosition_OpenLeft,
    DoorPosition_OpenRight
};
var DoorPosition DesiredPosition;

#if IG_SWAT_OCCLUSION
var() float SoundPropagationDistancePenalty "Distance this door will add to the attenuation distance for a sound playing behind this door when closed";
#endif

// Note: had to remove private property flag because of cross-package private/protected wackiness...
var DoorPosition PendingPosition "The DoorPosition after the current animation finishes";

// Array of pawns who are currently moving through the door.
var private array<Pawn> CurrentlyMovingThroughDoor;


replication
{
    reliable if ( Role == ROLE_Authority )
        DesiredPosition;
}

// THESE SHOULD NOT BE MADE EVENTS. For speed, native code should access the function
// with the same name on the door object directly.
simulated native function bool IsOpenLeft();
simulated native function bool IsOpenRight();
simulated native function bool IsOpeningLeft();
simulated native function bool IsOpeningRight();
simulated native function bool IsClosed();
simulated native function bool IsClosing();
simulated native function bool IsOpen();
simulated native function bool IsOpening();
simulated native function bool IsBroken();
simulated native function bool IsLocked();
simulated native function bool IsWedged();

simulated function bool IsBoobyTrapped();
simulated function bool IsActivelyTrapped();
simulated function Actor GetTrapOnDoor();
simulated function bool CanBeLocked();
simulated function bool BelievesDoorLocked(Pawn p);

// returns true when this door has no door model (only in SingleDoor)
// returns false all other times
native event bool IsEmptyDoorway();

// Overridden in SwatDoor.
simulated event DesiredPositionChanged();

defaultproperties
{
    bPropagatesSound=true
    SoundPropagationDistancePenalty=700.0
}
