class StatTracker extends SwatGame.StatTrackerBase
 implements IInterested_GameEvent_PawnIncapacitated,
  IInterested_GameEvent_PawnDied,
  IInterested_GameEvent_PawnArrested,
  IInterested_GameEvent_PawnDamaged,
  IInterested_GameEvent_MissionCompleted,
  IInterested_GameEvent_EvidenceSecured,
  IInterested_GameEvent_ReportableReportedToTOC;

function PostInitHook()
{
  Super.PostInitHook();

  GetGame().GameEvents.EvidenceSecured.Register(Self);
  GetGame().GameEvents.PawnDied.Register(Self);
  GetGame().GameEvents.PawnIncapacitated.Register(Self);
  GetGame().GameEvents.PawnArrested.Register(Self);
  GetGame().GameEvents.MissionCompleted.Register(Self);
  GetGame().GameEvents.PawnDamaged.Register(Self);
  GetGame().GameEvents.ReportableReportedToTOC.Register(self);
}

///////////////////////////////////////
//
// IInterested_GameEvent_PawnDied implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
  if(Pawn.IsA('SwatEnemy')) {
    // Send an enemy killed stat event
    GetGame().CampaignStats_TrackSuspectNeutralized();
  } else {
    OnPawnIncapacitated(Pawn, Killer, WasAThreat); // Treat it like an incapacitation event
  }
}

///////////////////////////////////////
//
// IInterested_GameEvent_PawnArrested implementation
function OnPawnArrested( Pawn Pawn, Pawn Arrester )
{
  if(Pawn.IsA('SwatEnemy')) {
    // Send an enemy arrested stat event
    GetGame().CampaignStats_TrackSuspectArrested();
  } else if(Pawn.IsA('SwatHostage')) {
    // Send a hostage arrested stat event
    GetGame().CampaignStats_TrackCivilianRestrained();
  }
}

///////////////////////////////////////
//
// IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
  if(Pawn.IsA('SwatPlayer')) {
    // Send a player incapacitated stat event
    GetGame().CampaignStats_TrackPlayerIncapacitation();
  } else if(Pawn.IsA('SwatOfficer')) {
    // Send an officer incapacitated stat event
    GetGame().CampaignStats_TrackOfficerIncapacitation();
  } else if(Pawn.IsA('SwatEnemy')) {
    // Send an enemy incapacitated stat event
    GetGame().CampaignStats_TrackSuspectIncapacitated();
  }
}

///////////////////////////////////////
//
// IInterested_GameEvent_PawnDamaged implementation
function OnPawnDamaged(Pawn Pawn, Actor Damager)
{
  if(Pawn.IsA('SwatPlayer')) {
    // Send a player injured stat event
    GetGame().CampaignStats_TrackPlayerInjury();
  }
}

///////////////////////////////////////
//
// IInterested_GameEvent_ReportableReportedToTOC implementation
function OnReportableReportedToTOC(IAmReportableCharacter ReportableCharacter, Pawn Reporter)
{
  // Send a TOC report stat event
  GetGame().CampaignStats_TrackTOCReport();
}

///////////////////////////////////////
//
// IInterested_GameEvent_EvidenceSecured implementation
function OnEvidenceSecured(IEvidence Secured)
{
  // Send an Evidence Secured stat event
  GetGame().CampaignStats_TrackEvidenceSecured();
}

///////////////////////////////////////
//
// IInterested_GameEvent_MissionCompleted implementation
function OnMissionCompleted()
{
  // Send a Mission Complete stat event
  GetGame().CampaignStats_TrackMissionCompleted();
}
