class RoundBasedAmmo extends Engine.Ammunition;

var(Ammo) config int DefaultEnemyRounds;
var(Ammo) config int DefaultOfficerRounds;
var(Ammo) config int DefaultBandolierRounds;

var int CurrentRounds;
var int ReserveRounds;


replication
{
	// Things the server should send to the client.
	//reliable if( bNetOwner && bNetDirty && (Role==ROLE_Authority) )
	reliable if( bNetInitial && (Role==ROLE_Authority) )
		CurrentRounds, ReserveRounds;
}


// Executes only on the server.
simulated function Initialize(bool bUsingAmmoBandolier)
{
    local RoundBasedWeapon Weapon;
    local Pawn Pawn;

    Super.Initialize(bUsingAmmoBandolier);

    Weapon = RoundBasedWeapon(Owner);
    assert(Weapon != None);

    Pawn = Pawn(Weapon.Owner);
    assert(Pawn != None);

	if (bUsingAmmoBandolier)
	{
		DefaultEnemyRounds += DefaultBandolierRounds;
		DefaultOfficerRounds += DefaultBandolierRounds;
	}

    if (Pawn.IsA('SwatEnemy'))
        ReserveRounds = DefaultEnemyRounds;
    else
    if (Pawn.IsA('SwatOfficer') || Pawn.IsA('SwatPlayer'))
        ReserveRounds = DefaultOfficerRounds;
    else
        assertWithDescription(false,
            "[tcohen] RoundBasedAmmo::Initialize() (class "$class.name$") expected Pawn Owner to be either a SwatEnemy or a SwatOfficer, but "$Pawn$" is neither. (Owner Weapon is "$Weapon$")");
    
    //we should have enough rounds to initially fill the magazine
    assertWithDescription(ReserveRounds >= Weapon.MagazineSize,
        "[tcohen] RoundBasedAmmo::Initialize() (class "$class.name$") can't fill "$Weapon$"'s Magazine. MagazineSize is "$Weapon.MagazineSize$", but the ammo only has "$ReserveRounds$" rounds.");

    CurrentRounds = Weapon.MagazineSize;
    ReserveRounds -= CurrentRounds;
}

simulated function bool IsEmpty()
{
    return (CurrentRounds == 0 && ReserveRounds == 0);
}

simulated function bool IsFull() 
{
	local RoundBasedWeapon Weapon;

    Weapon = RoundBasedWeapon(Owner);
    assert(Weapon != None);

	return (CurrentRounds == Weapon.MagazineSize);
}

simulated function bool IsLastRound()
{
    return (CurrentRounds == 1);
}

simulated function bool CanReload()
{
    return (ReserveRounds > 0);
}

simulated function bool NeedsReload()
{
    local RoundBasedWeapon Weapon;

    Weapon = RoundBasedWeapon(Owner);
    assert(Weapon != None);

    //we should never have more rounds loaded than the weapon can hold
    assert(CurrentRounds <= Weapon.MagazineSize);

    return (CurrentRounds == 0);
}

simulated function int RoundsRemainingBeforeReload()
{
    return GetCurrentRounds();
}

simulated function OnRoundUsed(Pawn User, Equipment Launcher)
{
	Super.OnRoundUsed(User, Launcher);

	assertWithDescription(CurrentRounds > 0,
        "[tcohen] RoundBasedAmmo::OnRoundUsed() tried to use a round, but the magazine is empty.");

    CurrentRounds--;

    UpdateHUD();
}

simulated function OnReloaded()
{
    local RoundBasedWeapon Weapon;

    Weapon = RoundBasedWeapon(Owner);
    assert(Weapon != None);

    assertWithDescription(ReserveRounds > 0,
        "[tcohen] RoundBasedAmmo::OnReloaded() tried to reload, but it is empty.");

    //if the weapon is fully loaded, then reloading doesn't do anything
    if (CurrentRounds == Weapon.MagazineSize) return;

    CurrentRounds++;

    //TMC in training, don't deduct rounds when reloading
    if (!Level.IsTraining)
        ReserveRounds--;

    UpdateHUD();
}

simulated function UpdateHUD()
{
    local SwatGame.SwatGamePlayerController LPC;

    LPC = SwatGamePlayerController(Level.GetLocalPlayerController());

    if (Pawn(Owner.Owner).Controller != LPC) return; //the player doesn't own this ammo

    LPC.GetHUDPage().AmmoStatus.SetWeaponStatus( self );
}

function int GetCurrentRounds()
{
    return CurrentRounds;
}

function int GetMagazineSize()
{
    local RoundBasedWeapon Weapon;

    Weapon = RoundBasedWeapon(Owner);
    assert(Weapon != None);

    return Weapon.MagazineSize;
}

function int GetReserveRounds()
{
    return ReserveRounds;
}

function int GetInitialReserveRounds()
{
    return DefaultOfficerRounds-GetMagazineSize();
}

simulated function int GetClip( int index ) 
{ 
    if( index == 0 )
        return CurrentRounds;
    else if( index == 1 )
        return ReserveRounds;

    return 0; 
}

simulated function SetClip(int index, int amount)
{
    if( index == 0 )
        CurrentRounds = amount;
    else if( index == 1 )
        ReserveRounds = amount;
}

simulated function int GetCurrentClip()
{
    return -1;
}

simulated function SetCurrentClip(int Clip)
{
    //do nothing
}

defaultproperties
{
	DefaultBandolierRounds=50
}