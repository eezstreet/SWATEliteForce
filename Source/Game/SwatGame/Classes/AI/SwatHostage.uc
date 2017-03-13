///////////////////////////////////////////////////////////////////////////////
class SwatHostage extends SwatAICharacter
    implements SwatAICommon.ISwatHostage,
               ICanBeSpawned,
               IInterested_GameEvent_ReportableReportedToTOC,
               IInterested_GameEvent_PostGameStarted
    native;

///////////////////////////////////////////////////////////////////////////////

import enum HostageState from SwatAICommon.ISwatHostage;

///////////////////////////////////////////////////////////////////////////////

cpptext
{
    // Will return NULL if this actor has no cover plane, or should not be
    // used as cover. A valid poly's coordinates will be relative to the origin.
    virtual const FPoly * GetCoverPlanePoly() const;
    // If TRUE, the CoverPlane should be rotated about the Z axis as-needed
    virtual UBOOL CanCoverPlaneBillboard() const;
    // Returns TRUE if the cover plane cannot move
    virtual UBOOL IsCoverPlaneStatic() const;

	virtual UBOOL IsOtherActorAThreat(AActor* otherActor);
}

///////////////////////////////////////////////////////////////////////////////

//var private HostageSpawner SpawnedFrom;   //the HostageSpawner that I was spawned from
var private HostageState   CurrentState;
var private bool		   bSpawnedAsIncapacitated;

var private noexport SwatAIData AIData;

///////////////////////////////////////////////////////////////////////////////
//
// Animation

simulated function EAnimationSet GetStandingWalkAnimSet()		{ return kAnimationSetCivilianWalk; }
simulated function EAnimationSet GetStandingRunAnimSet()		{ return kAnimationSetCivilianRun; }
simulated function EAnimationSet GetCrouchingAnimSet()	    { return kAnimationSetCrouching; }

///////////////////////////////////////////////////////////////////////////////
//
// Resource Construction

// Create SwatHostage specific abilities
protected function ConstructCharacterAI()
{
    local AI_Resource characterResource;
    characterResource = AI_Resource(characterAI);
    assert(characterResource != none);

	characterResource.addAbility(new class'SwatAICommon.ComplianceAction');
	characterResource.addAbility(new class'SwatAICommon.HostageCommanderAction');
	characterResource.addAbility(new class'SwatAICommon.HostageSpeechManagerAction');
	characterResource.addAbility(new class'SwatAICommon.FleeAction');
	characterResource.addAbility(new class'SwatAICommon.HostageReactionToOfficersAction');
	characterResource.addAbility(new class'SwatAICommon.CowerAction');
	characterResource.addAbility(new class'SwatAICommon.RestrainedAction');

	// call down the chain
	Super.ConstructCharacterAI();
}

///////////////////////////////////////////////////////////////////////////////
//
// AI Vision

event bool IgnoresSeenPawnsOfType(class<Pawn> SeenType)
{
    // we can see enemies, officers, or players
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatHostage') ||
			ClassIsChildOf(SeenType, class'SwatGame.SwatTrainer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SniperPawn'));
}

function InitializeFromSpawner(Spawner Spawner)
{
    local HostageSpawner HostageSpawner;
    local CharacterArchetypeInstance Archetype;

    Super.InitializeFromSpawner(Spawner);

    SwatGameInfo(Level.Game).GameEvents.ReportableReportedToTOC.Register(self);
    SwatGameInfo(Level.Game).GameEvents.PostGameStarted.Register(self);

    //we may not have a Spawner, for example, if
    //  the console command 'summonarchetype' was used.
    if (Spawner == None) return;

    AIData = new class'SwatGame.SwatAIData';

    Archetype = CharacterArchetypeInstance(GetArchetypeInstance());

    HostageSpawner = HostageSpawner(Spawner);
    assert(HostageSpawner != None);

	// set our idle category (it's ok to be '', which most likely it will be)
	SetIdleCategory(HostageSpawner.IdleCategoryOverride);

  //remember the spawner that I was spawned from
  AIData.SpawnedFrom = HostageSpawner;
	bSpawnedAsIncapacitated = HostageSpawner.SpawnIncapacitated;

  // Assign other important AI datas
  AIData.DOATimer = new class'Timer';
  AIData.DOATimer.TimerDelegate = DoDOAConversion;
  // Don't set the timer just yet

	if (! bSpawnedAsIncapacitated)
	{
		InitializePatrolling(HostageSpawner.HostagePatrol);
	}
	else
	{
		// set our health to be somewhere between the default incapacitated amount and 1
		Health = Rand(IncapacitatedHealthAmount) + 1;

		// incapacitate the hostage
		BecomeIncapacitated(HostageSpawner.IdleCategoryOverride);

    // if we use Static DOA Conversions, set a timer for them to go DOA
    if(Archetype.ConvertsToDOA_Static()) {
        AIData.DOATimer.SetTime(Archetype.GetDOAConversionTime_Static());
    }
	}
}

