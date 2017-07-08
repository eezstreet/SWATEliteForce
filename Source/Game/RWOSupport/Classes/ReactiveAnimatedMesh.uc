class ReactiveAnimatedMesh extends ReactiveWorldObject
    native;

var() array<String> ExtraAnimationSets "If you want your ReactiveAnimatedMesh to play any animations that are not in the default (first) Animation Set for the selected Mesh, then you must add to this list any other Animation Sets that you will use.  Each entry should look like {AnimationPackageName}.{AnimationSetName}";

var() export editinline ScriptedAnimationSet Idle "If an Idle AnimationSet is specified, then the ScriptedMesh will Idle until Triggered.";
var() export editinline array<ScriptedAnimationSet> ScriptedSequence "This is a list of ExtraAnimationSets that will be played in order.";

var() enum WhenDone
{
    WhenDone_Idle,
    WhenDone_LoopLastAnimationSet,
    WhenDone_RepeatFromStart,
    WhenDone_Freeze,
    WhenDone_Destroy
} WhenDoneDo "What should this ScriptedMesh do when its done playing all ScriptedSequences";

struct native AnimatedMeshAttachment
{
    var() StaticMesh Attachment;
    var() name Socket;
};
var() editinline array<AnimatedMeshAttachment> AnimatedMeshAttachments;
var array<AnimatedMeshAttachmentModel> AnimatedMeshAttachmentModels;

struct native PreCreatedAttachment
{
    var() name Label;
    var() name Socket;
};
var() editinline array<PreCreatedAttachment> PreCreatedAttachments;

simulated function PreBeginPlay()
{
    local int i;
    local Actor PreCreatedAttachment;

    Super.PreBeginPlay();

    LoadAnimationSets(ExtraAnimationSets);

    for (i=0; i<AnimatedMeshAttachments.length; ++i)
    {
        AnimatedMeshAttachmentModels[i] = Spawn(class'AnimatedMeshAttachmentModel');
        assert(AnimatedMeshAttachmentModels[i] != None);

        assertWithDescription(AnimatedMeshAttachments[i].Attachment != None,
                "[tcohen] ReactiveAnimatedMesh::PreBeginPlay() when initializing "$name
                $", the Attachment StaticMesh specified for AnimatedMeshAttachments index "$i
                $" resolves to None.");

        AnimatedMeshAttachmentModels[i].SetStaticMesh(AnimatedMeshAttachments[i].Attachment);

        AttachToBone(AnimatedMeshAttachmentModels[i], AnimatedMeshAttachments[i].Socket);
    }

    for (i=0; i<PreCreatedAttachments.length; ++i)
    {
        PreCreatedAttachment = findByLabel(class'Actor', PreCreatedAttachments[i].Label);
        
        assertWithDescription(PreCreatedAttachment != None,
            "[tcohen] ReactiveAnimatedMesh::PreBeginPlay() when initializing "$name
            $", no actor with the Label "$PreCreatedAttachments[i].Label
            $" was found for PreCreatedAttachment index "$i
            $".");

        AttachToBone(PreCreatedAttachment, PreCreatedAttachments[i].Socket);
    }
}

simulated event Trigger(Actor Other, Pawn EventInstigator)
{
    Super.Trigger(Other, EventInstigator);

    GotoState('Running');
}

auto simulated state Idling
{
Begin:

    //don't idle if no specified idle animations
    if (Idle == None || Idle.ScriptedAnimations.length == 0)
        GotoState('');

    while (true)
        PlayAnimationFromSet(Idle);
}

