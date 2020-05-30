class ThrownWeapon extends Weapon
    abstract;


var private float ThrowSpeed;                   //set this with SetThrowSpeed() before calling Use()

var config class<Actor> ProjectileClass;

var config name HandsPreThrowAnimation;
var config name ThirdPersonPreThrowAnimation;
var config name FirstPersonPreThrowAnimation;   //the animation that the ThrownWeapon's first-person model should play before thrown, ie. pin-being-pulled
var config name HandsThrowAnimation;
var config name ThirdPersonThrowAnimation;

//clients interested when a grenade is thrown or detonates
var array<IInterestedGrenadeThrowing> InterestedGrenadeRegistrants;

simulated function OnPlayerUse()
{
    Level.GetLocalPlayerController().Throw();
}

function SetThrowSpeed(float inThrowSpeed)
{
    ThrowSpeed = inThrowSpeed;
}

//called from HandheldEquipment::DoUsing()
simulated latent protected function DoUsingHook()
{
    local Hands Hands;
    local Pawn PawnOwner;
    local int PawnThrowAnimationChannel;

    //Play, then finish, animations on pawn, hands, and the models they hold.
    //We need to play both first, then finish both, since finishing happens latently,
    //  and we want them to play simultaneously.

    //pick long-throw/short-throw animations

    PawnOwner = Pawn(Owner);
    Hands = PawnOwner.GetHands();

    //
    // Play
    //

        // Pawn
        PawnThrowAnimationChannel = PawnOwner.AnimPlayEquipment(
			kAPT_Normal,
            GetThirdPersonThrowAnimation(),
            ICanThrowWeapons(PawnOwner).GetPawnThrowTweenTime(),
			ICanThrowWeapons(PawnOwner).GetPawnThrowRootBone());

        // Hands
        if (Hands != None)
            Hands.PlayAnim(GetHandsThrowAnimation(Hands));

    //
    // Finish
    //

        // Pawn
        Pawn(Owner).FinishAnim(PawnThrowAnimationChannel);

        // Hands
        if (Hands != None)
        {
            Hands.FinishAnim();
        }
}

//called from HandheldEquipment::OnUseKeyFrame()
simulated function UsedHook()
{
    local ICanThrowWeapons Holder;
    local vector InitialLocation;
    local rotator ThrownDirection;
	local PlayerController OwnerPC;

    if ( IsAvailable() && Level.NetMode != NM_Client )
    {
        Holder = ICanThrowWeapons(Owner);
        assertWithDescription(Holder != None,
                              "[tcohen] "$class.name$" was notified OnThrown(), but its Owner ("$Owner
                              $") cannot throw weapons.");

        Holder.GetThrownProjectileParams(InitialLocation, ThrownDirection);

		// dbeswick: stats
		OwnerPC = PlayerController(Pawn(Owner).Controller);
		if (OwnerPC != None && !Owner.IsA('SwatAI'))
		{
			OwnerPC.Stats.Used(class.Name);
		}

		SpawnProjectile(InitialLocation, vector(ThrownDirection) * ThrowSpeed);
    }
}

// Allow us to mutate the projectile based on some level specific criteria --eezstreet
function class<actor> MutateProjectile() { return ProjectileClass; }

function Actor SpawnProjectile(vector inLocation, vector inVelocity)
{
    local Actor Projectile;
    local SwatGrenadeProjectile GrenadeProjectile;
	local class<actor> ProjectileClass;

	ProjectileClass = MutateProjectile();

    Projectile = Owner.Spawn(
            ProjectileClass,
            Owner,
            ,                   //tag: default
            inLocation,
            ,                   //SpawnRotation: default
            true);              //bNoCollisionFail

    Projectile.SetInitialVelocity(inVelocity);

    Projectile.TriggerEffectEvent('Thrown');

    GrenadeProjectile = SwatGrenadeProjectile(Projectile);
    if(GrenadeProjectile != None)
    {
      RegisterInterestedGrenadeRegistrantWithProjectile(GrenadeProjectile);
    }

    return Projectile;
}

event Destroyed()
{
    Super.Destroyed();

    //destroy my models
    if (FirstPersonModel != None)
        FirstPersonModel.Destroy();
    if (ThirdPersonModel != None)
        ThirdPersonModel.Destroy();
}

//
// Registering for Grenade Detonation
//

// Register the clients interested in grenade detonation, that are already registered with the weapon,
// on the newly spawned projectile
function RegisterInterestedGrenadeRegistrantWithProjectile(SwatGrenadeProjectile Projectile)
{
	local int i;
	assert(Projectile != None);

	for(i=0; i<InterestedGrenadeRegistrants.Length; ++i)
	{
		Projectile.RegisterInterestedGrenadeRegistrant(InterestedGrenadeRegistrants[i]);
	}
}

// Returns true if the client is already registered on this weapon, false otherwise
private function bool IsAnInterestedGrenadeRegistrant(IInterestedGrenadeThrowing Client)
{
	local int i;

	for(i=0; i<InterestedGrenadeRegistrants.Length; ++i)
	{
		if (InterestedGrenadeRegistrants[i] == Client)
			return true;
	}

	// didn't find it
	return false;
}

function RegisterInterestedGrenadeThrowing(IInterestedGrenadeThrowing Client)
{
	assert(! IsAnInterestedGrenadeRegistrant(Client));

	InterestedGrenadeRegistrants[InterestedGrenadeRegistrants.Length] = Client;
}

function UnRegisterInterestedGrenadeThrowing(IInterestedGrenadeThrowing Client)
{
	local int i;

	for(i=0; i<InterestedGrenadeRegistrants.Length; ++i)
	{
		if (InterestedGrenadeRegistrants[i] == Client)
		{
			InterestedGrenadeRegistrants.Remove(i, 1);
			break;
		}
	}
}

// Animations
simulated function name GetHandsPreThrowAnimation()
{
	if (HandsPreThrowAnimation != '')
		return HandsPreThrowAnimation;
	else
		return Pawn(Owner).GetHands().GetPreThrowAnimation();
}

simulated function name GetFirstPersonPreThrowAnimation()
{
	return FirstPersonPreThrowAnimation;
}

simulated function name GetThirdPersonPreThrowAnimation()
{
	if (ThirdPersonPreThrowAnimation != '')
		return ThirdPersonPreThrowAnimation;
	else
		return ICanThrowWeapons(Owner).GetPreThrowAnimation();
}

simulated function name GetHandsThrowAnimation(Hands Hands)
{
	if (HandsThrowAnimation != '')
		return HandsThrowAnimation;
	else if (Hands != None)
		return Hands.GetThrowAnimation(ThrowSpeed);
}

simulated function name GetThirdPersonThrowAnimation()
{
	if (ThirdPersonThrowAnimation != '')
		return ThirdPersonThrowAnimation;
	else
        return ICanThrowWeapons(Pawn(Owner)).GetThrowAnimation(ThrowSpeed);
}

defaultproperties
{
    UnavailableAfterUsed=true
    bStatic=False
    bBounce=true
    CollisionRadius=5
    CollisionHeight=5
}
