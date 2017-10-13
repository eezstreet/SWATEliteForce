// ====================================================================
//  Class:  SwatGui.SwatMPScoresPanel
//  Parent: SwatGUIPanel
//
//  Screen that shows the scores after a round has finished
// ====================================================================

class SwatMPScoresPanel extends SwatGUIPanel
    Config(SwatGui);

import enum AdminPermissions from SwatGame.SwatAdmin;

var(SWATGui) EditInline Config SwatObjectivesPanel  MyObjectivesPanel;
var(SWATGui) EditInline Config SwatLeadershipPanel	MyLeadershipPanel;
var(SWATGui) EditInline Config SwatLeadershipPanel	MyDebriefingLeadershipPanel;
var(SWATGui) EditInline Config SwatMapPanel 		MyMapPanel;
var(SWATGui) EditInline Config SwatCOOPOfficerStatusPanel 	MyOfficerStatusPanel;

var(SWATGui) EditInline Config GUIButton MyChangeTeamButton;
var(SWATGui) EditInline Config GUIButton MyCOOPChangeTeamButton;
var(SWATGui) EditInline Config GUIButton MyToggleVOIPIgnoreButton;
var(SWATGui) EditInline Config GUIButton MyCOOPToggleVOIPIgnoreButton;
var(SWATGui) EditInline Config GUILabel MyTitleLabel;
var(SWATGui) EditInline Config GUILabel DeployInfoLabel;
var(SWATGui) private EditInline Config array<GUIMultiColumnListBox> MyTeamBoxes;
var(SWATGui) private EditInline Config array<GUILabel> MyTeamHeaders;
var(SWATGui) private EditInline Config GUIImage MyBorderImageSWATLeft;
var(SWATGui) private EditInline Config GUIImage MyBorderImageSWATRight;
var(SWATGui) private EditInline Config GUIImage MyBorderImageSuspectLeft;
var(SWATGui) private EditInline Config GUIImage MyBorderImageSuspectRight;

var(SWATGui) EditInline Config GUIButton MyAbortGameButton;

var(SWATGui) private EditInline GUIImage		    ReadyIcon;
var(SWATGui) private config Color VIPColor;
var(SWATGui) private config Color WaitingForRespawnColor;
var(SWATGui) private localized config String VIPString;
var(SWATGui) private localized config String TeamScoreFormatString;
var(SWATGui) private localized config String StartGameString;
var(SWATGui) private localized config String AbortGameString;
var(SWATGui) private localized config String NextGameString;
var(SWATGui) private localized config String AdminLoginString;
var(SWATGui) private localized config String AdminPasswordQueryString;

var private bool bSelectThisPlayer;
var int PlayerIDSelected;		// stores playerID of selected player (or -1)

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyChangeTeamButton.OnClick=InternalOnClick;
    MyCOOPChangeTeamButton.OnClick=InternalOnClick;
    MyToggleVOIPIgnoreButton.OnClick=InternalOnClick;
    MyCOOPToggleVOIPIgnoreButton.OnClick=InternalOnClick;
    MyAbortGameButton.OnClick=InternalOnClick;

	MyTeamBoxes[0].OnChange=TeamBoxOnChange;
	MyTeamBoxes[1].OnChange=TeamBoxOnChange;

    ReadyIcon=GUIImage(Controller.CreateComponent("GUI.GUIImage","Canvas_ReadyIcon"));
}

