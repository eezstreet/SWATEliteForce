class ClipBasedAmmo extends Engine.SwatAmmo;

var(Ammo) config int ClipSize "The number of bullets in a clip";
var(Ammo) config int DefaultEnemyClipCount "The number of clips of this ammunition that a suspect will carry (by default)";

// Dynamic arrays don't replicate, so I'm converting this to a static array.
//var array<int> ClipRoundsRemaining;

const MAX_CLIPS = 10;   // 10 should be greater than the number of clips we would need.
const INVALID_CLIP = -2;
var private int ClipRoundsRemaining[MAX_CLIPS];
var private int CurrentClip;
var private int StartingClipCount;


replication
{
	// Things the server should send to the client.
	unreliable if ( (!bSkipActorPropertyReplication || bNetInitial) && bReplicateMovement
					&& (((RemoteRole == ROLE_AutonomousProxy) && bNetInitial)
						|| ((RemoteRole == ROLE_SimulatedProxy) && (bNetInitial || bUpdateSimulatedPosition) && ((Base == None) || Base.bWorldGeometry))
						|| ((RemoteRole == ROLE_DumbProxy) && ((Base == None) || Base.bWorldGeometry))) )
		CurrentClip, ClipRoundsRemaining, StartingClipCount;

    // MCJ: Which is more appropriate, the above or this?
	//reliable if( bNetOwner && bNetDirty && (Role==ROLE_Authority) )
	//	CurrentClip, ClipRoundsRemaining;
}

simulated function InitializeAmmo(int StartingAmmoAmount) {
	local int ClipCount;
	local ICarryGuns Pawn;
	local FiredWeapon Weapon;
	local int i;

	Weapon = FiredWeapon(Owner);
	Pawn = ICarryGuns(Weapon.Owner);

	// Validate clip count
	if(Pawn.IsA('SwatEnemy'))
	{
		StartingAmmoAmount = DefaultEnemyClipCount;
	}
	else if(StartingAmmoAmount <= 0)
	{
		StartingAmmoAmount = 5;
	}
	else if(StartingAmmoAmount > 10)
	{
		StartingAmmoAmount = 10;
	}

	// Initialize clip amount
	ClipCount = StartingAmmoAmount;
	StartingClipCount = ClipCount;
	log("ClipBasedAmmo::InitializeAmmo: "$ClipCount$" clips");

	// Set ammo for each clip. On each clip set it to ClipSize but INVALID_CLIP on ones we don't have
	for(i=0; i < MAX_CLIPS; i++)
	{
		if(i >= StartingClipCount)
		{
			ClipRoundsRemaining[i] = INVALID_CLIP;
		}
		else
		{
			ClipRoundsRemaining[i] = ClipSize;
		}
	}
}

simulated function float GetCurrentAmmoWeight() {
	local int i;
	local float weight;
	local float amountThisClipAdded;

	for(i=0; i < StartingClipCount; i++)
	{
		if(ClipRoundsRemaining[i] == ClipSize)
		{
			weight += WeightPerReloadLoaded;	// Add the weight of a full magazine
		}
		else
		{
			weight += WeightPerReloadUnloaded;	// Add the weight of an empty magazine
			if(ClipRoundsRemaining[i] > 0)
			{
				// Add the weight of the bullets in the magazine
				amountThisClipAdded = ((WeightPerReloadLoaded - WeightPerReloadUnloaded) / ClipSize) * ClipRoundsRemaining[i];
				weight += amountThisClipAdded;
			}
		}
	}

	return weight;
}

simulated function float GetCurrentAmmoBulk() {
	return (StartingClipCount - 1) * BulkPerReload; // The magazine is factored into the bulk of the weapon, so we subtract one
}

simulated function bool IsEmpty()
{
    return (FullestClip() == -1);
}

simulated function bool IsFull()
{
	return (ClipRoundsRemaining[CurrentClip] == ClipSize);
}


simulated function bool IsLastRound()
{
    return (ClipRoundsRemaining[CurrentClip] == 1);
}

