class SwatChatPanel extends SwatGUIPanel
    ;

import enum EInputKey from Engine.Interactions;
import enum EInputAction from Engine.Interactions;
import enum EquipmentSlot from Engine.HandheldEquipment;
import enum EMPMode from Engine.Repo;

var(SWATGui) EditInline Config SwatChatEntry  MyChatEntry;
var(SWATGui) EditInline Config GUIListBox  MyChatHistory;

var private bool bGlobal;

var(StaticConfig)   Config  int     MaxChatLines "Maximum number of lines used for chat";
var(StaticConfig)   Config  int     MSGTimeout "Time (in seconds) for messages to remain before being pulled (0 = never pull)";
var(StaticConfig)   Config  bool    bDisplayDeaths "if true, will display death messages";
var(StaticConfig)   Config  bool    bDisplayConnects "if true, will display connect/disconnect messages";

var() private config localized string TeamChatMessage;
var() private config localized string GlobalChatMessage;
var() private config localized string TeamChatMessageLocalized;
var() private config localized string GlobalChatMessageLocalized;

var() private config localized string NameChangeMessage;
var() private config localized string KickMessage;
var() private config localized string BanMessage;
var() private config localized string SwitchTeamsMessage;

var() private config localized string StatsValidatedMessage;
var() private config localized string StatsBadProfileMessage;

var() private config localized string COOPMessageLeaderSelected;
var() private config localized string CoopQMMMessage;

var() private config localized string SwatSuicideMessage;
var() private config localized string SuspectsSuicideMessage;

var() private config localized string SwatTeamKillMessage;
var() private config localized string SuspectsTeamKillMessage;

var() private config localized string SwatKillMessage;
var() private config localized string SuspectsKillMessage;

var() private config localized string SwatArrestMessage;
var() private config localized string SuspectsArrestMessage;

var() private config localized string YesVoteMessage;
var() private config localized string NoVoteMessage;

var() private config localized string ReferendumStartedMessage;

var() private config localized string ReferendumAlreadyActiveMessage;
var() private config localized string ReferendumStartCooldownMessage;
var() private config localized string PlayerImmuneFromReferendumMessage;
var() private config localized string ReferendumAgainstAdminMessage;
var() private config localized string ReferendumsDisabledMessage;
var() private config localized string LeaderVoteTeamMismatchMessage;

var() private config localized string ReferendumSucceededMessage;
var() private config localized string ReferendumFailedMessage;

var() private config localized string ConnectedMessage;
var() private config localized string DisconnectedMessage;

var() private config localized string EquipNotAvailableString;
var() private config localized string SniperAlertedString;
var() private config localized string NewObjectiveString;
var() private config localized string ObjectiveCompleteString;
var() private config localized string MissionCompletedString;
var() private config localized string MissionFailedString;
var() private config localized string SettingsUpdatedString;
var() private config localized string DebugMessageString;

var() private config localized string StatsMessage;

var() private config localized string PromptToDebriefMessage;
var() private config localized string SomeoneString;

var() private config localized string SlotNames[EquipmentSlot.EnumCount];

var() private Config localized string SmashAndGrabGotItemMessage;
var() private Config localized string SmashAndGrabDroppedItemMessage;
var() private Config localized string SmashAndGrabArrestTimeDeductionMessage;


struct ChatLine
{
    var() string Msg;
    var() bool bIsChat;
};

var() array<ChatLine> FullChatHistory;
var() int ChatIndex;


function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    SwatGuiController(Controller).SetChatPanel( self );

    MyChatEntry.OnEntryCompleted = InternalOnEntryCompleted;
    MyChatEntry.OnEntryCancelled = InternalOnEntryCancelled;
    SetFocusInstead(MyChatEntry);

    MyChatEntry.bCaptureMouse=false;
    MyChatHistory.bCaptureMouse=false;
}

