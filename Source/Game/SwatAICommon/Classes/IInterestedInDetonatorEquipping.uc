///////////////////////////////////////////////////////////////////////////////
// IInterestedInDetonatorEquipping.uc - the IInterestedInDetonatorEquipping interface
// clients implement and will register with the UseBreachingChargeAction to be notified 
// when an officer is going to equip their detonator
interface IInterestedInDetonatorEquipping;
///////////////////////////////////////////////////////////////////////////////

// notification that an Officer is equipping their detonator
function NotifyDetonatorEquipping();