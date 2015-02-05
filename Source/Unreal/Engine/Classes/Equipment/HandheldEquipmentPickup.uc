class HandheldEquipmentPickup extends Actor
    implements ICanBeUsed
    config(SwatGame)
    placeable;

import enum EquipmentSlot from HandheldEquipment;
    
var(Pickup) class<HandheldEquipment> HandheldEquipmentClass;
var private class<HandheldEquipment> LastHHEClass;         //used to detect if the class has changed in the Editor

var private Pawn PickerUpper;               //the last Pawn to have picked this up
var private HandheldEquipment Item;         //the last Pawn to have picked this up

event PostEditChange()
{
    Super.PostEditChange();

    UpdateAppearance();
}

function UpdateAppearance()
{
    if (HandheldEquipmentClass == None)         return;
    if (LastHHEClass == HandheldEquipmentClass) return; //nothing important has changed

    LastHHEClass = HandheldEquipmentClass;

    if  (
            HandheldEquipmentClass.default.ShouldHaveThirdPersonModel
        &&  HandheldEquipmentClass.default.ThirdPersonModelClass != None
        )
    {
        switch (HandheldEquipmentClass.default.ThirdPersonModelClass.default.DrawType)
        {
            case DT_StaticMesh:
                SetDrawType(DT_StaticMesh);
                SetStaticMesh(HandheldEquipmentClass.default.ThirdPersonModelClass.default.StaticMesh);
                break;

            case DT_Mesh:
                SetDrawType(DT_Mesh);
                LinkMesh(HandheldEquipmentClass.default.ThirdPersonModelClass.default.Mesh);
                break;

            default:
                SetDrawType(DT_StaticMesh);
                SetStaticMesh(default.StaticMesh);
        }
    }
    else
    {
        SetDrawType(DT_StaticMesh);
        SetStaticMesh(default.StaticMesh);
    }

    //if the selected HandheldEquipmentClass doesn't have a ThirdPersonModelClass,
    //  or the ThirdPersonModelClass's DrawType isn't DT_StaticMesh, then the
    //  designer may still manually set a StaticMesh for the HandheldEquipmentPickup.
}

event PostBeginPlay()
{
    Super.PostBeginPlay();

    assertWithDescription(HandheldEquipmentClass != None,
        "[tcohen] The HandheldEquipmentPickup named "$name
        $" has no HandheldEquipmentClass.");

    assertWithDescription(Level.NetMode == NM_Standalone,
        "[tcohen] HandheldEquipmentPickups are not supported in Multiplayer.");
}

// ICanBeUsed Implementation

simulated function bool CanBeUsedNow()
{
    return true;
}

simulated function OnUsed(Pawn Other)
{
    PickerUpper = Other;
    GotoState('BeingPickedUp');
}

simulated function PostUsed();


function OnUnequipToEquipFinished()
{
    assertWithDescription(false,
        "[tcohen] HandheldEquipmentPickup::OnUnequipToEquipFinished() in Global state.  This should only happen in State 'BeingPickedUp'.");
}

state BeingPickedUp
{
    ignores CanBeUsedNow;

    latent function BePickedUp()
    {
        local HandheldEquipment ActiveItem;

        assertWithDescription(PickerUpper.IsA('SwatPlayer'),
            "[tcohen] HandheldEquipmentPickup::OnUsed() PickerUpper is "$PickerUpper
            $".  I only expect SwatPlayers to pick-up HandheldEquipment.");

        ActiveItem = PickerUpper.GetActiveItem();
        if  (
                ActiveItem == None          //at the moment between switching items
            ||  !ActiveItem.IsIdle()        //busy being equipped, unequipped, etc.
            )
            return;                         //can't pickup now

        Item = Spawn(HandheldEquipmentClass, PickerUpper);
        assert(Item != None);
        assertWithDescription(Item.GetSlot() != SLOT_Breaching,
            "[tcohen] HandheldEquipmentPickup::OnUsed() The Dropped is a breaching Tactical Aid.  "
            $"HandheldEquipment with SLOT_Breaching cannot be picked-up (because its illegal to have more than one type).");
        Item.OnGivenToOwner();

        Item.Pickup = self; //setup callback when unequip of ActiveItem finishes
        Item.LatentEquip(); //this should result in a call to OnUnequipToEquipFinished()
        Item.Pickup = None; //clear callback

        PickerUpper.OnPickedUp(Item);
    }

    function OnUnequipToEquipFinished()
    {
        local HandheldEquipment OldPocketItem;

        OldPocketItem = PickerUpper.FindItemForPickupToReplace(Item);
        if (OldPocketItem != None)
        {
            HandheldEquipmentClass = OldPocketItem.class;
            UpdateAppearance();
        }
    }

Begin:

    BePickedUp();
    GotoState('');
}

defaultproperties
{
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'SwatGear_sm.Placeholder'

    bCollideActors=true
    bBlockActors=true
}
