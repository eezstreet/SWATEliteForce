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

var bool GasAffectsMe; // Can CS Gas affect me?

var bool DOAConversion; // Whether to convert to DOA some time after being incapacitated
var bool StaticDOAConversion; // For units that are incapacitated at the start: how long to wait before becoming a DOA
var float DOAConversionTime; // The amount of time it will take to convert to a DOA
var float StaticDOAConversionTime; // The amount of time it will take to convert to a static DOA

var bool UseEmpathyModifier;
var float EmpathyPepperSprayAmount;
var float EmpathyTaserAmount;
var float EmpathyShotAmount;
var float EmpathyPepperBallAmount;
var float EmpathyStungAmount;	// applies to all blunt damage

var class<Equipment> SelectedEquipment1Class;
var class<Equipment> SelectedEquipment2Class;
var class<Equipment> SelectedEquipment3Class;
var class<Equipment> SelectedEquipment4Class;

var string FriendlyName;

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

function bool TaserMightKillMe()
{
  // Only determines if the taser MAY kill this character, not if this instance DOES kill it.
  local CharacterArchetype CharacterArchetype;

  CharacterArchetype = CharacterArchetype(Archetype);
  if (CharacterArchetype == None)
  {
    return false;
  }
  return CharacterArchetype.TaserDeathChance > 0.001f; // FIXME: Epsilon...?
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

function bool ConvertsToDOA()
{
  return DOAConversion;
}

function bool ConvertsToDOA_Static()
{
  return StaticDOAConversion;
}

function float GetDOAConversionTime()
{
  return DOAConversionTime;
}

function float GetDOAConversionTime_Static()
{
  return StaticDOAConversionTime;
}

function bool EmpathyModifierEnabled()
{
	return UseEmpathyModifier;
}

function float GetEmpathyPepperSprayAmount()
{
	return EmpathyPepperSprayAmount;
}

function float GetEmpathyTaserAmount()
{
	return EmpathyTaserAmount;
}

function float GetEmpathyShotAmount()
{
	return EmpathyShotAmount;
}

function float GetEmpathyPepperBallAmount()
{
	return EmpathyPepperBallAmount;
}

function float GetEmpathyStungAmount()
{
	return EmpathyStungAmount;
}
