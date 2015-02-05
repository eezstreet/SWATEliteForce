class ProtectiveEquipment extends Equipment
    implements ICanBeSelectedInTheGUI
    abstract
	native;

var() name AttachmentBone "To which Bone of the Wearer does this ProtectiveEquipment attach (if any).";
var() ESkeletalRegion ProtectedRegion "Which SkeletalRegion does this ProtectiveEquipment protect (if any).";
var() float MomentumToPenetrate;
var() Range PenetratedDamageFactor "If a bullet penetrates this ProtectiveEquipment, then the Damage that it _would_ cause is multiplied by this Factor before being delt to the Wearer.";
var() Range BlockedDamageFactor "If a bullet is blocked by this ProtectiveEquipment, then the Damage that it _would_ cause (if it had penetrated) is multiplied by this Factor, and the resulting Damage is given to the Wearer.";
var() Mesh WearerMesh "If a Pawn wears this ProtectiveEquipment, then the Pawn should use this Mesh.  Leave None if the ProtectiveEquipment shouldn't affect the Wearer's Mesh.  Note that a WearerMesh must be compatible with the SwatOfficer Mesh, ie. must have all the same animations with the same names.";
var() Material FirstPersonOverlay "What overlay if anything will be used on player pawns when worn";

var() config localized   String  Description;
var() config localized   String  FriendlyName;
var() config localized   Material GUIImage;

function QualifyProtectedRegion()
{
    assertWithDescription(ProtectedRegion > REGION_None,
        "[tcohen] The ProtectiveEquipment class "$class.name
        $" does not specify a ProtectedRegion.  Please fix this in UnrealEd.");

    assertWithDescription(ProtectedRegion < REGION_Body_Max,
        "[tcohen] The ProtectiveEquipment class "$class.name
        $" specifies ProtectedRegion="$GetEnum(ESkeletalRegion, ProtectedRegion)
        $".  ProtectiveEquipment may only protect body regions.");
}

//Equipment implementation
function OnGivenToOwner()
{
    local Pawn PawnOwner;

    PawnOwner = Pawn(Owner);
    assert(PawnOwner != None && PawnOwner.IsA('ICanUseProtectiveEquipment'));

    if (AttachmentBone != '')
        PawnOwner.AttachToBone(self, AttachmentBone);

    QualifyProtectedRegion();

    PawnOwner.SetProtection(ProtectedRegion, self);

    if (WearerMesh != None && WearerMesh != PawnOwner.Mesh)
        PawnOwner.SwitchToMesh(WearerMesh);
}

static function String GetDescription()
{
    return default.Description;
}

static function String GetFriendlyName()
{
    return default.FriendlyName;
}

static function Material GetGUIImage()
{
    return default.GUIImage;
}

static function class<Actor> GetRenderableActorClass()
{
    return default.Class;
}

defaultproperties
{
    StaticMesh=StaticMesh'SwatGear_sm.Placeholder'
    DrawType=DT_StaticMesh

	bStatic=False
    bNoDelete=False

    bBlockActors=false
    bBlockPlayers=false
}
