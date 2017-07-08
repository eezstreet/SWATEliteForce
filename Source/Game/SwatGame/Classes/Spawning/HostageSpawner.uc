class HostageSpawner extends Spawner
	native
    placeable;

// the Patrol List for the Hostage, defined by the designer in UnrealEd and 
// passed to the Enemy at spawning
var() editinline nocopy PatrolList HostagePatrol;

// our overridden Idle Category
var() name IdleCategoryOverride; 

// whether we are incapacitated from the beginning
var() bool SpawnIncapacitated;

// the texture we use when we spawn an incapacitated hostage
var Texture IncapacitatedTexture;

defaultproperties
{
    ArchetypeClass=class'HostageArchetype'
    ProfileArrayIndex=1

    DrawType=DT_Sprite
    Texture=Texture'EditorSprites.Spawner_Hostage'

	IncapacitatedTexture=Texture'EditorSprites.EditorSprites.Spawner_Hostage_Incapacitated'

	SpawnerSprites[0]=Texture'EditorSprites.Spawner_Hostage'
	SpawnerSprites[1]=Texture'EditorSprites.Spawner_Hostage_Slave'
	SpawnerSprites[2]=Texture'EditorSprites.Spawner_Hostage_SlaveOnly'
	SpawnerSprites[3]=Texture'EditorSprites.Spawner_Hostage_Custom'
}
