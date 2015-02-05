// ====================================================================
//  Class:  SwatGui.SwatCOOPOfficerStatusPanel
//  Parent: GUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatCOOPOfficerStatusPanel extends SwatGUIPanel
     ;

import enum COOPStatus from SwatGame.SwatPlayerReplicationInfo;

var(SWATGui) private EditInline Config GUIMultiColumnListBox MyTeamBox;

var() private config localized string IncapacitatedString;
var() private config localized string InjuredString;
var() private config localized string HealthyString;
var() private config localized string NotAvailable;
var() private config localized string NotReady;
var() private config localized string Ready;
var() private config localized string LeaderString;

var private bool bSelectThisPlayer;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	MyTeamBox.OnChange=COOPTeamBoxOnChange;
}

function InternalOnActivate()
{
	bSelectThisPlayer = true;		 // start off by selecting local player
}

event Show()
{
    Super.Show();
    SetTimer( GC.MPPollingDelay, true );
}

event Timer()
{
	if( PlayerOwner().Level.IsPlayingCOOP )
    {
		DisplayScores();
	}
}


function DisplayScores()
{
    local SwatGameReplicationInfo SGRI;
    local SwatPlayerReplicationInfo PlayerInfo;
	local SwatPlayerController PC;
    local int i,row;
    //local int lastSelected;
    local string PlayerName;
	local string VOIPstatus;
	local int PlayerIndex;

    SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );
    
    if( SGRI == None )
        return;

	PC = SwatPlayerController(PlayerOwner());

    //lastSelected=MyTeamBox.GetIndex();
    MyTeamBox.Clear();

    //populate the players into their team boxes, sorted by team and score
    for (i = 0; i < ArrayCount(SGRI.PRIStaticArray); ++i)
    {
        PlayerInfo = SGRI.PRIStaticArray[i];
        if (PlayerInfo != None)
        {
			if (NetTeam(PlayerInfo.Team).GetTeamNumber() == 0)
				PlayerName = MakeColorCode(class'Engine.Canvas'.Static.MakeColor(0,0,255)) $ PlayerInfo.PlayerName;
			else
	            PlayerName = MakeColorCode(class'Engine.Canvas'.Static.MakeColor(255,0,0)) $ PlayerInfo.PlayerName;

            MyTeamBox.AddNewRowElement( "Ping",,,Min(999,PlayerInfo.Ping));
            MyTeamBox.AddNewRowElement( "Teamnames",,PlayerName,NetTeam(PlayerInfo.Team).GetTeamNumber());

			if ( GC.SwatGameState == GAMESTATE_MidGame && PlayerInfo.COOPPlayerStatus != STATUS_Incapacitated && PlayerInfo.IsLeader )
				MyTeamBox.AddNewRowElement( "Health",,LeaderString);
			else
				MyTeamBox.AddNewRowElement( "Health",,GetStatusString( PlayerInfo.COOPPlayerStatus ));

			if (PC.VOIPIsIgnored(PlayerInfo.PlayerID))
				VOIPStatus = "x";
			else if (PC.VOIPIsSpeaking(PlayerInfo.PlayerID))
				VOIPStatus = "o";
			else
				VOIPStatus = "";

			MyTeamBox.AddNewRowElement( "VOIP",,VOIPstatus,PlayerInfo.PlayerID+1);
 
            //if( PlayerInfo.GetPlayerIsReady() )

            row = MyTeamBox.PopulateRow();
        }
    }

    MyTeamBox.Sort("PlayerName");

    if( bSelectThisPlayer && PlayerOwner().PlayerReplicationInfo != None)
    {
		bSelectThisPlayer = false;
		SwatMPScoresPanel(MenuOwner).PlayerIDSelected = SwatPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).PlayerID;
    }

	// highlight PlayerIDSelected (since it will be cleared every time this function is called)
	if (SwatMPScoresPanel(MenuOwner).PlayerIDSelected != -1)
		PlayerIndex = MyTeamBox.GetColumn("VOIP").FindExtraIntData(SwatMPScoresPanel(MenuOwner).PlayerIDSelected+1,,true);
	else
		PlayerIndex = -1;
    if( PlayerIndex == -1 )
        MyTeamBox.MyActiveList.SetIndex(-1,,true);
    else
        MyTeamBox.MyActiveList.SetIndex(PlayerIndex,,true);
}

private function string GetStatusString( COOPStatus status )
{
    switch(status)
    {
        case STATUS_NotReady:
            if( GC.SwatGameState != GAMESTATE_MidGame )
                return NotReady;
            else
                return NotAvailable;
        case STATUS_Ready:
            if( GC.SwatGameState != GAMESTATE_MidGame )
                return Ready;
            else
                return NotAvailable;
        case STATUS_Healthy:
            return HealthyString;
        case STATUS_Injured:
            return InjuredString;
        case STATUS_Incapacitated:
            return IncapacitatedString;
    }

    return "";
}

function COOPTeamBoxOnChange(GUIComponent Sender)
{
	if (MyTeamBox.MyActiveList.GetIndex() >= 0)
	{
		SwatMPScoresPanel(MenuOwner).PlayerIDSelected = MyTeamBox.GetColumn("VOIP").GetExtraIntData()-1; //(will be -1 if nothing selected)
	}
}

defaultproperties
{
	OnActivate=InternalOnActivate
    Ready="[c=00FF00]Ready"
    NotReady="[c=FF0000]Not Ready"
    HealthyString="Healthy"
    InjuredString="[c=ff0000]Injured"
    IncapacitatedString="[c=ff0000][b]Incapacitated"
    NotAvailable="[c=ff00ff][b]Not Available"
	LeaderString="[c=ffff00][b]Leader"
}