class HighGroundVolume extends Engine.PhysicsVolume
    implements IEffectObserver,
    IInterested_GameEvent_PawnDied,
    IInterested_GameEvent_PawnArrested,
    IInterested_GameEvent_PawnIncapacitated,
    IInterested_GameEvent_PostGameStarted
    config(HighGround);

// =============================================================================
//  HighGroundVolume
//
//  A HighGroundVolume is a physics volume that in fiction allows the TOC to inform
//  the SWAT team about events that are happening in other parts of the map.  Generally
//  HGV's are placed in front of windows, or places that TOC can logically see through.
//  The implementation is a PhysicsVolume that reacts to things happening inside of it
//  by triggering different effect events.  There is a list of possible events that the
//  designers fill.
//
// ==============================================================================

#define DEBUG_HIGHGROUNDVOLUME 0

struct HighGroundCondition
{
    var() config Name   Subject;                    // What initiated the event
    var() config Name   Archetype;                  // What archetype the Subject has to be
    var() config Name   Action;                     // What actually happened
    var() config Name   Object;                     // Who it happened to

    var() config int    Priority;                   // Priority that it takes place in
    var() config float  Delay;                      // Time delay between when this event gets announced, and when the next one can
    var() config bool   bShrinkOnAction;
    var          Name   Instance;                   // Instance specific data
};


var() name RoomName;                                // Name of the specific room this highgroundvolume responds to.
var() config array<HighGroundCondition> Conditions; // Designer generated list conditions

var transient array<HighGroundCondition> PriorityQueue; // Transient priority queue of active conditions
var const HighGroundCondition NullCondition;            // Since UnrealScript doesn't allow Struct references to be None, this is used as a NullObject

var bool bStillPlaying;                             // True if there is an event playing currently, and if true will queue up future events
var HighGroundCondition PlayingCondition;
var bool bGameStarted;

function PostBeginPlay()
{
    Super.PostBeginPlay();

    if ( Level.NetMode == NM_Standalone )
    {
        SwatGameInfo(Level.Game).GameEvents.PostGameStarted.Register(self);
        SwatGameInfo(Level.Game).GameEvents.PawnDied.Register(self);
        SwatGameInfo(Level.Game).GameEvents.PawnArrested.Register(self);
        SwatGameInfo(Level.Game).GameEvents.PawnIncapacitated.Register(self);
    }
    else
    {
        OnPostGameStarted();
    }
}

function OnPostGameStarted()
{
    local int ct;

    bGameStarted = true;

    for ( ct = 0; ct < Touching.Length; ++ct )
    {
        if ( Touching[ct] != None && Touching[ct].IsA( 'Pawn' ) )
        {
#if DEBUG_HIGHGROUNDVOLUME
            log( "Highground: Pawn was in volume at start of level!!" );
#endif
            PawnEnteredVolume(Pawn(Touching[ct]));
        }
    }
}

final private function string ConditionToString( HighGroundCondition inCondition )
{
    return inCondition.Subject $ " has " $ inCondition.Action $ " " $ inCondition.Object $ ".  Instance: " $ inCondition.Instance;
}

// Add an HighGroundCondition to the queue, inserted into a sorted position based on priority
final private function QueueEvent(HighGroundCondition inCondition)
{
    local int ct;

    if ( PriorityQueue.Length == 0 )
    {
        PriorityQueue.Insert(0,1);
        PriorityQueue[0] = inCondition;
    } else
    {
        // Insert this event in the the proper sorted place in the list
        for ( ct = 0; ct < PriorityQueue.Length; ct ++ )
        {
            if ( inCondition.Priority <= PriorityQueue[ct].Priority )
            {
                PriorityQueue.Insert(ct, 1);
                PriorityQueue[ct] = inCondition;
                break;
            }
        }
    }
}

// Shrink the queue of any subjects matching the passed in subject
final private function QueueShrinkOnSubject(Name inSubject)
{
    local int ct;

    for ( ct = PriorityQueue.Length - 1; ct >= 0; ct-- )
    {
        if ( SubjectsMatch( PriorityQueue[ct].Subject, inSubject ) )
        {
#if DEBUG_HIGHGROUNDVOLUME
            log( "Highground: Shrinking array and removing condition: "$ConditionToString(PriorityQueue[ct]) );
#endif
            PriorityQueue.Remove(ct, 1);
        }
    }
}

