class InanimateSpawner extends Spawner
    placeable;

//Spawner override
function ValidateSpawningFromLocalProperties(bool bTesting)
{
    //InanimateSpawners can always spawn from local properties, even in custom scenarios
}

defaultproperties
{
    ArchetypeClass=class'InanimateArchetype'
    ProfileArrayIndex=2

    DrawType=DT_Sprite
    Texture=Texture'EditorSprites.Spawner_Inanimate'

	SpawnerSprites[0]=Texture'EditorSprites.Spawner_Inanimate'
	SpawnerSprites[1]=Texture'EditorSprites.Spawner_Inanimate_Slave'
	SpawnerSprites[2]=Texture'EditorSprites.Spawner_Inanimate_SlaveOnly'
	SpawnerSprites[3]=Texture'EditorSprites.Spawner_Inanimate_Custom'
}