simulated latent function PlayAnimationFromSet(ScriptedAnimationSet Set)
{
    local float StartTime;
    local name Animation;
    
    StartTime = Level.TimeSeconds;

    Animation = Set.SelectAnimation();
//log( self$"::PlayAnimationFromSet( "$Set$" ) ... About to PlayAnim() ... Animation = "$Animation$", StartTime = "$StartTime );
    if (Animation != '')
    {
        PlayAnim(Animation);
//log( self$"::PlayAnimationFromSet( "$Set$" ) ... About to FinishAnim()" );
        FinishAnim();
//log( self$"::PlayAnimationFromSet( "$Set$" ) ... Finished Playing animation" );

        if (Level.TimeSeconds == StartTime)
        {
            assertWithDescription(Level.TimeSeconds > StartTime,
                "[tcohen] "$name
                $" tried to play the animation named "$Animation
                $" from the ScriptedAnimationSet named "$Set.name
                $", but it did not play.  Please check that the animation names are correct, and that you've added the Animation Set to the ExtraAnimationSets list.");

            Sleep(60);  //give player a chance to quit! I was getting a nasty reboot-requiring infinite loop here!
        }
    }
}

simulated state Running
{
Begin:

    PlayScriptedSequences();

    switch (WhenDoneDo)
    {
        case WhenDone_Idle:
            GotoState('Idling');
            break;

        case WhenDone_LoopLastAnimationSet:
            //endlessly loop the last animation set
            while (true)
                PlayAnimationFromSet(ScriptedSequence[ScriptedSequence.length-1]);

            break;

        case WhenDone_RepeatFromStart:
            Goto('Begin');
            break;

        case WhenDone_Freeze:
            break;

        case WhenDone_Destroy:
            Destroy();
            break;
    }
}

simulated latent function PlayScriptedSequences()
{
    local int ScriptedSequenceIndex;
    local int ChosenLoopCount;
    local int LocalLoopCount;
//log( self$"::PlayScriptedSequences() ... ScriptedSequence.length = "$ScriptedSequence.length );
    for (ScriptedSequenceIndex=0; ScriptedSequenceIndex < ScriptedSequence.length; ++ScriptedSequenceIndex)
    {
        ChosenLoopCount = RandRange(ScriptedSequence[ScriptedSequenceIndex].LoopCount.Min, ScriptedSequence[ScriptedSequenceIndex].LoopCount.Max);
//log( self$"::PlayScriptedSequences() ... ScriptedSequenceIndex = "$ScriptedSequenceIndex$", ScriptedSequence[ScriptedSequenceIndex] = "$ScriptedSequence[ScriptedSequenceIndex]$", ChosenLoopCount = "$ChosenLoopCount$", ScriptedSequence[ScriptedSequenceIndex].LoopCount.Min = "$ScriptedSequence[ScriptedSequenceIndex].LoopCount.Min$", ScriptedSequence[ScriptedSequenceIndex].LoopCount.Max = "$ScriptedSequence[ScriptedSequenceIndex].LoopCount.Max );
        for (LocalLoopCount=0; LocalLoopCount < ChosenLoopCount; ++LocalLoopCount)
        {
//log( self$"::PlayScriptedSequences() ... ScriptedSequenceIndex = "$ScriptedSequenceIndex$", LocalLoopCount = "$LocalLoopCount$", ScriptedSequence[ScriptedSequenceIndex] = "$ScriptedSequence[ScriptedSequenceIndex] );
            PlayAnimationFromSet(ScriptedSequence[ScriptedSequenceIndex]);
        }
    }
}

simulated event Destroyed()
{
    local int i;

    Super.Destroyed();

    //destroy attachments
    for (i=0; i<AnimatedMeshAttachmentModels.length; ++i)
        AnimatedMeshAttachmentModels[i].Destroy();

    //unlink references from objects to this actor, to permit safe garbage collection
    UnlinkScriptedAnimationSet(Idle);
    
    Idle = None;
    
    for (i=0; i<ScriptedSequence.length; ++i)
        UnlinkScriptedAnimationSet(ScriptedSequence[i]);
        
    ScriptedSequence.Remove( 0, ScriptedSequence.Length );
}

//cause ScriptedAnimationSets to lose their reference to this ReactiveAnimatedMesh
//  by renaming them to the Transient package, so that their Outer is no longer this
native function UnlinkScriptedAnimationSet(ScriptedAnimationSet SAS);

defaultproperties
{
    DrawType=DT_Mesh;

    //dkaplan: RWOs no longer replicated
    //RemoteRole=ROLE_SimulatedProxy

    bAlwaysProcessState=true
}


