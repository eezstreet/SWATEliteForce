class PopupRWO extends ReactiveWorldObject;

import enum EHavokHingeType from Engine.HavokHingeConstraint;

var(Havok) name HingeConstraintLabel "The label of the HavokHingeConstraint for this RWO.  This HingeConstraint will have hkHingeType set to HKH_Normal before impulses are imparted.";
var HavokHingeConstraint HingeConstraint;

function PostBeginPlay()
{
    local HavokHingeConstraint Candidate;

    Super.PostBeginPlay();

    if (HingeConstraintLabel != '')
    {
        foreach AllActors(class'HavokHingeConstraint', Candidate)
        {
            if (Candidate.Label == HingeConstraintLabel)
                HingeConstraint = Candidate;
        }

        AssertWithDescription(HingeConstraint != None,
            "[tcohen] The HavokHingeConstraint labeled "$HingeConstraintLabel
            $" was not found for the ReactiveWorldObject of class "$class.name
            $" named "$name);
    }
}

simulated event TakeHitImpulse(vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    if (HingeConstraint != None)
    {
        HingeConstraint.hkMotorActive = false;
		HingeConstraint.UpdateConstraintDetails();
    }

    Super.TakeHitImpulse(HitLocation, Momentum, DamageType);
}

