class SwatGUIConfig extends Core.Object
    native
    config(SwatGuiState)
    HideCategories(Object)
    dependsOn(SwatStartPointBase);

import enum Pocket from Engine.HandheldEquipment;
import enum EEntryType from SwatStartPointBase;
import enum EMPMode from Engine.Repo;


//TODO: move this somewhere else
enum eDifficultyLevel
{
    DIFFICULTY_Easy,
    DIFFICULTY_Normal,
    DIFFICULTY_Hard,
    DIFFICULTY_Elite,
};

var(Difficulty) Config Localized String DifficultyString[eDifficultyLevel.EnumCount];
var(Difficulty) Config int DifficultyScoreRequirement[eDifficultyLevel.EnumCount];
var(Difficulty) Config eDifficultyLevel CurrentDifficulty;

//////////////////////////////////////////////////////////////////////////////////////
// Campaigns & SP Missions
//////////////////////////////////////////////////////////////////////////////////////
var(Missions) Config			array<Name>		CompleteMissionList			"The list of all available missions";
var(Missions) config localized  array<string>   CompleteFriendlyNameList    "Friendly name to display in the gui";

var(Missions) EditConst EditInline SwatMission	CurrentMission	"The current mission selected for Single Player";

//these specify the campaign
var(Missions) config            array<Name>     MissionName			"Name used for this mission";
var(Missions) config /*localized*/  array<string>   FriendlyName		"Friendly name to display in the gui";
var(Missions) config			array<class>	MissionEquipment	"The piece of equipment unlocked at this mission";

var(Missions) private Config    Name            LastMissionPlayedName           "The Name of the last mission that was played in Single Player";
var(Missions) private Config    String          LastMissionPlayedFriendlyName   "The friendly name of the last mission that was played in Single Player";
var(Missions) private Config    CustomScenario  LastMissionPlayedCustomScenario "The last Custom Scenario that was played in Single Player";

var(Missions) private           Name            CurrentMissionName           "The Name of the last mission that was played in Single Player";
var(Missions) private           String          CurrentMissionFriendlyName   "The friendly name of the last mission that was played in Single Player";
var(Missions) private           CustomScenario  CurrentMissionCustomScenario "The last Custom Scenario that was played in Single Player";

var(Missions) config array<Name> MissionResultNames;
var(Missions) array<MissionResults> MissionResults;

var(Missions) private EditConst EditInline CustomScenarioPack CurrentCustomScenarioPack   "The current CustomScenarioPack selected for Single Player";
var(Missions) private EditConst EditInline String PakName   "The name of the current CustomScenarioPack selected for Single Player";
var(Missions) private EditConst EditInline String PakFriendlyName   "The name of the current CustomScenarioPack selected for Single Player in friendly display format (without extension)";
var(Missions) private EditConst EditInline String PakExtension "The extension of the current CustomScenarioPack selected for Single Player";
var(Missions) private EditConst EditInline String ScenarioName "The current CustomScenario selected for Single Player";

// This value indicates which set of start points (primary or secondary)
// officers and players should use when entering a single player map.
var(Missions) private EEntryType DesiredSPEntryPoint;

var(Missions) Config Bool bEverRanTraining "true if the player ever ran training or click through it";


//////////////////////////////////////////////////////////////////////////////////////
// Loadout Options
//////////////////////////////////////////////////////////////////////////////////////
enum eNetworkValidity
{
    NETVALID_None,
    NETVALID_SPOnly,
    NETVALID_MPOnly,
    NETVALID_All,
};

enum eTeamValidity
{
	TEAMVALID_All,
	TEAMVALID_SWATOnly,
	TEAMVALID_SuspectsOnly,
};

var(Equipment) editconst array<SwatEquipmentSpec> AvailableEquipmentPockets "Specifies other available equipment";
var(Equipment) config array<String> CustomEquipmentLoadouts "Specifies custom equipment loadouts";
var(Equipment) config array<String> CustomEquipmentLoadoutFriendlyNames "Specifies custom equipment loadouts";
var(Equipment) localized config array<String> CustomEquipmentLoadoutDefaultFriendlyNames "Specifies custom equipment loadouts";
var(Equipment) config array<bool> LoadoutIsUndeletable "Specifies whether the loadout is undeletable";

