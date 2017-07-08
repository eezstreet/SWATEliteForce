class MPSpawner extends Spawner
    placeable;

defaultproperties
{
    ArchetypeClass=class'MPArchetype'
    ProfileArrayIndex=0

    DrawType=DT_Sprite
    Texture=Texture'EditorSprites.Spawner_Inanimate'

	SpawnerSprites[0]=Texture'EditorSprites.Spawner_Inanimate'
	SpawnerSprites[1]=Texture'EditorSprites.Spawner_Inanimate_Slave'
	SpawnerSprites[2]=Texture'EditorSprites.Spawner_Inanimate_SlaveOnly'
	SpawnerSprites[3]=Texture'EditorSprites.Spawner_Inanimate_Custom'
}
