// SwatRepoPlayerItem.uc
//
// Each player connected to the server has one of these items in the
// SwatRepo (but only in the server's repo, not the client's repo).
//

class SwatRepoPlayerItem extends Core.Object
    ;

import enum Pocket from Engine.HandheldEquipment;


//
// Member variables
//
var int SwatPlayerID;
var int TeamID;
var private int PreferredTeamID;

// Note: If bHasEnteredFirstRound is true, it means that the player has
// already entered a round and had its pawn created. If it is false, it means
// that the player has not yet entered a round (which likely means the player
// joined the game after a round had started, and is currently spectating
// until the round ends).
var bool bHasEnteredFirstRound;

// This is false until an entire loadout spec has been set, indicating that
//   this player is ready to spawn
var bool bIsReadyToSpawn;

// Represents whether a player entering a game was present in the previous
// round of the game (see SwatRepo.SetTravellingToNewRound()).
var bool bIsAReconnectingClient;

// true if the player is currently connected, but false if we are between
// rounds and the player has disconnected and trying to reconnect.
var bool bConnected;

// true if the player is muted
var bool bMuted;

// true if the player is forced to a less lethal loadout
var bool bForcedLessLethal;

var class<actor> RepoLoadOutSpec[Pocket.EnumCount];
var int RepoLoadOutPrimaryWeaponAmmo;
var int RepoLoadOutSecondaryWeaponAmmo;

var String CustomSkinClassName;

//last admin password used
var String LastAdminPassword;


//
// Member functions
//
function SetPrimaryAmmoCount(int amount) {
  RepoLoadOutPrimaryWeaponAmmo = amount;
}

function SetSecondaryAmmoCount(int amount) {
  RepoLoadOutSecondaryWeaponAmmo = amount;
}

function SetPocketItemClass( Pocket Pocket, class<actor> ItemClass )
{
    //log( self$" in SwatRepoPlayerItem::SetPocketItemClass(). Pocket="$Pocket$", Item="$ItemClass );
	if(bForcedLessLethal)
	{
		return;
	}

	RepoLoadOutSpec[ Pocket ] = ItemClass;
}


function SetPocketItemClassName( Pocket Pocket, string ItemClassName )
{
    local class<actor> ItemClass;

    //log( self$" in SwatRepoPlayerItem::SetPocketItemClassName(). Pocket="$Pocket$", ItemClassName="$ItemClassName );

    if ( ItemClassName != "" )
    {
        ItemClass = class<HandheldEquipment>(DynamicLoadObject(ItemClassName, class'Class'));
    }

	if(bForcedLessLethal)
	{
		return;
	}
	
    SetPocketItemClass( Pocket, ItemClass );
}


function SetCustomSkinClassName( String NewCustomSkinClassName )
{
	CustomSkinClassName = NewCustomSkinClassName;
}


function class<actor> GetPocketItem( Pocket Pocket )
{
    //log( self$" in SwatRepoPlayerItem::GetPocketItem(). Pocket="$Pocket );
    return RepoLoadOutSpec[ Pocket ];
}

function int GetPrimaryAmmoCount()
{
  return RepoLoadOutPrimaryWeaponAmmo;
}

function int GetSecondaryAmmoCount()
{
  return RepoLoadOutSecondaryWeaponAmmo;
}


simulated function PrintLoadOutSpecToMPLog()
{
    local int i;

    mplog( "LoadOutSpec contains:" );

    for ( i = 0; i < Pocket.EnumCount; i++ )
    {
        mplog( "...RepoLoadOutSpec["$GetEnum(Pocket,i)$"]="$RepoLoadOutSpec[i] );
    }
}


function SetTeamID( int NewTeamID )
{
    log( self$" in SwatRepoPlayerItem::SetTeamID(). TeamID="$TeamID );
    TeamID = NewTeamID;
}


function int GetTeamID()
{
    log( self$" in SwatRepoPlayerItem::GetTeamID(). TeamID="$TeamID );
    return TeamID;
}

function SetPreferredTeamID( int NewPreferredTeamID )
{
    PreferredTeamID = NewPreferredTeamID;
    log( self$" in SwatRepoPlayerItem::SetPreferredTeamID(). PreferredTeamID="$PreferredTeamID );
}


function int GetPreferredTeamID()
{
    log( self$" in SwatRepoPlayerItem::GetPreferredTeamID(). PreferredTeamID="$PreferredTeamID );
    return PreferredTeamID;
}


function SetHasEnteredFirstRound()
{
    bHasEnteredFirstRound = true;
}

function bool HasEnteredFirstRound()
{
    return bHasEnteredFirstRound;
}

function SetReadyToSpawn()
{
    bIsReadyToSpawn = true;
}

function bool IsReadyToSpawn()
{
    return bIsReadyToSpawn;
}


defaultproperties
{
}