//////////////////////////////////////////////////////////////////////////////////////
// Key Config Settings
//////////////////////////////////////////////////////////////////////////////////////
enum eCommandCategory
{
    COMCAT_Movement,
    COMCAT_Interactions,
    COMCAT_Chat,
    COMCAT_Reserved,
};

var(KeyConfigSettings) config           array<string>   CommandString "The string corresponding to the command this Input Function struct is representing";
var(KeyConfigSettings) config localized array<string>   LocalizedCommandString "The localized string corresponding to the command this Input Function struct is representing";
var(KeyConfigSettings) config array<eCommandCategory>   CommandCategory "The category of this command";

//////////////////////////////////////////////////////////////////////////////////////
// Audio Settings
//////////////////////////////////////////////////////////////////////////////////////
var(AudioSettings) config localized array<string> AudioVirtualizationChoices "Choices for audio virtualization";
var(AudioSettings) config localized array<string> SoundQualityChoices "Choices for sound quality";

//////////////////////////////////////////////////////////////////////////////////////
// Video Settings
//////////////////////////////////////////////////////////////////////////////////////
var(VideoSettings) config array<string> ScreenResolutionChoices "Choices for screen resolution";
var(VideoSettings) config localized array<string> TextureDetailChoices "Choices for texture detail";
var(VideoSettings) config localized array<string> OtherDetailChoices "Choices for other detail";
var(VideoSettings) config localized array<string> RenderDetailChoices "Choices for generic render detail";
var(VideoSettings) config localized array<string> PixelShaderChoices "Choices for pixel shaders";
var(VideoSettings) config localized array<string> RealtimeMirrorChoices "Choices for Realtime Mirrors";

//////////////////////////////////////////////////////////////////////////////////////
// Network Settings
//////////////////////////////////////////////////////////////////////////////////////

enum eVoiceType
{
    VOICETYPE_Random,
    VOICETYPE_Lead,
    VOICETYPE_OfficerRedOne,
    VOICETYPE_OfficerRedTwo,
    VOICETYPE_OfficerBlueOne,
    VOICETYPE_OfficerBlueTwo,
    VOICETYPE_VIP,
};


var(MPSettings) config localized array<string> VoiceTypeChoices "Choices for network voicetypes";
var(MPSettings) config           eVoiceType     PreferredVoiceType "Selected voicetype for network games";

// dbeswick: integrated 20/6/05
// Caches the voice type to use when the user chooses "random" in the GUI.
// If it's set to RANDOM, then it will be re-cached when next queried
var                               eVoiceType     CachedRandomVoice;

var config bool bNoIronSights;		// Use old-style zoom?
var config bool bHideFPWeapon;		// Hide first person weapon?
var config bool bHideCrosshairs;	// Hide crosshairs at all times?
var config bool bNoWeaponInertia;	// No weapon inertia?
var() config int NotUsed;
var() config int NotUsed2;
var() config int NotUsed3;
var() config int NotUsed4;
var() config int NotUsed5;
var(MPSettings) config           int           NetSpeedSelection "Selected speed for network connection";

var(MPSettings) Config float MPPostMissionTime "Time (in seconds) between when the round has been completed and the MPPage is brought up";
var(MPSettings) Config float MPPollingDelay "Time (in seconds) between information polls in MP";
var(MPSettings) bool    FirstTimeThrough "Simple switch to determine if the player is entering the server";

var(MPSettings) array<string> AvailableMPMaps "Choices for MP maps to play";

var(MPSettings) private Config string SwatMapFileExtension "File extension for swat maps";
var(MPSettings) private Config string SwatMPMapNamePrefix "Prefix for multiplayer maps (typically MP)";