//
// ICanBeSpawned Implementation
//

function Spawner GetSpawner()
{
    return AIData.SpawnedFrom;
}

///////////////////////////////////////////////////////////////////////////////
//
// DOA conversion

function DoDOAConversion()
{
  log("[DOA Conversions] "$self$" went DOA");
  AIData.TreatAsDOA = true;
  log("[DOA Conversions] TreatAsDOA is now "$AIData.TreatAsDOA);
  TakeDamage(100000, None, vect(0,0,0), vect(0,0,0), class'DamageType');
}

simulated function bool IsDOA()
{
  return AIData.TreatAsDOA;
}

///////////////////////////////////////////////////////////////////////////////
//
// IInterested_GameEvent_ReportableReportedToTOC implementation (part of DOA conversion)

function OnReportableReportedToTOC(IAmReportableCharacter ReportedCharacter, Pawn Reporter)
{
  // Freeze the timer!
  log("[DOA Conversions] "$self$" was reported to TOC, so we can freeze timer "$AIData.DOATimer);
  AIData.DOATimer.TimerDelegate = None;
  AIData.DOATimer.StopTimer();
}

///////////////////////////////////////////////////////////////////////////////
//
// IInterested_GameEvent_GameStarted implementation (part of DOA conversion)

function OnPostGameStarted()
{
  if(bSpawnedAsIncapacitated)
  {
    AIData.DOATimer.StartTimer(, false);
  }
}


///////////////////////////////////////////////////////////////////////////////
//
// Incapacitated

function bool WasHostageSpawnedIncapacitated()
{
	return bSpawnedAsIncapacitated;
}

function NotifyBecameIncapacitated(Pawn Incapacitator)
{
	// notify the commander of the incapacitation
	if (Incapacitator != None)
		NotifyNearbyHostagesOfIncap();

}
simulated function NotifyNearbyHostagesOfIncap()
{
	local Pawn Iter;

	for (Iter = Level.pawnList; Iter != None; Iter = Iter.nextPawn)
	{
		if ((Iter != self) && Iter.IsA('SwatHostage'))
		{
			if (LineOfSightTo(Iter))
			{
				SwatHostage(Iter).GetHostageCommanderAction().NotifyNearbyHostageDowned(self);
			}
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// ISwatHostage implementation

function HostageCommanderAction GetHostageCommanderAction()
{
	return HostageCommanderAction(GetCommanderAction());
}

function HostageSpeechManagerAction GetHostageSpeechManagerAction()
{
	return HostageSpeechManagerAction(GetSpeechManagerAction());
}

function name SpawnedFromGroup()
{
	return GetSpawner().SpawnedFromGroup();
}

function HostageState GetCurrentState()
{
	return CurrentState;
}

function SetCurrentState(HostageState NewState)
{
	CurrentState = NewState;

	// reset the idle category if we aren't unaware
	if (CurrentState != HostageState_Unaware)
	{
		SetIdleCategory('');
	}
}

///////////////////////////////////////

// Provides the effect event name to use when this ai is being reported to
// TOC. Overridden from SwatAI

simulated function name GetEffectEventForReportingToTOCWhenDead()           { return 'ReportedHostageKilled'; }
simulated function name GetEffectEventForReportingToTOCWhenIncapacitated()  { return 'ReportedInjCivilianSecured'; }
simulated function name GetEffectEventForReportingToTOCWhenArrested()       { return 'ReportedCivilianSecured'; }

// Subclasses should override these functions with class-specific response
// effect event names. Overridden from SwatAI
simulated function name GetEffectEventForReportResponseFromTOCWhenIncapacitated()      { return 'RepliedInjHostageReported'; }
simulated function name GetEffectEventForReportResponseFromTOCWhenNotIncapacitated()   { return 'RepliedHostageReported'; }

///////////////////////////////////////////////////////////////////////////////
//
// Misc


// Override superclass method so that in single player games it gives the
// proper name instead of "SwatHostage12" or some other auto-generated name
simulated function String GetHumanReadableName()
{
	if (Level.NetMode == NM_StandAlone)
    {
	    // ckline FIXME: right now we don't have to display a
	    // human-readable name for hostages in single-player games.
		// If it becomes necessary to do this, we should associated a localized
		// human-readable name with each archetype, and then return
		// the human-readable name associated with this pawn's archetype.
		//
		// But for now we're ignoring the problem, and just returning "Hostage".
        return "Hostage";
    }

	// Superclass will deal non-standalone games, etc
    return Super.GetHumanReadableName();
}

simulated function Destroyed()
{
  Super.Destroyed();

  AIData = None;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}
