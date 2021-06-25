class Spawner extends Engine.SpawnerBase
    native
    abstract;

////////////////////////////////////////////////////////////////////
// NOTE: Dynamic class variables should be reset to their initial state
//    in ResetForMPQuickRestart()
////////////////////////////////////////////////////////////////////

var() protected name SpawnerGroup;

var() enum ESpawnMode
{
    SpawnMode_Normal,
    SpawnMode_Slave,
    SpawnMode_SlaveOnly
} SpawnMode;

var() enum EMissionSpawn
{
    MissionSpawn_Any,
    MissionSpawn_CustomOnly,
    MissionSpawn_CampaignOnly
} MissionSpawn  "If MissionSpawn_CustomOnly, then this Spawner will only be used in Custom Scenarios, and similarly, MissionSpawn_CampaignOnly means only for Campaign Missions.";

enum EStartPointDependent
{
    StartPoint_Any,
    StartPoint_OnlyPrimary,
    StartPoint_OnlySecondary
};
var() EStartPointDependent StartPointDependent "This Spawner will be ignored if StartPointDependent doesn't match the selected EntryPoint.  For example, if StartPointDependent is set to StartPoint_OnlySecondary, then the Spawner will be ignored unless the Secondary Start Point is used.";

var() editinline array<Archetype.ChanceArchetypePair> Archetypes;    //named for clarity in the Editor

var() int Priority;

var class<Archetype> ArchetypeClass;
var int ProfileArrayIndex;

var bool HasSpawned;                            //has this Spawner spawned anything
var protected actor Spawned;                    //what Actor (if any) did this Spawner spawn.  May be None if it was Destroy()ed.
var protected Archetype Archetype;
var protected bool SpawnedFromRoster;           //did this Spawner spawn from a roster, or from local properties.  Only meaningful if HasSpawned.
var protected array<Texture> SpawnerSprites;    // sprites used in the editor to set Texture based on spawner's properties

var() array<name> AntiSlaves "A list of *Labels* of Spawners that will NOT spawn if this Spawner DOES spawn.  This is like the inverse of a Slave Spawner.  Note that AntiSlaves should never be listed in the SpawningManager's list of Rosters before their Master (otherwise they could spawn first, which will assert).";

var SwatGameInfo Game;
var bool Disabled;

function PreBeginPlay()
{
	local int i;

    Super.PreBeginPlay();

    Game = SwatGameInfo(Level.Game);

	// useful debugging info, but terry thinks it'll confuse the designers more. [crombie]

	if ((Archetypes.Length > 0))
	{
		log("[SPAWNING] - Logging all possible *local* archetypes for " $ Name);

		for(i=0; i<Archetypes.Length; ++i)
		{
			log("           " $ Archetypes[i].Archetype $ " (Chance: " $ Archetypes[i].Chance $ ")");
		}
	}
}

function Archetype CreateArchetype(name ArchetypeName, CustomScenario CustomScenario)
{
    local Archetype SpawnedArchetype;

    SpawnedArchetype = new(None, string(ArchetypeName), 0) ArchetypeClass;
    SpawnedArchetype.Initialize(self);

    return SpawnedArchetype;
}

function actor SpawnArchetype(
        name ArchetypeName,
        optional bool bTesting,
        optional CustomScenario CustomScenario,
        optional int CustomRosterNumber,
        optional int CustomArchetypeNumber)
{
    local class<Actor> ClassToSpawn;
    local Spawner Slave;

    //we don't expect any Spawner to ever spawn more than once (unless we're testing)
    assert((!Disabled) || bTesting || ArchetypeName == 'TestSpawn');

    //tell the level that we're used-up
    //  (need to do this before we might return!)
    assert(Level.SpawningManager != None);
    if (ArchetypeName != 'TestSpawn')
        Level.SpawningManager.SpawnerAllocated(self);

    //the None Archetype always spawns nothing
    if (ArchetypeName == '')
        return None;

    Archetype = CreateArchetype(ArchetypeName, CustomScenario);

    if (CustomScenario != None)
        CustomScenario.MutateArchetype(Archetype);

    ClassToSpawn = Archetype.PickClass();

    if (!bTesting)
    {
        HasSpawned = true;
        SpawnedFromRoster = IsSpawningFromRosters();

        Spawned = Spawn(ClassToSpawn);
        AssertWithDescription(Spawned != None,
                "[tcohen] "$name$" tried to spawn an instance of class "$ClassToSpawn$", but couldn't.");
        if(Spawned == None)
        {
            return Spawned;
        }


            log("[SPAWNING] ... ... "$name
                    $" in SpawnerGroup "$SpawnerGroup
                    $" spawned "$Spawned
                    $" for Archetype "$ArchetypeName
                    $".");
            log("[SPAWNING] ... ... ... "$name
                    $".Location=("$Location
                    $"), "$Spawned.name
                    $".Location=("$Spawned.Location
                    $")");

        if (CustomScenario == None)
            DisableAntiSlaves();

            log("[SPAWNING] ... ... Spawner "$name$" (SpawnerGroup "$SpawnerGroup$") is calling Archetype "$Archetype.name$" to InitializeSpawned "$Spawned.name);

        Archetype.InitializeSpawned(IUseArchetype(Spawned), self, CustomScenario, CustomRosterNumber, CustomArchetypeNumber);
    }
    else
        //TMC NOTE when testing, we return the *spawner* as spawned!
        //  (this is to distinguish between would spawn something or would spawn Nothing)
        Spawned = self;

    //look for slave spawners - they are spawners with tag equal to my event,
    //  and with SpawnMode equal Slave or SlaveOnly
    if (Event != '')
    {
        foreach AllActors(class'Spawner', Slave, Event)
        {
            if  (
                    (Slave.SpawnMode == SpawnMode_Slave || Slave.SpawnMode == SpawnMode_SlaveOnly)  //its a Slave
                &&  (!Slave.HasSpawned || bTesting)                                                 //hasn't already spawned (or we're testing spawning)
                &&  (CustomScenario == None || Slave.IsA('InanimateSpawner'))                       //... only InanimateSpawners can be Slaves in CustomScenarios
                )
            {
                AssertWithDescription(Slave != self,
                        "[tcohen] "$name$" seems to be its own slave.  That's not good.  (Does its Tag & Event match?)");

                if (Slave.Disabled)
                {
                        log("[SPAWNER]  "$name
                                $" (Tag="$tag
                                $") would tell its Slave "$Slave.name
                                $" (Label="$Slave.label
                                $") to spawn from local properties, but "$Slave.name
                                $" is disabled, probably because it is an AntiSlave.");
                }
                else
                {
                        log("[SPAWNER]  "$name
                                $" (Tag="$tag
                                $") is telling its Slave "$Slave.name
                                $" (Tag="$Slave.tag
                                $") to spawn from local properties");
                    Slave.SpawnFromLocalProperties(bTesting);
                }
            }
        }
    }

    return Spawned;
}

