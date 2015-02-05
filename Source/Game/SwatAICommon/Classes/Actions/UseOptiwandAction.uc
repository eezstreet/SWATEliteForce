///////////////////////////////////////////////////////////////////////////////
// UseOptiwandAction.uc - UseOptiwandAction class
// this action that causes the AI to use a optiwand

class UseOptiwandAction extends SwatWeaponAction
	native
	config(AI);
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// our weapon
var private HandheldEquipment Optiwand;

// copied from our goal
var(parameters) bool	bUseOverloadedViewOrigin;
var(parameters) vector  OverloadedViewOrigin;
var(parameters) bool	bMirrorAroundCorner;
var(parameters) vector  OptiwandViewDirection;

// who we can see
var array<Pawn>			SeenPawns;

// config
var config float		OptiwandUseTweenTime;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

    ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_FullBody);

	if ((Optiwand != None) && !Optiwand.IsIdle())
	{
		Optiwand.AIInterrupt();
	}

	// make sure the fired weapon is re-equipped
	ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();
}

///////////////////////////////////////////////////////////////////////////////
//
// AI Optiwand Code

private function vector GetOptiwandViewOrigin()
{
	if (bUseOverloadedViewOrigin)
	{
		return OverloadedViewOrigin;
	}
	else
	{
		return Optiwand.GetThirdPersonModel().GetBoneCoords('Lens', true).Origin;
	}
}

native function LookForPawnsUsingOptiwand(vector OptiwandViewOrigin);

///////////////////////////////////////////////////////////////////////////////
//
// Reporting

function ReportSeeingPawns()
{
	local int i, NumEnemies, NumHostages;
	local Pawn SeenPawnIter;

	for(i=0; i<SeenPawns.Length; ++i)
	{
		SeenPawnIter = SeenPawns[i];

		if (SeenPawnIter.IsA('SwatEnemy'))
		{
			NumEnemies++;
		}
		else if (SeenPawnIter.IsA('SwatHostage'))
		{
			NumHostages++;
		}

		// let the shared awareness system know about the seen pawn
		SwatAIRepository(Level.AIRepo).GetHive().GetAwareness().ForceViewerSawPawn(m_Pawn, SeenPawnIter);
	}

	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerOptiwandReportSpeech(NumEnemies, NumHostages);
}

// debug for the log
function DebugSeenPawns()
{
	local int i;

	for(i=0; i<SeenPawns.Length; ++i)
	{
		log("UseOptiwandAction - SeenPawns["$i$"] is: " $ SeenPawns[i].Name);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function EquipOptiwand()
{
	Optiwand = ISwatOfficer(m_Pawn).GetItemAtSlot(Slot_Optiwand);
	assert(Optiwand != None);

	Optiwand.LatentWaitForIdleAndEquip();
}

private function name GetUseOptiwandAnimation()
{
	if (bMirrorAroundCorner)
	{
		return 'sUseOptiwandCorner';
	}
	else
	{
		return 'sUseOptiwand';
	}
}

latent function UseOptiwand()
{
	local int MirroringAnimChannel;

	MirroringAnimChannel = m_Pawn.AnimPlayEquipment(kAPT_Normal, GetUseOptiwandAnimation(), OptiwandUseTweenTime);

	LookForPawnsUsingOptiwand(GetOptiwandViewOrigin());

	m_Pawn.FinishAnim(MirroringAnimChannel);

	ReportSeeingPawns();

	if (m_Pawn.logAI)
		DebugSeenPawns();
}

state Running
{
 Begin:
	EquipOptiwand();
	UseOptiwand();

	ISwatOfficer(m_Pawn).ReEquipFiredWeapon();

	succeed();
}

defaultproperties
{
	satisfiesGoal = class'UseOptiwandGoal'
}