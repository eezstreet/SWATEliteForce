///////////////////////////////////////////////////////////////////////////////
// Base action to allow pawns to randomly look at nearby officers from time
// to time.

class LookAtOfficersActionBase extends SwatCharacterAction
    abstract
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;

///////////////////////////////////////////////////////////////////////////////

var private EUpperBodyAnimBehaviorClientId UpperBodyAnimBehaviorClientId;

var private Pawn  OfficerBeingLookedAt;
var private float TimeStartedLookingAtOfficer;
var private float TimeDurationLookingAtOfficer;
var private float TimeLastLookedAtOfficer;
var private float TimeBetweenLookingAtOfficers;

const kLookAtNearbyOfficerMinDistSq = 90000; // 300 * 300

const kTimeDurationLookingAtOfficerMin =  4.0; // in seconds
const kTimeDurationLookingAtOfficerMax =  6.0; // in seconds

const kTimeBetweenLookingAtOfficersMin =  0.0; // in seconds
const kTimeBetweenLookingAtOfficersMax = 20.0; // in seconds

///////////////////////////////////////////////////////////////////////////////

protected function InitLookAtOfficersActionBase(EUpperBodyAnimBehaviorClientId id)
{
    UpperBodyAnimBehaviorClientId = id;
    // Initialize the first delay before looking at officers
    TimeLastLookedAtOfficer = m_Pawn.Level.TimeSeconds;
    TimeBetweenLookingAtOfficers = RandRange(kTimeBetweenLookingAtOfficersMin, kTimeBetweenLookingAtOfficersMax);
}

///////////////////////////////////////

protected latent function LookAtNearbyOfficers()
{
    local ISwatAI SwatAI;
    SwatAI = ISwatAI(m_Pawn);

    // Make sure the current state's aim poses are swapped in
    m_Pawn.ChangeAnimation();

    // While the pawn is still conscious, have him look at any nearby officers
	while (class'Pawn'.static.checkConscious(m_Pawn))
	{
        CacheNearbyOfficerToLookAt();

        if (OfficerBeingLookedAt != None)
        {
            SwatAI.SetUpperBodyAnimBehavior(kUBAB_AimWeapon, UpperBodyAnimBehaviorClientId);
            SwatAI.AimAtActor(OfficerBeingLookedAt);
        }
        else
        {
            //log("Not looking at officer");
            SwatAI.UnsetUpperBodyAnimBehavior(UpperBodyAnimBehaviorClientId);
            SwatAI.DisableAim();
        }

        // Quick sleep so we're not hogging too much cpu
        Sleep(RandRange(0.2, 0.4));
    }
}

///////////////////////////////////////

private function CacheNearbyOfficerToLookAt()
{
    // If we're currently looking at an officer, decide whether or not we want
    // to continue looking at him (if not, OfficerBeingLookedAt will be set to
    // None).
    if (OfficerBeingLookedAt != None)
    {
        if ((m_Pawn.Level.TimeSeconds - TimeStartedLookingAtOfficer) > TimeDurationLookingAtOfficer)
        {
            OfficerBeingLookedAt = None;
            TimeLastLookedAtOfficer = m_Pawn.Level.TimeSeconds;
            TimeBetweenLookingAtOfficers = RandRange(kTimeBetweenLookingAtOfficersMin, kTimeBetweenLookingAtOfficersMax);
        }
    }

    // If not currently looking at anyone, determine if we should be.
    if (OfficerBeingLookedAt == None)
    {
        if ((m_Pawn.Level.TimeSeconds - TimeLastLookedAtOfficer) > TimeBetweenLookingAtOfficers)
        {
            DetermineAndCacheNearbyOfficerToLookAt();
        }
    }
}

///////////////////////////////////////////////////////////////////////////////

private function DetermineAndCacheNearbyOfficerToLookAt()
{
    local SwatAIRepository SwatAIRepo;
    local array<Pawn> OfficerPawns;
    local Pawn  Officer;
    local float OfficerDistanceSq;
    local Pawn  BestOfficer;
    local float BestOfficerDistanceSq;
    local int i;
    local ISwatAI SwatAI;
	local Controller Iter;
    
	// If in Single Player, add the local player and the officers
	// If in Coop, add the players on the server
	if (Level.NetMode == NM_Standalone)
	{
		SwatAI = ISwatAI(m_Pawn);

		// Get AI officers
		SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);
		OfficerPawns = SwatAIRepo.GetElementSquad().pawns;

		// Add the player pawn to the officer array
		OfficerPawns[OfficerPawns.length] = m_Pawn.Level.GetLocalPlayerController().Pawn;
	}
	else
	{
		// we should be a coop game (and be the server)
		assert(Level.IsCOOPServer);

		for (Iter = Level.ControllerList; Iter != None; Iter = Iter.NextController)
		{
			if (Iter.IsA('PlayerController'))
			{
				OfficerPawns[OfficerPawns.Length] = Iter.Pawn;
			}
		}
	}

	for (i = 0; i < OfficerPawns.length; i++)
	{
		Officer = OfficerPawns[i];

		if (class'Pawn'.static.checkConscious(Officer))
		{
			// If the officer is close enough and conscious, look at him
			OfficerDistanceSq = VDistSquared(m_Pawn.Location, Officer.Location);
			if (OfficerDistanceSq < kLookAtNearbyOfficerMinDistSq && m_Pawn.LineOfSightTo(Officer))
			{
				if (BestOfficer == None || OfficerDistanceSq < BestOfficerDistanceSq)
				{
					BestOfficer = Officer;
					BestOfficerDistanceSq = OfficerDistanceSq;
				}
			}
		}
	}

    OfficerBeingLookedAt = BestOfficer;
    TimeStartedLookingAtOfficer  = m_Pawn.Level.TimeSeconds;
    TimeDurationLookingAtOfficer = RandRange(kTimeDurationLookingAtOfficerMin, kTimeDurationLookingAtOfficerMax);
}

///////////////////////////////////////////////////////////////////////////////
