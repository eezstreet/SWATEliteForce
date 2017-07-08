//=============================================================================
// The light class.
//=============================================================================
class DynamicLight extends Engine.Light placeable 
    native;

defaultproperties
{
    RemoteRole=ROLE_None
     bStatic=False
     bDynamicLight=True
     bMovable=True
     bStasis=True
//#if IG_ZONECONSTRAINED_LIGHTS 
    bOnlyAffectCurrentZone=true
//#endif

     // placed lights should always be important by default
     bImportantDynamicLight=true
}

