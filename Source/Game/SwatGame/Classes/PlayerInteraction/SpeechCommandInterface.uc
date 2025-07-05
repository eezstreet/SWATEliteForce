class SpeechCommandInterface extends CommandInterface
    implements  ISpeechClient;

import enum SpeechRecognitionConfidence from Engine.SpeechManager;

var private array<Focus>	PhraseStartFoci;  //the CommandInterface's list of Foci at the start of a speech phrase
var private int				PhraseStartFociLength;
var private array<Focus>	RecognitionFoci;  //the CommandInterface's list of Foci at the recognition of a speech phrase
var private int				RecognitionFociLength;

simulated function Initialize()
{
	Super.Initialize();
	RegisterSpeechRecognition();
}

simulated function Destroyed()
{
	Super.Destroyed();
	UnregisterSpeechRecognition();
}

simulated function RegisterSpeechRecognition()
{
	Level.GetEngine().SpeechManager.RegisterInterest(self);
}

simulated function UnregisterSpeechRecognition()
{
	Level.GetEngine().SpeechManager.UnRegisterInterest(self);
}

simulated protected function PostDeactivated()
{
	Super.PostDeactivated();
	UnregisterSpeechRecognition();
}

simulated function ProcessRule(name Rule, name Value)
{
	local int i;

	switch (Rule)
	{
		case 'Team':
			switch (Value)
			{
				case 'RedTeam':
					SetCurrentTeam(RedTeam);
					break;
				case 'BlueTeam':
					SetCurrentTeam(BlueTeam);
					break;
				case 'Element':
					SetCurrentTeam(Element);
					break;
			}
			break;

		case 'HoldRecognizedCommand':
			for (i=0; i<Commands.Length - 1; ++i)
			{
				if (GetEnum(ECommand, Commands[i].Command) == Value)
				{
					log("[SPEECHCOMMAND] Held speech command"@GetEnum(ECommand, Commands[i].Command));
					GiveCommand(Commands[i], true);
					break;
				}
			}
			break;

		case 'Command':
			for (i=0; i<Commands.Length - 1; ++i)
			{
				if (GetEnum(ECommand, Commands[i].Command) == Value)
				{
					log("[SPEECHCOMMAND] Recognized speech command"@GetEnum(ECommand, Commands[i].Command));
					GiveCommand(Commands[i], false);
					break;
				}
			}
			break;

		case 'Actions':
			if(Value == 'TOCReport') {
				IssueTOCOrder();
			} else if(Value == 'Compliance') {
				IssueComplianceOrder();
			}
			break;

		default:
			log("[SPEECHCOMMAND] Unknown rule.");
	}
}

//ISpeechClient implementation
simulated function OnSpeechPhraseStart()
{
	log("[SPEECHCOMMAND] Speech phrase start outside of state.");
}

//called by the speech recognition system when a speech command is recognized
simulated function OnSpeechCommandRecognized(name Rule, Array<name> Value, SpeechRecognitionConfidence Confidence)
{
	log("[SPEECHCOMMAND] Speech recognised outside of state.");
}

function OnSpeechFalseRecognition()
{
	log("[SPEECHCOMMAND] False recognition outside of state.");
}

function OnSpeechAudioLevel(int Value)
{
}

// CommandInterface overrides
simulated function bool ShouldSpeakTeam()
{
	return false;
}

simulated function bool ShouldSpeak()
{
	return false;
}

simulated function IssueComplianceOrder()
{
	local SwatGamePlayerController Player;

	Player = SwatGamePlayerController(Level.GetLocalPlayerController());

	Player.ServerIssueCompliance();
}

simulated function IssueTOCOrder()
{
	local SwatGamePlayerController PlayerController;
	local SwatPlayer Player;
	local Actor Target;
	local SwatAI TargetAI;
	local array<IInterested_GameEvent_ReportableReportedToTOC> Interested;
	local int i;
	local name EffectEventName;
	local bool IsReported;
	local SwatAI AIListener;
	local SwatPlayer PlayerListener;

	PlayerController = SwatGamePlayerController(Level.GetLocalPlayerController());
	if (PlayerController == None) return;
	Player = PlayerController.GetSwatPlayer();
	if (Player == None) return;
	
	Target = GetPendingTOCReportTargetActor();
	TargetAI = SwatAI(Target);
	
	//if the target is an AI and can be used, report them to TOC _without triggering the report effect_
	//(we still get the sound effect for the response from TOC)
	if (TargetAI == None) {
		//PlayerController.IssueMessage("No valid TargetAI", 'SpeechManagerNotification'); //for easy debugging
	} else {
		if (!TargetAI.CanBeUsedNow()) {
			//PlayerController.IssueMessage("This AI can't be used now", 'SpeechManagerNotification'); //for easy debugging
		} else {
			//get the array of all listeners that have been registered to the TOC event
			Interested = SwatGameInfo(Level.Game).GameEvents.ReportableReportedToTOC.Interested;
			//loop through the listeners and call the ones that don't trigger sound effects
			for (i=0; i<Commands.Length - 1; ++i)
			{
				//listeners on SwatAI and on the Player will trigger sound effects, so we don't trigger them
				AIListener = SwatAI(Interested[i]);
				PlayerListener = SwatPlayer(Interested[i]);
				if (AIListener == None && PlayerListener == None)
				{
					Interested[i].OnReportableReportedToTOC(TargetAI, Player);
					IsReported = true;
				}
			}
			if (IsReported) {
				TargetAI.PostUsed(); //mark the target as reported
				//try to play the response-from-toc sound effect
				EffectEventName = TargetAI.GetEffectEventForReportResponseFromTOC();
				if (EffectEventName != '') 
				{
					Player.TriggerEffectEvent(EffectEventName, TargetAI, , , , , , , 'TOC');
				}
			}
		}
	}
}

