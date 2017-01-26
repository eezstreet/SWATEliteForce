class RoundBasedAmmo extends Engine.SwatAmmo;

var(Ammo) config int DefaultEnemyRounds;
var(Ammo) config int DefaultOfficerRounds;
var(Ammo) config int DefaultBandolierRounds;

var int CurrentRounds;
var int ReserveRounds;

// Ammo and weight related
var int StartingRounds;



replication
{
	// Things the server should send to the client.
	//reliable if( bNetOwner && bNetDirty && (Role==ROLE_Authority) )
	reliable if( bNetInitial && (Role==ROLE_Authority) )
		CurrentRounds, ReserveRounds;
}

simulated function InitializeAmmo(int StartingAmmoAmount) {
	local int AmmoCount;
	local ICarryGuns Pawn;
	local FiredWeapon Weapon;
	local RoundBasedWeapon RBWeapon;

	if(StartingAmmoAmount <= 0) {
		StartingAmmoAmount = 25;
	}

	Weapon = FiredWeapon(Owner);
	RBWeapon = RoundBasedWeapon(Weapon);
	Pawn = ICarryGuns(Weapon.Owner);

	if(!Pawn.IsA('SwatEnemy')) {
		AmmoCount = StartingAmmoAmount;
	} else {
		AmmoCount = DefaultEnemyRounds;
	}

	log("RoundBasedAmmo::InitializeAmmo: "$AmmoCount$" shells");

	ReserveRounds = AmmoCount;
	CurrentRounds = RBWeapon.MagazineSize;
	ReserveRounds -= CurrentRounds;
}

simulated function float GetCurrentAmmoWeight() {
	local int TotalAmmo;

	TotalAmmo = ReserveRounds + CurrentRounds;

	return TotalAmmo * WeightPerReloadLoaded;
}

simulated function float GetCurrentAmmoBulk() {
	return ReserveRounds * BulkPerReload;
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
		LPC.GetHUDPage().UpdateWeight();
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
