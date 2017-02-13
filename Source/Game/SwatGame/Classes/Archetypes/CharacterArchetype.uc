class CharacterArchetype extends Archetype;

struct EquipmentChancePair
{
    var config string Equipment;
    var config int Chance;
};

var config Mesh Mesh;

var config name			   CharacterType;
var config name			   VoiceTypeOverride;

//for Mesh!=Mesh'SwatMaleAnimation.SwatOfficer'
var config array<Material> FleshMaterial;
var config array<Material> ClothesMaterial;
//for Mesh==Mesh'SwatMaleAnimation.SwatOfficer'
var config array<Material> FaceMaterial;
var config array<Material> VestMaterial;
var config array<Material> NameMaterial;
var config array<Material> PantsMaterial;

var config Range Morale;

var config array<EquipmentChancePair> Equipment1;
var config array<EquipmentChancePair> Equipment2;
var config array<EquipmentChancePair> Equipment3;
var config array<EquipmentChancePair> Equipment4;

var array< class<Equipment> >           Equipment1Class;
var array< class<Equipment> >           Equipment2Class;
var array< class<Equipment> >           Equipment3Class;
var array< class<Equipment> >           Equipment4Class;

var config float AggressiveChance;

var config float TaserDeathChance;	// Chance that any hit with a taser may cause cardiac arrest in this archetype (will probably not actually kill?)
var config float PepperDeathChance;	// Chance that any hit with pepper spray may cause respiratory failure in this archetype (will probably not actually kill?)

var config bool Fearless;   // Won't scream if in a room with a suspect
var config bool Polite;     // Won't threaten hostages
var config bool Insane;     // Will shoot hostages like their life depends on it
var config bool Wanders;    // Doesn't patrol; instead it wanders

var Mesh OfficerMesh;

//initialize this archetype
function Initialize(Actor inOwner)
{
    InitializeEquipment(Equipment1, Equipment1Class, "1");
    InitializeEquipment(Equipment2, Equipment2Class, "2");
    InitializeEquipment(Equipment3, Equipment3Class, "3");
    InitializeEquipment(Equipment4, Equipment4Class, "4");

    Super.Initialize(inOwner);
}

//initialize the equipment mentioned in this archetype
final private function InitializeEquipment(
    array<EquipmentChancePair> Equipment,
    out array< class<Actor> > EquipmentClasses,
    string Index)
{
    local int i;

    for (i=0; i<Equipment.length; ++i)
    {
        if (Equipment[i].Equipment != "")
        {
            EquipmentClasses[i] =
                class<Actor>(DynamicLoadObject(Equipment[i].Equipment, class'Class'));

            AssertWithDescription(EquipmentClasses[i] != None,
                "[tcohen] While initializing the character part of the "$class.name
                $" instance named "$name
                $", the class for Equipment"$Index $" option #"$i
                $" ("$Equipment[i].Equipment$")"
                $" couldn't be loaded.");
        }
        else
            EquipmentClasses[i] = None;
    }
}

//check that the data provided for this archetype is valid
protected function Validate()
{
    local int i;

    Super.Validate();

    ValidateCondition(Mesh != None, "Mesh resolves to None");

    if (Mesh == OfficerMesh)
    {
        ValidateCondition(FaceMaterial.length > 0, "it is Missing a FaceMaterial");
        for (i=0; i<FaceMaterial.length; ++i)
            ValidateCondition(FaceMaterial[i] != None, "FaceMaterial number "$i+1$" resolves to None");

        ValidateCondition(VestMaterial.length > 0, "it is Missing a VestMaterial");
        for (i=0; i<VestMaterial.length; ++i)
            ValidateCondition(VestMaterial[i] != None, "VestMaterial number "$i+1$" resolves to None");

        ValidateCondition(NameMaterial.length > 0, "it is Missing a NameMaterial");
        for (i=0; i<NameMaterial.length; ++i)
            ValidateCondition(NameMaterial[i] != None, "NameMaterial number "$i+1$" resolves to None");

        ValidateCondition(PantsMaterial.length > 0, "it is Missing a PantsMaterial");
        for (i=0; i<PantsMaterial.length; ++i)
            ValidateCondition(PantsMaterial[i] != None, "PantsMaterial number "$i+1$" resolves to None");

        //shouldn't specify non-SwatOfficer materials for SwatOfficer Mesh
        ValidateCondition(FleshMaterial.length == 0,
            "it uses the SwatOfficer mesh but it specifies a FleshMaterial");
        ValidateCondition(ClothesMaterial.length == 0,
            "it uses the SwatOfficer mesh but it specifies a ClothesMaterial");
    }
    else
    {
        ValidateCondition(FleshMaterial.length > 0, "it is Missing a FleshMaterial");
        for (i=0; i<FleshMaterial.length; ++i)
            ValidateCondition(FleshMaterial[i] != None, "FleshMaterial number "$i+1$" resolves to None");

        ValidateCondition(ClothesMaterial.length > 0, "it is Missing a ClothesMaterial");
        for (i=0; i<ClothesMaterial.length; ++i)
            ValidateCondition(ClothesMaterial[i] != None, "ClothesMaterial number "$i+1$" resolves to None");

        //shouldn't specify SwatOfficer materials unles using SwatOfficer Mesh
        ValidateCondition(FaceMaterial.length == 0,
            "it doesn't use the SwatOfficer mesh but it specifies a FaceMaterial");
        ValidateCondition(VestMaterial.length == 0,
            "it doesn't use the SwatOfficer mesh but it specifies a VestMaterial");
        ValidateCondition(NameMaterial.length == 0,
            "it doesn't use the SwatOfficer mesh but it specifies a NameMaterial");
        ValidateCondition(PantsMaterial.length == 0,
            "it doesn't use the SwatOfficer mesh but it specifies a PantsMaterial");
    }

    //validate equipment
    ValidateEquipment("Equipment1", Equipment1, Equipment1Class);
    ValidateEquipment("Equipment2", Equipment2, Equipment2Class);
    ValidateEquipment("Equipment3", Equipment3, Equipment3Class);
    ValidateEquipment("Equipment4", Equipment4, Equipment4Class);
}

