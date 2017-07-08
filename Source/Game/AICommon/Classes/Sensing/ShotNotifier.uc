///////////////////////////////////////////////////////////////////////////////
// The ShotNotifier notifies all registered clients when the Shooter fires a weapon
// Clients of the ShotNotifier are stored in the NotificationList, and should be registered through the Pawn

class ShotNotifier extends Core.Object
	native;
///////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////
/// Private Variables
/////////////////////////////////////////////////
var private array<IShotNotification>  NotificationList;
var private Pawn                      Shooter;


/////////////////////////////////////////////////
/// Initialization
/////////////////////////////////////////////////
function InitializeShotNotifier(Pawn shooter)
{
    assert(shooter != None);
    
    self.Shooter = shooter;
}

/////////////////////////////////////////////////
/// Notifications from Pawn
/////////////////////////////////////////////////

// The Shooter's weapon code will call this function when it fires its weapon
function OnShotFired( Actor projectile )
{
     NotifyShotFired( projectile );
}

// Notify every client on the Notification List that we can see a Pawn
private function NotifyShotFired( Actor projectile )
{
    local int i;

    for( i = 0; i < NotificationList.Length; ++i )
    {
        NotificationList[i].OnShooterFiredShot( Shooter, projectile );
    }
}

/////////////////////////////////////////////////
/// Registration functions
/////////////////////////////////////////////////

// Register to be notified when the shooter shoots
function RegisterShotNotification(IShotNotification Registrant)
{
	local int i;		// debug

    assert(Registrant != None);

	if ( IsOnShotNotificationList(Registrant) )
	{
		log( "AI ERROR:" @ Registrant @ "has already registered for" @ shooter.name );
		for( i = 0; i < NotificationList.Length; ++i )
			log( "   " @ NotificationList[i] );
    }
    
    assert(! IsOnShotNotificationList(Registrant));

    NotificationList[NotificationList.Length] = Registrant;
}

// Unregister to be notified when the shooter shoots
function UnregisterShotNotification(IShotNotification Registrant)
{
    local int i;
   
	if ( Registrant == None )
		log( "AI WARNING:" @ self @ "has 'None' Registrant" );
    assert(Registrant != None);

#if !IG_TRIBES3
	if ( !IsOnShotNotificationList(Registrant) )
		log( "AI WARNING:" @ self @ Registrant @ "not on notification list" );
	assert(IsOnShotNotificationList(Registrant));
#endif

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
/// Shot Notification Private Functions
/////////////////////////////////////////////////

// returns true if the Client interface is on the Shot notification list
// returns false if the Client interface is not on the Shot notification list
private function bool IsOnShotNotificationList(IShotNotification PossibleRegistrant)
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
