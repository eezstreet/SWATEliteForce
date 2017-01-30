class ClipBasedAmmo extends Engine.SwatAmmo;

var(Ammo) config int ClipSize;
var(Ammo) config int DefaultEnemyClipCount;
var(Ammo) config int DefaultOfficerClipCount;
var(Ammo) config int DefaultBandolierClipCount;

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
		CurrentClip, ClipRoundsRemaining;

    // MCJ: Which is more appropriate, the above or this?
	//reliable if( bNetOwner && bNetDirty && (Role==ROLE_Authority) )
	//	CurrentClip, ClipRoundsRemaining;
}

simulated function InitializeAmmo(int StartingAmmoAmount) {
	local int ClipCount;
	local ICarryGuns Pawn;
	local FiredWeapon Weapon;
	local int i;

	if(StartingAmmoAmount <= 0) {
		StartingAmmoAmount = 5;
	}

	for(i=0; i < MAX_CLIPS; i++) {
		ClipRoundsRemaining[i] = INVALID_CLIP;
	}

	Weapon = FiredWeapon(Owner);
	Pawn = ICarryGuns(Weapon.Owner);

	if(!Pawn.IsA('SwatEnemy')) {
		ClipCount = StartingAmmoAmount;
	} else {
		ClipCount = DefaultEnemyClipCount;
	}

	log("ClipBasedAmmo::InitializeAmmo: "$ClipCount$" clips");

	for(i=0; i < ClipCount; i++) {
		ClipRoundsRemaining[i] = ClipSize;
	}

	StartingClipCount = ClipCount;
}

simulated function float GetCurrentAmmoWeight() {
	local int i;
	local float weight;
	local float amountThisClipAdded;

	for(i=0; i < StartingClipCount; i++) {
		if(ClipRoundsRemaining[i] == ClipSize) {
			weight += WeightPerReloadLoaded;	// Add the weight of a full magazine
		} else {
			weight += WeightPerReloadUnloaded;	// Add the weight of an empty magazine
			if(ClipRoundsRemaining[i] > 0) {
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
    return (FullestClip() > -1);
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

function string GetAmmoCountString()
{
    return GetClip(GetCurrentClip()) $ "/" $ GetMagazineSize();
}

//refill the ammo for the Training mission
function TrainingRefill()
{
    local int i;

    for (i=0; i<DefaultOfficerClipCount; ++i)
        if (i != CurrentClip)
            ClipRoundsRemaining[i] = ClipSize;
}

defaultproperties
{
	DefaultBandolierClipCount=2
}