simulated function bool CanReload()
{
	local int DesiredClip;

	DesiredClip = FullestClip();

	// SEF: don't allow reloading if we would be reloading back into our current clip
	return (DesiredClip > -1 && DesiredClip != CurrentClip);
}

//returns -1 if no clip has any rounds remaining
simulated function int FullestClip()
{
    local int i;
    local int Max;
    local int Clip;

    Clip = -1;

    for (i=0; (i < MAX_CLIPS) && (ClipRoundsRemaining[i] != INVALID_CLIP); ++i)
    {
        if (ClipRoundsRemaining[i] > Max)
        {
            Max = ClipRoundsRemaining[i];
            Clip = i;
        }
    }

    return Clip;
}

simulated function bool NeedsReload()
{
    assert(ClipRoundsRemaining[CurrentClip] >= 0 && ClipRoundsRemaining[CurrentClip] <= ClipSize);

    return (ClipRoundsRemaining[CurrentClip] == 0);
}

simulated function bool ShouldReload()
{
    assert(ClipRoundsRemaining[CurrentClip] >= 0 && ClipRoundsRemaining[CurrentClip] <= ClipSize);

    return (ClipRoundsRemaining[CurrentClip] <= ClipSize/2);
}

simulated function OnRoundUsed(Pawn User, Equipment Launcher)
{
	Super.OnRoundUsed(User, Launcher);

    assertWithDescription(ClipRoundsRemaining[CurrentClip] > 0,
        "[tcohen] ClipBasedAmmo::OnRoundUsed() tried to use a round, but the current clip is empty.");

    ClipRoundsRemaining[CurrentClip]--;

    if (Level.IsTraining && IsEmpty())
        TrainingRefill();

    UpdateHUD();
}

simulated function int GetCurrentClip()
{
    return CurrentClip;
}

simulated function SetCurrentClip(int Clip)
{
    CurrentClip = Clip;
}

simulated function OnReloaded()
{
    local int NewClip;

    assertWithDescription(!IsEmpty(),
        "[tcohen] ClipBasedAmmo::OnReloaded() tried to reload, but it is empty.");

    NewClip = FullestClip();
    assert(NewClip > -1);   //since we're not empty, there should be a Z+ FullestClip

	//if the weapon is not empty , leave a round in the chamber in the new clip and remove one in the current clip
	if (ClipRoundsremaining[currentClip] > 0 )
	{
		ClipRoundsremaining[currentClip] = ClipRoundsremaining[currentClip] -1;
		ClipRoundsremaining[NewClip] = ClipRoundsremaining[NewClip] + 1;
	}	
	
    CurrentClip = NewClip;

    UpdateHUD();
}

simulated function UpdateHUD()
{
    local SwatGame.SwatGamePlayerController LPC;

    LPC = SwatGamePlayerController(Level.GetLocalPlayerController());

    if (Pawn(Owner.Owner).Controller != LPC) return; //the player doesn't own this ammo

    LPC.GetHUDPage().AmmoStatus.SetWeaponStatus( self );
		LPC.GetHUDPage().UpdateWeight();
}

function int GetMagazineSize()
{
    return ClipSize;
}

function int GetClipCount()
{
    return StartingClipCount;
}

simulated function int GetClip(int index)
{
    return ClipRoundsRemaining[index];
}

simulated function SetClip(int index, int amount)
{
    ClipRoundsRemaining[index] = amount;
}

simulated function int RoundsRemainingBeforeReload()
{
    return GetClip(CurrentClip);
}

simulated function int RoundsComparedBeforeReload()
{
    return ClipSize;
}

function string GetAmmoCountString()
{
    return GetClip(GetCurrentClip()) $ "/" $ GetMagazineSize();
}

//refill the ammo for the Training mission
function TrainingRefill()
{
    local int i;

    for (i=0; i<MAX_CLIPS; ++i)
        if (i != CurrentClip)
            ClipRoundsRemaining[i] = ClipSize;
}
