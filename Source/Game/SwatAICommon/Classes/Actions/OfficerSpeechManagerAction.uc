///////////////////////////////////////////////////////////////////////////////
// OfficerSpeechManagerAction.uc - the OfficerSpeechManagerAction class
// this action is used by Officers to organize their speech
// typically instructions come from the ElementSpeechManagerAction

class OfficerSpeechManagerAction extends CharacterSpeechManagerAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Speech Requests

// Officers
function TriggerOfficerDownSpeech()
{
	TriggerSpeech('ReportedOfficerDown', true);
}

function TriggerLeadDownSpeech()
{
	TriggerSpeech('ReportedLeadDown', true);
}

function TriggerReactedFirstShotSpeech()
{
	TriggerSpeech('ReactedFirstShot', true);
}

function TriggerReactedSecondShotSpeech()
{
	TriggerSpeech('ReactedSecondShot', true);
}

function TriggerReactedThirdShotSpeech()
{
	TriggerSpeech('ReactedThirdShot', true);
}

// Suspects
function TriggerSuspectSpottedSpeech()
{
	TriggerSpeech('ReportedSuspectSpotted', true);
}

function TriggerSuspectDownSpeech(Pawn Suspect)
{
	if (Suspect.IsIncapacitated())
	{
		TriggerSpeech('ReportedSuspectDown', true);
	}
	else
	{
		TriggerSpeech('ReportedSuspectNeutralized', true);
	}
}

function TriggerSuspectFleeingSpeech(Pawn Suspect)
{
	if (ISwatAICharacter(Suspect).IsFemale())
	{
		TriggerSpeech('ReportedFemSuspectFleeing', true);
	}
	else
	{
		TriggerSpeech('ReportedMaleSuspectFleeing', true);
	}
}

function TriggerSuspectWontComplySpeech(Pawn Suspect)
{
	if (ISwatAICharacter(Suspect).IsFemale())
	{
		TriggerSpeech('ReportedFemSuspectWillNotComply', true);
	}
	else
	{
		TriggerSpeech('ReportedMaleSuspectWillNotComply', true);
	}
}

// Hostages
function TriggerHostageSpottedSpeech(Pawn Hostage)
{
	assert(Hostage.IsA('SwatHostage'));

	if (ISwatHostage(Hostage).GetHostageCommanderAction().IsInDanger())
	{
		TriggerSpeech('ReportedHostageSpottedWithThreat', true);
	}
	else
	{
		TriggerSpeech('ReportedHostageSpottedNoThreat', true);
	}
}

function TriggerHostageDownSpeech(Pawn Hostage)
{
	// @NOTE: There is no generic speech for downed hostages
	TriggerSpeech('ReportedHostageIncapacitated', true);
}

function TriggerHostageWontComplySpeech(Pawn Hostage)
{	
	if (ISwatAICharacter(Hostage).IsFemale())
	{
		TriggerSpeech('ReportedFemCivilianWillNotComply', true);
	}
	else
	{
		TriggerSpeech('ReportedMaleCivilianWillNotComply', true);
	}
}

// Commands
function TriggerClearAnnouncement()
{
	TriggerSpeech('AnnouncedClear');
}

function TriggerComplySpeech()
{
	TriggerSpeech('AnnouncedComply', true);
}

function TriggerComplyWithGunSpeech()
{
	TriggerSpeech('AnnouncedComplyWithGun', true);
}

function TriggerWedgePlacedSpeech()
{
	TriggerSpeech('AnnouncedDoorIsWedged');
}

function TriggerWedgeRemovedSpeech()
{
	TriggerSpeech('AnnouncedRemovedWedged');
}

function TriggerWedgeNotFoundSpeech()
{
	TriggerSpeech('ReportedNotWedged');
}

// for deploying the toolkit when picking a lock
function TriggerDeployingToolkitSpeech()
{
	TriggerSpeech('ReportedDeployingToolkit');
}

function TriggerDeployingTaserSpeech()
{
	TriggerSpeech('ReportedDeployingTaser');
}

function TriggerFinishedLockPickSpeech()
{
	TriggerSpeech('ReportedDoorUnlocked');
}

function TriggerReportDoorLockedSpeech()
{
	TriggerSpeech('ReportedDoorLocked');
}

function TriggerReportDoorWedgedSpeech()
{
	TriggerSpeech('AnnouncedDoorIsAlreadyWedged');
}

function TriggerReportDoorOpenSpeech()
{
	TriggerSpeech('ReportedDoorOpen');
}

function TriggerReachedStackUpSpeech()
{
	TriggerSpeech('ReachedStackUp');
}

function TriggerStartedClearingSpeech()
{
	TriggerSpeech('StartedClearing', true);
}