// Shrink the queue of any subjects matching the passed in subject
final private function QueueShrinkOnSubjectAndAction(Name inSubject, Name inAction)
{
    local int ct;

    for ( ct = PriorityQueue.Length - 1; ct >= 0; ct-- )
    {
        if ( SubjectsMatch( PriorityQueue[ct].Subject, inSubject ) && PriorityQueue[ct].Action == inAction )
        {
#if DEBUG_HIGHGROUNDVOLUME
            log( "Highground: Shrinking array and removing condition: "$ConditionToString(PriorityQueue[ct]) );
#endif
            PriorityQueue.Remove(ct, 1);
        }
    }
}

final private function bool SubjectsMatch(Name inSubject1, Name inSubject2)
{
    if ( (inSubject1 == 'SwatOfficer' || inSubject1 == 'SwatPlayer')
        && (inSubject2 == 'SwatOfficer' || inSubject2 == 'SwatPlayer') )
        return true;

    return inSubject1 == inSubject2;
}

// Extract a HighGroundCondition from the queue, since the list is already sorted, it just grabs the first element in the array
final private function HighGroundCondition QueueExtract()
{
    local HighGroundCondition returnType;

    if ( PriorityQueue.Length == 0 )
        return NullCondition;

    returnType = PriorityQueue[0];
    PriorityQueue.Remove(0, 1);

    return returnType;
}

// Return a HighGroundCondition if found in the Conditions array
final private function HighGroundCondition FindCondition( Actor inSubject, Name inAction, Actor inObject )
{
    local int ct;
    //local SwatPawn SubjectPawn;

    for ( ct = 0; ct < Conditions.Length; ct ++ )
    {
        if ( inSubject.IsA( Conditions[ct].Subject ) && inAction == Conditions[ct].Action )
        {
            if ( inObject == None || ( inObject.IsA( Conditions[ct].Object ) ) )
            {
                // TODO: handle archetypes
                /*if ( Conditions[ct].Archetype != '' )
                {
                    if ( inSubject.IsA( 'SwatPawn' ) )
                    {
                        //SubjectPawn = SwatPawn(inSubject);
                        //if ( SubjectPawn
                    }
                }*/
                return Conditions[ct];
            }
        }
    }
    return NullCondition;
}

final private function bool IsConditionQueued(Name inSubject, Name inAction, Name inObject )
{
    local int ct;

    for ( ct = PriorityQueue.Length - 1; ct >= 0; ct-- )
    {
        if ( SubjectsMatch( PriorityQueue[ct].Subject, inSubject ) )//&& PriorityQueue[ct].Action == inAction )
        {
            return true;
        }
    }

    if ( SubjectsMatch( PlayingCondition.Subject, inSubject ) && PlayingCondition.Action == inAction )
        return true;
    else
        return false;
}

// Play or queue up a condition if it's one we care about
final private function PlayCondition(Actor inSubject, Name inAction, Actor inObject)
{
    local HighGroundCondition Condition;

    Condition = FindCondition( inSubject, inAction, inObject );

    if ( Condition != NullCondition )
    {
        Condition.Instance = inSubject.Name;

        if ( IsConditionQueued( Condition.Subject, Condition.Action, Condition.Object ) )
        {
#if DEBUG_HIGHGROUNDVOLUME
            log( "Highground: Condition "$ConditionToString( Condition )$", not playing because something similair is already playing" );
#endif
            return;
        }

        if ( bStillPlaying || !bGameStarted )
        {
            QueueEvent( Condition );
        }
        else
        {
            PlayConditionEffect( Condition );
        }
    }
}

// Return the effectname in the effectssystem to trigger....
final private function name GetEffectName(HighGroundCondition inCondition)
{
    return name(string(inCondition.Subject) $ string(inCondition.Action) $ string(inCondition.Object));
}

