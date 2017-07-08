///////////////////////////////////////////////////////////////////////////////
// VisionSensor.uc - the VisionSensor class
// sensor that keeps track of all currently interesting and visible pawns
// - slightly modified version of the AI_EnemySensor from Marc Atkin in IGA

class VisionSensor extends Tyrion.AI_Sensor implements IVisionNotification;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var array<Pawn> Pawns;							// the pawns this AI is interested in
var Pawn LastPawnSeen;							// last Pawn spotted (cleared if a pawn is lost)
var float LastTimeSeen;							// last time we saw somone
var Pawn LastPawnLost;							// last Pawn lost (cleared if a pawn is spotted)
var vector LastLostPawnLocation;				// the last location the pawn we lost was at
var float LastTimeLost;							// last time we lost someone
var array<Pawn> RecentlyLostPawns;
var array<float> RecentlyLostTimes;

const MaxSecondsConsideredRecent = 5.0;

///////////////////////////////////////////////////////////////////////////////
//
// IVisionNotification implementation

function OnViewerSawPawn(Pawn Viewer, Pawn Seen)
{
	local int i;

	// don't add guys that aren't conscious
	if (! class'Pawn'.static.checkConscious(Seen))
		return;

	// make sure Seen isn't already on the list
	for ( i = 0; i < Pawns.length; i++ )
		if ( Pawns[i] == Seen )
			return;

	Pawns[Pawns.length] = Seen;
	LastPawnSeen = Seen;
	LastPawnLost = None;
	LastTimeSeen = Viewer.Level.TimeSeconds;
	setIntegerValue( Pawns.Length );
	
	cleanOutRecentlyLost(Viewer.Level.TimeSeconds);
}

function OnViewerLostPawn(Pawn Viewer, Pawn Lost)
{
	local int i;
	local int j;
	local bool WasLostRecently;

	// for now: forget about opponents that can't be seen
	for( i = 0; i < Pawns.length; i++ )
	{
		if ( Pawns[i] == Lost )
		{
			Pawns.remove( i, 1 );	// removes element - shifts the rest
			
			LastPawnSeen = None;
			LastPawnLost = Lost;
			LastLostPawnLocation = Lost.Location;
			LastTimeLost = Viewer.Level.TimeSeconds;
			setIntegerValue( Pawns.Length );
			
			for (j = 0; j < RecentlyLostPawns.Length; j++)
			{
				if (RecentlyLostPawns[j] == Lost) 
				{
					WasLostRecently = true;
					break;
				}
			}
			if (!WasLostRecently) 
			{
				RecentlyLostPawns[RecentlyLostPawns.Length] = Lost;
				RecentlyLostTimes[RecentlyLostTimes.Length] = Viewer.Level.TimeSeconds;
			}
			
			break;
		}
	}
	
	cleanOutRecentlyLost(Viewer.Level.TimeSeconds);
}

function cleanOutRecentlyLost(float currentTime)
{
	local int i;
	
	for( i = RecentlyLostPawns.Length - 1; i >= 0; i-- )
	{
		if (currentTime - RecentlyLostTimes[i] >= MaxSecondsConsideredRecent)
		{
			RecentlyLostTimes.remove(i, 1);
			RecentlyLostPawns.remove(i, 1);
		}
	}
}

function bool GetWasLostRecently(Pawn Viewer, Pawn Lost)
{
	local int i;
	
	cleanOutRecentlyLost(Viewer.Level.TimeSeconds);
	
	for (i = 0; i < RecentlyLostPawns.Length; i++)
	{
		//don't return true if the pawn was lost this frame
		if (RecentlyLostPawns[i] == Lost && Viewer.Level.TimeSeconds != RecentlyLostTimes[i])
		{
			return true;
		}
	}
	
	//not found
	return false;
}

///////////////////////////////////////////////////////////////////////////////
//
// Initialization / Cleanup

function begin()
{
	ISwatAI(CommonSensorAction(sensorAction).pawn()).RegisterVisionNotification( self );
}

function cleanup()
{
	ISwatAI(CommonSensorAction(sensorAction).pawn()).UnregisterVisionNotification( self );
}

///////////////////////////////////////////////////////////////////////////////
//
// Queries

function bool IsCurrentlySeen(Pawn TestPawn)
{
	local int i;

	for(i=0; i<Pawns.Length; ++i)
	{
		if (Pawns[i] == TestPawn)
		{
			return true;
		}
	}

	// nope, didn't find 'em
	return false;
}

function Pawn GetVisibleConsciousPawnClosestTo(vector TestLocation, optional name PawnClassType)
{
	local int i;
	local Pawn Closest, Iter;
	local float ClosestDistance, IterDistance;

	for(i=0; i<Pawns.Length; ++i)
	{
		Iter = Pawns[i];

		if (class'Pawn'.static.checkConscious(Iter))
		{
			// make sure iter is of the type we are looking for (if we're looking)
			if ((PawnClassType != '') && !Iter.IsA(PawnClassType))
				continue;

			IterDistance = VSize(TestLocation - Iter.Location);

			if ((Closest == None) || (IterDistance < ClosestDistance))
			{
				Closest         = Iter;
				ClosestDistance = IterDistance;
			}
		}
	}

	return Closest;
}