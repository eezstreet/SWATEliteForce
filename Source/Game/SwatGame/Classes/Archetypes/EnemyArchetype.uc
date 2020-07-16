class EnemyArchetype extends CharacterArchetype
    perobjectconfig
    dependson(SwatEnemy)
    config(EnemyArchetypes);

//EnemyArchetype data

struct EnemySkillChancePair
{
    var config ISwatEnemy.EnemySkill Skill;
    var config int Chance;
};
var config array<EnemySkillChancePair> Skill;

struct WeaponClipcountChanceSet
{
    var config string Weapon;
//    var config int ClipCount; //TMC 3/21/2004 this is never used
    var config int Chance;
};
var config array<WeaponClipcountChanceSet> PrimaryWeapon;
var config array<WeaponClipcountChanceSet> BackupWeapon;

var array< class<FiredWeapon> > PrimaryWeaponClass;
var array< class<FiredWeapon> > BackupWeaponClass;

var config class<Actor> ActorClass;

var config float InvestigateChance; // First roll: Investigate a disturbing sound
var config float BarricadeChance; // Second roll: Barricade when hearing a disturbing sound. If this roll fails, the AI does nothing

function Initialize(Actor inOwner)
{
	local CustomScenario CustomScenario;

    CustomScenario = SwatGameInfo(inOwner.Level.Game).GetCustomScenario();

    if (CustomScenario != None)
    {
        CustomScenario.MutateEnemyWeapons(PrimaryWeapon, CustomScenario.EnemyPrimaryWeaponOptions);
        CustomScenario.MutateEnemyWeapons(BackupWeapon, CustomScenario.EnemyBackupWeaponOptions);
    }

    InitializeEquipment(PrimaryWeapon, PrimaryWeaponClass, "Primary");
    InitializeEquipment(BackupWeapon, BackupWeaponClass, "Backup");

    Super.Initialize(inOwner);
}

//initialize the equipment mentioned in this archetype
final private function InitializeEquipment(
    array<WeaponClipcountChanceSet> Weapons,
    out array< class<FiredWeapon> > WeaponClasses,
    string Which)
{
    local int i;

    for (i=0; i<Weapons.length; ++i)
    {
        if (Weapons[i].Weapon != "")
        {
            WeaponClasses[i] =
                class<FiredWeapon>(DynamicLoadObject(Weapons[i].Weapon, class'Class'));

            AssertWithDescription(WeaponClasses[i] != None,
                "[tcohen] While initializing the enemy part of the "$class.name
                $" instance named "$name
                $", the class for "$Which$"Weapon option #"$i
                $" ("$Weapons[i].Weapon$")"
                $" couldn't be loaded.");
        }
        else
            WeaponClasses[i] = None;
    }
}


protected function Validate()
{
    local bool PrimaryWeaponCanBeNone;
    local bool BackupWeaponCanBeNone;
    local int i;

    Super.Validate();

    ValidateCondition(Skill.length>0,
        "AI's Skill is not set (Crombie says: Designers should set the skill for this archetype as soon as possible, or they will all be amateur criminals)");

    //enemies must always start with some weapon
    if (PrimaryWeapon.length == 0)
        PrimaryWeaponCanBeNone = true;
    else
        for (i=0; i<PrimaryWeaponClass.length; ++i)
            if (PrimaryWeaponClass[i] == None)
                PrimaryWeaponCanBeNone = true;
    if (BackupWeapon.length == 0)
        BackupWeaponCanBeNone = true;
    else
        for (i=0; i<BackupWeaponClass.length; ++i)
            if (BackupWeaponClass[i] == None)
                BackupWeaponCanBeNone = true;

    //TMC 8/10/2004 we now permit enemies with no weapons for QMM variety
//    ValidateCondition(!(PrimaryWeaponCanBeNone && BackupWeaponCanBeNone),
//        "The Enemy could have no weapon.");
}

function InitializeInstance(ArchetypeInstance inInstance, 
    optional CustomScenario CustomScenario, 
    optional int CustomScenarioAdvancedRosterIndex,
    optional int CustomScenarioAdvancedArchetypeIndex)
{
    local EnemyArchetypeInstance Instance;

    Instance = EnemyArchetypeInstance(inInstance);

    Super.InitializeInstance(Instance);

    // initialize the skill value
    InitializeSkill(Instance);

	Instance.InvestigateChance = InvestigateChance;
	Instance.BarricadeChance = BarricadeChance;

    //initialize weapons
    InitializeWeapon(PrimaryWeapon, PrimaryWeaponClass, Instance.SelectedPrimaryWeaponClass, Instance);
    InitializeWeapon(BackupWeapon, BackupWeaponClass, Instance.SelectedBackupWeaponClass, Instance);

    CustomScenario.MutateAdvancedEnemyArchetypeInstance(Instance, CustomScenarioAdvancedRosterIndex, CustomScenarioAdvancedArchetypeIndex);

    SpawnWeapon(Instance.SelectedPrimaryWeaponClass, Instance, Instance.PrimaryWeapon, Instance.SelectedPrimaryWeaponAmmoClass);
    SpawnWeapon(Instance.SelectedBackupWeaponClass, Instance, Instance.BackupWeapon, Instance.SelectedBackupWeaponAmmoClass);
}

private function InitializeSkill(EnemyArchetypeInstance inInstance)
{
    local int i, TotalChance, RandChance, AccumulatedChance;

    assert(Skill.length > 0);   //this should have already been caught by Validate() above

    //calculate the sum of chances of the options
    for (i=0; i<Skill.length; ++i)
        TotalChance += Skill[i].Chance;

    RandChance = Rand(TotalChance);

    //find the chosen option
    for (i=0; i<Skill.length; ++i)
    {
        AccumulatedChance += Skill[i].Chance;

        if (AccumulatedChance >= RandChance)
        {
            inInstance.Skill = Skill[i].Skill;
            break;
        }
    }
}

private function InitializeWeapon(
    array<WeaponClipcountChanceSet> Options,
    array< class<FiredWeapon> > OptionClasses,
    out class<FiredWeapon> theSelectedWeaponClass,
    EnemyArchetypeInstance Instance)
{
    local int i, TotalChance, RandChance, AccumulatedChance;
    local class<FiredWeapon> WeaponClass;

    //if there are no weapon options, then Weapon=None and we're done.
    if (Options.length == 0) return;

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
            WeaponClass = OptionClasses[i];
            break;
        }
    }

    // The ammo class stuff below has to happen after the call to
    // OnGivenToOwner() above, since that's where we decide what class of ammo
    // to give to the weapon.
    theSelectedWeaponClass = WeaponClass;
}

private function SpawnWeapon(class<FiredWeapon> WeaponClass, EnemyArchetypeInstance Instance, out FiredWeapon Weapon, out class<Ammunition> AmmoClass
    )
{
    if(WeaponClass != None)
    {
        Weapon = Owner.Spawn(WeaponClass, Instance.Owner);
        Weapon.OnGivenToOwner();
    }

    AmmoClass = Weapon.AmmoClass;
}

//implemented from base Archetype
function class<Actor> PickClass()
{
    log("[ARCHETYPE] .. Class SwatEnemy selected to spawn from Archetype "$name);

    return ActorClass;
}

defaultproperties
{
    InstanceClass=class'SwatGame.EnemyArchetypeInstance'

	CharacterType=EnemyMaleDefault

    ActorClass=class'SwatEnemy'

	FriendlyName="a Suspect"

	InvestigateChance=0.0000
	BarricadeChance=100.0000
}