function InternalOnActivate()
{
    local int i;
    local bool bPlayingCOOP;
    local bool bCampaignCoop;

    bPlayingCOOP = SwatGUIController(Controller).Repo.Level.IsPlayingCOOP;
	bSelectThisPlayer = true;		 // start off by selecting local player
  bCampaignCoop = SwatGUIController(Controller).coopcampaign;

	MyChangeTeamButton.SetVisibility(!bPlayingCOOP && GC.SwatGameState != GAMESTATE_ClientTravel );
	MyChangeTeamButton.SetActive(!bPlayingCOOP && GC.SwatGameState != GAMESTATE_ClientTravel );
	MyCOOPChangeTeamButton.SetVisibility(bPlayingCOOP && GC.SwatGameState != GAMESTATE_ClientTravel );
	MyCOOPChangeTeamButton.SetActive(bPlayingCOOP && GC.SwatGameState != GAMESTATE_ClientTravel );
	MyToggleVOIPIgnoreButton.SetVisibility(!bPlayingCOOP && GC.SwatGameState != GAMESTATE_ClientTravel );
	MyToggleVOIPIgnoreButton.SetActive(!bPlayingCOOP && GC.SwatGameState != GAMESTATE_ClientTravel );
	MyCOOPToggleVOIPIgnoreButton.SetVisibility(bPlayingCOOP && GC.SwatGameState != GAMESTATE_ClientTravel );
	MyCOOPToggleVOIPIgnoreButton.SetActive(bPlayingCOOP && GC.SwatGameState != GAMESTATE_ClientTravel );

	SetTimer( GC.MPPollingDelay, true );

	DeployInfoLabel.SetVisibility( bPlayingCOOP && GC.SwatGameState != GAMESTATE_ClientTravel && !bCampaignCoop );

    MyObjectivesPanel.SetVisibility( bPlayingCOOP );
    MyObjectivesPanel.SetActive( bPlayingCOOP );

    MyLeadershipPanel.SetVisibility( bPlayingCOOP && GC.SwatGameState != GAMESTATE_PostGame );
    MyLeadershipPanel.SetActive( bPlayingCOOP && GC.SwatGameState != GAMESTATE_PostGame );

    MyDebriefingLeadershipPanel.SetVisibility( bPlayingCOOP && GC.SwatGameState == GAMESTATE_PostGame );
    MyDebriefingLeadershipPanel.SetActive( bPlayingCOOP && GC.SwatGameState == GAMESTATE_PostGame );

    MyMapPanel.SetVisibility( bPlayingCOOP && GC.SwatGameState != GAMESTATE_PostGame );
    MyMapPanel.SetActive( bPlayingCOOP && GC.SwatGameState != GAMESTATE_PostGame );

    MyOfficerStatusPanel.SetVisibility( bPlayingCOOP );
    MyOfficerStatusPanel.SetActive( bPlayingCOOP );

    if( MyTitleLabel != None )
    MyTitleLabel.SetVisibility( !bPlayingCOOP );

    UpdateChangeTeamsButton();
	UpdateToggleVOIPIgnoreButton();
    UpdateAdminButton();
    MyAbortGameButton.EnableComponent();

    for( i = 0; i < 2; i++)
    {
        MyTeamBoxes[i].SetVisibility( !bPlayingCOOP );
        MyTeamHeaders[i].SetVisibility( !bPlayingCOOP );
    }

    MyBorderImageSWATLeft.SetVisibility( !bPlayingCOOP );
    MyBorderImageSWATRight.SetVisibility( !bPlayingCOOP );
    MyBorderImageSuspectLeft.SetVisibility( !bPlayingCOOP );
    MyBorderImageSuspectRight.SetVisibility( !bPlayingCOOP );
}

function InternalOnDeActivate()
{
    KillTimer();
}

event Timer()
{
    UpdateChangeTeamsButton();
	UpdateToggleVOIPIgnoreButton();
    UpdateAdminButton();

    if( !PlayerOwner().Level.IsPlayingCOOP )
    {
        DisplayScores();
    }
}

private function UpdateChangeTeamsButton()
{
    local bool Enabled;
    local bool bPlayingCOOP;
	local GUIButton Button;

    Enabled = false;

    bPlayingCOOP = SwatGUIController(Controller).Repo.Level.IsPlayingCOOP;
	if (bPlayingCOOP)
	{
		Button = MyCOOPChangeTeamButton;
	}
	else
	{
		Button = MyChangeTeamButton;
	}

    if (GC.SwatGameState != GAMESTATE_MidGame)
    {
        Enabled = true;
    }
    else                //GameState is MidGame
    {
        if (SwatPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).bIsTheVIP)
        {
            Enabled = false;
        }
        else            //GameState is MidGame, not VIP
        {
            assert(SwatGamePlayerController(PlayerOwner()) != None);

            if (SwatGamePlayerController(PlayerOwner()).SwatPlayer == None)
            {
                Enabled = true;
            }
            else        //GameState is MidGame, not VIP, Player is in the game
            {
                if( SwatGamePlayerController(PlayerOwner()).SwatPlayer.IsNonlethaled() ||
                    SwatGamePlayerController(PlayerOwner()).SwatPlayer.IsBeingArrestedNow() )
                {
                    Enabled = false;
                }
                else    //GameState is MidGame, not VIP, Player is in the game, not nonlethaled or being arrested
                {
                    Enabled = true;
                }
            }
        }
    }

    //do not update back to blurry if this is already pressed
    if( !Enabled || Button.MenuState != MSAT_Pressed )
	{
        Button.SetEnabled(Enabled);
	}
}

