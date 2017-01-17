// ====================================================================
//  Class:  SwatGui.SwatMPLoadoutPanel
//  Parent: SwatGUIPanel
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatMPLoadoutPanel extends SwatLoadoutPanel
    ;

///////////////////////////
// Initialization & Page Delegates
///////////////////////////
function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	SwatGuiController(Controller).SetMPLoadoutPanel(self);
}

function LoadMultiPlayerLoadout()
{
    //create the loadout & send to the server, then destroy it
    SpawnLoadouts();
    DestroyLoadouts();
}

protected function SpawnLoadouts()
{
    LoadLoadOut( "CurrentMultiplayerLoadOut", true );
}

protected function DestroyLoadouts()
{
    if( MyCurrentLoadOut != None )
        MyCurrentLoadOut.destroy();
    MyCurrentLoadOut = None;
}

///////////////////////////
//Utility functions used for managing loadouts
///////////////////////////
function LoadLoadOut( String loadOutName, optional bool bForceSpawn )
{
    Super.LoadLoadOut( loadOutName, bForceSpawn );

//    MyCurrentLoadOut.ValidateLoadOutSpec();
    SwatGUIController(Controller).SetMPLoadOut( MyCurrentLoadOut );
}

function SaveCurrentLoadout() {
  SaveLoadOut( "CurrentMultiPlayerLoadout" );
}

function ChangeLoadOut( Pocket thePocket )
{
    local class<actor> theItem;
//log("[dkaplan] changing loadout for pocket "$GetEnum(Pocket,thePocket) );
    Super.ChangeLoadOut( thePocket );
    SaveCurrentLoadout(); //save to current loadout

    switch (thePocket)
    {
        case Pocket_PrimaryWeapon:
        case Pocket_PrimaryAmmo:
            SwatGUIController(Controller).SetMPLoadOutPocketWeapon( Pocket_PrimaryWeapon, MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_PrimaryWeapon], MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_PrimaryAmmo] );
            break;
        case Pocket_SecondaryWeapon:
        case Pocket_SecondaryAmmo:
            SwatGUIController(Controller).SetMPLoadOutPocketWeapon( Pocket_SecondaryWeapon, MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_SecondaryWeapon], MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_SecondaryAmmo] );
            break;
        case Pocket_Breaching:
            SwatGUIController(Controller).SetMPLoadOutPocketItem( Pocket.Pocket_Breaching, MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_Breaching] );
            SwatGUIController(Controller).SetMPLoadOutPocketItem( Pocket.Pocket_HiddenC2Charge1, MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_HiddenC2Charge1] );
            SwatGUIController(Controller).SetMPLoadOutPocketItem( Pocket.Pocket_HiddenC2Charge2, MyCurrentLoadOut.LoadOutSpec[Pocket.Pocket_HiddenC2Charge2] );
            break;
		case Pocket_CustomSkin:
			SwatGUIController(Controller).SetMPLoadOutPocketCustomSkin( Pocket_CustomSkin, String(EquipmentList[thePocket].GetObject()) );
			break;
        default:
            theItem = class<actor>(EquipmentList[thePocket].GetObject());
            SwatGUIController(Controller).SetMPLoadOutPocketItem( thePocket, theItem );
            break;
    }
}

function bool CheckValidity( eNetworkValidity type )
{
    return (type == NETVALID_MPOnly) || (Super.CheckValidity( type ));
}

function bool CheckTeamValidity( eTeamValidity type )
{
	local bool IsSuspect;

	if (PlayerOwner().Level.IsPlayingCOOP)
	{
		IsSuspect = false; // In coop the player is never a suspect
	}
	else
	{
		assert(PlayerOwner() != None);

		// If we don't have access to a team object assume the item is valid for the players future team
		// This case should only be true right after a level change when the player has no control over their team or loadout anyway
		// but we don't want the client to reset the loadout based on team without knowing the team. The server will never allow
		// an illegal loadout anyway so this is just a lax client side check.
		if (PlayerOwner().PlayerReplicationInfo == None || NetTeam(PlayerOwner().PlayerReplicationInfo.Team) == None)
			return true;

		// The suspect team always has a team number of 1
		IsSuspect = (NetTeam(PlayerOwner().PlayerReplicationInfo.Team).GetTeamNumber() == 1);
	}

	       // Item is usable by any team   or // Suspect only item and player is suspect    or // SWAT only item and player is not a suspect
	return Super.CheckTeamValidity( type ) || (type == TEAMVALID_SuspectsOnly && IsSuspect) || (type == TEAMVALID_SWATOnly && !IsSuspect);
}

function bool CheckWeightBulkValidity() {
  local float Weight;
  local float Bulk;

  Weight = MyCurrentLoadOut.GetTotalWeight();
  Bulk = MyCurrentLoadOut.GetTotalBulk();

  if(Weight > MyCurrentLoadOut.GetMaximumWeight()) {
    TooMuchWeightModal();
    return false;
  } else if(Bulk > MyCurrentLoadOut.GetMaximumBulk()) {
    TooMuchBulkModal();
    return false;
  }

  return true;
}

defaultproperties
{
  EquipmentOverWeightString="You are equipped with too much weight. Your loadout will be changed to the default if you don't adjust it."
  EquipmentOverBulkString="You are equipped with too much bulk. Your loadout will be changed to the default if you don't adjust it."
}
