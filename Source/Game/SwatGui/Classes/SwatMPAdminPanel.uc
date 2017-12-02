class SwatMPAdminPanel extends SwatGuiPanel
	config(SwatGui);

import enum AdminPermissions from SwatGame.SwatAdmin;

enum AdminPlayerActions
{
	PlayerAction_Kick,
	PlayerAction_Ban,
	PlayerAction_LockTeam,
	PlayerAction_ForceRed,
	PlayerAction_ForceBlue,
	PlayerAction_Mute,
	PlayerAction_MakeLeader,
	PlayerAction_Kill,
	PlayerAction_ForceSpectator,
	PlayerAction_ForceLessLethal/*,
	The following are what I intend to implement. Someday.
	PlayerAction_Respawn,
	PlayerAction_Freeze,
	PlayerAction_ClearWarnings
	*/
};

enum AdminMapActions
{
	MapAction_NextMap,
	MapAction_StartGame,
	MapAction_EndGame,
	MapAction_ForceAllRed,
	MapAction_ForceAllBlue,
	MapAction_LockTeams,
	MapAction_GoToSpectator/*,
	The following are what I intend to implement. Someday.
	MapAction_PassVote,
	MapAction_FailVote,
	MapAction_Restart,
	MapAction_ClearPenalties,
	MapAction_UnreadyAll,
	MapAction_RespawnAll
	*/
};

var(SWATGui) private EditInline Config GUIListBox Players;
var private array<string> OldPlayerNames;

var(SWATGui) private EditInline Config GUIComboBox PlayerActions;
var(SWATGui) private EditInline Config GUIButton PlayerActionButton;
var localized config string PlayerActionNames[AdminPlayerActions.EnumCount];
var config string PlayerConsoleCommands[AdminPlayerActions.EnumCount]; // These MUST match the ones in the PlayerController!!
var private int NumberPlayerActionsAllowed;

var(SWATGui) private EditInline Config GUIComboBox MapActions;
var(SWATGui) private EditInline Config GUIButton MapActionButton;
var localized config string MapActionNames[AdminMapActions.EnumCount];
var config string MapConsoleCommands[AdminMapActions.EnumCount];	// These MUST match the ones in the PlayerController!!
var private int NumberMapActionsAllowed;

// Maps a player action to a permission
private function AdminPermissions MapPlayerActionToPermission(AdminPlayerActions e)
{
	switch(e)
	{
		case PlayerAction_Kick:
			return AdminPermissions.Permission_Kick;
		case PlayerAction_Ban:
			return AdminPermissions.Permission_KickBan;
		case PlayerAction_LockTeam:
			return AdminPermissions.Permission_LockPlayerTeams;
		case PlayerAction_ForceRed:
		case PlayerAction_ForceBlue:
			return AdminPermissions.Permission_ForcePlayerTeam;
		case PlayerAction_Mute:
			return AdminPermissions.Permission_Mute;
		case PlayerAction_Kill:
			return AdminPermissions.Permission_KillPlayers;
		case PlayerAction_MakeLeader:
			return AdminPermissions.Permission_PromoteLeader;
		case PlayerAction_ForceSpectator:
			return AdminPermissions.Permission_ForceSpectator;
		case PlayerAction_ForceLessLethal:
			return AdminPermissions.Permission_ForceLessLethal;
	}
}

// Maps a map action to a permission
private function AdminPermissions MapMapActionToPermission(AdminMapActions e)
{
	switch(e)
	{
		case MapAction_NextMap:
			return AdminPermissions.Permission_Switch;
		case MapAction_StartGame:
			return AdminPermissions.Permission_StartGame;
		case MapAction_EndGame:
			return AdminPermissions.Permission_EndGame;
		case MapAction_LockTeams:
			return AdminPermissions.Permission_LockTeams;
		case MapAction_ForceAllRed:
		case MapAction_ForceAllBlue:
			return AdminPermissions.Permission_ForceAllTeams;
		case MapAction_GoToSpectator:
			return AdminPermissions.Permission_GoToSpec;
	}
}

// Populates the player actions list
private function PopulatePlayerActions(SwatPlayerReplicationInfo PRI)
{
	local int i;

	if(PRI == None)
	{
		return;
	}

	PlayerActions.Clear();
	NumberPlayerActionsAllowed = 0;

	// Iterate through the player actions, adding each one to the list
	for(i = 0; i < AdminPlayerActions.EnumCount; i++)
	{
		if(PRI.MyRights[MapPlayerActionToPermission(AdminPlayerActions(i))] > 0 || PRI.bLocalClient)
		{
			PlayerActions.AddItem(PlayerActionNames[i], , , i);
			NumberPlayerActionsAllowed++;
		}
	}

	// Disable the button if we don't have any actions
	PlayerActionButton.OnClick = InternalPlayerActionButton;
	PlayerActionButton.Show();
	if(NumberPlayerActionsAllowed > 0)
	{
		PlayerActionButton.EnableComponent();

	}
	else
	{
		PlayerActionButton.DisableComponent();
	}
}