var(MPSettings) Config localized string TDMDescription "Gametype Team Deathmatch game description. Newlines should be seperated by | (for now)";
var(MPSettings) Config localized string VIPDescription "Gametype VIP Escort game description. Newlines should be seperated by | (for now)";
var(MPSettings) Config localized string BombDescription "Gametype Diffuse Da Bomb game description. Newlines should be seperated by | (for now)";
var(MPSettings) Config localized string COOPDescription "Gametype COOP description. Newlines should be seperated by | (for now)";
var(MPSettings) Config localized string COOPQMMDescription "Gametype COOP QMM description. Newlines should be seperated by | (for now)";
var(MPSettings) Config localized string SmashAndGrabDescription "Gametype Test description. Newlines should be seperated by | (for now)";

var(MPSettings) Config localized string TDMFriendlyName "Gametype Team Deathmatch game FriendlyName.";
var(MPSettings) Config localized string VIPFriendlyName "Gametype VIP Escort game FriendlyName.";
var(MPSettings) Config localized string BombFriendlyName "Gametype Diffuse Da Bomb game FriendlyName.";
var(MPSettings) Config localized string COOPFriendlyName "Gametype COOP FriendlyName.";
var(MPSettings) Config localized string COOPQMMFriendlyName "Gametype COOP QMM FriendlyName.";
var(MPSettings) Config localized string SmashAndGrabFriendlyName "Gametype SmashAndGrab FriendlyName.";

var(MPSettings) Config localized string MPSuspectsWinMessage "The message to display when the suspects win";
var(MPSettings) Config localized string MPSWATWinMessage "The message to display when the SWAT team wins";
var(MPSettings) Config localized string MPTieMessage "The message to display when the game ends in a tie";


//////////////////////////////////////////////////////////////////////////////////////
// Game Settings
//////////////////////////////////////////////////////////////////////////////////////
var(GameSettings) const Config Localized String DefaultMPName "The default name given to the player for Multiplayer Games";
var(GameSettings) Config String MPName "The name the player will use for Multiplayer Games";
#if IG_CAPTIONS
var(GameSettings) Config Bool bShowSubtitles "If true, subtitles will be displayed for in-game audio";
#endif
var(GameSettings) Config Bool bShowHelp "If true, help text will be displayed for each control";
var(GameSettings) Config Bool bAlwaysRun "If true, the player will run by default rather than walk";
var(GameSettings) Config Bool bShowCustomSkins "If true, custom skins will be shown in MP games";

var(GameSettings) int MPNameLength "The max length of the name the player will use for Multiplayer Games";
var(GameSettings) localized String MPNameAllowableCharSet "The allowable character set for the name the player will use for Multiplayer Games";

//////////////////////////////////////////////////////////////////////////////////////
// HUD Settings
//////////////////////////////////////////////////////////////////////////////////////
enum ECommandInterfaceStyle
{
    CommandInterface_Invalid,
    CommandInterface_Classic,
    CommandInterface_Graphic
};

var(HUDSettings) config ECommandInterfaceStyle CommandInterfaceStyle;
var(HUDSettings) EditConst ECommandInterfaceStyle CurrentCommandInterfaceStyle;
var(HUDSettings) Config int MessageDisplayTime "Time (in seconds) for messages to be displayed on the hud";
var(HUDSettings) Config int GCIButtonMode "Button Mode currently selected for the Graphical Command Interface";
var(HUDSettings) Config bool bUseExitMenu "Exit pad displayed the Graphical Command Interface";


//////////////////////////////////////////////////////////////////////////////////////
// Server Settings
//////////////////////////////////////////////////////////////////////////////////////

enum eConnectionType
{
    CONNECTION_Modem,
    CONNECTION_Cable,
    CONNECTION_DSL,
    CONNECTION_T1,
    CONNECTION_T3,
    CONNECTION_OC3,
};


//Generic Server Settings Information
var                 config String         AdminPassword "Admin Password for the server for authenticating users";

var(ServerSettings) editinline array<MapRotation> MapList "Maplists to cycle through - 1 per gametype";


