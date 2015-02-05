class MaterialTrigger extends Triggers;

var() array<Material> MaterialsToTrigger;

function PostBeginPlay()
{
	local int i;
	for( i=0;i<MaterialsToTrigger.Length;i++ )
	{
		if( MaterialsToTrigger[i] != None )
			MaterialsToTrigger[i].Reset();
	}
}

function Trigger( Actor Other, Pawn EventInstigator )
{
	local int i;

	if( Other == None )
		Other = Self;
		
	for( i=0;i<MaterialsToTrigger.Length;i++ )
	{
		if( MaterialsToTrigger[i] != None )
			MaterialsToTrigger[i].Trigger( Other, EventInstigator );
	}
}

defaultproperties
{
	Texture=Texture'Engine_res.S_MaterialTrigger'
	bCollideActors=False
}