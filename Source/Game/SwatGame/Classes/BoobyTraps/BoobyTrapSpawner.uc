class BoobyTrapSpawner extends InanimateSpawner;

//import struct DoorAttachmentSpec from SwatDoor;
var() name DoorTag                      "The tag of the door this spawner corresponds to.";
var() name DoorAttachmentBone           "Information about how this booby trap attaches itself to the door if at all";
var() class<BoobyTrap> BoobyTrapClass   "The type of booby trap to spawn";

function actor SpawnArchetype(
        name ArchetypeName, 
        optional bool bTesting, 
        optional CustomScenario CustomScenario)
{
    local Spawner Slave;

    //we don't expect any Spawner to ever spawn more than once (unless we're testing)
    assert(!HasSpawned || bTesting || ArchetypeName == 'TestSpawn');

    //tell the level that we're used-up
    //  (need to do this before we might return!)
    assert(Level.SpawningManager != None);
    if (ArchetypeName != 'TestSpawn')
        Level.SpawningManager.SpawnerAllocated(self);

    if (!bTesting)
    {
        HasSpawned = true;
        SpawnedFromRoster = IsSpawningFromRosters();

        Spawned = Spawn(BoobyTrapClass);
        log("BoobyTrapSpawner: Spawned boobytrap: "$Spawned);

        AssertWithDescription(Spawned != None,
                "[tcohen] "$name$" tried to spawn an instance of class "$BoobyTrapClass$", but couldn't.");

        // Note: even though we're not using an archetype in this case, IUseArchetype already has an InitializeFromSpawner() interface function
        IUseArchetype(Spawned).InitializeFromSpawner(Self);
    }
    else
        //TMC NOTE when testing, we return the *spawner* as spawned!
        //  (this is to distinguish between would spawn something or would spawn Nothing)
        Spawned = self;

    //slave spawners are regular spawners in Custom Scenarios
    if (SwatGameInfo(Level.Game).GetCustomScenario() == None)
    {
        //look for slave spawners - they are spawners with tag equal to my event,
        //  and with SpawnMode equal Slave or SlaveOnly
        if (Event != '')
        {
            foreach AllActors(class'Spawner', Slave, Event)
            {
                if ((Slave.SpawnMode == SpawnMode_Slave || Slave.SpawnMode == SpawnMode_SlaveOnly)
                        && (!Slave.HasSpawned || bTesting))
                {
                    AssertWithDescription(Slave != self,
                            "[tcohen] "$name$" seems to be its own slave.  That's not good.  (Does its Tag & Event match?)");

                    log("[SPAWNER]  "$name$" (Tag="$tag$") is telling its Slave "$Slave.name$" (Tag="$Slave.tag$") to spawn from local properties");
                    Slave.SpawnFromLocalProperties(bTesting);
                }
            }
        }
    }

    return Spawned;
}

defaultproperties
{
    ArchetypeClass=class'BoobyTrapArchetype'
}
