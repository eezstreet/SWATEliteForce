class Conversation extends Core.Object
    implements IEffectObserver
    config(Conversations)
    perObjectConfig
    threaded
    native;

struct native DialogLine
{
    var config name Speaker;
    var config name Speech;
    var bool Skippable;
    var config float DelayAfter;
};

var config array<DialogLine> Line;     //named in the singular for simplicity of the config file

var private int CurrentLineIndex;
var private float CurrentDelay;
var private Actor CurrentSpeaker;
var private bool bShouldCurrentSpeakerMoveMouth;
var private SoundEffectsSubsystem SoundEffectsSubsystem;

var private ConversationManager Manager;

function Start(ConversationManager inManager)
{
log("[CONVERSATION] Starting Conversation "$name);

    Manager = inManager;

    SoundEffectsSubsystem =
        SoundEffectsSubsystem(EffectsSystem(Manager.Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem'));

    AssertWithDescription(SoundEffectsSubsystem != None,
        "[tcohen] Conversation::Start() couldn't locate the SoundEffectsSubsystem.");

    StartLine();
}

function StartLine()
{
    local float SpeakerDistance;
    local Pawn PlayerPawn;
    local SoundEffectSpecification SoundEffectSpec;

    CurrentDelay = Manager.DefaultInterLineDelay;
    if (Line[CurrentLineIndex].DelayAfter > 0)
        CurrentDelay = Line[CurrentLineIndex].DelayAfter;

log("[CONVERSATION] Conversation "$name$" starting Line #"$CurrentLineIndex$" (base zero)");

    bShouldCurrentSpeakerMoveMouth = true;
    CurrentSpeaker = LocateAvailableSpeaker(Line[CurrentLineIndex].Speaker);

    //check if the specified speaker doesn't exist or is unavailable
    if ( CurrentSpeaker == None || CurrentSpeaker.bDeleteMe ) 
    {
log("[CONVERSATION] Conversation "$name$" Line #"$CurrentLineIndex$": "$Line[CurrentLineIndex].Speaker$" could not be located.");

        HandleUnavailableSpeaker();
        return;
    }

    // Carlos: The player has died, no point in carrying on conversations!  Also conveniently prevents an access violation in 
    // GetSoundPropagationDistance...
    if( Manager.Level.GetLocalPlayerController() != None )
        PlayerPawn = Manager.Level.GetLocalPlayerController().Pawn;
    if ( PlayerPawn == None || !class'Pawn'.static.checkConscious(PlayerPawn) )
    {
        return;
    }

    //check if the speaker is too far away to be heard
    SpeakerDistance = GetSoundPropagationDistance(PlayerPawn, CurrentSpeaker.Location);

    SoundEffectSpec = SoundEffectSpecification(
        SoundEffectsSubsystem.FindEffectSpecification(Line[CurrentLineIndex].Speech));

    assertWithDescription(SoundEffectSpec != None,
        "[tcohen] Conversation::StartLine() The Conversation named "$name
        $" tried to find the Speech named "$Line[CurrentLineIndex].Speech
        $" specified in Line #"$CurrentLineIndex
        $" (base zero), but that SoundEffectSpecification was not found.");

    if (!SoundEffectSpec.IsLocal() && SoundEffectSpec.GetOuterRadius() < SpeakerDistance)
    {
        log("[CONVERSATION] Conversation "$name
                $" Line #"$CurrentLineIndex$": "$Line[CurrentLineIndex].Speaker
                $" is too far away to speak his/her Line (SpeakerDistance="$SpeakerDistance
                $", "$SoundEffectSpec.name
                $".OuterRadius="$SoundEffectSpec.GetOuterRadius()
                $".");

        HandleUnavailableSpeaker();
        return;
    }

    //okay, the speaker is available... play the line

    SoundEffectsSubsystem.PlayEffectSpecification(
        SoundEffectSpec,    //EffectSpec
        CurrentSpeaker,     //Source
        ,                   //Target
        ,                   //TargetMaterial
        ,                   //overrideWorldLocation
        ,                   //overrideWorldRotation
        self);              //IEffectObserver Observer
}

function Actor LocateAvailableSpeaker(name SpeakerLabel)
{
    local Actor Speaker;

    SubstituteSpeakerAliases(SpeakerLabel);    

    Speaker = Manager.findStaticByLabel(class'Actor', SpeakerLabel);

    if (Speaker == None)                                return None;    //no speaker with that label

    if  (
            Speaker.IsA('Pawn')
        &&  !Pawn(Speaker).IsConscious()
        )                                               return None;    //the speaker is dead or unconscious

    return Speaker;
}

//some speakers are known by special names, for example,
//  'TOC' (for Tactical Operations Center) is an alias
//  for the Player, since TOC's lines should actually
//  be played on the player to simulate the voice coming
//  from the Team Lead's earphone.
function SubstituteSpeakerAliases(out name SpeakerLabel)
{
    switch (SpeakerLabel)
    {
    case 'TOC':
        SpeakerLabel = 'Player';
        bShouldCurrentSpeakerMoveMouth = false;
        break;
    
    //no default case here
    //
    //default:
    }
}

function HandleUnavailableSpeaker()
{
log("[CONVERSATION] Conversation "$name$" Line #"$CurrentLineIndex$": "$Line[CurrentLineIndex].Speaker$" is unavailable to speak his/her Line.");

    if (Line[CurrentLineIndex].Skippable)
        GotoState('DelayingUntilNextLine');
    else
        OnConversationEnded(self, false);       //did not complete
}

function HandleInterruptedSpeaker()
{
log("[CONVERSATION] Conversation "$name$" Line #"$CurrentLineIndex$": "$Line[CurrentLineIndex].Speaker$" was interrupted.");

    //For now, we'll treat interrupted Speakers as if they
    //  were unavailable to begin with.
    HandleUnavailableSpeaker();
}

state DelayingUntilNextLine
{
Begin:

    Sleep(CurrentDelay);

    CurrentLineIndex++;

    if (CurrentLineIndex < Line.Length)
        StartLine();
    else
        OnConversationEnded(self, True);    //completed
}

delegate OnConversationEnded(Conversation Conversation, bool Completed);

native function float GetSoundPropagationDistance(Actor Listener, Vector SoundLocation);

// IEffectObserver implementation

function OnEffectStarted(Actor inStartedEffect)
{
    local SwatPawn CurrentSwatPawnSpeaker;
    // If bShouldCurrentSpeakerMoveMouth is true and the speaker is a SwatPawn, we
    // start moving the mouth on the pawn.
    if (bShouldCurrentSpeakerMoveMouth)
    {
        CurrentSwatPawnSpeaker = SwatPawn(CurrentSpeaker);
        if (CurrentSwatPawnSpeaker != None)
        {
            CurrentSwatPawnSpeaker.StartMouthMovement();
        }
    }
}

function OnEffectStopped(Actor inStoppedEffect, bool Completed)
{
    local SwatPawn CurrentSwatPawnSpeaker;
    // If bShouldCurrentSpeakerMoveMouth is true and the speaker is a SwatPawn, we
    // start moving the mouth on the pawn.
    if (bShouldCurrentSpeakerMoveMouth)
    {
        CurrentSwatPawnSpeaker = SwatPawn(CurrentSpeaker);
        if (CurrentSwatPawnSpeaker != None)
        {
            CurrentSwatPawnSpeaker.StopMouthMovement();
        }
    }

    if (Completed)
        GotoState('DelayingUntilNextLine');
    else
        //The Line was cut-off.
        //This can happen because
        //  a) there was already a higher priority sound in the same group was
        //      already playing on the speaker, or
        //  b) a higher priority sound in the same group was started on the
        //      speaker before the Line completed.
        HandleInterruptedSpeaker();
}

function OnEffectInitialized(Actor inInitializedEffect);



function CleanupActorRefs()
{
    Manager=None;
    CurrentSpeaker=None;
}