//check that the equipment data provided for this archetype is valid
function ValidateEquipment(
    string WhichOne,
    array<EquipmentChancePair> Equipment,
    array< class<Actor> > EquipmentClasses)
{
    local int i;

    for (i=0; i<EquipmentClasses.length; ++i)
    {
        ValidateCondition(Equipment[i].Equipment=="" || EquipmentClasses[i] != None,
            WhichOne$" (choice #"$i$") resolves to None");
        ValidateCondition(EquipmentClasses[i] == None || ClassIsChildOf(EquipmentClasses[i], class'Equipment'),
            WhichOne$" (choice #"$i$") resolves to a valid class, but not a kind of Equipment");
    }
}

//initialize an instance of this archetype
function InitializeInstance(ArchetypeInstance inInstance)
{
    local CharacterArchetypeInstance Instance;

    Instance = CharacterArchetypeInstance(inInstance);

    Super.InitializeInstance(Instance);

    Instance.Mesh = Mesh;
    if (Mesh == OfficerMesh)
    {
        Instance.FaceMaterial = FaceMaterial[Rand(FaceMaterial.length)];
        Instance.VestMaterial = VestMaterial[Rand(VestMaterial.length)];
        Instance.NameMaterial = NameMaterial[Rand(NameMaterial.length)];
        Instance.PantsMaterial = PantsMaterial[Rand(PantsMaterial.length)];
    }
    else
    {
        Instance.FleshMaterial = FleshMaterial[Rand(FleshMaterial.length)];
        Instance.ClothesMaterial = ClothesMaterial[Rand(ClothesMaterial.length)];
    }
    Instance.Morale = RandRange(Morale.Min, Morale.Max);
    Instance.Equipment[3] = None;   //grow the instance's Equipment array to at least 4 large

    Instance.SelectedEquipment1Class = InitializeInstanceEquipment(Instance.Equipment[0], Equipment1, Equipment1Class, Instance);
    Instance.SelectedEquipment2Class = InitializeInstanceEquipment(Instance.Equipment[1], Equipment2, Equipment2Class, Instance);
    Instance.SelectedEquipment3Class = InitializeInstanceEquipment(Instance.Equipment[2], Equipment3, Equipment3Class, Instance);
    Instance.SelectedEquipment4Class = InitializeInstanceEquipment(Instance.Equipment[3], Equipment4, Equipment4Class, Instance);

	Instance.VoiceTypeOverride = VoiceTypeOverride;
	Instance.CharacterType     = CharacterType;
	Instance.IsAggressive	   = (FRand() < AggressiveChance);

	Instance.TaserKillsMe = (FRand() < TaserDeathChance);
	Instance.PepperKillsMe = (FRand() < PepperDeathChance);
  Instance.Fearless = Fearless;
  Instance.Polite = Polite;
  Instance.Insane = Insane;
  Instance.Wandering = Wanders;

    Instance.UpdateInstancePrecachables();

    //TMC TODO select values from CharacterArchetype
}

//select specific equipment from the random distribution of equipment specified for this archetype
final private function class<Equipment> InitializeInstanceEquipment(
    out Equipment Equipment,
    array<EquipmentChancePair> Options,
    array< class<Equipment> > OptionClasses,
    CharacterArchetypeInstance Instance)
{
    local int TotalChance;
    local int RandChance;
    local int AccumulatedChance;
    local class<Equipment> Chosen;
    local int i;

    if (Options.length == 0)
        return None;

    //calculate the sum of chances of the options
    for (i=0; i<Options.length; ++i)
        TotalChance += Options[i].Chance;

    RandChance = Rand(TotalChance);

    //find the chosen option
    for (i=0; i<Options.length; ++i)
    {
        AccumulatedChance += Options[i].Chance;

        if (AccumulatedChance >= RandChance)
        {
            //we found our chosen Equipment
            Chosen = OptionClasses[i];

            //spawn and initialize it
            if (Chosen != None)
            {
                Equipment = Owner.Spawn(Chosen, Instance.Owner);   //the equipment's owner = archetype instance's Owner = the character that was spawned
                Equipment.OnGivenToOwner();
            }

            return Chosen;
        }
    }

    assert(false);  //we should have chosen something (even if it was a 'None')
}

defaultproperties
{
	OfficerMesh=Mesh'SWATMaleAnimation2.SwatOfficer'

	// There's only really a small handful of archetypes that can cause issues here. Probably best we leave this at zero.
	TaserDeathChance = 0.0;
	PepperDeathChance = 0.0;
  Fearless = false;
  Polite = false;
  Insane = false;
}