struct native ServerFilters
{
    var() config int            MaxPing "Filter by max ping, -1 = dont filter by ping";
    var() config bool           bFull "Filter out full servers if true";
	var() config bool           bEmpty "Filter out empty servers if true";
    var() config bool           bPassworded "Filter out passworded servers if true";
    var() config bool           bFilterGametype "Filter out gametype servers if true";
    var() config EMPMode        GameType "What game type to filter by";
	var() config bool           bFilterMapName "Filter out servers by map name if true";
	var() config String			MapName "What map name to filter by";
    var() config bool           bHideIncompatibleVersions "Filter out incompatible by version servers if true";
    var() config bool           bHideIncompatibleMods "Filter out incompatible by mod servers if true";
};

var(ServerSettings) config ServerFilters theServerFilters "The current server filters";
var(ServerSettings) config bool          bViewingGameSpy "If true, the client is viewing the server list provided by GameSpy";


//////////////////////////////////////////////////////////////////////////////////////
// Game State
//////////////////////////////////////////////////////////////////////////////////////

enum eSwatGameState
{
    GAMESTATE_None,             //Not in game at all, GUI only
    GAMESTATE_EntryLoading,     //Currently loading the entry level
    GAMESTATE_LevelLoading,     //Currently loading a (non-entry) level
    GAMESTATE_PreGame,          //Level has loaded but round not yet begun
    GAMESTATE_MidGame,          //Game in progress
    GAMESTATE_PostGame,         //Level completed
    GAMESTATE_ClientTravel,     //Client is travelling to the new map on the server
    GAMESTATE_ConnectionFailed, //Client failed to connect to the server (remote OR local)
};

enum eSwatGameRole
{
    GAMEROLE_None,              //Not doing much of anything, GUI exclusive
    GAMEROLE_SP_Campaign,       //Playing through a campaign
    GAMEROLE_SP_Custom,         //Playing a custom mission
    GAMEROLE_SP_Other,          //Playing anything else on own (training)
    GAMEROLE_MP_Host,           //Playing as the host/admin in a MP game
    GAMEROLE_MP_Client,         //Playing as the client in a MP game
};

var(SwatGame) eSwatGameState SwatGameState;
var(SwatGame) eSwatGameRole  SwatGameRole;

var(SwatGame) config float CriticalMomentDelay "The amount of time after a critical moment to wait until popping out of the action (eg. to give players time to die)";

overloaded function Construct()
{
    local int i;
	local SwatSkinEquipmentSpec SSES;

    AssertWithDescription( MissionName.Length == FriendlyName.Length, "The number of campaign MissionNames specified in SwatGUIState.ini does not match the number of FriendlyNames" );
    AssertWithDescription( MissionName.Length > 0, "There must be at least one valid campaign MissionNames specified in SwatGUIState.ini" );

    for( i = 0; i < Pocket.EnumCount; i++ )
    {
		if (i != Pocket.Pocket_CustomSkin)
		{
			AvailableEquipmentPockets[i] = new(,string(GetEnum(Pocket,i))) class'SwatGame.SwatEquipmentSpec';
		}
		else
		{
			SSES = new(,string(GetEnum(Pocket,i))) class'SwatGame.SwatSkinEquipmentSpec';
			SSES.Initialise();
			AvailableEquipmentPockets[i] = SSES;
		}
    }

	for ( i = 0; i < CustomEquipmentLoadoutDefaultFriendlyNames.Length; ++i )
	{
		CustomEquipmentLoadoutFriendlyNames[i] = CustomEquipmentLoadoutDefaultFriendlyNames[i];
	}

    AssertWithDescription( CustomEquipmentLoadoutFriendlyNames.Length == CustomEquipmentLoadouts.Length, "The number of Custom Loadouts does not match the number of Friendly Names specified in SwatGUIState.ini!");

	//TODO: clean this up later
    LoadLastMissionPlayed();

    //custom mission results
    for (i=0; i<MissionResultNames.Length; i++)
    {
        MissionResults[i] = new(,string(MissionResultNames[i])) class'SwatGame.MissionResults';

        Assert(MissionResults[i] != None);
    }

    for( i = 0; i < EMPMode.EnumCount; i++ )
    {
        MapList[i] = new(,string(GetEnum(EMPMode,i))) class'SwatGame.MapRotation';
    }

	if (MPName == "")
		MPName = DefaultMPName;
}

