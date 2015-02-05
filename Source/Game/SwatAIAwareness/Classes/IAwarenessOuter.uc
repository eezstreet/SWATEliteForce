///////////////////////////////////////////////////////////////////////////////
//
// The pawn containing an awareness object should implement this interface,
// so awareness can ask it certain things.
//

interface IAwarenessOuter native;

///////////////////////////////////////////////////////////////////////////////

// Sensing registration methods. Allows the awareness object to register
// itself with for receiving vision and hearing notifications from the outer
// object.

function RegisterVisionNotification(IVisionNotification Registrant);
function UnregisterVisionNotification(IVisionNotification Registrant);
function RegisterHearingNotification(IHearingNotification Registrant);
function UnregisterHearingNotification(IHearingNotification Registrant);

///////////////////////////////////////

function bool IsOtherActorAThreat(Actor otherActor);
function bool GetKnownLocationOfPawn(Pawn otherPawn, out vector location);

///////////////////////////////////////////////////////////////////////////////