simulated function GiveCommandSP()
{
	local CommandInterface CurrentCommandInterface;
	local SwatGamePlayerController Player;

	// get the current graphic command interface
    Player = SwatGamePlayerController(Level.GetLocalPlayerController());
    CurrentCommandInterface = Player.GetCommandInterface();

	CurrentCommandInterface.CurrentSpeechCommand = GetColorizedCommandText(PendingCommand);
	CurrentCommandInterface.CurrentSpeechCommandTime = Player.Level.TimeSeconds + 2;

	Super.GiveCommandSP();
}

simulated function GiveCommandMP()
{
	// should never get here
	log("[SPEECHCOMMAND] Error - in multiplayer.");
}

function StartCommand()
{
    if (SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState != GAMESTATE_MidGame)
    {
        GotoState('');
        return;
    }

    SendCommandToOfficers();
}

// override - this interface just re-uses the current command interface's foci
simulated function PostUpdate(SwatGamePlayerController Player)
{
	Super.PostUpdate(Player);

	Foci = Player.GetCommandInterface().Foci;
	FociLength = Player.GetCommandInterface().FociLength;
	LastFocusUpdateOrigin = Player.GetCommandInterface().LastFocusUpdateOrigin;
}

// override - return the focus the player was viewing at the start of speech if it was a better match
simulated protected function Actor GetPendingCommandTargetActor()
{
	local Actor FocusActor;
	
	// try foci at recognition
	PendingCommandFoci = RecognitionFoci;
	PendingCommandFociLength = RecognitionFociLength;
	log("[SPEECHCOMMAND] Try recognition foci ("$PendingCommandFoci[0].Actor$")");
	FocusActor = Super.GetPendingCommandTargetActor();

	if (FocusActor == None)
	{
		// try foci at phrase start
		PendingCommandFoci = PhraseStartFoci;
		PendingCommandFociLength = PhraseStartFociLength;
		log("[SPEECHCOMMAND] Try phrase start foci ("$PendingCommandFoci[0].Actor$")");
		FocusActor = Super.GetPendingCommandTargetActor();
	}
	
	return FocusActor;
}

//Get the pending command target actor using different logic to support AI characters
simulated protected function Actor GetPendingTOCReportTargetActor()
{
	local Actor FocusActor;

	// try foci at recognition
	PendingCommandFoci = RecognitionFoci;
	PendingCommandFociLength = RecognitionFociLength;
	log("[SPEECHCOMMAND] Try recognition foci ("$PendingCommandFoci[0].Actor$")");
	FocusActor = PendingCommandFoci[0].Actor;

	if (FocusActor == None)
	{
		// try foci at phrase start
		PendingCommandFoci = PhraseStartFoci;
		PendingCommandFociLength = PhraseStartFociLength;
		log("[SPEECHCOMMAND] Try phrase start foci ("$PendingCommandFoci[0].Actor$")");
		FocusActor = PendingCommandFoci[0].Actor;
	}

	return FocusActor;
}

// States
// We are waiting for speech input from the user
auto state WaitingForSpeech
{
	simulated function OnSpeechPhraseStart()
	{
		// save foci at time of phrase start detection
		PhraseStartFoci = Foci;
		PhraseStartFociLength = FociLength;

		log("[SPEECHCOMMAND] Begin recognition, got phrase start foci"@PhraseStartFociLength);
		GotoState('ProcessingSpeech');
	}

	simulated function OnSpeechCommandRecognized(name Rule, Array<name> Value, SpeechRecognitionConfidence Confidence)
	{
		// do nothing
	}

	function OnSpeechFalseRecognition()
	{
		// who cares?
	}
}

// Speech is being received and decoded
state ProcessingSpeech
{
	simulated function OnSpeechPhraseStart()
	{
		// do nothing
	}

	simulated function OnSpeechCommandRecognized(name Rule, Array<name> Value, SpeechRecognitionConfidence Confidence)
	{
		// save foci at time of recognition
		RecognitionFoci = Foci;
		RecognitionFociLength = FociLength;

		switch (Rule)
		{
			case 'TeamAndCommand':
				ProcessRule('Team', Value[0]);
				ProcessRule('Command', Value[1]);
				break;

			case 'HoldCommand':
				ProcessRule('HoldRecognizedCommand', Value[1]);
				break;

			case 'TeamAndHoldCommand':
				ProcessRule('Team', Value[0]);
				ProcessRule('HoldRecognizedCommand', Value[2]);
				break;

			default:
				ProcessRule(Rule, Value[0]);
				break;
		}

		GotoState('WaitingForSpeech');
	}

	function OnSpeechFalseRecognition()
	{
		log("[SPEECHCOMMAND] Bad speech.");
		GotoState('WaitingForSpeech');
	}
}

defaultproperties
{
    bStatic=false
    Physics=PHYS_None
    bStasis=true

	AlwaysPostUpdate = true
	ValidateCommandFocus = false;

    CommandClass=class'Command_SP'
    StaticCommandsClass=class'CommandInterfaceStaticCommands_SP'
    MenuInfoClass=class'CommandInterfaceMenuInfo_SP'
    ContextsListClass=class'CommandInterfaceContextsList_SP'
    ContextClass=class'CommandInterfaceContext_SP'
    DoorRelatedContextClass=class'CommandInterfaceDoorRelatedContext_SP'
}