private function UpdateToggleVOIPIgnoreButton()
{
	// currently always active
}

private function UpdateAdminButton()
{
	local SwatPlayerReplicationInfo PRI;

	MyAbortGameButton.SetVisibility(true);

	PRI = SwatPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);

	if(GC.SwatGameState == GAMESTATE_PreGame &&
		PRI.MyRights[AdminPermissions.Permission_StartGame] > 0)
	{
		MyAbortGameButton.SetCaption( StartGameString );
	}
	else if(GC.SwatGameState == GAMESTATE_MidGame &&
		PRI.MyRights[AdminPermissions.Permission_EndGame] > 0)
	{
		MyAbortGameButton.SetCaption( AbortGameString );
	}
	else if(GC.SwatGameState == GAMESTATE_PostGame &&
		PRI.MyRights[AdminPermissions.Permission_StartGame] > 0)
	{
		MyAbortGameButton.SetCaption( NextGameString );
	}
	else if(!PRI.bIsAdmin)
	{
		MyAbortGameButton.SetCaption( AdminLoginString );
	}
	else
	{
		MyAbortGameButton.SetVisibility(false);
	}
}

private function int ObjScore( NetScoreInfo a )
{
    return
        a.GetVIPPlayerEscaped() +
        a.GetArrestedVIP() +
        a.GetBombsDiffused() +
        a.GetRDCrybaby() +
		a.GetSGCrybaby() +
		a.GetEscapedSG();
}

private function bool GreaterScoreThan( NetScoreInfo a, NetScoreInfo b )
{
    return
        ( a.GetScore() > b.GetScore() ||
            ( a.GetScore() == b.GetScore() &&
                ( ObjScore( a ) > ObjScore( b ) ||
                    ( ObjScore( a ) == ObjScore( b ) &&
                        ( a.GetArrests() > b.GetArrests() ||
                            ( a.GetArrests() == b.GetArrests() &&
                                ( a.GetTimesDied() < b.GetTimesDied() ||
                                    ( a.GetTimesDied() == b.GetTimesDied() &&
                                        ( a.GetEnemyKills() > b.GetEnemyKills() ||
                                            ( a.GetEnemyKills() == b.GetEnemyKills() &&
                                                ( a.GetTimesArrested() < b.GetTimesArrested()
        )   )   )   )   )   )   )   )   )   )   );
}

