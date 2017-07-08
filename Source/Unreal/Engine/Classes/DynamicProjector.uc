class DynamicProjector extends Projector;

function Tick(float DeltaTime)
{
	DetachProjector();
	AttachProjector();
}

defaultproperties
{
	bStatic=False
	bDynamicAttach=True
}