//////////////////////////////////////////////////////////////////////////////////////
// Accessors
//////////////////////////////////////////////////////////////////////////////////////
function SetCurrentMissionAllMissions(String URL, Name MissionName, optional string FriendlyName, optional CustomScenario CustomScenario)
{
  local string MapPath;

  MapPath = Left(URL, InStr(URL, "?"));

  SetCurrentMission(MissionName, FriendlyName, CustomScenario);

  CurrentMissionName = Name(MapPath);
  CurrentMission.MapName = MapPath;
  log("SetCurrentMissionAllMissions: MapPath is "$MapPath);
  log("SetCurrentMissionAllMissions: CurrentMissionName = "$CurrentMissionName);
}

function SetCurrentMission( Name MissionName, optional string FriendlyName, optional CustomScenario CustomScenario )
{
log("[ckline] >>> SwatGUIConfig::SetCurrentMission('"$MissionName$"', '"$FriendlyName$"', '"$CustomScenario$"')");
    if( CurrentMission != None &&
        CurrentMission.Name == MissionName &&
        CurrentMission.FriendlyName == FriendlyName &&
        CurrentMission.CustomScenario == CustomScenario )
    {
        log("[carlos] >>> SwatGUIConfig::SetCurrentMission() desired mission is already the current mission");
        return;
    }
    if( CurrentMission != None )
    {
        CurrentMission.Release();
        CurrentMission=None;
    }
    if( MissionName == '' )
    {
log("[ckline] >>> SwatGUIConfig::SetCurrentMission(): CurrentMission is now None");
        return;
    }

    CurrentMission = new( None, string(MissionName) ) class'SwatGame.SwatMission';
    Assert(CurrentMission != None);
    CurrentMission.AddRef();

    if( CustomScenario != None )
        SetScenarioName( FriendlyName );

    CurrentMission.Initialize( FriendlyName, CustomScenario );

    //the the new one as the Last played immediately
    CurrentMissionName = CurrentMission.Name;
    CurrentMissionFriendlyName = CurrentMission.FriendlyName;
    CurrentMissionCustomScenario = CurrentMission.CustomScenario;

    //set the default entry point
    if( CurrentMission.EntryOptionTitle.Length < 2 )
    {
        //only primary entry is available
        SetDesiredEntryPoint( ET_Primary );
    }
    else if( CustomScenario != None && CustomScenario.SpecifyStartPoint )
    {
        if( CustomScenario.UseSecondaryStartPoint )
            SetDesiredEntryPoint( ET_Secondary );
        else
            SetDesiredEntryPoint( ET_Primary );
    }

log("[ckline] >>> SwatGUIConfig::SetCurrentMission(): CurrentMission is now '"$CurrentMission$"'");

    SetCurrentCommandInterfaceStyle( CommandInterfaceStyle );
}

function ResetCurrentMission()
{
    SetCurrentMission( CurrentMissionName, CurrentMissionFriendlyName, CurrentMissionCustomScenario );
}

function ClearCurrentMission()
{
    SetCurrentMission( '' );
}

function LoadLastMissionPlayed()
{
    //dkaplan: this is totally a hack to load something other than training if instant action is clicked
	if( LastMissionPlayedName != '' && LastMissionPlayedName != 'SP-Training' )
	    SetCurrentMission( LastMissionPlayedName, LastMissionPlayedFriendlyName, LastMissionPlayedCustomScenario );
	else
        SetCurrentMission( MissionName[0], FriendlyName[0] );

    AssertWithDescription( CurrentMission != None, "Failed to load a CurrentMission on GuiConfig LoadLastMissionPlayed().  The InstantAction option may not be available." );
}

function SaveLastMissionPlayed()
{
    LastMissionPlayedName = CurrentMissionName;
    LastMissionPlayedFriendlyName = CurrentMissionFriendlyName;
    LastMissionPlayedCustomScenario = CurrentMissionCustomScenario;
    SaveConfig();
}

