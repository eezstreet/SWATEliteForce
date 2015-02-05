/////////////////////////////////////////////////////////////////////////////////////////////
// WieldableEvidenceEquipment
// Evidence that is held by AIs
/////////////////////////////////////////////////////////////////////////////////////////////
class WieldableEvidenceEquipment extends SimpleEquipment
	implements IEvidence;

var private bool Secured;
var private bool Destroyed;

simulated function Drop()
{
	if (!CanDrop())
		return;

	UnEquip();
	bHidden = false;
	SetRotation(Rot(0,0,0));
	SetPhysics(PHYS_Falling);
	bCollideWorld=true;
	SetCollision(true,true,true);
}

simulated function OnGivenToOwner()
{
    local SwatEnemy PawnOwner;

    PawnOwner = SwatEnemy(Owner);

	Super.OnGivenToOwner();

	if (PawnOwner != None)
		PawnOwner.HeldEvidence = self;
}

simulated function bool CanDrop()
{
	return !Secured && !Destroyed;
}

// IEvidence implementation

simulated function bool CanBeUsedNow()
{
    return !Secured && !Destroyed && !bHidden && Pawn(Base) == None;
}

simulated function OnUsed(Pawn SecurerPawn)
{
    ReactToUsed(SecurerPawn);

    SwatGameInfo(Level.Game).GameEvents.EvidenceSecured.Triggered(self);
}

simulated function PostUsed()
{
    Secured = true;
	Hide();
}

simulated function String UniqueID()
{
    return Owner.UniqueID() $ "_Evidence";
}

simulated function DestroyEvidence()
{
	if (!Destroyed)
		SwatGameInfo(Level.Game).GameEvents.EvidenceDestroyed.Triggered(self);

	Destroyed = true;
	Hide();
}

defaultproperties
{
    AutoEquip=true
    StaticMesh=StaticMesh'SwatGear2_sm.drug_bag'
	DrawType=DT_StaticMesh
	AttachmentBone=MiscGrip
	CollisionRadius=20
	CollisionHeight=5
}
