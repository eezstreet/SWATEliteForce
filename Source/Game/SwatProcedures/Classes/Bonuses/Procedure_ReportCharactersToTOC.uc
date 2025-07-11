///////////////////////////////////////////////////////////////////////////////
// An excerpt from section 21.3.5 of the SWAT design doc:
//
//      Reporting all characters to TOC
//      Players receive this bonus if they have reported every character’s
//      situation to TOC.  Players must report every character to get this
//      bonus.  This includes characters that start incapacitated.  This
//      bonus does not include incapacitated officers.  Reporting all
//      incapacitated officers avoids a penalty.
//
// That penalty in Procedure_EvacuateDownedOfficers

class Procedure_ReportCharactersToTOC extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnDied,
                IInterested_GameEvent_PawnIncapacitated,
                IInterested_GameEvent_PawnArrested,
                IInterested_GameEvent_ReportableReportedToTOC;

///////////////////////////////////////////////////////////////////////////////

var config int Bonus;

// Contains the characters who are, or were ever, eligible to be reported
var array<IAmReportableCharacter> ReportableCharacters;
// Contains the characters in the above array who have actually been reported
var array<IAmReportableCharacter> ReportedCharacters;

///////////////////////////////////////////////////////////////////////////////

function PostInitHook()
{
    Super.PostInitHook();

    // Register for notifications
    GetGame().GameEvents.PawnDied.Register(self);
    GetGame().GameEvents.PawnIncapacitated.Register(self);
    GetGame().GameEvents.PawnArrested.Register(self);
    GetGame().GameEvents.ReportableReportedToTOC.Register(self);

    FindInitialReportableCharacters();
}

///////////////////////////////////////

// Finds the characters who are currently eligible to be reported.
private function FindInitialReportableCharacters()
{
    local IAmReportableCharacter ReportableCharacter;

    foreach GetGame().AllActors(class'IAmReportableCharacter', ReportableCharacter)
    {
        if (ReportableCharacter.CanBeUsedNow())
            AddReportableCharacter(ReportableCharacter, 'InitiallyReportable');
    }
}

///////////////////////////////////////

// IInterested_GameEvent_PawnDied implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if (Pawn.IsA('IAmReportableCharacter'))
        AddReportableCharacter(IAmReportableCharacter(Pawn), 'PawnDied');
}

///////////////////////////////////////

// IInterested_GameEvent_PawnArrested implementation
function OnPawnArrested( Pawn Pawn, Pawn Arrester )
{
    if (Pawn.IsA('IAmReportableCharacter'))
        AddReportableCharacter(IAmReportableCharacter(Pawn), 'PawnArrested');
}

///////////////////////////////////////

// IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if (Pawn.IsA('IAmReportableCharacter'))
        AddReportableCharacter(IAmReportableCharacter(Pawn), 'PawnIncapacitated');
}

///////////////////////////////////////

private function AddReportableCharacter(IAmReportableCharacter ReportableCharacter, name DebugWhy)
{
    local bool isAlreadyInArray;
    local int i;

    for (i = 0; i < ReportableCharacters.length; i++)
    {
        if (ReportableCharacters[i] == ReportableCharacter)
        {
            isAlreadyInArray = true;
            break;
        }
    }

    // It's possible that multiple attempts to add a single character
    // can happen. For example, once when he is restrained, and again
    // when he is killed. Here we defend against duplicate entries.
    if (!isAlreadyInArray)
    {
        ReportableCharacters[ReportableCharacters.length] = ReportableCharacter;
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $" added "$ReportableCharacter.name
                $" to the list of ReportableCharacters because "$DebugWhy
                $". ReportableCharacters.length="$ReportableCharacters.length);
    }
    else
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $" was called to AddReportableCharacter() because "$DebugWhy
                $", but "$ReportableCharacter
                $" is already in the list of ReportableCharacters.");
}

///////////////////////////////////////

// IInterested_GameEvent_ReportableReportedToTOC implementation
function OnReportableReportedToTOC(IAmReportableCharacter ReportableCharacter, Pawn Reporter)
{
    local int i;
    local bool wasInReportableArray;
    local bool isAlreadyInReportedArray;

    assert(ReportableCharacter != None);

    // Verify that this character was in our ReportableCharacters array
    for (i = 0; i < ReportableCharacters.length; i++)
    {
        if (ReportableCharacters[i] == ReportableCharacter)
        {
            wasInReportableArray = true;
            break;
        }
    }

    assertWithDescription(wasInReportableArray,
        "Unexpected bonus state: AI was reported without first being declared eligible [darren]");

    // Add to the reported array
    for (i = 0; i < ReportedCharacters.length; i++)
    {
        if (ReportedCharacters[i] == ReportableCharacter)
        {
            isAlreadyInReportedArray = true;
            break;
        }
    }

    assertWithDescription(!isAlreadyInReportedArray,
        "Unexpected bonus state: AI was reported more than once [darren]");
    if (!isAlreadyInReportedArray)
    {
        ReportedCharacters[ReportedCharacters.length] = ReportableCharacter;

        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $" added "$ReportableCharacter.name
                $" to the list of ReportedCharacters because ReportableReportedToTOC"
                $". ReportedCharacters.length="$ReportedCharacters.length
                $" (ReportableCharacters.length="$ReportableCharacters.length$")");
    }

    assert(ReportedCharacters.length <= ReportableCharacters.length);
}

///////////////////////////////////////

function string Status()
{
    assert(ReportedCharacters.length <= ReportableCharacters.length);
    return ReportedCharacters.length
        $"/"$ReportableCharacters.length;
}

///////////////////////////////////////

// IProcedure implementation
function int GetCurrentValue()
{
    local int retVal;
    
    assert(ReportedCharacters.length <= ReportableCharacters.length);
    
    //don't give a score for 0/0 status
    if( ReportedCharacters.length == 0 )
        retVal = 0;
    else
        retVal = int( ( float( ReportedCharacters.length ) / float( ReportableCharacters.length ) )
                        * float( Bonus ) );

    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = "$retVal
            $" with status (ReportedCharacters.length / ReportableCharacters.length) = "$Status() );

    return retVal;
}

function int GetPossible()
{
	return Bonus;
}

///////////////////////////////////////////////////////////////////////////////

//returns true iff the procedure's value is the highest possible
function bool IsMaxed()
{
    return GetCurrentValue() == Bonus;
}
