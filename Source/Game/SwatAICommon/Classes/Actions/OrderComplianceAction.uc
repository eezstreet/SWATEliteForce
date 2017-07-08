///////////////////////////////////////////////////////////////////////////////
// OrderComplianceAction.uc - EngageTargetAction class
// The Action that causes an Officer AI to engage a target for compliance

class OrderComplianceAction extends SwatWeaponAction
	implements Tyrion.ISensorNotification
	config(AI)
    dependson(ISwatAI)
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehavior from ISwatAI;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;
import enum EComplianceWeaponAnimation from SwatWeapon;


///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Pawn	TargetPawn;

// our sensors
var CompliantSensor		CompliantSensor;

// internal
var private float		TimeToStopTryingToEngage;

// config variables
var config float		MaximumTimeToWaitToEngage;

var config float		MinComplianceOrderSleepTime;
var config float		MaxComplianceOrderSleepTime;

var config float		MinComplianceWaitTime;
var config float		MaxComplianceWaitTime;

var config array<name>	ComplyMGOrderAnims;
var config array<name>	ComplySGOrderAnims;
var config array<name>	ComplySMGOrderAnims;
var config array<name>	ComplyHGOrderAnims;
var config array<name>	ComplyPepperBallOrderAnims;

const kMinOrderComplyTime = 0.5;
const kMaxOrderComplyTime = 1.0;
const kPlayOrderComplianceAnimation = 0.375;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	// set the initial amount of time
	SetTimeToStopTryingToEngage();

	ActivateComplianceSensor();

	assert(MinComplianceOrderSleepTime > 0.0);
	assert(MaxComplianceOrderSleepTime > 0.0);
}

private function ActivateComplianceSensor()
{
	assert(TargetPawn != None);

	// Note that the CompliantSensor is on the character resource rather than the weapon resource
	// TODO: determine if that is the correct way to do things. [crombie]
	CompliantSensor = CompliantSensor(class'AI_Sensor'.static.activateSensor( self, class'CompliantSensor', characterResource(), 0, 1000000 ));
	CompliantSensor.setParameters( TargetPawn );
}

private latent function SetOrderComplianceAim()
{
	ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_OrderComplianceAction);

	// @HACK: See comments in ISwatAI::LockAim for more info.
	ISwatAI(m_Pawn).AimAtActor(TargetPawn);
	ISwatAI(m_Pawn).LockAim();

	// just make sure we're aimed at him
	LatentAimAtActor(TargetPawn);
}

private function UnsetOrderComplianceAim()
{
	// @HACK: See comments in ISwatAI::UnlockAim for more info.
	ISwatAI(m_Pawn).UnlockAim();

	// we're no longer aiming at someone
    ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_OrderComplianceAction);
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CompliantSensor != None)
	{
		CompliantSensor.deactivateSensor(self);
		CompliantSensor = None;
	}

	UnsetOrderComplianceAim();
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensor Messages

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	if (m_Pawn.logTyrion)
		log("OrderComplianceAction received sensor message from " $ sensor.name $ " value is "$ value.integerData);

	// the message could be either that we were successful, the target died, or became a threat
	// either way we should complete
	if (sensor == CompliantSensor)
	{
		// TODO: Maybe fail if they die or become a threat?
		instantSucceed();
	}
}

function name GetComplyOrderAnimName()
{
	local HandheldEquipment ActiveItem;
	local SwatWeapon EquippedWeapon;

	ActiveItem = m_Pawn.GetActiveItem();
	EquippedWeapon = SwatWeapon(ActiveItem);

	if(EquippedWeapon != None)
	{
		switch(EquippedWeapon.ComplianceAnimation)
		{
			case Compliance_Machinegun:
				return ComplyMGOrderAnims[Rand(ComplyMGOrderAnims.Length)];

			case Compliance_Shotgun:
				return ComplySGOrderAnims[Rand(ComplySGOrderAnims.Length)];

			case Compliance_SubmachineGun:
				return ComplySMGOrderAnims[Rand(ComplySMGOrderAnims.Length)];

			case Compliance_CSBallLauncher:
				return ComplyPepperBallOrderAnims[Rand(ComplyPepperBallOrderAnims.Length)];

			case Compliance_Handgun:
			default:
				return ComplyHGOrderAnims[Rand(ComplyHGOrderAnims.Length)];
		}
	}
	else
	{
		return ComplyHGOrderAnims[Rand(ComplyHGOrderAnims.Length)];
	}
}

latent function OrderToComply()
{
	local int ComplyAnimationChannel;

	// trigger the appropriate speech depending on whether the target has a gun equipped or not
	if (ISwatAI(TargetPawn).HasFiredWeaponEquipped())
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerComplyWithGunSpeech();
	}
	else
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerComplySpeech();
	}

	if (FRand() < kPlayOrderComplianceAnimation)
	{
		ComplyAnimationChannel = m_Pawn.AnimPlaySpecial(GetComplyOrderAnimName(), 0.1, ISwatAI(m_Pawn).GetUpperBodyBone());
		m_Pawn.FinishAnim(ComplyAnimationChannel);
	}
	else
	{
		sleep(RandRange(kMinOrderComplyTime, kMaxOrderComplyTime));
	}

	ISwatAI(m_Pawn).IssueComplianceTo(TargetPawn);
}

private function SetTimeToStopTryingToEngage()
{
	assert(Level != None);

	TimeToStopTryingToEngage = Level.TimeSeconds + MaximumTimeToWaitToEngage;
}

private function bool ShouldEngageImmediately() {
	local SwatAIRepository SwatAIRepo;
	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	// test to see if we're moving and clearing
	return (SwatAIRepo.IsOfficerMovingAndClearing(m_Pawn));
}

state Running
{
 Begin:
	// wait until the target is either dead or compliant
	while (class'Pawn'.static.checkConscious(TargetPawn) && !ISwatAI(TargetPawn).IsCompliant() && (Level.TimeSeconds < TimeToStopTryingToEngage) && !ISwatAI(TargetPawn).IsDisabled())
	{
		if (ISwatAI(m_Pawn).CanIssueComplianceTo(TargetPawn))
		{
			SetOrderComplianceAim();
			OrderToComply();

			// reset the timer
			if(!ShouldEngageImmediately()) {
				SetTimeToStopTryingToEngage();

				sleep(RandRange(MinComplianceOrderSleepTime, MaxComplianceOrderSleepTime));
			}
		}
		else
		{
			sleep(RandRange(MinComplianceWaitTime, MaxComplianceWaitTime));
		}
	}

	succeed();
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'OrderComplianceGoal'
}