function actor SpawnFromLocalProperties(optional bool bTesting)
{
    ValidateSpawningFromLocalProperties(bTesting);

    //we don't expect any Spawner to ever spawn more than once (unless we're testing)
    assert(!HasSpawned || bTesting);

        log("[SPAWNER]  "$name$" (Tag="$tag$") is picking an Archetype to spawn");

    return SpawnArchetype(class'Archetype'.static.PickArchetype(Archetypes), bTesting);
}

function ValidateSpawningFromLocalProperties(bool bTesting)
{
    assertWithDescription(bTesting || SwatGameInfo(Level.Game).GetCustomScenario() == None,
            "[tcohen] in Spawner::ValidateSpawningFromLocalProperties(), we seem to have a custom scenario.  (We don't expect to use local spawner properties in custom scenarios.)");
}

function name GetSpawnerGroup()
{
    return SpawnerGroup;
}

//If self spawned from a roster, then returns the name of the roster's spawner group.
//Otherwise, returns None.
function name SpawnedFromGroup()
{
   if (!HasSpawned) return '';        //hasn't spawned anything

   if (!SpawnedFromRoster) return ''; //didn't spawn from a roster

   return SpawnerGroup;
}

function DisableAntiSlaves()
{
    local int i;
    local Spawner AntiSlave;
    local bool Found;

    for (i=0; i<AntiSlaves.length; ++i)
    {
        //we won't use findStaticByLabel here, because we want to disable
        //  *all* spawners labeled AntiSlaves[i], not just the first one found
        Found = false;
        foreach AllActors(class'Spawner', AntiSlave)
        {
            if (AntiSlaves[i] == AntiSlave.label)
            {
                //if campaign objectives are in effect, then
                //  the AntiSlave should not have already spawned
                AssertWithDescription(!Level.Game.CampaignObjectivesAreInEffect() || !AntiSlave.HasSpawned,
                    "[tcohen] Spawner::DisableAntiSlaves() "$name
                    $" spawned, and found its AntiSlave labeled "$AntiSlaves[i]
                    $", but "$AntiSlave.name
                    $" has already spawned, so its too late to disable it.");
                AntiSlave.Disabled = true;

                    log("[SPAWNING] ... AntiSlave "$AntiSlave$" is now Disabled.");

                Found = true;

                //this AntiSlave is no longer available to spawn
                Level.SpawningManager.SpawnerAllocated(AntiSlave);
            }
        }
        //we should have found at least one (designers should ensure this)
        AssertWithDescription(Found,
            "[tcohen] Spawner::DisableAntiSlaves() "$name
            $" spawned, but could not locate its AntiSlave labeled "$AntiSlaves[i]
            $" to disable it.");
    }
}

function bool IsSpawningFromRosters()
{
    if (Level.SpawningManager == None)
        return false;

    return Level.SpawningManager.IsSpawningFromRosters();
}

////////////////////////////////////////////////////////////////////
// Reset the class variables to their initial state
////////////////////////////////////////////////////////////////////
function ResetForMPQuickRestart()
{
    HasSpawned = false;
    Spawned = None;
    Archetype = None;
    SpawnedFromRoster = false;
    Disabled = false;
}
////////////////////////////////////////////////////////////////////

defaultproperties
{
    bHidden=true
        bStatic=true
        bDirectional=true
}
