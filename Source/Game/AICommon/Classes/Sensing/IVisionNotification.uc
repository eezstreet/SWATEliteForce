///////////////////////////////////////////////////////////////////////////////
// IVisionNotification.uc - IVisionNotification interface
// this interface is used when we want to be a client of the Vision notification system
// clients are stored in the VisionNotifier of an AI

interface IVisionNotification native;

/////////////////////////////////////////////////
/// IVisionNotification Signature
/////////////////////////////////////////////////

function OnViewerSawPawn(Pawn Viewer, Pawn Seen);
function OnViewerLostPawn(Pawn Viewer, Pawn Seen);