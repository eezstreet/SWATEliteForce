///////////////////////////////////////////////////////////////////////////////
// ICollisionAvoidanceNotification.uc - the ICollisionAvoidanceNotification interface
// this interface specifies that this object is interested in a notification when Collision Avoidance
// starts and stops

interface ICollisionAvoidanceNotification;

function NotifyBeganCollisionAvoidance(Pawn Avoider);
function NotifyEndedCollisionAvoidance(Pawn Avoider);