class SwatEquipmentSpec extends Core.Object
	dependson(SwatGUIConfig)
    config(SwatEquipment)
    perObjectConfig
    HideCategories(Object);

import enum eNetworkValidity from SwatGUIConfig;
import enum eTeamValidity from SwatGUIConfig;
import enum Pocket from Engine.HandheldEquipment;

enum eEquipmentType
{
    EQUIP_Weaponry,
    EQUIP_Handheld,
    EQUIP_Protection,
    EQUIP_Simple,
	EQUIP_Skin,
};

var() config array<String> EquipmentClassName "Specifies available equipment types for this pocket";
var() config array<eNetworkValidity> Validity "Under what game conditions these pieces of equipment are valid";
var() config array<eTeamValidity> TeamValidity "Team for which these pieces of equipment are valid";
var() config array<byte> bSelectable "True if equipment in this pocket can be selected from the gui";

var() config Pocket DependentPocket "If set, the specified pocket will have its equipment loaded based on the selection in this pocket"; 
var() config eNetworkValidity DisplayValidity "Under what game conditions this pocket should be displayed in the GUI";
var() config localized String PocketFriendlyName "The name of this pocket as displayed in the GUI";
var() config eEquipmentType TypeOfEquipment "The type of this pocket: what equipment it holds";
var() config bool bSpawnable "True if equipment in this pocket should be spawned";


defaultproperties
{
    DependentPocket=Pocket_Invalid
    DisplayValidity=NETVALID_None
}