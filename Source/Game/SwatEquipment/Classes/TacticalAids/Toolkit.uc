class Toolkit extends SwatGame.EquipmentUsedOnOther
    implements ITacticalAid;


simulated latent protected function OnUsingBegan()
{
    mplog( self$"---Toolkit::OnUsingBegan(). Other="$Other$", Owner="$Owner );
    Super.OnUsingBegan();
    IAmUsedByToolkit(Other).OnUsingByToolkitBegan( Pawn(Owner) );
}


simulated function UsedHook()
{
    mplog( self$"---Toolkit::UsedHook(). Other="$Other$", Owner="$Owner );
    IAmUsedByToolkit(Other).OnUsedByToolkit(Pawn(Owner));
}


simulated function OnInterrupted()
{
    mplog( self$"---Toolkit::OnInterrupted(). Other="$Other$", Owner="$Owner );
    Super.OnInterrupted();
    IAmUsedByToolkit(Other).OnUsingByToolkitInterrupted( Pawn(Owner) );
}

//which slot should be equipped after this item becomes unavailable
simulated function EquipmentSlot GetSlotForReequip()
{
    return Slot_Invalid;

    //returning Slot_Invalid means equip the default.
}

// IAmAQualifiedUseEquipment implementation

simulated function bool ShouldUseAlternate()
{
    //use lockpick animation set if being used on a door
    return Other.IsA('Door');
}

simulated function float GetQualifyDuration()
{
    return IAmUsedByToolkit(Other).GetQualifyTimeForToolkit() * GetQualifyModifier();
}

simulated function bool CanUseOnOtherNow(Actor other) {
  local Door theDoor;

  if(!other.IsA('Door')) {
    return true;
  }

  theDoor = Door(other);
  if(!theDoor.CanBeLocked()) {
    return false;
  }
  return true;
}


// IAmUsedOnOther implementation

simulated protected function AssertOtherIsValid()
{
    assertWithDescription(Other.IsA('IAmUsedByToolkit'),
        "[tcohen] A Toolkit was called to AssertOtherIsValid(), but Other is a "$Other.class.name
        $", which is not an IAmUsedByToolkit.");
}


defaultproperties
{
    Slot=SLOT_Toolkit

    EquipOtherAfterUsed=true
}