// Hook for subclasses...
function OnConditionPlayed();
function bool ShouldRejectCondition(HighGroundCondition inCondition);

// Play the corresponding EffectEvent for this condition
final function PlayConditionEffect( HighGroundCondition inCondition )
{
    if ( ShouldRejectCondition(inCondition) )
        return;

    log( "Highground: Condition "$ConditionToString( inCondition )$", is playing it's effect event!" );

    //if ( Level.NetMode == NM_Standalone )
    //    GetAnySwatPlayer().TriggerEffectEvent( GetEffectName(inCondition), ,,,,,,Self, RoomName );
    //else
        GetAnySwatPlayer().BroadcastEffectEvent( GetEffectName(inCondition),,,,,,, Self, RoomName );
    bStillPlaying = true;
    SetTimer( inCondition.Delay, false );

    PlayingCondition = inCondition;
    OnConditionPlayed();
}

// Timer is called when a delay has timed out, if there are any pending conditions in the queue, they will be played in sorted order
event Timer()
{
    local HighGroundCondition QueuedCondition;

    QueueShrinkOnSubjectAndAction( PlayingCondition.Subject, PlayingCondition.Action );
    QueuedCondition = QueueExtract();

    if ( QueuedCondition == NullCondition  )
    {
        bStillPlaying = false;
        PlayingCondition = NullCondition;
    } else
    {
        PlayConditionEffect( QueuedCondition );
    }
}

// IEffectObserver Interface!!
simulated function OnEffectStarted(Actor inStartedEffect)
{

}

simulated function OnEffectStopped(Actor inStoppedEffect, bool Completed)
{
    if (Completed)
    {
        GetAnySwatPlayer().TriggerEffectEvent('RepliedAcknowledged', , , , , , , , 'TOC');
    }
}

simulated function OnEffectInitialized(Actor inInitializedEffect);

simulated function SwatPlayer GetAnySwatPlayer()
{
    local SwatPlayer Player;

    foreach AllActors(class 'SwatPlayer', Player)
        return Player;
}

// Event triggers, possible things that a highground volume might be interested in
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if ( Controller(Killer) != None && Controller(Killer).Pawn.IsInVolume( Self ) )
        PlayCondition( Killer, 'Killed', Pawn );
}

event PawnEnteredVolume(Pawn Other)
{
#if DEBUG_HIGHGROUNDVOLUME
    log("Highground: Pawn entered volume: "$Other);
#endif
    PlayCondition( Other, 'Entered', Self );
}

event PawnLeavingVolume(Pawn Other)
{
#if DEBUG_HIGHGROUNDVOLUME
    log("Highground: Pawn left volume: "$Other);
#endif
    if ( !class'Pawn'.static.CheckDead(Other) )
        PlayCondition( Other, 'Left', Self );
}

event ActorEnteredVolume(Actor Other)
{
#if DEBUG_HIGHGROUNDVOLUME
    log("Highground: Actor entered volume: "$Other);
#endif
    PlayCondition( Other, 'Entered', Self );
}

event ActorLeavingVolume(Actor Other)
{
#if DEBUG_HIGHGROUNDVOLUME
    log("Highground: Actor left volume: "$Other);
#endif
    PlayCondition( Other, 'Left', Self );
}

function OnPawnArrested( Pawn Arrestee, Pawn Arrester )
{
    if ( Arrestee.IsInVolume( Self ) )
        PlayCondition( Arrestee, 'Restrained', Arrestee );
}

function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if ( Pawn.IsInVolume( Self ) )
        PlayCondition( Incapacitator, 'Incapacitated', Pawn );
}

simulated event Destroyed()
{
    SwatGameInfo(Level.Game).GameEvents.PawnDied.UnRegister(self);
    SwatGameInfo(Level.Game).GameEvents.PawnArrested.UnRegister(self);
    SwatGameInfo(Level.Game).GameEvents.PawnIncapacitated.UnRegister(self);

    Super.Destroyed();
}


defaultproperties
{
    bOccludedByGeometryInEditor=true
    bStatic=false
    bStasis=false
}