function DisplayScores()
{
    local SwatGameReplicationInfo SGRI;
    local SwatPlayerReplicationInfo PlayerInfo, otherPlayerInfo;
    local int i,j,row;
//  local array<int> lastTop, lastSelected;
    local string PlayerName;
	local string VOIPstatus;
	local int PlayerIndex;
	local SwatPlayerController PC;

    SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );

    if( SGRI == None )
        return;

    //set the headers and clear the team boxes
    for( i = 0; i < 2; ++i)
    {
        MyTeamHeaders[i].SetCaption( FormatTextString( TeamScoreFormatString, SGRI.Teams[i].TeamName, NetTeam(SGRI.Teams[i]).NetScoreInfo.GetScore(), NetTeam(SGRI.Teams[i]).NetScoreInfo.GetRoundsWon() ) );

        //lastTop[i]=MyTeamBoxes[i].MyActiveList.Top;
        //lastSelected[i]=MyTeamBoxes[i].GetIndex();
        MyTeamBoxes[i].Clear();
    }

    //populate the players into their team boxes, sorted by score
    for (i = 0; i < ArrayCount(SGRI.PRIStaticArray); i++)
    {
        PlayerInfo = SGRI.PRIStaticArray[i];
        if (PlayerInfo != None)
        {
            PlayerInfo.NetScoreInfo.Ranking = 1;

            //populate the players into their team boxes, sorted by score
            for (j = 0; j < i; j++)
            {
                otherPlayerInfo = SGRI.PRIStaticArray[j];
                if (otherPlayerInfo != None)
                {
                    if( GreaterScoreThan( PlayerInfo.NetScoreInfo, otherPlayerInfo.NetScoreInfo ) )
                        otherPlayerInfo.NetScoreInfo.Ranking++;
                    else
                        PlayerInfo.NetScoreInfo.Ranking++;
                }
            }
        }
    }

	PC = SwatPlayerController(PlayerOwner());

    //populate the players into their team boxes, sorted by score
    for (i = 0; i < ArrayCount(SGRI.PRIStaticArray); ++i)
    {
        PlayerInfo = SGRI.PRIStaticArray[i];
        if (PlayerInfo != None)
        {
            PlayerName = PlayerInfo.PlayerName;

            if( PlayerInfo.bIsTheVIP )
            {
                PlayerName = MakeColorCode( VIPColor )$PlayerName$VIPString;
            }
            else if( PlayerInfo.bIsDead )
            {
				// use different color for players waiting for respawn
                PlayerName = MakeColorCode( WaitingForRespawnColor )$PlayerName;
            }

            if( PC.ShouldDisplayPRIIds )
            {
                PlayerName = "[b]["$i$"][\\b]"$PlayerName;
            }

			// VOIP todo: fill in VOIPstatus: none, ignore ('x'), speaking ('o')
			if (PC.VOIPIsIgnored(PlayerInfo.PlayerID))
				VOIPStatus = "x";
			else if (PC.VOIPIsSpeaking(PlayerInfo.PlayerID))
				VOIPStatus = "o";
			else
				VOIPStatus = "";

            MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "Teamnames",,PlayerName,PlayerInfo.SwatPlayerID);
			MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "VOIP",,VOIPstatus,PlayerInfo.PlayerID+1);
            MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "Ping",,,Min(999,PlayerInfo.Ping));
            MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "Rank",,,PlayerInfo.NetScoreInfo.Ranking);
            MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "Score",,,PlayerInfo.NetScoreInfo.GetScore());
            MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "Kills",,,PlayerInfo.NetScoreInfo.GetEnemyKills());
            MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "Deaths",,,PlayerInfo.NetScoreInfo.GetTimesDied());
            MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "Arrested",,,PlayerInfo.NetScoreInfo.GetTimesArrested());
            MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "Obj",,,ObjScore(PlayerInfo.NetScoreInfo) );
            MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "Arrests",,,PlayerInfo.NetScoreInfo.GetArrests());
            if( PlayerInfo.GetPlayerIsReady() )
                MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].AddNewRowElement( "Ready",ReadyIcon,,,true);
            row = MyTeamBoxes[NetTeam(PlayerInfo.Team).GetTeamNumber()].PopulateRow( /*"Teamnames" dkaplan: fix for same name replacement*/ );
    //log("[dkaplan]: adding player "$PlayerInfo.PlayerName$" to team box"$PlayerInfo.Team.TeamIndex$", adding at row index "$row);
        }
    }

	if ( bSelectThisPlayer && PlayerOwner().PlayerReplicationInfo != None )
	{
		bSelectThisPlayer = false;
		PlayerIDSelected = SwatPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).PlayerID;
	}

    for( i = 0; i < 2; i++)
    {
        MyTeamBoxes[i].Sort("Rank"); // sort based on rank

		// highlight PlayerIDSelected (since it will be cleared every time this function is called)
		if (PlayerIDSelected != -1)
			PlayerIndex = MyTeamBoxes[i].GetColumn("VOIP").FindExtraIntData(PlayerIDSelected+1,,true);
		else
			PlayerIndex = -1;
        if( PlayerIndex == -1 )
            MyTeamBoxes[i].MyActiveList.SetIndex(-1,,true);
        else
            MyTeamBoxes[i].MyActiveList.SetIndex(PlayerIndex,,true);
    }
}

