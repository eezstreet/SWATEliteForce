class Procedure_SecureAllWeapons extends SwatGame.Procedure
    implements IInterested_GameEvent_EvidenceSecured, IInterested_GameEvent_EvidenceDestroyed;

var config int Bonus;
var int NumSecured;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.EvidenceSecured.Register(self);
}

//interface IInterested_GameEvent_EvidenceSecured implementation
function OnEvidenceSecured(IEvidence Secured)
{
    NumSecured++;

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" incremented NumSecured to "$NumSecured
            $" because EvidenceSecured.");
}

//interface IInterested_GameEvent_EvidenceDestroyed implementation
function OnEvidenceDestroyed(IEvidence Destroyed)
{
	NumSecured++;
	
	if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" incremented NumSecured to "$NumSecured
            $" because EvidenceDestroyed.");
}

//currently returns remaining weapons to be secured
function string Status()
{
    local int NumUnsecured;

    NumUnsecured = GetNumUnSecuredWeapons();

    return NumSecured $ "/" $ NumUnsecured + NumSecured;
}

///////////////////////////////////////
function int GetCurrentValue()
{
    local int NumUnsecured, retVal;

    NumUnsecured = GetNumUnSecuredWeapons();

    if (NumUnsecured == 0)
        retVal = Bonus;
    else
        retVal = int( ( float( NumSecured ) / float( NumUnsecured + NumSecured ) )
                        * float( Bonus ) );

    if(GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = "$retVal
            $" because NumSecured = "$NumSecured$" / NumUnsecured = "$NumUnsecured$".");

    return retVal;
}

function int GetPossible()
{
	return Bonus;
}

private function int GetNumUnSecuredWeapons()
{
    local IEvidence Evidence;
    local int count;

    foreach GetGame().DynamicActors(class'IEvidence', Evidence)
    {
        if (Evidence.CanBeUsedNow())
        {
            count++;
            if(GetGame().DebugLeadershipStatus)
                log("[LEADERSHIP] SecureAllWeapons: Remaining UnSecuredWeapon #"$count$" - "$Evidence.name);
        }
    }
    
    return count;
}

//returns true iff the procedure's value is the highest possible
function bool IsMaxed()
{
    return GetCurrentValue() == Bonus;
}