function string GetGameDescription( EMPMode type )
{
    switch (type)
    {
        case MPM_BarricadedSuspects:
            return TDMDescription;
            break;
        case MPM_VIPEscort:
            return VIPDescription;
            break;
        case MPM_RapidDeployment:
            return BombDescription;
            break;
        case MPM_COOP:
            return COOPDescription;
            break;
		case MPM_COOPQMM:
			return COOPQMMDescription;
			break;
		case MPM_SmashAndGrab:
			return SmashAndGrabDescription;
			break;
    }
}

function string GetGameModeName( EMPMode type )
{
    switch (type)
    {
        case MPM_BarricadedSuspects:
            return TDMFriendlyName;
            break;
        case MPM_VIPEscort:
            return VIPFriendlyName;
            break;
        case MPM_RapidDeployment:
            return BombFriendlyName;
            break;
        case MPM_COOP:
            return COOPFriendlyName;
            break;
		case MPM_COOPQMM:
			return COOPQMMFriendlyName;
			break;
		case MPM_SmashAndGrab:
			return SmashAndGrabFriendlyName;
			break;
    }
}

function string GetGameModeNameFromNonlocalizedString( string NonlocalizedString )
{
    if ( NonlocalizedString == "Rapid Deployment" )
        return BombFriendlyName;
    else if ( NonlocalizedString == "VIP Escort" )
        return VIPFriendlyName;
    else if ( NonlocalizedString == "CO-OP" )
        return COOPFriendlyName;
    else if ( NonlocalizedString == "CO-OP QMM" )
        return COOPQMMFriendlyName;
	else if ( NonlocalizedString == "Smash And Grab" )
		return SmashAndGrabFriendlyName;
    else
        return TDMFriendlyName;
}

function String GetDifficultyString( eDifficultyLevel difficulty )
{
    return DifficultyString[difficulty];
}

final function MissionEnded(name Mission, eDifficultyLevel difficulty, bool Completed, int Score)
{
    local int index;

    index = GetMissionIndex(Mission);

    if( (index >= MissionResults.length) ) //mission was never played before
    {
        MissionResults[index] = new(,string(Mission)) class'SwatGame.MissionResults';
        MissionResultNames[index] = Mission;
    }

    Assert( MissionResults[index] != None );

    //add this mission result
    MissionResults[index].AddResult( difficulty, Completed, Score );

    SaveConfig();
}

//returns the MissionResults of the specified Mission.
//if the mission was played, then MissionResults.Mission will equal the Mission argument.
//otherwise, MissionResults is empty (ie. MissionResults.Mission is None)
final function MissionResults GetMissionResults(name Mission)
{
    local int index;

    index = GetMissionIndex(Mission);
log( "[dkaplan] getting mission results for mission " $ Mission $ ", index = " $ index );

    //(GetMissionIndex() returns MissionResults.length if Mission is not found.)
    return MissionResults[index];
}

//returns the index of Mission in MissionResults, or MissionResults.length if not found.
private function int GetMissionIndex(name Mission)
{
    local int i;

    for (i=0; i<MissionResults.length; ++i)
        if (MissionResults[i] != None && MissionResultNames[i] == Mission)
            break;

    return i;
}

function Name GetCurrentMissionName()
{
    return CurrentMissionName;
}

function SetCustomScenarioPackData( CustomScenarioPack Pak, optional string pakN, optional string pakFN, optional string pakExt )
{
    CurrentCustomScenarioPack = Pak;
    PakName = pakN;
    PakFriendlyName = pakFN;
    PakExtension = pakExt;
}

function CustomScenarioPack GetCustomScenarioPack()
{
    return CurrentCustomScenarioPack;
}

function String GetPakName()
{
    return PakName;
}

function SetScenarioName( string inScenarioName )
{
    ScenarioName = inScenarioName;
}

function String GetScenarioName()
{
    return ScenarioName;
}

function String GetPakFriendlyName()
{
    return PakFriendlyName;
}

function String GetPakExtension()
{
    return PakExtension;
}

