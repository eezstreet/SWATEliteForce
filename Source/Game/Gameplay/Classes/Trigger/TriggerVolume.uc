class TriggerVolume extends Engine.PhysicsVolume;

////////////////////////////////////////////////////////////////////
// NOTE: Dynamic class variables should be reset to their initial state
//    in ResetForMPQuickRestart()
////////////////////////////////////////////////////////////////////

var(TriggerVolume) array< class<Pawn> >     TriggerOnlyByClass "If not empty, this TriggerVolume will only trigger if the class of Pawn entering or leaving the Volume is in this list.";
var(TriggerVolume) array< name >            TriggerOnlyByLabel "If not empty, this TriggerVolume will only trigger if the label of the Pawn entering or leaving the Volume is in this list.";
var(TriggerVolume) bool                     TriggerOnlyOnce "If true, then MessageTriggerVolumeEnter and MessageTriggerVolumeExit will only be sent once (each).";

var bool Disabled;

var bool AlreadyTriggeredEntered;
var bool AlreadyTriggeredLeaving;

//note: if TriggerOnlyOnce, then it is possible that
//  PawnEnteredVolume() could be called with a different Pawn
//  than PawnLeavingVolme().

event PawnEnteredVolume(Pawn Other)
{
    if (Disabled) return;

    if (TriggerOnlyOnce && AlreadyTriggeredEntered) return;

    if (MeetsRestrictions(Other))
    {
        dispatchMessage(new class'MessageTriggerVolumeEnter'(label, Other.label));
        AlreadyTriggeredEntered = true;
    }
}

event PawnLeavingVolume(Pawn Other)
{
    if (Disabled) return;

    if (TriggerOnlyOnce && AlreadyTriggeredLeaving) return;

    if (MeetsRestrictions(Other))
    {
        dispatchMessage(new class'MessageTriggerVolumeExit'(label, Other.label));
        AlreadyTriggeredLeaving = true;
    }
}

function bool MeetsRestrictions(Pawn Other)
{
    local int i;
    local bool trigger;

    if (TriggerOnlyByClass.length == 0 && TriggerOnlyByLabel.length == 0)
        return true;    //no restrictions to meet

    if (TriggerOnlyByClass.length > 0)
    {
        trigger = false;

        for (i=0; i<TriggerOnlyByClass.length; ++i)
        {
            if (TriggerOnlyByClass[i] == Other.Class)
            {
                trigger = true;
                break;
            }
        }

        if (!trigger) return false;   //other's class was not found in the TriggerOnlyByClass list
    }

    if (TriggerOnlyByLabel.length > 0)
    {
        trigger = false;

        for (i=0; i<TriggerOnlyByLabel.length; ++i)
        {
            if (TriggerOnlyByLabel[i] == Other.Label)
            {
                trigger = true;
                break;
            }
        }

        if (!trigger) return false;   //other's class was not found in the TriggerOnlyByLabel list
    }
    
    return true;    //meets all restrictions
}

////////////////////////////////////////////////////////////////////
// Reset the class variables to their initial state
////////////////////////////////////////////////////////////////////
function ResetForMPQuickRestart()
{
    Disabled = false;
    AlreadyTriggeredEntered = false;
    AlreadyTriggeredLeaving = false;
}
////////////////////////////////////////////////////////////////////
