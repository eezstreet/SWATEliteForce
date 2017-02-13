class CharacterArchetypeInstance extends ArchetypeInstance
    abstract;

var Mesh Mesh;
//for Mesh!=Mesh'SwatMaleAnimation.SwatOfficer'
var Material FleshMaterial;
var Material ClothesMaterial;
//for Mesh==Mesh'SwatMaleAnimation.SwatOfficer'
var Material FaceMaterial;
var Material VestMaterial;
var Material NameMaterial;
var Material PantsMaterial;
var float Morale;
var array<Equipment> Equipment;
var name CharacterType;
var name VoiceTypeOverride;
var bool IsAggressive;

var bool TaserKillsMe;	// Will a taser hit kill me?
var bool PepperKillsMe; // Will pepper spray kill me?
var bool Fearless;  // Will I scream if I'm in a room with a suspect?
var bool Polite;  // Will I forgo shooting hostages?
var bool Insane; // Will I kill basically everyone?
var bool Wandering; // Will I wander instead of patrol?

var class<Equipment> SelectedEquipment1Class;
var class<Equipment> SelectedEquipment2Class;
var class<Equipment> SelectedEquipment3Class;
var class<Equipment> SelectedEquipment4Class;

function DestroyEquipment()
{
    local int i;

    for (i=0; i<Equipment.length; ++i)
	{
		if (Equipment[i] != None)
		{
			Equipment[i].Destroy();
		}
	}
}

function UpdateInstancePrecachables()
{
    local SwatGameInfo SGI;

    if( !Owner.Level.IsCOOPServer )
        return;

    SGI = SwatGameInfo( Owner.Level.Game );
    Assert( SGI != None );

    SGI.AddMesh( Mesh );
    SGI.AddMaterial( FleshMaterial );
    SGI.AddMaterial( ClothesMaterial );
    SGI.AddMaterial( FaceMaterial );
    SGI.AddMaterial( VestMaterial );
    SGI.AddMaterial( NameMaterial );
    SGI.AddMaterial( PantsMaterial );
    SGI.AddStaticMesh( SelectedEquipment1Class.default.StaticMesh );
    SGI.AddStaticMesh( SelectedEquipment2Class.default.StaticMesh );
    SGI.AddStaticMesh( SelectedEquipment3Class.default.StaticMesh );
    SGI.AddStaticMesh( SelectedEquipment4Class.default.StaticMesh );

	if( IsFemale() )
	    SGI.SetLevelHasFemaleCharacters();
}

//basically ripped from SwatAICharacter.uc
function bool IsFemale()
{
    return (CharacterType != '') && ( SwatAIRepository(Owner.Level.AIRepo).IsAFemaleCharacterType( CharacterType ) );
}

function bool IsFearless()
{
  return Fearless;
}

function bool IsPolite()
{
  return Polite;
}

function bool IsInsane()
{
  return Insane;
}

function bool Wanders()
{
  return Wandering;
}