function SetCurrentCommandInterfaceStyle(ECommandInterfaceStyle Style)
{
    if( CurrentMission == None || CurrentMission.Name != 'SP-Training' )
        CurrentCommandInterfaceStyle = Style;
    else
        CurrentCommandInterfaceStyle = CommandInterface_Graphic;
}

// Set whether the player and his team should start from the primary or
// secondary set of entry points in a single player mission.
final function SetDesiredEntryPoint(EEntryType EntrySet)
{
	DesiredSPEntryPoint = EntrySet;

	if (EntrySet == ET_Primary)
		log("Desired entry point was set to PRIMARY");
	else
		log("Desired entry point was set to SECONDARY");
}

final function EEntryType GetDesiredEntryPoint()
{
	return DesiredSPEntryPoint;
}

final function Name GetTagForVoiceType( eVoiceType Type )
{
    switch( Type )
    {
        case VOICETYPE_VIP:
            return 'VIP';
        case VOICETYPE_Lead:
            return 'Lead';
        case VOICETYPE_OfficerRedOne:
            return 'OfficerRedOne';
        case VOICETYPE_OfficerRedTwo:
            return 'OfficerRedTwo';
        case VOICETYPE_OfficerBlueOne:
            return 'OfficerBlueOne';
        case VOICETYPE_OfficerBlueTwo:
            return 'OfficerBlueTwo';
    }
    return '';
}

// dbeswick: integrated 20/6/05
final function eVoiceType GetVoiceTypeForCurrentPlayer()
{
    local eVoiceType Voice;

	//log("GetVoiceTypeForCurrentPlayer() Preferred type =  "$GetEnum(eVoiceType, PreferredVoiceType));

    if( PreferredVoiceType == eVoiceType.VOICETYPE_Random )
	{
	    if (CachedRandomVoice == eVoiceType.VOICETYPE_Random) // random voice has not yet been chosen
        {
            // choose a random voice to use consistently until the next time the
            // user changes back and forth from a specific voice to the "random"
            // option in the GUI
            CachedRandomVoice = eVoiceType( Rand( eVoiceType.EnumCount - 2 ) + 1 );

		    //log("Caching a new consistent random voice: "$GetEnum(eVoiceType, CachedRandomVoice));
        }

        Voice = CachedRandomVoice;
	}
    else
        Voice = PreferredVoiceType;

    //log("GetVoiceTypeForCurrentPlayer() returning "$GetEnum(eVoiceType, Voice));

    return Voice;
}


defaultproperties
{
    FirstTimeThrough=true
    MPPollingDelay=0.25
    MPPostMissionTime=9.0
    MessageDisplayTime=15
    DifficultyString(0)="Easy"
    DifficultyString(1)="Normal"
    DifficultyString(2)="Hard"
    DifficultyString(3)="Elite"
    DifficultyScoreRequirement(0)=0
    DifficultyScoreRequirement(1)=50
    DifficultyScoreRequirement(2)=75
    DifficultyScoreRequirement(3)=95
    TDMFriendlyName="Barricaded Suspects"
    VIPFriendlyName="VIP Escort"
    BombFriendlyName="Rapid Deployment"
	COOPQMMFriendlyName="COOP QMM"
	SmashAndGrabFriendlyName="Smash And Grab Game Mode"
    SwatMPMapNamePrefix="MP"
    SwatMapFileExtension=".s4m"

	// The default entry choice is Primary, until the user chooses a different
	// one in the briefing screen.
    DesiredSPEntryPoint=ET_Primary

    //by default, we do not want to show subtitles in the game
//#if IG_CAPTIONS
    bShowSubtitles=false
//#endif

    ServerName="SWAT 4 Server"
    DefaultMPName="Player"
    MPNameLength=30
    MPNameAllowableCharSet="abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ()<>{}|_!^"

    AdminPassword=""

    VoiceTypeChoices(0)="Random"
    VoiceTypeChoices(1)="Lead"
    VoiceTypeChoices(2)="Reynolds"
    VoiceTypeChoices(3)="Girard"
    VoiceTypeChoices(4)="Fields"
    VoiceTypeChoices(5)="Jackson"
}