event Show()
{
    MyChatHistory.Show();
    Super.Show();
    if( MSGTimeout > 0 )
        SetTimer( MSGTimeout, true );

    if( SwatGuiController(Controller).EnteredChatText == "" )
        CloseChatEntry();
    else
        OpenChatEntry(SwatGuiController(Controller).EnteredChatGlobal);
}

event Hide()
{
    Super.Hide();

    SwatGuiController(Controller).EnteredChatGlobal=bGlobal;
    SwatGuiController(Controller).EnteredChatText=MyChatEntry.GetText();
}

function string GetWeaponFriendlyName(string ClassName)
{
	local class<DamageType> C;

	C = class<DamageType>(DynamicLoadObject(ClassName, class'Class'));
	if (C != None)
		return C.static.GetFriendlyName();   //this actually calls polymorphically into the DamageType subclass!
	else
		return ClassName;
}

function MessageRecieved( String MsgText, Name Type, optional bool bDisplaySpecial )
{
    local string StrA, StrB, StrC, Keys, DisplayPromptString;
    local bool MsgIsChat, DisplayPromptToDebriefMessage;

    StrA = GetFirstField(MsgText,"\t");
    StrB = GetFirstField(MsgText,"\t");
    StrC = GetFirstField(MsgText,"\t");

    switch (Type)
    {
        case 'EquipNotAvailable':
            MsgText = FormatTextString( EquipNotAvailableString, SlotNames[ int(StrA) ] );
            break;

        case 'SpeechManagerNotification':
        case 'Caption':
            MsgText = StrA;
            break;

        case 'SniperAlerted':
            Keys = PlayerOwner().ConsoleCommand("GETLOCALIZEDKEYFORBINDING ShowViewport Sniper");
            MsgText = FormatTextString( SniperAlertedString, GetFirstField(Keys,", ") );
            break;

        case 'Penalty':
            MsgText = FormatTextString( MsgText, StrA );
            break;
        case 'ObjectiveShown':
            MsgText = NewObjectiveString;
            break;
        case 'ObjectiveCompleted':
            MsgText = ObjectiveCompleteString;
            break;
        case 'MissionCompleted':
            MsgText = MissionCompletedString;
            break;
        case 'MissionFailed':
            MsgText = MissionFailedString;
            break;

        case 'SettingsUpdated':
            MsgText = FormatTextString( SettingsUpdatedString, StrA );
            break;

        case 'TeamSay':
            MsgText = FormatTextString( TeamChatMessage, StrA, StrB );
            MsgIsChat = true;
            break;

        case 'Say':
            MsgText = FormatTextString( GlobalChatMessage, StrA, StrB );
            MsgIsChat = true;
            break;

        case 'SayLocalized':
            MsgText = FormatTextString(GlobalChatMessageLocalized, StrA, StrB, StrC);
            MsgIsChat = true;
            break;

        case 'TeamSayLocalized':
            MsgText = FormatTextString(TeamChatMessageLocalized, StrA, StrB, StrC);
            MsgIsChat = true;
            break;

		case 'StatsValidatedMessage':
			MsgText = StatsValidatedMessage;
			break;
		case 'StatsBadProfileMessage':
			MsgText = StatsBadProfileMessage;
			break;

        case 'SwitchTeams':
            MsgText = FormatTextString( SwitchTeamsMessage, StrA );
            break;
        case 'NameChange':
            MsgText = FormatTextString( NameChangeMessage, StrA, StrB );
            break;
        case 'Kick':
            MsgText = FormatTextString( KickMessage, StrA, StrB );
            break;
        case 'KickBan':
            MsgText = FormatTextString( BanMessage, StrA, StrB );
            break;
		case 'CoopLeaderPromoted':
			MsgText = FormatTextString( COOPMessageLeaderSelected, StrA );
			break;
		case 'CoopQMM':
		case 'CoopMessage':
			MsgText = FormatTextString( CoopQMMMessage, StrA );
			break;

		case 'YesVote':
			MsgText = FormatTextString( YesVoteMessage, StrA );
			break;

		case 'NoVote':
			MsgText = FormatTextString( NoVoteMessage, StrA );
			break;

    case 'ReferendumStarted':
      MsgText = FormatTextString(ReferendumStartedMessage, MsgText);
      break;

		case 'ReferendumAlreadyActive':
			MsgText = FormatTextString( ReferendumAlreadyActiveMessage );
			break;

		case 'ReferendumStartCooldown':
			MsgText = FormatTextString( ReferendumStartCooldownMessage );
			break;

		case 'PlayerImmuneFromReferendum':
			MsgText = FormatTextString( PlayerImmuneFromReferendumMessage, StrA );
			break;

		case 'ReferendumAgainstAdmin':
			MsgText = FormatTextString( ReferendumAgainstAdminMessage );
			break;

		case 'ReferendumsDisabled':
			MsgText = FormatTextString( ReferendumsDisabledMessage );
			break;

		case 'LeaderVoteTeamMismatch':
			MsgText = FormatTextString( LeaderVoteTeamMismatchMessage );
			break;

		case 'ReferendumSucceeded':
			MsgText = FormatTextString( ReferendumSucceededMessage );
			break;

		case 'ReferendumFailed':
			MsgText = FormatTextString( ReferendumFailedMessage );
			break;

		case 'SwatSuicide':
            MsgText = FormatTextString( SwatSuicideMessage, StrA );
            break;
        case 'SuspectsSuicide':
            MsgText = FormatTextString( SuspectsSuicideMessage, StrA );
            break;
        case 'SwatTeamKill':
            if( StrB == "" )
                StrB = SomeoneString;
            MsgText = FormatTextString( SwatTeamKillMessage, StrA, StrB, GetWeaponFriendlyName(StrC) );
            break;
        case 'SuspectsTeamKill':
            if( StrB == "" )
                StrB = SomeoneString;
			MsgText = FormatTextString( SuspectsTeamKillMessage, StrA, StrB, GetWeaponFriendlyName(StrC) );
            break;
        case 'SwatKill':
            if( StrB == "" )
                StrB = SomeoneString;
            MsgText = FormatTextString( SwatKillMessage, StrA, StrB, GetWeaponFriendlyName(StrC) );
            break;
        case 'SuspectsKill':
            if( StrB == "" )
                StrB = SomeoneString;
            MsgText = FormatTextString( SuspectsKillMessage, StrA, StrB, GetWeaponFriendlyName(StrC) );
            break;
        case 'SwatArrest':
            if( StrB == "" )
                StrB = SomeoneString;
            MsgText = FormatTextString( SwatArrestMessage, StrA, StrB );
            break;
        case 'SuspectsArrest':
            if( StrB == "" )
                StrB = SomeoneString;
            MsgText = FormatTextString( SuspectsArrestMessage, StrA, StrB );
            break;

        case 'PlayerConnect':
            if( !bDisplayConnects )
                return;
            MsgText = FormatTextString( ConnectedMessage, StrA );
            break;
        case 'PlayerDisconnect':
            if( !bDisplayConnects )
                return;
            MsgText = FormatTextString( DisconnectedMessage, StrA );
            break;

        case 'CommandGiven':
            MsgText = StrA;
            break;

		case 'Stats':
			MsgText = FormatTextString( StatsMessage, StrA );
			break;

		case 'SmashAndGrabGotItem':
			MsgText = FormatTextString( SmashAndGrabGotItemMessage, StrA );
			break;

		case 'SmashAndGrabDroppedItem':
			MsgText = FormatTextString( SmashAndGrabDroppedItemMessage, StrA );
			break;

		case 'SmashAndGrabArrestTimeDeduction':
			MsgText = FormatTextString( SmashAndGrabArrestTimeDeductionMessage, StrA );
			break;

        case 'DebugMessage':
			if (PlayerOwner().Level.GetEngine().EnableDevTools)
			{
				// The chat panel is hidden by default when launching a map
				// from the commandline, so force it to be shown when debug
				// messages are sent, in case this map wasn't run from the GUI.
				Show();
				MsgText = FormatTextString( DebugMessageString, StrA );
            }
            break;

    }

    AddChat( MsgText, MsgIsChat );

    if( bDisplaySpecial )
    {
        if( ( GC.SwatGameRole == GAMEROLE_SP_Campaign ) &&
            ( Type == 'MissionCompleted' ||
              Type == 'MissionFailed' ))
        {
            DisplayPromptToDebriefMessage = true;
            DisplayPromptString = ReplaceKeybindingCodes( PromptToDebriefMessage, "[k=", "]"  );
            AddChat( DisplayPromptString, false );
        }

        MyChatHistory.Clear();
        MyChatHistory.List.Add( MsgText );

        if( DisplayPromptToDebriefMessage )
        {
            MyChatHistory.List.Add( DisplayPromptString );
        }

        KillTimer();
    }
}

