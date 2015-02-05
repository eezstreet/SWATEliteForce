///////////////////////////////////////////////////////////////////////////////
// IInterestedInDoorOpening.uc - the IInterestedInDoorOpening interface
// clients implement and will register with a door to be notified when a door 
// starts opening
interface IInterestedInDoorOpening;
///////////////////////////////////////////////////////////////////////////////

// notification that a door has opened
function NotifyDoorOpening(Door TargetDoor);