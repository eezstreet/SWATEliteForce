///////////////////////////////////////////////////////////////////////////////
// VisionNotifier.uc - VisionNotifier class
// The VisionNotifier notifies all registered clients when the Viewer sees or no longer sees another Pawn
// Clients of the VisionNotifier are stored in the NotificationList, and should be registered through the Pawn

class VisionNotifier extends Core.RefCount
	implements Engine.IInterestedPawnDied
	native
	noexport;
///////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////
/// Private Variables
/////////////////////////////////////////////////

// the viewer is the pawn that we are doing the vision for
var Pawn						        Viewer;

// These are placeholders for native TSets
//
// We need to serialize (some of) these natively to ensure 
// references are counted properly during Garbage Collection
var transient const private int			SeenListPadding;
var transient const private int			CurrentSeenListPadding;
var transient const private int			NotificationListPadding;


/////////////////////////////////////////////////
/// Initialization
/////////////////////////////////////////////////
function InitializeVisionNotifier(Pawn InViewer)
{
    assert(InViewer != None);
    
    Viewer = InViewer;

	// register to find out when a pawn dies or is destroyed
	Viewer.Level.RegisterNotifyPawnDied(self);
}

function CleanupVisionNotifier()
{
	// unregister finding out when a pawn dies or is destroyed
	Viewer.Level.UnRegisterNotifyPawnDied(self);
}

/////////////////////////////////////////////////
/// Death / Destruction Notifications
/////////////////////////////////////////////////

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	if (ActorBeingDestroyed.IsA('Pawn'))
	{
		RemoveAnyReferencesToPawn(Pawn(ActorBeingDestroyed));
	}
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	RemoveAnyReferencesToPawn(DeadPawn);
}

protected native function RemoveAnyReferencesToPawn(Pawn PawnBeingRemoved);

/////////////////////////////////////////////////
/// Notifications from Pawn
/////////////////////////////////////////////////

// returns true if the specified pawn can currently be seen
function bool isVisible(Pawn TestPawn)
{
	return IsOnSeenList(TestPawn);
}

// returns true if the Pawn can be found in the CurrentSeenList
// returns false if the Pawn cannot be found in the CurrentSeenList
protected native function bool IsOnCurrentSeenList(Pawn TestPawn);

// returns true if the Pawn can be found in the SeenList
// returns false if the Pawn cannot be found in the SeenList
protected native function bool IsOnSeenList(Pawn TestPawn);

/////////////////////////////////////////////////
//// Registration functions
/////////////////////////////////////////////////

native function RegisterVisionNotification(IVisionNotification Registrant);
native function UnregisterVisionNotification(IVisionNotification Registrant);

/////////////////////////////////////////////////
// Vision debug
////////////////////////////////////////////////

native function logSeenList();
