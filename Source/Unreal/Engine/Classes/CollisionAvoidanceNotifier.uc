///////////////////////////////////////////////////////////////////////////////
// The CollisionAvoidanceNotifier notifies all registered clients when the Avoider is going to avoid a collision
// Clients of the ShotNotifier are stored in the NotificationList, and should be registered through the Pawn

class CollisionAvoidanceNotifier extends Core.Object;
///////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////
/// Private Variables
/////////////////////////////////////////////////
var private array<ICollisionAvoidanceNotification>  NotificationList;
var private Pawn									Avoider;


/////////////////////////////////////////////////
/// Constructor
/////////////////////////////////////////////////
overloaded function construct( Pawn inAvoider )
{
    assert(inAvoider != None);
    
    Avoider = inAvoider;
}

/////////////////////////////////////////////////
/// Notifications from Pawn
/////////////////////////////////////////////////

// Notify every client on the Notification List that we can see a Pawn
function NotifyBeganCollisionAvoidance()
{
    local int i;

    for( i = 0; i < NotificationList.Length; ++i )
    {
        NotificationList[i].NotifyBeganCollisionAvoidance(Avoider);
    }
}

function NotifyEndedCollisionAvoidance()
{
	local int i;

	for( i = 0; i < NotificationList.Length; ++i )
    {
        NotificationList[i].NotifyEndedCollisionAvoidance(Avoider);
    }
}

/////////////////////////////////////////////////
/// Registration
/////////////////////////////////////////////////

// Register to be notified when a Pawn stops / starts collision avoidance
function RegisterCollisionAvoidanceNotification(ICollisionAvoidanceNotification Registrant)
{
    assert(Registrant != None);
    assert(! IsOnCollisionAvoidanceNotificationList(Registrant));

    NotificationList[NotificationList.Length] = Registrant;
}

// Unregister to be notified when a Pawn stops / starts collision avoidance
function UnregisterCollisionAvoidanceNotification(ICollisionAvoidanceNotification Registrant)
{
    local int i;

    assert(Registrant != None);

    for( i = 0; i < NotificationList.Length; ++i )
    {
        if (NotificationList[i] == Registrant)
        {
            NotificationList.Remove(i, 1);
            break;
        }
    }
}


/////////////////////////////////////////////////
/// Vision Notification Private Functions
/////////////////////////////////////////////////

// returns true if the Client interface is on the Collision Avoidance notification list
// returns false if the Client interface is not on the Collision Avoidance notification list
private function bool IsOnCollisionAvoidanceNotificationList(ICollisionAvoidanceNotification PossibleRegistrant)
{
    local int i;
    
    for( i = 0; i < NotificationList.Length; ++i)
    {
        if ( NotificationList[i] == PossibleRegistrant )
        {
            return true;
        }
    }
    
    // PossibleRegistrant not found
    return false;
}