function TriggerReportedThresholdClearSpeech()
{
	TriggerSpeech('ReportedThresholdClear', true);
}

function TriggerReportedContinuingClear2Plus()
{
	TriggerSpeech('ReportedContinuingClear2Plus', true);
}

function TriggerReportedContinuingClear2Minus()
{
	TriggerSpeech('ReportedContinuingClear2Minus', true);
}

function TriggerReportedDeployingShotgunSpeech()
{
	TriggerSpeech('ReportedDeployingBreachSG');
}

function TriggerReportedDeployingC2Speech()
{
	TriggerSpeech('ReportedDeployingC2');
}

function TriggerDoorNotClosedSpeech()
{
	TriggerSpeech('AnnouncedDoorIsNotClosed');
}

function TriggerDoorIsAlreadyWedgedSpeech()
{
	TriggerSpeech('AnnouncedDoorIsAlreadyWedged');
}

function TriggerLessLethalShotgunUnavailableSpeech()
{
	TriggerSpeech('ReportedBeanBagUnavailable');
}

function TriggerGrenadeLauncherUnavailableSpeech()
{
	TriggerSpeech('ReportedBeanBagUnavailable');
}

function TriggerDeployingPepperBallSpeech()
{
	TriggerSpeech('ReportedDeployingPepperGun');
}

function TriggerPepperBallUnavailableSpeech()
{
	TriggerSpeech('ReportedPepperGunUnavailable');
}

function TriggerWedgeUnavailableSpeech()
{
	TriggerSpeech('ReportedWedgesUnavailable');
}

function TriggerFlashbangUnavailableSpeech()
{
	TriggerSpeech('ReportedFlashbangUnavailable');
}

function TriggerGasUnavailableSpeech()
{
	TriggerSpeech('ReportedGasUnavailable');
}

function TriggerStingUnavailableSpeech()
{
	TriggerSpeech('ReportedStingUnavailable');
}

function TriggerTaserUnavailableSpeech()
{
	TriggerSpeech('ReportedTaserUnavailable');
}

function TriggerC2UnavailableSpeech()
{
	TriggerSpeech('CouldntBreachNoC2');
}

function TriggerDoorBreachingEquipmentUnavailableSpeech()
{
	TriggerSpeech('ReportedDoorBreachingEquipmentUnavailable');
}

function TriggerToolkitUnavailableSpeech()
{
	TriggerSpeech('ReportedToolkitUnavailable');
}

function TriggerShotgunUnavailableSpeech()
{
	TriggerSpeech('ReportedBreachSGUnavailable');
}

function TriggerPepperSprayUnavailableSpeech()
{
	TriggerSpeech('ReportedPepperUnavailable');
}

function TriggerMirrorUnavailableSpeech()
{
	TriggerSpeech('ReportedMirrorUnavailable');
}

function TriggerReportedSuspectSecuredSpeech()
{
	TriggerSpeech('ReportedSuspectSecured');
}

function TriggerReportedHostageSecuredSpeech()
{
	TriggerSpeech('ReportedHostageSecured');
}

function TriggerCompletedMoveToSpeech()
{
	TriggerSpeech('CompletedMoveTo');
}

function TriggerRepliedMoveToSpeech()
{
	TriggerSpeech('RepliedMoveTo');
}

function TriggerRepliedFallInSpeech()
{
	TriggerSpeech('RepliedFallIn');
}

function TriggerCompletedFallInSpeech()
{
	TriggerSpeech('CompletedFallIn');
}

function TriggerStillCoveringSpeech()
{
	TriggerSpeech('AnnouncedStillCovering');
}

function TriggerEvidenceSecuredSpeech()
{
	TriggerSpeech('ReportedEvidenceSecured');
}

function TriggerEvidenceNotFoundSpeech()
{
	TriggerSpeech('ReportedNoEvidence');
}

function TriggerWeaponSecuredSpeech()
{
	TriggerSpeech('ReportedWeaponSecured');
}

function TriggerWeaponNotFoundSpeech()
{
	TriggerSpeech('ReportedNoGun');
}

function TriggerReassureAggressiveHostageSpeech()
{
	TriggerSpeech('ReassuredAggressiveHostage');
}

function TriggerReassurePassiveHostageSpeech()
{
	TriggerSpeech('ReassuredPassiveHostage');
}

function TriggerArrestedSuspectSpeech()
{
	TriggerSpeech('ArrestedSuspect');
}

function TriggerArrestedReportSpeech(Pawn Target)
{
	if (Target.IsA('SwatEnemy'))
	{
		TriggerSpeech('ReportedSuspectRestrained');
	}
	else
	{
		TriggerSpeech('ReportedCivilianRestrained');
	}
}

