class QualifiedUseEquipment extends Engine.HandheldEquipment
    implements IAmAQualifiedUseEquipment
    abstract;

//In order to use a QualifiedUseEquipment, the player must first
//  "qualify", ie. hold the use button for a minimum amount of time.

var private config float NoArmorQualifyMultiplier;

var protected float UseBeginTime;
var protected bool Interrupted;

function PostBeginPlay()
{
    Super.PostBeginPlay();

    Disable('Tick');
}

simulated function float GetQualifyDuration() { assert(false); return 0; }   //TMC TODO remove this... it is here to work-around bug 79

simulated function float CalcQualifyDuration()
{
	local float CalculatedDuration;
	local SwatPlayer SP;

	CalculatedDuration = GetQualifyDuration();

	SP = SwatPlayer(Owner);

	if (SP != None && SP.GetLoadOut() != None && SP.GetLoadOut().HasNoArmor())
		CalculatedDuration *= NoArmorQualifyMultiplier;

	return CalculatedDuration;
}

// PreUse() gets called before GotoState('BeingUsed') in HandheldEquipment. We
// need to set Interrupted to false here, in case an interrupt comes in from
// the server in the single tick between the GotoState() and when the Begin:
// label of 'BeingUsed' starts executing (don't ask; we've actually seen it
// happen).
simulated function PreUse()
{
    Super.PreUse();
    mplog( self$"...setting Interrupted to false." );
    Interrupted = false;
}


simulated latent protected function DoUsingHook()
{
    local GUIProgressBar Progress;
    local bool UseAlternate;

    local QualifiedUseEquipmentModel QualifiedUseFirstPersonModel;
    local QualifiedUseEquipmentModel QualifiedUseThirdPersonModel;

    local bool OwnerIsLocalPlayer;

    mplog( self$"---QualifiedUseEquipment::DoUsingHook()." );

    //Hack: In case we ever want an EquipmentUsedOnOther that isn't QualifiedUseEquipment,
    //  we can consider a QualifyDuration of 0 to mean no qualification necessary.
    //Another potential way to handle this case (which we don't expect!) is to delegate
    //  all IAmUsedOnOther and IAmAQualifiedUseEquipment methods to implementation
    //  objects, thus mimicing multiple inheritance of implementation (which is what
    //  we ideally would like to do here).
    //But we currently don't expect to have anything that is EquipmentUsedOnOther but
    //  not QualifiedUseEquipment.  So this shouldn't be necessary.
    //
    //if (GetQualifyDuration() == 0)
    //{
    //  Super.DoUsingHook();
    //  return;
    //}

    OwnerIsLocalPlayer = (Pawn(Owner) == SwatGamePlayerController(Level.GetLocalPlayerController()).Pawn);

    Progress = SwatGamePlayerController(Level.GetLocalPlayerController()).GetHUDPage().Progress;
    UseAlternate = ShouldUseAlternate();    //does subclass want to use alternate using animations?

    if (FirstPersonModel != None)
    {
        QualifiedUseFirstPersonModel = QualifiedUseEquipmentModel(FirstPersonModel);
        assertWithDescription(QualifiedUseFirstPersonModel != None,
            "[tcohen] The FirstPersonModel "$FirstPersonModel.class.name
            $" specified for "$class.name
            $" (in SwatEquipment.ini) is not a QualifiedUseEquipmentModel. "
            $" Models for QualifiedUseEquipment must be QualifiedUseEquipmentModels.");
    }

    if (ThirdPersonModel != None)
    {
        QualifiedUseThirdPersonModel = QualifiedUseEquipmentModel(ThirdPersonModel);
        assertWithDescription(QualifiedUseThirdPersonModel != None,
            "[tcohen] The ThirdPersonModel "$ThirdPersonModel.class.name
            $" specified for "$class.name
            $" (in SwatEquipment.ini) is not a QualifiedUseEquipmentModel. "
            $" Models for QualifiedUseEquipment must be QualifiedUseEquipmentModels.");
    }

    if (QualifiedUseFirstPersonModel != None)
    {
        QualifiedUseFirstPersonModel.PlayBeginQualify(UseAlternate);
        QualifiedUseFirstPersonModel.TriggerEffectEvent('QualifyBegan');
    }
    if (QualifiedUseThirdPersonModel != None)
    {
        QualifiedUseThirdPersonModel.PlayBeginQualify(UseAlternate);
        QualifiedUseThirdPersonModel.TriggerEffectEvent('QualifyBegan');
    }

    OnUsingBegan();

    if (QualifiedUseFirstPersonModel != None)
        QualifiedUseFirstPersonModel.FinishBeginQualify(UseAlternate);
    if (QualifiedUseThirdPersonModel != None)
        QualifiedUseThirdPersonModel.FinishBeginQualify(UseAlternate);

    UseBeginTime = Level.TimeSeconds;

    if (OwnerIsLocalPlayer)
    {
        Progress.Reposition('up');
        Progress.Value = 0.0; //bad Terry! must set this initially because we wait for our own first tick before updating
        Enable('Tick');
    }

    if (QualifiedUseFirstPersonModel != None)
    {
        QualifiedUseFirstPersonModel.PlayQualifyLoop(UseAlternate);
        QualifiedUseFirstPersonModel.TriggerEffectEvent('Qualifying');
    }
    if (QualifiedUseThirdPersonModel != None)
    {
        QualifiedUseThirdPersonModel.PlayQualifyLoop(UseAlternate);
        QualifiedUseThirdPersonModel.TriggerEffectEvent('Qualifying');
    }

    //wait to finish or be interrupted
    while (!Interrupted && Level.TimeSeconds < UseBeginTime + CalcQualifyDuration())
        Sleep(0);

    if (QualifiedUseFirstPersonModel != None)
        QualifiedUseFirstPersonModel.UnTriggerEffectEvent('Qualifying');
    if (QualifiedUseThirdPersonModel != None)
        QualifiedUseThirdPersonModel.UnTriggerEffectEvent('Qualifying');

    if (OwnerIsLocalPlayer)
    {
    Disable('Tick');
    Progress.Reposition('down');
    }

    if (!Interrupted)
    {
        //we qualified!

        if (Level.NetMode != NM_Client)
        {
            DoQualifyComplete();
        }

        if (QualifiedUseFirstPersonModel != None)
            QualifiedUseFirstPersonModel.UnTriggerEffectEvent('Qualified');
        if (QualifiedUseThirdPersonModel != None)
            QualifiedUseThirdPersonModel.UnTriggerEffectEvent('Qualified');
    }
    else
    {
        if (QualifiedUseFirstPersonModel != None)
            QualifiedUseFirstPersonModel.UnTriggerEffectEvent('QualifyInterrupted');
        if (QualifiedUseThirdPersonModel != None)
            QualifiedUseThirdPersonModel.UnTriggerEffectEvent('QualifyInterrupted');
    }

    if (QualifiedUseFirstPersonModel != None)
        QualifiedUseFirstPersonModel.PlayEndQualify(UseAlternate);
    if (QualifiedUseThirdPersonModel != None)
        QualifiedUseThirdPersonModel.PlayEndQualify(UseAlternate);

    if (QualifiedUseFirstPersonModel != None)
        QualifiedUseFirstPersonModel.FinishEndQualify(UseAlternate);
    if (QualifiedUseThirdPersonModel != None)
        QualifiedUseThirdPersonModel.FinishEndQualify(UseAlternate);
}