event Timer()
{
    MoveChatUp();
}

private function AddChat( String newText, optional bool newIsChat )
{
    local Array<String> WrappedLines;
    local int i;
    local string InitialColor;

    if( Len(newText) > 6 &&
        Caps(Left(newText,3)) == "[C=" )
    {
        //set the initial color
        InitialColor = Left( newText, 10 );
        //strip the initial color from the string (it will be applied later)
        newText = Mid( newText, 10 );
    }

//log( self$"::AddChat( "$NewText$" )... InitialColor = "$InitialColor );
    MyChatHistory.WrapStringToArray( newText, WrappedLines );

    for( i = 0; i < WrappedLines.Length; i++ )
    {
//log( self$"::AddChat()... WrappedLines["$i$"] = "$WrappedLines[i] );
        AddChatLine( InitialColor $ WrappedLines[i], newIsChat );
    }

    ScrollChatToEnd();
}

private function AddChatLine( string newText, optional bool newIsChat )
{
    local ChatLine newLine;

    newLine.Msg = newText;
    newLine.bIsChat = newIsChat;

    FullChatHistory[FullChatHistory.Length] = newLine;
}

private function MoveChatUp()
{
    MyChatHistory.List.Add( "",, "" );

    if( UpdateChatAlpha() )
    {
        if( MSGTimeout > 0 )
            SetTimer( MSGTimeout, true );
    }
    else
    {
        KillTimer();
    }
}

