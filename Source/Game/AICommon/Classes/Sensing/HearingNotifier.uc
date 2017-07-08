///////////////////////////////////////////////////////////////////////////////
// HearingNotifier.uc - HearingNotifier class
// The HearingNotifier notifies all registered clients when the Listener hears a sound
// Clients of the HearingNotifier are stored in the NotificationList, and should be registered through the Pawn

class HearingNotifier extends Core.RefCount
	native;
///////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////
//// Private Variables
/////////////////////////////////////////////////
var private array<IHearingNotification>  NotificationList;
var private Pawn                         Listener;

/////////////////////////////////////////////////
//// Initialization
/////////////////////////////////////////////////
function InitializeHearingNotifier(Pawn InListener)
{
    assert(InListener != None);
    
    Listener = InListener;
}

/////////////////////////////////////////////////
//// Notifications from Pawn
/////////////////////////////////////////////////

// when we hear a sound, let all of the clients know we heard it, 
// whether or not they are interested.
function OnHearSound(Actor SoundMaker, vector SoundOrigin, Name SoundCategory)
{
    local int i;

    for(i=0; i<NotificationList.Length; ++i)
    {
        NotificationList[i].OnListenerHeardNoise(Listener, SoundMaker, SoundOrigin, SoundCategory);
    }
}


/////////////////////////////////////////////////
//// Registration functions
/////////////////////////////////////////////////

// Register to be notified when the Listener hears a noise
function RegisterHearingNotification(IHearingNotification Registrant)
{
    assert(Registrant != None);
    assert(! IsOnHearingNotificationList(Registrant));
    
    // push the registrant onto the notification list
    NotificationList[NotificationList.Length] = Registrant;
}

// Unregister to be notified when the Listener hears a noise
function UnregisterHearingNotification(IHearingNotification Registrant)
{
    local int i;
    
    assert(Registrant != None);

	// commented out for the time being.  Marc suggested that I comment it out.  
	// assertion was being triggered because sensors are being cleaned up twice for some reason. (why?)
//#if !IG_TRIBES3
//    assert(IsOnHearingNotificationList(Registrant));
//#endif
    
    for(i=0; i<NotificationList.Length; ++i)
    {
        if (NotificationList[i] == Registrant)
        {
            NotificationList.Remove(i, 1);
            break;
        }
    }
}

/////////////////////////////////////////////////
//// Vision Notification Private Functions
/////////////////////////////////////////////////

// returns true if the Client interface is on the Hearing notification list
// returns false if the Client interface is not on the Hearing notification list
private function bool IsOnHearingNotificationList(IHearingNotification PossibleRegistrant)
{
    local int i;
    
    for(i=0; i<NotificationList.Length; ++i)
    {
        if (NotificationList[i] == PossibleRegistrant)
        {
            return true;
        }
    }
    
    // PossibleRegistrant not found
    return false;
}