simulated latent protected function OnUsingBegan()
{
    Pawn(Owner).ChangeAnimation();
}

simulated function OnUsingFinishedHook()
{
    Pawn(Owner).ChangeAnimation();
}

simulated function DoQualifyComplete()
{
	local PlayerController OwnerPC;

	if (Owner.IsA('ICanQualifyForUse'))
        ICanQualifyForUse(Owner).OnQualifyCompleted();

    OnUseKeyFrame();

	// dbeswick: stats
	OwnerPC = PlayerController(Pawn(Owner).Controller);
	if (OwnerPC != None)
	{
		OwnerPC.Stats.Used(class.Name);
	}
}

simulated function bool ShouldUseAlternate()
{
    return false;
}

//call Interrupt() while a QualifiedUseEquipment() is being Used to interrupt & cancel the
//  qualification process and therefore cancel the Use().
simulated final function Interrupt()
{
    local SwatGamePlayerController LPC;
    local QualifiedUseEquipmentModel QualifiedUseFirstPersonModel;
    local QualifiedUseEquipmentModel QualifiedUseThirdPersonModel;

    mplog( self$"---QualifiedUseEquipment::Interrupt()." );

	// if we've already been interrupted, don't do anything
	if (Interrupted)
		return;

    Interrupted = true;

    if ( Level.NetMode == NM_Standalone )
    {
        DoInterrupt();
    }
    else
    {
        // In a network game, we ask the server to interrupt for us.
        LPC = SwatGamePlayerController(Level.GetLocalPlayerController());
        if( LPC != None )
            LPC.ServerRequestQualifyInterrupt();
    }

    QualifiedUseFirstPersonModel = QualifiedUseEquipmentModel(FirstPersonModel);
    if (QualifiedUseFirstPersonModel != None)
    {
        QualifiedUseFirstPersonModel.OnInterrupted();
    }

    QualifiedUseThirdPersonModel = QualifiedUseEquipmentModel(ThirdPersonModel);
    if (QualifiedUseThirdPersonModel != None)
    {
        QualifiedUseThirdPersonModel.OnInterrupted();
    }
}

//HACK AIs need to be able to interrupt qualification and have the item
//  go back to UsingStatus=Idle before the next tick.
//This is ugly, but Crombie says that the AIs will clean up after themselves.
final function InstantInterrupt()
{
  log("QualifiedUseEquipment::InstantInterrupt step 0");
    Interrupt();
  log("QualifiedUseEquipment::InstantInterrupt step 1");
	OnUsingFinished();
  log("QualifiedUseEquipment::InstantInterrupt step 2");
}

simulated function OnInterrupted();

function DoInterrupt()
{
    mplog( self$"---QualifiedUseEquipment::DoInterrupt()." );

    // Because DoInterrupt() is called for Equipment that is owned by a remote
    // pawn, which means that Interrupt() wasn't called for it on the server,
    // Interrupted would not have been set to true so set it here.
    Interrupted = true;

    ICanQualifyForUse(Owner).OnQualifyInterrupted();
    OnInterrupted();
}

function Tick(float dTime)
{
    local SwatGamePlayerController LPC; //(need to move this class into SwatGame)

    LPC = SwatGamePlayerController(Level.GetLocalPlayerController());
    if ( LPC != None && Pawn(Owner) == LPC.Pawn)        //our owner is the local player
        LPC.GetHUDPage().Progress.Value = (Level.TimeSeconds - UseBeginTime)/CalcQualifyDuration();
}

//overridden from HandheldEquipment
protected function AIInterrupt_Using()
{
    log("QualifiedUseEquipment::AIInterrupt_Using step 0");
    InstantInterrupt();
    log("QualifiedUseEquipment::AIInterrupt_Using step 1");
}