private function bool UpdateChatAlpha()
{
    local int i;
    local bool bAnyVisible;
    local String CurrentMsg;
    local Color CurrentColor;

    for( i = 0; i < MaxChatLines; i++ )
    {
        CurrentMsg = MyChatHistory.List.GetExtraAtIndex(i);

        if( CurrentMsg == "" )
            Continue;

        bAnyVisible = true;

        CurrentColor.A = int( 255.0 * float(i+1) / float(MaxChatLines) );

        MyChatHistory.List.SetItemAtIndex( i, MakeColorCode( CurrentColor ) $ CurrentMsg );
    }

    return bAnyVisible;
}


private function SetChatIndex( int newIndex )
{
    local bool bAnyVisible;
    local int i;

    ChatIndex = newIndex;

    MyChatHistory.Clear();

    for( i = ChatIndex; i >= 0 && i > ChatIndex - MaxChatLines; i-- )
    {
        MyChatHistory.List.Insert( 0, "",, FullChatHistory[i].Msg );
    }

    for( i = MyChatHistory.Num(); i < MaxChatLines; i++ )
    {
        MyChatHistory.List.Insert( 0, "",,"" );
    }

    bAnyVisible = UpdateChatAlpha();

    if( bAnyVisible &&
        MSGTimeout > 0 &&
        ChatIndex == FullChatHistory.Length - 1 )
        SetTimer( MSGTimeout, true );
    else
        KillTimer();
}


function ScrollChatPageUp()
{
    AdjustChatIndex( -1 * MaxChatLines );
}

function ScrollChatPageDown()
{
    AdjustChatIndex( MaxChatLines );
}

function ScrollChatUp()
{
    AdjustChatIndex( -1 );
}

function ScrollChatDown()
{
    AdjustChatIndex( 1 );
}

