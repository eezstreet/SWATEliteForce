class SimpleEquipment extends Engine.Equipment
    native;

var() name AttachmentBone;
var() bool AutoEquip;

function PostBeginPlay()
{
    Super.PostBeginPlay();

    AssertWithDescription(class.name != 'SimpleEquipment',
        "[tcohen] "$name$" is a SimpleEquipment.  SimpleEquipment cannot be used directly in SWAT.  It is used only as a template to create specific pieces of simple equipment.  Please delete the SimpleEquipment from the map.");
    
    AssertWithDescription(AttachmentBone != '',
        "[tcohen] "$class.name$" (a SimpleEquipment) does not have an AttachmentBone.  Please give it one.");
}

//Equipment implementation

function OnGivenToOwner()
{
    local Pawn PawnOwner;

    PawnOwner = Pawn(Owner);
    assert(PawnOwner != None);

    if (AutoEquip)
    {
        Show();
        PawnOwner.AttachToBone(self, AttachmentBone);
    }
    else
        Hide();
}

//it is not an error to equip something that is already equipped
function Equip()
{
    local Pawn PawnOwner;

    PawnOwner = Pawn(Owner);
    assert(PawnOwner != None);

    Show();

    PawnOwner.AttachToBone(self, AttachmentBone);
}

//it is not an error to unequip something that is not equipped
function UnEquip()
{
    local Pawn PawnOwner;

    PawnOwner = Pawn(Owner);
    assert(PawnOwner != None);

    Show();

    PawnOwner.DetachFromBone(self);
}

defaultproperties
{
    AutoEquip=true
    StaticMesh=StaticMesh'SwatGear_sm.Placeholder'
    DrawType=DT_StaticMesh

	bStatic=False
    bNoDelete=False

    bBlockActors=false
    bBlockPlayers=false
}
