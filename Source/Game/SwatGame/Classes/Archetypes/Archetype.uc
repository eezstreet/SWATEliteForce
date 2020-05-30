class Archetype extends Core.Object
    perobjectconfig
    native
    abstract;

var config localized string Description;    //only Archetypes used in Custom Scenarios need to provide a Description

var class<ArchetypeInstance> InstanceClass;

var private string ValidationErrors;    //this string may be populated with errors when subclasses are Validate()d by calling ValidationError()

var protected Actor Owner;

enum EArchetypeCategory
{
    Archetype_Enemy,
    Archetype_Hostage,
    Archetype_Inanimate
};

struct native ChanceArchetypePair
{
    var() int Chance;
    var() name Archetype;
};

function Initialize(Actor inOwner)
{
    Owner = inOwner;
    ValidateArchetype();
}
final function ValidateArchetype()
{
    ValidationErrors = "";
    Validate();
    AssertWithDescription(ValidationErrors=="",
        "[tcohen] The "$Class.name$" named '"$name$"' is invalid because "$ValidationErrors);
}
protected function Validate();    //implement in subclasses, and call Super.Validate()
final protected function ValidateCondition(bool Condition, string ErrorMessage)
{
    if (!Condition) ValidationError(ErrorMessage);
}
final protected function ValidationError(string ErrorMessage)
{
    if (ValidationErrors != "")
        ValidationErrors = ValidationErrors $ " AND ";
    ValidationErrors = ValidationErrors $ ErrorMessage;
}

//selects and returns an Actor subclass, presumably
//  to be spawned by a Spawner.
//PURE VIRTUAL: concrete Archetype subclasses must implement.
function class<Actor> PickClass()
{
    assert(false);
    return None;
}

private final function ArchetypeInstance NewInstance(IUseArchetype Spawned, 
    optional CustomScenario CustomScenario, 
    optional int CustomScenarioAdvancedRosterIndex,
    optional int CustomScenarioAdvancedArchetypeIndex)
{
    local ArchetypeInstance Instance;

    Instance = new() InstanceClass;
    assert(Instance != None);
    Instance.Owner = Actor(Spawned);
    assert(Instance.Owner != None);

    InitializeInstance(Instance, CustomScenario, CustomScenarioAdvancedRosterIndex, CustomScenarioAdvancedArchetypeIndex);

    return Instance;
}
function InitializeInstance(ArchetypeInstance Instance, optional CustomScenario CustomScenario, optional int CustomScenarioAdvancedRosterIndex, optional int CustomScenarioAdvancedArchetypeIndex);

static function name PickArchetype(array<ChanceArchetypePair> Archetypes)
{
    local int TotalChance;
    local int RandChance;
    local int AccumulatedChance;
    local ChanceArchetypePair Picked;
    local int i;
    
    if (Archetypes.length == 0)
    {
        log("[ARCHETYPE] .. (no Archetypes specified)");
        return '';
    }
    
    //calculate the sum of chances of the Archetypes
    for (i=0; i<Archetypes.length; ++i)
        TotalChance += Archetypes[i].Chance;

    RandChance = Rand(TotalChance);

    //find the selected Archetype
    for (i=0; i<Archetypes.length; ++i)
    {
        AccumulatedChance += Archetypes[i].Chance;
        
        if (AccumulatedChance >= RandChance)
        {
            Picked = Archetypes[i];

            log("[ARCHETYPE] .. picked "$Picked.Archetype$" (Chance="$Picked.Chance$" out of "$TotalChance$" total)");

            //we found our archetype
            return Picked.Archetype;
        }
    }

    assert(false);  //we should have chosen something to spawn
}

function InitializeSpawned(IUseArchetype Spawned, Spawner Spawner, 
    optional CustomScenario CustomScenario, 
    optional int CustomScenarioAdvancedRosterIndex,
    optional int CustomScenarioAdvancedArchetypeIndex)
{
    local ArchetypeInstance Instance;

    Instance = NewInstance(Spawned, CustomScenario, CustomScenarioAdvancedRosterIndex, CustomScenarioAdvancedArchetypeIndex);
    assert(Instance != None);

    // NOTE: do not change this order, we depend on the Archetype initializing the 
    // Spawned first, and then we initialize using the Spawner.  thanks.  [crombie]
    Spawned.Internal_InitializeFromArchetypeInstance(Instance);
    Spawned.InitializeFromSpawner(Spawner);
}
