//=============================================================================
// Mutator.
//
// Mutators allow modifications to gameplay while keeping the game rules intact.  
// Mutators are given the opportunity to modify player login parameters with 
// ModifyLogin(), to modify player pawn properties with ModifyPlayer(), or to modify, remove, 
// or replace all other actors when they are spawned with CheckRelevance(), which 
// is called from the PreBeginPlay() function of all actors except those (Decals, 
// Effects and Projectiles for performance reasons) which have bGameRelevant==true.
//=============================================================================
class Mutator extends Info
	native
	dependson(GameInfo);

var Mutator NextMutator;
var() string            GroupName; // Will only allow one mutator with this tag to be selected.
var() localized string  FriendlyName;
var() localized string  Description;
var bool bUserAdded;

/* Don't call Actor PreBeginPlay() for Mutator 
*/
event PreBeginPlay()
{
	if ( !MutatorIsAllowed() )
		Destroy();
}

function bool MutatorIsAllowed()
{
	return !Level.IsDemoBuild() || Class==class'Mutator';
}

function Destroyed()
{
	local Mutator M;
	
	// remove from mutator list
	if ( Level.Game.BaseMutator == self )
		Level.Game.BaseMutator = NextMutator;
	else
	{
		for ( M=Level.Game.BaseMutator; M!=None; M=M.NextMutator )
			if ( M.NextMutator == self )
			{	
				M.NextMutator = NextMutator;
				break;
			}
	}
	Super.Destroyed();
}

function Mutate(string MutateString, PlayerController Sender)
{
	if ( NextMutator != None )
		NextMutator.Mutate(MutateString, Sender);
}

function ModifyLogin(out string Portal, out string Options)
{
	if ( NextMutator != None )
		NextMutator.ModifyLogin(Portal, Options);
}

/* called by GameInfo.RestartPlayer()
	change the players jumpz, etc. here
*/
function ModifyPlayer(Pawn Other)
{
	if ( NextMutator != None )
		NextMutator.ModifyPlayer(Other);
}

function AddMutator(Mutator M)
{
	if ( NextMutator == None )
		NextMutator = M;
	else
		NextMutator.AddMutator(M);
}

/* ReplaceWith()
Call this function to replace an actor Other with an actor of aClass.
*/
function bool ReplaceWith(actor Other, string aClassName)
{
	local Actor A;
	local class<Actor> aClass;

	if ( aClassName == "" )
		return true;
		
	aClass = class<Actor>(DynamicLoadObject(aClassName, class'Class'));
	if ( aClass != None )
		A = Spawn(aClass,Other.Owner,Other.tag,Other.Location, Other.Rotation);
#if !IG_SWAT // ckline: we don't support pickups
	if ( Other.IsA('Pickup') )
	{
		if ( Pickup(Other).MyMarker != None )
		{
			Pickup(Other).MyMarker.markedItem = Pickup(A);
			if ( Pickup(A) != None )
			{
				Pickup(A).MyMarker = Pickup(Other).MyMarker;
				A.SetLocation(A.Location 
					+ (A.CollisionHeight - Other.CollisionHeight) * vect(0,0,1));
			}
			Pickup(Other).MyMarker = None;
		}
		else if ( A.IsA('Pickup') )
			Pickup(A).Respawntime = 0.0;
	}
#endif
	if ( A != None )
	{
		A.event = Other.event;
		A.tag = Other.tag;
		return true;
	}
	return false;
}

/* Force game to always keep this actor, even if other mutators want to get rid of it
*/
function bool AlwaysKeep(Actor Other)
{
	if ( NextMutator != None )
		return ( NextMutator.AlwaysKeep(Other) );
	return false;
}

function bool IsRelevant(Actor Other, out byte bSuperRelevant)
{
	local bool bResult;

	bResult = CheckReplacement(Other, bSuperRelevant);
	if ( bResult && (NextMutator != None) )
		bResult = NextMutator.IsRelevant(Other, bSuperRelevant);

	return bResult;
}

function bool CheckRelevance(Actor Other)
{
	local bool bResult;
	local byte bSuperRelevant;

	if ( AlwaysKeep(Other) )
		return true;

	// allow mutators to remove actors

	bResult = IsRelevant(Other, bSuperRelevant);

	return bResult;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	return true;
}

//
// Called when a player sucessfully changes to a new class
//
function PlayerChangedClass(Controller aPlayer)
{
	if ( NextMutator != None )
	NextMutator.PlayerChangedClass(aPlayer);
}

//
// server querying
//
function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
	// append the mutator name.
	local int i;
	i = ServerState.ServerInfo.Length;
	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "Mutator";
	ServerState.ServerInfo[i].Value = GetHumanReadableName();
}

function GetServerPlayers( out GameInfo.ServerResponseLine ServerState )
{
}

// jmw - Allow mod authors to hook in to the %X var parsing

function string ParseChatPercVar(Controller Who, string Cmd)
{
	if (NextMutator !=None)
		Cmd = NextMutator.ParseChatPercVar(Who,Cmd);
		
	return Cmd;
}

function ServerTraveling(string URL, bool bItems)
{
	if (NextMutator != None)
    	NextMutator.ServerTraveling(URL,bItems);
}

defaultproperties
{
    GroupName=""
    FriendlyName="Mutator"
    Description="Description"
}

