class Equipment extends Actor
implements IHaveWeight
    config(SwatEquipment)
    abstract
    native;

//TMC note: no attach socket(s) here! That goes in subclasses.

// The following covers nearly all of the edge cases (IAmCuffed, pouches, ...)
simulated function float GetWeight() {
  return 0.0;
}

simulated function float GetBulk() {
  return 0.0;
}

function OnGivenToOwner();

defaultproperties
{
    RemoteRole=ROLE_None

    // Warning: subclasses (e.g., HandHeldEquipment) *might* change bOwnerNoSee dynamically changed every frame
    bOwnerNoSee=true

    // To speed up rendering, don't let pawn shadows be cast on equipment
    bAcceptsShadowProjectors=true

    // To speed up rendering, regular equipment doesn't accept projectors
    bAcceptsProjectors=true
}