// Populates the map actions list
private function PopulateMapActions(SwatPlayerReplicationInfo PRI)
{
	local int i;

	if(PRI == None)
	{
		Log("SwatMPAdminPanel:PopulateMapActions: PRI was None ?");
		return;
	}

	MapActions.Clear();
	NumberMapActionsAllowed = 0;

	// Iterate through the map actions, adding each one to the list.
	for(i = 0; i < AdminMapActions.EnumCount; i++)
	{
		if(i == AdminMapActions.MapAction_StartGame && GC.SwatGameState != GAMESTATE_PreGame)
		{
			// Special case -- don't show the Start Game action unless we're in pregame
			continue;
		}
		else if(i == AdminMapActions.MapAction_EndGame && GC.SwatGameState != GAMESTATE_MidGame)
		{
			// Special case -- don't show the End Game action unless we're actually in the game
			continue;
		}
		else if(PRI.MyRights[MapMapActionToPermission(AdminMapActions(i))] > 0 || PRI.bLocalClient)
		{
			MapActions.List.Add(MapActionNames[i], , , i);
			NumberMapActionsAllowed++;
		}
	}

	// Disable the button if we don't have any actions
	MapActionButton.OnClick = InternalMapActionButton;
	MapActionButton.Show();
	if(NumberMapActionsAllowed > 0)
	{
		MapActionButton.EnableComponent();
	}
	else
	{
		MapActionButton.DisableComponent();
	}
}

// Populates the list of players
private function PopulatePlayerNames(SwatGameReplicationInfo SGRI)
{
	local int i;
	local SwatPlayerReplicationInfo PRI;
	local array<string> NewPlayerNames;
	local bool TheyAreTheSame;

	if(SGRI == None)
	{
		return;
	}

	// Populate the list of new player names
	for(i = 0; i < ArrayCount(SGRI.PRIStaticArray); i++)
	{
		PRI = SGRI.PRIStaticArray[i];
		if(PRI == none)
		{
			continue;
		}
		NewPlayerNames[i] = PRI.PlayerName;
	}

	// Compare the new player list to the old player list.
	// If there is no difference, then we don't need to do anything.
	TheyAreTheSame = true;
	if(NewPlayerNames.Length == OldPlayerNames.Length)
	{
		for(i = 0; i < NewPlayerNames.Length; i++)
		{
			if(!(NewPlayerNames[i] ~= OldPlayerNames[i]))
			{
				TheyAreTheSame = false;
			}
		}
	}
	else
	{
		TheyAreTheSame = false;
	}

	if(TheyAreTheSame)
	{
		return;
	}

	Players.List.Clear();

	for(i = 0; i < NewPlayerNames.Length; i++)
	{
		Players.List.Add(NewPlayerNames[i]);
	}

	OldPlayerNames = NewPlayerNames;
}

///////////////////////////////////////////////////////////////////////////
//
//	Delegates

// Update the players every second
event Timer()
{
	local SwatGameReplicationInfo SGRI;

	SGRI = SwatGameReplicationInfo(PlayerOwner().GameReplicationInfo);

	PopulatePlayerNames(SGRI);
}

// Happens when the player action button is clicked
private function InternalPlayerActionButton(GUIComponent Sender)
{
	local int Action;
	local string PlayerName;

	Action = PlayerActions.List.GetExtraIntData();
	PlayerName = Players.List.Get();

	PlayerOwner().ConsoleCommand(PlayerConsoleCommands[Action] $ " " $ PlayerName);
}

// Happens when the map action button is clicked
private function InternalMapActionButton(GUIComponent Sender)
{
	local int Action;

	Action = MapActions.List.GetExtraIntData();

	PlayerOwner().ConsoleCommand(MapConsoleCommands[Action]);
}

// Happens upon the menu becoming activated
private function InternalOnActivate()
{
	local SwatPlayerReplicationInfo PRI;

	SetTimer(1.0, true);

	PRI = SwatPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);

	PopulatePlayerActions(PRI);
	PopulateMapActions(PRI);
}

private function InternalOnDeActivate()
{
    KillTimer();
}

// Default properties.
defaultproperties
{
	OnActivate=InternalOnActivate
	//OnDeActivate=InternalOnDeActivate

	PlayerActionNames[0]="Kick"
	PlayerActionNames[1]="Ban"
	PlayerActionNames[2]="Lock Team"
	PlayerActionNames[3]="Send to Red"
	PlayerActionNames[4]="Send to Blue"
	PlayerActionNames[5]="Mute/Unmute"
	PlayerActionNames[6]="Kill"
	PlayerActionNames[7]="Promote to Leader"
	PlayerActionNames[8]="Send to Spectator"
	PlayerActionnames[9]="Force Less Lethal"
	MapActionNames[0]="Go to Next Map"
	MapActionNames[1]="Start Game"
	MapActionNames[2]="End Game"
	MapActionNames[3]="Send All to Red"
	MapActionNames[4]="Send All to Blue"
	MapActionNames[5]="Lock Teams"
	MapActionNames[6]="Go to Spectator"
	PlayerConsoleCommands[0]="Kick"
	PlayerConsoleCommands[1]="KickBan"
	PlayerConsoleCommands[2]="TogglePlayerTeamLock"
	PlayerConsoleCommands[3]="ForcePlayerToTeam 2"
	PlayerConsoleCommands[4]="ForcePlayerToTeam 0"
	PlayerConsoleCommands[5]="ToggleMute"
	PlayerConsoleCommands[6]="AdminKillPlayer"
	PlayerConsoleCommands[7]="AdminPromotePlayer"
	PlayerConsoleCommands[8]="ForceSpec"
	PlayerConsoleCommands[9]="ForceLL"
	MapConsoleCommands[0]="NM"
	MapConsoleCommands[1]="StartGame"
	MapConsoleCommands[2]="AbortGame"
	MapConsoleCommands[3]="ForceAllToTeam 2"
	MapConsoleCommands[4]="ForceAllToTeam 0"
	MapConsoleCommands[5]="ToggleTeamLock"
	MapConsoleCommands[6]="GoToSpec"
}
