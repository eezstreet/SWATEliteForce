//This is the base class for deployed tactical aids. 
//
//It is in RWOSupport to allow for native implementation of the 
//  PredictedBoxAdjustmentHook function

class DeployedTacticalAid extends RWOSupport.ReactiveStaticMesh
    native;

// default implementation; returns !bHidden
simulated native event bool IsDeployed();

cpptext
{
    // To ensure when deployed on a door the object is lit by lights
    // in neighboring zones (make the object bigger than it actually
    // is for lighting purposes) 
    void PredictedBoxAdjustmentHook(FBox& PredictedBox);
}

defaultproperties
{
    //should be initially hidden (not yet deployed)
    bHidden=true
    bAlwaysRelevant=true
    RemoteRole=ROLE_DumbProxy

    //previewed items shouldn't block traces
    bCollideActors=false

    bUseCylinderCollision=true
    bNoDelete=false
    bBlockHavok=false

    bStasis = true;
}
