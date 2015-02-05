class RawMaterialFactory extends MaterialFactory;

var() Class<Engine.Material> MaterialClass;

function Engine.Material CreateMaterial( Core.Object InOuter, string InPackage, string InGroup, string InName )
{		
	if( MaterialClass == None )
		return None;

	return New(InOuter, InName, RF_Public+RF_Standalone) MaterialClass;
}

defaultproperties
{
	MaterialClass=class'Shader';
	Description="Raw Material"
}