class Detonator extends Engine.HandheldEquipment
    implements ITacticalAid;

simulated function float GetWeight() {
  return 0.0;
}

simulated function float GetBulk() {
  return 0.0;
}

simulated function bool HandleMultiplayerUse()
{
    if ( Level.NetMode != NM_Standalone )
    {
        SwatPlayer(Owner).ServerRequestUse( SwatPlayer(Owner) );
        return true;
    }

    return false;
}

simulated function EquippedHook()
{
  Super.EquippedHook();
  UpdateHUD();
}

simulated function UsedHook()
{
    local ICanUseC2Charge Officer;
    local DeployedC2ChargeBase Charge;
    local SwatDoor AssociatedDoor;
    local Controller i;
    local Controller theLocalPlayerController;
    local SwatGamePlayerController current;

    Officer = ICanUseC2Charge(Owner);
    assertWithDescription(Officer != None,
        "[tcohen] Detonator::UsedHook() the Owner of this Detonator ("$Owner
        $") isn't an ICanUseC2Charge.");

    Charge = Officer.GetDeployedC2Charge();
    AssociatedDoor = SwatDoor(Charge.GetDoorDeployedOn());

    if (Charge != None && !Charge.bDeleteMe)
    {
        // Clients play their OnDetonated when SGPC::ClientPlayDoorBreached is called().
        if ( Level.NetMode != NM_Client )
            Charge.OnDetonated();

        // Notify all clients that the door has been breached.
        if ( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer )
        {
            theLocalPlayerController = Level.GetLocalPlayerController();
            for ( i = Level.ControllerList; i != None; i = i.NextController )
            {
                current = SwatGamePlayerController( i );
                if ( current != None && current != theLocalPlayerController )
                {
                    mplog( "...on server: calling OnDoorUnlocked() on "$current );
                    current.ClientPlayDoorBreached( AssociatedDoor, Charge );
                }
            }
        }
    }
    //else
    //{
    //TMC TODO handle Detonator::UsedHook() with no linked charge
    //}
    UpdateHUD();
}

function UpdateHUD()
{
  local SwatGame.SwatGamePlayerController LPC;
  local int ReserveWedges;

  LPC = SwatGamePlayerController(Level.GetLocalPlayerController());

  if (Pawn(Owner).Controller != LPC) return; //the player doesn't own this ammo

  ReserveWedges = LPC.SwatPlayer.GetTacticalAidAvailableCount(GetSlot());
  ReserveWedges--; // We are holding one
  if(ReserveWedges < 0)
  {
    ReserveWedges = 0;
  }

  LPC.GetHUDPage().AmmoStatus.SetTacticalAidStatus(ReserveWedges, self);
  LPC.GetHUDPage().UpdateWeight();
}

simulated function EquipmentSlot GetSlotForReequip()
{
  local SwatGame.SwatGamePlayerController LPC;

  LPC = SwatGamePlayerController(Level.GetLocalPlayerController());

  if (Pawn(Owner).Controller != LPC) return Slot_PrimaryWeapon; //the player doesn't own this ammo

  if(LPC.bSecondaryWeaponLast)
    return Slot_SecondaryWeapon;
  return Slot_PrimaryWeapon;
}

defaultproperties
{
    Slot=Slot_Detonator
    EquipOtherAfterUsed=true
}
