///////////////////////////////////////////////////////////////////////////////

class AnimNotify_SecurePendingEvidence extends Engine.AnimNotify_Scripted;

///////////////////////////////////////////////////////////////////////////////

function IEvidence GetEvidenceTarget(SwatOfficer SwatOfficer)
{
    local int i;
    local SecureEvidenceAction SecureEvidenceAction;
    local AI_Resource Resource;
    local AI_RunnableAction Action;

    Resource = AI_Resource(SwatOfficer.CharacterAI);
    if (Resource != None)
    {
        for (i = 0; i < Resource.runningActions.length; i++)
        {
            Action = Resource.runningActions[i];
            SecureEvidenceAction = SecureEvidenceAction(Action);
            if (SecureEvidenceAction != None)
            {
                return SecureEvidenceAction.GetEvidenceTarget();
            }
        }
    }

    return None;
}

///////////////////////////////////////

event Notify(Actor Owner)
{
    local SwatOfficer SwatOfficer;
    local IEvidence EvidenceTarget;

    SwatOfficer = SwatOfficer(Owner);
    if (SwatOfficer != None)
    {
        EvidenceTarget = GetEvidenceTarget(SwatOfficer);
        if (EvidenceTarget != None)
        {
            EvidenceTarget.OnUsed(SwatOfficer);
            EvidenceTarget.PostUsed();
        }
	}
}

///////////////////////////////////////////////////////////////////////////////