function TriggerOptiwandReportSpeech(int NumEnemies, int NumHostages)
{
	if ((NumEnemies == 0) && (NumHostages == 0))
	{
		TriggerSpeech('ReportedMirrorNoTargets');
	}
	else if (NumHostages == 0)	// which at this point inherantly means NumEnemies > 0
	{
		if (NumEnemies == 1)
		{
			TriggerSpeech('ReportedOneSuspectSeen');
		}
		else if (NumEnemies == 2)
		{
			TriggerSpeech('ReportedTwoSuspectsSeen');
		}
		else // (NumEnemies > 2)
		{
			TriggerSpeech('ReportedManySuspectsSeen');
		}
	}
	else if (NumEnemies == 0)
	{
		if (NumHostages == 1)
		{
			TriggerSpeech('ReportedOneCivilianSeen');
		}
		else if (NumHostages == 2)
		{
			TriggerSpeech('ReportedTwoCiviliansSeen');
		}
		else // (NumHostages > 2)
		{
			TriggerSpeech('ReportedManyCiviliansSeen');
		}
	}
	else // (NumHostages > 0) && (NumEnemies > 0)
	{
		if ((NumHostages == 1) && (NumEnemies == 1))
		{
			TriggerSpeech('Reported1Suspect1Civilian');
		}
		else
		{
			TriggerSpeech('ReportedSuspectsAndCivsSeen');
		}
	}
}

function TriggerMoveUpBangsSpeech()
{
	TriggerSpeech('ReportedMoveUpBangs');
}

function TriggerMoveUpGasSpeech()
{
	TriggerSpeech('ReportedMoveUpGas');
}

function TriggerMoveUpStingSpeech()
{
	TriggerSpeech('ReportedMoveUpSting');
}

function TriggerMoveUpBreachSGSpeech()
{
	TriggerSpeech('ReportedMoveUpBreachSG');
}

function TriggerMoveUpC2Speech()
{
	TriggerSpeech('ReportedMoveUpC2');
}

function TriggerGenericMoveUpSpeech()
{
	TriggerSpeech('RepliedSwitchingPositions');
}

function TriggerRepliedDisablingSpeech()
{
	TriggerSpeech('RepliedDisabling');
}

function TriggerReportedBombDisabledSpeech()
{
	TriggerSpeech('ReportedBombDisabled');
}

function TriggerReportedTrapDisabledSpeech()
{
	TriggerSpeech('ReportedTrapDisabled');
}

function TriggerReportedGenericDisabledSpeech()
{
	TriggerSpeech('ReportedDisabled');
}

function TriggerGenericOrderReplySpeech()
{
	TriggerSpeech('ReportedGenericOrderReply', true);
}

// Announcements
function TriggerBusyEngagingSpeech()
{
	TriggerSpeech('ReportedAlreadyBusy');
}

function TriggerLostTargetSpeech()
{
	TriggerSpeech('AnnouncedLostTarget');
}

function TriggerTargetCompliantSpeech(Pawn Target)
{
	if (Target.IsA('SwatEnemy'))
	{
		TriggerSpeech('AnnouncedSuspectComplied');
	}
	else
	{
		TriggerSpeech('AnnouncedCivilianComplied');
	}
}

function TriggerCouldntBreachLockedDoorSpeech()
{
	TriggerSpeech('CouldntBreachLocked');
}

function TriggerPlayerInTheWaySpeech()
{
	TriggerSpeech('ToldPlayerToMove', true);
}

function TriggerPlayerBlockingDoorSpeech()
{
	TriggerSpeech('ToldPlayerBlocksDoor', true);
}

function TriggerCharacterBlockingDoorSpeech()
{
	TriggerSpeech('ReportedDoorBlocked', true);
}

function TriggerCouldntCompleteMoveSpeech()
{
	TriggerSpeech('CouldntCompleteMove');
}

function TriggerCantDeployThrownSpeech()
{
	TriggerSpeech('RepliedCantDeployThrown');	
}

function TriggerRedTeamNeedsOrdersSpeech()
{
	TriggerSpeech('RedTeamReported');
	TriggerSpeech('RequestedOrders');
}

function TriggerBlueTeamNeedsOrdersSpeech()
{
	TriggerSpeech('BlueTeamReported');
	TriggerSpeech('RequestedOrders');
}

function TriggerOtherTeamOnItSpeech()
{
	TriggerSpeech('ReportedOtherTeamOnIt');
}

function TriggerCoveringTargetSpeech()
{
	TriggerSpeech('CoveredCompliedUnrestrained');
}

function TriggerElementReportedSpeech()
{
	TriggerSpeech('ElementReported');
}

function TriggerRedTeamReportedSpeech()
{
	TriggerSpeech('RedTeamReported');
}

function TriggerBlueTeamReportedSpeech()
{
	TriggerSpeech('BlueTeamReported');
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}