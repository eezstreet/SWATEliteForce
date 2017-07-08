///////////////////////////////////////////////////////////////////////////////
// IInterestedGrenadeThrowing.uc - the IInterestedGrenadeThrowing interface
// clients register with a class to be interested when the grenade is ready to 
// throw, when it is thrown, and when it detonates

interface IInterestedGrenadeThrowing;
///////////////////////////////////////////////////////////////////////////////

// notification that a character is ready to throw a grenade
function NotifyGrenadeReadyToThrow();

// notification that a the client has been registered on the projectile
function NotifyRegisteredOnProjectile(SwatGrenadeProjectile Grenade);

// notification that a grenade has detonated
function NotifyGrenadeDetonated(SwatGrenadeProjectile Grenade);