function ScrollChatToHome()
{
    SetChatIndex( 0 );
}

function ScrollChatToEnd()
{
    SetChatIndex( FullChatHistory.Length - 1 );
}

private function AdjustChatIndex( int offset )
{
    SetChatIndex( Clamp( ChatIndex + offset, 0, FullChatHistory.Length - 1 ) );
}


function InternalOnEntryCompleted(GUIComponent Sender)
{
    local string ChatText;

    ChatText = MyChatEntry.GetText();

    CloseChatEntry();

    //send the message
    if( ChatText != "" )
    {
        SwatGUIController(Controller).AddChatMessage( ChatText, bGlobal );
    }
}

function InternalOnEntryCancelled(GUIComponent Sender)
{
    CloseChatEntry();
}

function OpenChatEntry(bool bSendGlobal)
{
    KillTimer();
    MyChatHistory.Show();
    bGlobal = bSendGlobal;
    if( Controller.TopPage().bIsHUD )
    {
        Controller.SetCaptureScriptExec(true);
        Controller.TopPage().Activate();   //activate the HUDPage (accept input)
    }
    Focus();
    MyChatEntry.bDontReleaseMouse=true;
    MyChatEntry.bReadOnly=false;
    MyChatEntry.Show();
    MyChatEntry.Activate();
    MyChatEntry.Focus();

    MyChatEntry.SetText(SwatGuiController(Controller).EnteredChatText);
    MyChatEntry.CaretPos = Len( MyChatEntry.GetText() );

    Controller.bSwallowNextKeyType=true;
}

function CloseChatEntry()
{
    MyChatEntry.AddEntryToHistory( MyChatEntry.GetText() );

    MyChatEntry.bDontReleaseMouse=false;
    if( MSGTimeout > 0 )
        SetTimer( MSGTimeout, true );
    MyChatEntry.bReadOnly=true;
    MyChatEntry.DisableComponent();
    MyChatEntry.DeActivate();
    MyChatEntry.Hide();
    if( Controller.TopPage().bIsHUD )
    {
        Controller.TopPage().DeActivate();   //deactivate the HUDPage (dont accept input)
        Controller.SetCaptureScriptExec(false);
    }
    else
    {
        Controller.TopPage().Focus();
    }

    SwatGuiController(Controller).EnteredChatText = "";
}

function RemoveNonChatMessagesFromHistory()
{
    local int i;

    for( i = FullChatHistory.Length-1; i >= 0; i-- )
    {
        if( !FullChatHistory[i].bIsChat )
        {
            FullChatHistory.Remove( i, 1 );
        }
    }

    ScrollChatToEnd();
}

function ClearChatHistory()
{
    FullChatHistory.Remove( 0, FullChatHistory.Length );
}