function ToggleVOIPIgnore()
{
	local SwatPlayerController PC;

	if (PlayerIDSelected != -1)
	{
		PC = SwatPlayerController(PlayerOwner());

		// add/remove PlayerID thru replicated function on server - PlayerID list stored with SwatPlayerControllers
		if (PC.VOIPIsIgnored(PlayerIDSelected))
			PC.VOIPUnIgnore(PlayerIDSelected);
		else
			PC.VOIPIgnore(PlayerIDSelected);
	}
}

function InternalOnClick(GUIComponent Sender)
{
	local SwatPlayerReplicationInfo PRI;

	PRI = SwatPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);

	switch (Sender)
	{
		case MyCOOPChangeTeamButton:
		case MyChangeTeamButton:
		    //TODO: Change Teams here
		    SwatGuiController(Controller).ChangeTeams();
			PlayerIDSelected = PRI.PlayerID;	// reselect local player
		    break;
		case MyToggleVOIPIgnoreButton:
		case MyCOOPToggleVOIPIgnoreButton:
			ToggleVOIPIgnore();
			break;
		case MyAbortGameButton:

			if(GC.SwatGameState == GAMESTATE_PreGame &&
				PRI.MyRights[AdminPermissions.Permission_StartGame] > 0)
			{
				SwatPlayerController(PlayerOwner()).StartGame();
			}
			else if(GC.SwatGameState == GAMESTATE_MidGame &&
				PRI.MyRights[AdminPermissions.Permission_EndGame] > 0)
			{
				SwatPlayerController(PlayerOwner()).AbortGame();
    		    Controller.CloseMenu();
			}
			else if(GC.SwatGameState == GAMESTATE_PostGame &&
				PRI.MyRights[AdminPermissions.Permission_StartGame] > 0)
			{
				SwatPlayerController(PlayerOwner()).StartGame();
			}
			else if(!PRI.bIsAdmin)
			{
				Controller.TopPage().OnPopupReturned=InternalOnPasswordPopupReturned;
		        Controller.OpenMenu( "SwatGui.SwatPasswordPopup", "SwatPasswordPopup", AdminPasswordQueryString );
			}
		    MyAbortGameButton.DisableComponent();
		    break;
	}
}

function TeamBoxOnChange(GUIComponent Sender)
{
	local int team;

	if (Sender == MyTeamBoxes[0])
		team = 0;
	else
		team = 1;

	if (MyTeamBoxes[team].MyActiveList.GetIndex() >= 0)
	{
		PlayerIDSelected = MyTeamBoxes[team].GetColumn("VOIP").GetExtraIntData()-1; //(will be -1 if nothing selected)
	}

	// deselect other teambox (not necessary, done indirectly via DisplayScores() on next update)
	//if (PlayerIDSelected != -1 && MyTeamBoxes[1-team].MyActiveList.GetIndex() >= 0)
	//{
	//	MyTeamBoxes[1-team].MyActiveList.SetIndex(-1,,true);
	//}
}

function InternalOnPasswordPopupReturned( GUIListElem returnObj, optional string Passback )
{
    log( "...InternalOnPasswordPopupReturned()." );

    SwatPlayerController(PlayerOwner()).SAD( returnObj.item );
    MyAbortGameButton.EnableComponent();
}

defaultproperties
{
	OnActivate=InternalOnActivate
	OnDeActivate=InternalOnDeActivate
	VIPColor=(R=0,G=255,B=0,A=255)
	WaitingForRespawnColor=(R=255,G=0,B=0,A=255)
	VIPString=" (VIP)"
	TeamScoreFormatString="%1: %2   Rounds won: %3"
	StartGameString="START GAME"
	AbortGameString="END GAME"
	NextGameString="NEXT GAME"
	AdminLoginString="ADMIN LOGIN"
	AdminPasswordQueryString="Please enter the admin password to login:"
	PlayerIDSelected=-1
}
