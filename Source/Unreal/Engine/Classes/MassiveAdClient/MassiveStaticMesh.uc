class MassiveStaticMesh extends StaticMeshActor
	native;

#if IG_ADCLIENT_INTEGRATION // dbeswick: Massive AdClient integration

var() protected string MassiveAdTargetName		"The Massive ad target name (Inventory Element Name). If this field is blank, the object's Label will be passed to the Massive server instead.";
var() int MassiveAdMaterialIndex				"The material at this index is overridden with the Massive ad data.";

var private Object MassiveTarget;
var bool bLogImpressionData;

simulated event string GetMassiveAdTargetName()
{
		return MassiveAdTargetName;
}

defaultproperties
{
	bStatic = false // static objects cannot update textures, static must be false.
	bNoDelete = true // must be true since bStatic is false, otherwise this will be deleted on clients.
	StaticMesh=StaticMesh'Editor_res.TexPropCube'

	bLogImpressionData = false
}

#endif