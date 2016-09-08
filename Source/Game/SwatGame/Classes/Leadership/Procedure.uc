class Procedure extends Core.Object
    implements IProcedure
    config(Leadership)
    abstract;

var config localized string Description;
var config bool IsNeverHidden;
var config bool IsShownInObjectivesPanel;
var config bool IsABonus; //bonuses are treated differently than penalties
var config string ChatMessage;

var private SwatGameInfo Game;

const NOT_IN_ARRAY = -1;

protected final function SwatGameInfo GetGame()
{
    assert(Game != None);
    return Game;
}

// Must be called before a procedure can be used, so that the procedure
// has reference to the game.
final function Init(SwatGameInfo GameInfo)
{
    assert(GameInfo != None);
    Game = GameInfo;

    if (Game.DebugLeadership)
        log("[LEADERSHIP] Initializing "$class.name);

    PostInitHook();
}

// Called automatically after the procedure is initialized.
function PostInitHook();

function string Status()
{
    return "";
}

//IProcedure implementation
function int GetCurrentValue();

//returns true iff the procedure's value is the highest possible
function bool IsMaxed()
{
    return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
//  Pawn Array Utilities
/////////////////////////////////////////////////////////////////////////////////////////////////

function Add(Pawn InPawn, out array<SwatPawn> SwatPawnArray)
{
    if( IsInArray( InPawn, SwatPawnArray ) )
        return;

    assert(InPawn.IsA('SwatPawn'));

    SwatPawnArray[SwatPawnArray.length] = SwatPawn(InPawn);
}

//it is not an error to Remove() and InPawn from an array they're not in
function Remove(Pawn InPawn, out array<SwatPawn> SwatPawnArray)
{
    local int i;

    i = GetArrayIndex(InPawn, SwatPawnArray);

    if (i != NOT_IN_ARRAY)
        SwatPawnArray.Remove(i, 1);
}

function AssertNotInArray(Pawn InPawn, out array<SwatPawn> SwatPawnArray, name Doc)
{
    AssertWithDescription( !IsInArray(InPawn, SwatPawnArray),
        "[tcohen] "$class.name
        $": "$InPawn.name
        $" was found to be in the "$Doc
        $" array, but it shouldn't be there.");
}

function bool IsInArray(Pawn InPawn, out array<SwatPawn> SwatPawnArray)
{
    return GetArrayIndex(InPawn, SwatPawnArray) != NOT_IN_ARRAY;
}

//returns the index of InPawn in SwatPawnArray, or NOT_IN_ARRAY
function int GetArrayIndex(Pawn InPawn, out array<SwatPawn> SwatPawnArray)
{
    local int i;

    for (i=0; i<SwatPawnArray.length; ++i)
        if (SwatPawnArray[i] == InPawn)
            return i;

    return NOT_IN_ARRAY;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
//  Number of Actors in level Utilities
/////////////////////////////////////////////////////////////////////////////////////////////////

function int GetNumActors( class<Actor> InClass )
{
    local Actor AnActor;
    local int NumActors;

    foreach GetGame().AllActors(InClass, AnActor)
    {
        NumActors++;
    }

    return NumActors;
}

function int GetNumPlayers()
{
    return GetNumActors( class'SwatPlayer' );
}

function int GetNumOfficers()
{
    return GetNumActors( class'SwatOfficer' );
}

/////////////////////////////////////////////////////////////////////////////////////////////////
//  Chat messages!
/////////////////////////////////////////////////////////////////////////////////////////////////

function ChatMessageEvent(Name EventType)
{
  Game.SendGlobalMessage(ChatMessage, EventType);
}
