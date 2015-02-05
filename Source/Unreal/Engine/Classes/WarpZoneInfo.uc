//=============================================================================
// WarpZoneInfo. For making disjoint spaces appear as if they were connected;
// supports both in-level warp zones and cross-level warp zones.
//=============================================================================
class WarpZoneInfo extends ZoneInfo
	native;

//-----------------------------------------------------------------------------
// Information set by the level designer.

var() string     OtherSideURL;
var() name       ThisTag;
var() bool		 bNoTeleFrag;

//-----------------------------------------------------------------------------
// Internal.

var const int              iWarpZone;
var const coords           WarpCoords;
var transient WarpZoneInfo OtherSideActor;
var transient Core.Object  OtherSideLevel;
var() string		       Destinations[8];
var int					   numDestinations;

//-----------------------------------------------------------------------------
// Network replication.

replication
{
	reliable if( Role==ROLE_Authority )
		OtherSideURL, ThisTag, OtherSideActor;
}

//-----------------------------------------------------------------------------
// Functions.

// Warp coordinate system transformations.
native(314) final function Warp  ( out vector Loc, out vector Vel, out rotator R );
native(315) final function UnWarp( out vector Loc, out vector Vel, out rotator R );

function PreBeginPlay()
{
	Super.PreBeginPlay();

	// Generate the local connection.
	Generate();

	// Setup destination list.
	numDestinations = 0;
	While( numDestinations < 8 )
		if (Destinations[numDestinations] != "")
			numDestinations++;
		else
			numDestinations = 8;

	// Generate URL if necessary.
	if( numDestinations>0 && (OtherSideURL == "") )
		OtherSideURL = Destinations[0];
}

function Trigger( actor Other, pawn EventInstigator )
{
	local int nextPick;
	if (numDestinations == 0)
		return;
	
	nextPick = 0;
	While( (nextPick < 8) && (Destinations[nextPick] != OtherSideURL )  )
		nextPick++;

	nextPick++;
	if ( (nextPick > 7) || (Destinations[nextPick] == "") )
		nextPick = 0;
	
	OtherSideURL = Destinations[nextPick];
	ForceGenerate();
}

// Set up this warp zone's destination.
simulated event Generate()
{
	if( OtherSideLevel != None )
		return;
	ForceGenerate();
}

// Set up this warp zone's destination.
simulated event ForceGenerate()
{
	if( InStr(OtherSideURL,"/") >= 0 )
	{
		// Remote level.
		//log( "Warpzone " $ Self $ " remote" );
		OtherSideLevel = None;
		OtherSideActor = None;
	}
	else
	{
		// Local level.
		OtherSideLevel = XLevel;
		foreach AllActors( class 'WarpZoneInfo', OtherSideActor )
			if( string(OtherSideActor.ThisTag)~=OtherSideURL && OtherSideActor!=Self )
				break;
		//log( "Warpzone " $ Self $ " local, connected to " $ OtherSideActor );
	}
}

// When an actor enters this warp zone.
simulated function ActorEntered( actor Other )
{
	local vector L;
	local rotator R;
	local Controller P;

	//if ( Other.Role == ROLE_AutonomousProxy )
	//	return; // don't simulate for client players
	if( !Other.bJustTeleported )
	{
		Generate();
		if( OtherSideActor != None )
		{
			// This needs to also perform a coordinate system transformation,
			// in case the portals aren't directionally aligned. This is easy to
			// do but UnrealScript doesn't provide coordinate system operators yet.
			Other.Disable('Touch');
			Other.Disable('UnTouch');

			L = Other.Location;
			if( Pawn(Other) != None )
				R = Pawn(Other).GetViewRotation();

			UnWarp( L, Other.Velocity, R );
			OtherSideActor.Warp( L, Other.Velocity, R );

			if( Other.IsA('Pawn') )
			{
				Pawn(Other).bWarping = bNoTelefrag;
				if ( Other.SetLocation(L) )
				{
					//tell enemies about teleport
					if ( Role == ROLE_Authority )
						For ( P=Level.ControllerList; P!=None; P=P.NextController )
							if (P.Enemy == Other)
								P.LineOfSightTo(Other); 
					R.Roll = 0;
					Pawn(Other).SetViewRotation(R);
					Pawn(Other).ClientSetLocation(L, R );
					if ( Pawn(Other).Controller != None )
						Pawn(Other).Controller.MoveTimer = -1.0;
				}
				else
				{
					// set up to keep trying to teleport
					GotoState('DelayedWarp');
				}
			}
			else
			{
				Other.SetLocation(L);
				Other.SetRotation( R );
			}
			Other.Enable('Touch');
			Other.Enable('UnTouch');
			// Change rotation according to portal's rotational change.
		}
	}
}

event ActorLeaving( actor Other )
{
	If ( Other.IsA('Pawn') )
		Pawn(Other).bWarping = false;
}

State DelayedWarp
{
	function Tick(float DeltaTime)
	{
		local Controller P;
		local bool bFound;

		For ( P=Level.ControllerList; P!=None; P=P.NextController )
			if ( P.Pawn.bWarping && (P.Pawn.Region.Zone == Self) )
			{
				bFound = true;
				ActorEntered(P);
			}

		If ( !bFound )
			GotoState('');
	}
}

defaultproperties
{
}