defaultproperties
{
    bDisplayDeaths=true
    bDisplayConnects=true
    MSGTimeout=15

    PropagateVisibility=false
    PropagateActivity=false
    PropagateState=false

    SettingsUpdatedString="[c=ffff00][b]%1[\\b] updated the server settings."

    NameChangeMessage="[c=ff00ff][b]%1[\\b] changed name to [b]%2[\\b]."
    KickMessage="[c=ff00ff][b]%1[\\b] kicked [b]%2[\\b]."
    BanMessage="[c=ff00ff][b]%1[\\b] BANNED [b]%2[\\b]!"
    SwitchTeamsMessage="[c=00ffff][b]%1[\\b] switched teams."

	CoopQMMMessage="[c=ffff00]%1"

	StatsMessage="[c=ffff00]%1"

	YesVoteMessage="[c=ff00ff]%1 voted yes"
	NoVoteMessage="[c=ff00ff]%1 voted no"

	COOPMessageLeaderSelected="[c=ffff00][b]%1[\\b] has been promoted to leader."

	StatsValidatedMessage = "[c=ffff00][b][STATS][\\b] The server has validated your profile and is tracking statistics."
	StatsBadProfileMessage = "[c=ffff00][b][STATS][\\b] Your profile data is invalid. Please ensure your profile data is entered correctly."

	SmashAndGrabGotItemMessage = "[c=ffff00]%1 has picked up the briefcase."
	SmashAndGrabDroppedItemMessage = "[c=ffff00]%1 dropped the briefcase."
	SmashAndGrabArrestTimeDeductionMessage = "[c=ffff00]%1 seconds deducted from round time."

	ReferendumAlreadyActiveMessage="[c=ff00ff]A vote is already in progress"
	ReferendumStartCooldownMessage="[c=ff00ff]You may only start a vote once every 60 seconds"
	PlayerImmuneFromReferendumMessage="[c=ff00ff]%1 is currently immune from voting"
	ReferendumAgainstAdminMessage="[c=ff00ff]You may not start a vote against an admin"
	ReferendumsDisabledMessage="[c=ff00ff]Voting has been disabled on this server"
	LeaderVoteTeamMismatchMessage="[c=ff00ff]You may not start leadership votes for players on the other team"

	ReferendumSucceededMessage="[c=ff00ff]The vote succeeded"
	ReferendumFailedMessage="[c=ff00ff]The vote failed"

    TeamChatMessage="[c=808080][b]%1[\\b]: %2"
    GlobalChatMessage="[c=00ff00][b]%1[\\b][c=00ff00]: %2"
    TeamChatMessageLocalized="[c=808080][b]%1 (%2)[\\b]: %3"
    GlobalChatMessageLocalized="[c=00ff00][b]%1 [\\c][c=ffffff](%2)[\\c][\\b][c=00ff00]: %3"
    SwatSuicideMessage="[c=0000ff][b]%1[\\b] suicided!"
    SuspectsSuicideMessage="[c=ff0000][b]%1[\\b] suicided!"
    SwatTeamKillMessage="[c=0000ff][b]%1[\\b] betrayed [b]%2[\\b] with a %3!"
    SuspectsTeamKillMessage="[c=ff0000][b]%1[\\b] double crossed [b]%2[\\b] with a %3!"
    SwatKillMessage="[c=0000ff][b]%1[\\b] neutralized [b]%2[\\b] with a %3!"
    SuspectsKillMessage="[c=ff0000][b]%1[\\b] killed [b]%2[\\b] with a %3!"
    SwatArrestMessage="[c=0000ff][b]%1[\\b] arrested [b]%2[\\b]!"
    SuspectsArrestMessage="[c=ff0000][b]%1[\\b] arrested [b]%2[\\b]!"

    ConnectedMessage="[c=ffff00][b]%1[\\b] connected to the server."
    DisconnectedMessage="[c=ffff00][b]%1[\\b] dropped from the server."

    MissionFailedString="[c=ffffff]You have [c=ff0000]FAILED[c=ffffff] the mission!"
    MissionCompletedString="[c=ffffff]You have [c=00ff00]COMPLETED[c=ffffff] the mission!"
    NewObjectiveString="[c=ffffff]You have received a new objective."
    SniperAlertedString="[c=ffffff]Press %1 to activate the sniper view."
    EquipNotAvailableString="[c=ffffff]No %1 available to equip."
    DebugMessageString="[c=ffffff]DEBUG_MSG: %1"

    ReferendumStartedMessage="[c=ff00ff]%1[\\c]"

    PromptToDebriefMessage="[c=ffffff]Press '[k=GUICloseMenu]' to proceed to Debrief."
    SomeoneString="someone"

    SlotNames(0)="Invalid"
    SlotNames(1)="Primary Weapon"
    SlotNames(2)="Backup Weapon"
    SlotNames(3)="Flashbang Grenade"
    SlotNames(4)="CS Gas Grenade"
    SlotNames(5)="Sting Grenade"
    SlotNames(6)="Pepper Spray"
    SlotNames(7)="breaching device"
    SlotNames(8)="Toolkit"
    SlotNames(9)="Optiwand"
    SlotNames(10)="Wedge"
    SlotNames(11)="ZipCuff"
    SlotNames(14)="Lightstick"
}
