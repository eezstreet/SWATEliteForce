//=============================================================================
// SwatCheatManager:
//
// Swat-specific cheats for single-player mode only; see Engine.CheatManager
// for more details
//=============================================================================

class SwatCheatManager extends Engine.CheatManager within SwatPlayerController
      dependson(SwatStartPointBase)
      native;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum EEntryType from SwatStartPointBase;

var private bool bUserHidAIs;
var private bool bDebugGrenades;

// Prints a list of all available SwatCheatManager exec functions
exec function Help()
{
	ConsoleMessage("--------------------------------------------------------------------");
	ConsoleMessage("              SwatCheatManager available functions");
	ConsoleMessage("--------------------------------------------------------------------");
	ConsoleMessage("");
	ConsoleMessage("---------- QA stuff ----------");
	ConsoleMessage("");
	ConsoleMessage("Loc: Print player location/rotation to the log file"); // in SwatGamePlayerController.uc
	ConsoleMessage("OpenDoorsToLeft: Opens all doors in the level to the left");
	ConsoleMessage("OpenDoorsToRight: Opens all doors in the level to the right");
	ConsoleMessage("");
	ConsoleMessage("---------- HUD/GUI stuff ----------");
	ConsoleMessage("");
	ConsoleMessage("ToggleGUI: Turn GUI/HUD rendering on/off"); // in SwatHUD.uc
	ConsoleMessage("ShowHands or HandsDown: Turn First-person hands & weapon rendering on/off"); // in SwatGamePlayerController.uc
	ConsoleMessage("ToggleWatermark: Turn screenshot watermark (version, %%complete, etc) on/off"); // in SwatCheatManager.cpp
	ConsoleMessage("");
	ConsoleMessage("---------- AI stuff ----------");
	ConsoleMessage("");
	ConsoleMessage("HideAI: Hides all AIs");
	ConsoleMessage("ShowAI: Shows hidden AIs");
	ConsoleMessage("DebugAIs: Turn on/off AI debug info");
	ConsoleMessage("DebugTyrion: Turn on/off all Tyrion debug info");
	ConsoleMessage("DebugTyrionCharacter: Turn on/off Tyrion Character debug info");
	ConsoleMessage("DebugTyrionMovement: Turn on/off Tyrion Movement debug info");
	ConsoleMessage("DebugTyrionWeapon: Turn on/off Tyrion Weapon debug info");
	ConsoleMessage("DisableVision <optional: AI Class (ie. SwatEnemy)>: Disables AI vision");
	ConsoleMessage("EnableVision <optional: AI Class (ie. SwatEnemy)>: Enables vision for AIs whose vision has been disabled");
	ConsoleMessage("DisableHearing <optional: AI Class (ie. SwatEnemy)>: Disables AI hearing");
	ConsoleMessage("EnableHearing <optional: AI Class (ie. SwatEnemy)>: Enables hearing for AIs whose hearing has been disabled");
	ConsoleMessage("ToggleAIHiddenState: Toggle between ShowAI/HideAI");
	ConsoleMessage("DebugMorale: Turn on/off morale debugging info");
	ConsoleMessage("EveryoneComply: Asks all enemy/hostage AIs to comply");
	ConsoleMessage("DisableAwareness <optional: AI Class (ie. SwatEnemy)>: Disables the awareness system of AIs");
	ConsoleMessage("EnableAwareness <optional: AI Class (ie. SwatEnemy)>: Enables the awareness system of AIs whose awareness has been disabled");
	ConsoleMessage("DisableCollisionAvoidance <optional: AI Class (ie. SwatEnemy)>: Disables collision avoidance");
	ConsoleMessage("EnableCollisionAvoidance <optional: AI Class (ie. SwatEnemy)>: Enables collision avoidance");
	ConsoleMessage("MakeAIGod <optional: AI Class (ie. SwatEnemy)>: Makes particular types unhurtable (defaults to all AIs)");
	ConsoleMessage("");
	ConsoleMessage("---------- Cover stuff ----------");
	ConsoleMessage("");
	ConsoleMessage("DebugCover <name of pawn taking cover>: Shows 'true' cover area for specified pawn (i.e., intersection of per-officer cover extrusions)");
	ConsoleMessage("DebugCover2 <name of pawn taking cover>: 'DebugCover' functionality PLUS per-officer cover extrusions for cover plane");
	ConsoleMessage("DebugCover3 <name of pawn taking cover>: 'DebugCover2' functionality PLUS extrusion from each officer to the cover plane");
	ConsoleMessage("");
	ConsoleMessage("---------- Weapon stuff ----------");
	ConsoleMessage("");
    ConsoleMessage("DebugBallistics: Toggles debugging ballistics on and off.  When on, ballistics information will be logged for each shot fired.");
    ConsoleMessage("UseAmmo <Ammo class>: Use the specified ammunition class with your current weapon, Eg. 'useammo fullmetaljacket'");
    ConsoleMessage("ToggleRecoil: Turns recoil on and off");
    ConsoleMessage("FlashlightLines <0 or 1>: Turns debug flashlight lines on and off");
    ConsoleMessage("FlashlightFancy <0 or 1>: Selects Flashlight spot lights (true) or point lights (false)");
    ConsoleMessage("DebugGrenades: Toggles debugging of grenades on and off.  When on, trajectories and radii of affect are drawn.");
	ConsoleMessage("");
	ConsoleMessage("---------- Weapon ScreenEffect stuff ----------");
	ConsoleMessage("");
    ConsoleMessage("GetSprayed:   Runs camera effect for Pepper Spray (with 0 damage).");
    ConsoleMessage("GetGassed:    Runs camera effect for CS Gas (similar to Pepper Spray) (with 0 damage).");
    ConsoleMessage("GetTased:     Runs camera effect for Taser (with 0 damage).");
    ConsoleMessage("GetStung:     Runs camera effect for Sting Grenade (with 0 damage).");
    ConsoleMessage("GetLLShotgun: Runs camera effect for Less Lethal Shotgun (similar to Sting Grenade) (with 0 damage).");
	ConsoleMessage("---------- For editing ScreenEffect Parameters:");
    ConsoleMessage("editClass paramsClass: Where paramsClass is one of: ");
	ConsoleMessage("  DesignerStingParams, DesignerPepperSprayParams, DesignerCSGasParams, DesignerLessLethalSGParams");
	ConsoleMessage("");
	ConsoleMessage("---------- Archetypes/Spawning stuff ----------");
	ConsoleMessage("");
    ConsoleMessage("SummonArchetype <'Enemy' / 'Hostage' / 'Inanimate'>, <Archetype name>: Spawns an instance of the specified archetype in front of the player.  Eg. 'summonarchetype enemy arms_dealer'");
    ConsoleMessage("TestSpawn <Count>: Simulate spawning for the current level Count times.  Nothing is actually spawned.  But results of the simulation are logged.");    //TMC TODO make count=0 do 'allspawn'
    ConsoleMessage("TestSpawn (no count): Spawn a 'TestSpawn' Archetype at each Enemy and Hostage Spawner.");
	ConsoleMessage("UsePrimaryEntry <1 or 0>: if 1, singleplayer missions will use the primary entry point. If 0, they will use the secondary entry point");
	ConsoleMessage("");
	ConsoleMessage("---------- Sound/Visual FX stuff ----------");
	ConsoleMessage("");
    ConsoleMessage("DebugEffectEvent <EffectEvent>: log the details of TriggerEffectEvent() each time EffectEvent is triggered.");
    ConsoleMessage("DumpEffects <'Visual' / 'Sound'>: Logs the state of the specified effects subsystem.");
	ConsoleMessage("");
	ConsoleMessage("---------- Leadership/Objectives stuff ----------");
	ConsoleMessage("");
    ConsoleMessage("MissionStatus: Log the current mission status");
    ConsoleMessage("LeadershipStatus: Log the current leadership status & scores");
	ConsoleMessage("");
    ConsoleMessage("---------- Rendering Stuff ----------");
	ConsoleMessage("");
    ConsoleMessage("RenderDetail <0-3>: Globally adjusts ALL other rendering settings; 3 is highest detail, 0 is lowest");
    ConsoleMessage("TextureDetail <0-3>: Changes texture detail (size); 3 is highest detail, 0 is lowest");
    ConsoleMessage("BumpDetail <0-3>: Changes bumpmapping settings. 3 = characters+staticmesh+bsp+emitters, 2 = characters+staticmesh; 1 = static mesh, 0 = nothing");
	ConsoleMessage("");
    ConsoleMessage("---------- Profiling Stuff ----------");
	ConsoleMessage("");
    ConsoleMessage("EnableProfile: Turn on profiling of function calls");
    ConsoleMessage("TickProfile: Enable profiling of time spent in Tick() on a per-class basis");
    ConsoleMessage("ResetProfile: Rest the profiling stats");
    ConsoleMessage("LogProfile: Dump the current profile to the log");
	ConsoleMessage("");
    ConsoleMessage("---------- Debugging Stuff ----------");
	ConsoleMessage("");
    ConsoleMessage("stat anim: Show details on what animations are playing");
    ConsoleMessage("show projectorbounds: Show bounds of projectors in-game.");
    ConsoleMessage("show actors: turn on/off rendering of actors");
    ConsoleMessage("show actorinfo: turn on/off rendering of actor info");
    ConsoleMessage("show staticmesh: turn on/off rendering of static meshes");
    ConsoleMessage("show fog: turn on/off rendering of fog");
    ConsoleMessage("show sky: turn on/off rendering of skyzone");
    ConsoleMessage("show corona: turn on/off rendering of coronas");
    ConsoleMessage("show particle: turn on/off rendering of particles");
    ConsoleMessage("show bsp: turn on/off rendering of bsp surfaces");
    ConsoleMessage("show radii: turn on/off rendering of radii for things using cylinder collision");
    ConsoleMessage("show fluid: turn on/off rendering of fluid surfaces");
    ConsoleMessage("show projector: turn on/off rendering of dynamic projectors");
    ConsoleMessage("show collision: Show non-havok collision bounds. Dynamic objects are in pink. Also show bone collision boxes.");
    ConsoleMessage("rend collision: Show pawn collision. If pawn is on top of something, show that thing in yellow and draw line to it");
    ConsoleMessage("AnimDrawDebugLines: Show where the pawns should be aiming");
    ConsoleMessage("DebugAIMovement: Show where the AIs think they are going");
    ConsoleMessage("rend bound: Show the rendering bounding sphere/box for skeletal");
    ConsoleMessage("            meshes (blue), the render bounding box for static meshes (green),");
    ConsoleMessage("            the predicted render bounding box (red) and the emitter bounds (yellow)");
    ConsoleMessage("ListVisibleSprites: writes to the log the identity of any 'dragon-camel' icons appearing in the game.");
	ConsoleMessage("");
    ConsoleMessage("--------------------------------------------------------------------");
}

// Turn the screenshot watermark on/off
exec native function ToggleWatermark();

// Calls hide() on all instances of SwatAI.
exec function HideAI()
{
	local SwatAI TheAI;
	ForEach AllActors(class'SwatAI',TheAI)
	{
		ConsoleMessage("SwatCheatManager: Hiding SwatAI \""$TheAI$"\"");
		TheAI.Hide();
	}
    bUserHidAIs = true;
}

// Calls show() on all instances of SwatAI.
exec function ShowAI()
{
	local SwatAI TheAI;
	ForEach AllActors(class'SwatAI', TheAI)
	{
		ConsoleMessage("SwatCheatManager: Unhiding SwatAI \""$TheAI$"\"");
		TheAI.Show();
	}
    bUserHidAIs = false;
}

// If the user has previously called HideAI(), this function calls ShowAI();
// otherwise it calls HideAI().
exec function ToggleAIHiddenState()
{
	if (bUserHidAIs)
	{
		ShowAI();
	}
	else
	{
		HideAI();
	}
}

// Compliance
// sends the comply command to all AIs
exec function EveryoneComply()
{
    local SwatAI IterAI;

	ForEach AllActors(class'SwatAI', IterAI)
	{
		ConsoleMessage("SwatCheatManager: Telling SwatAI "$IterAI$" to comply using "$Pawn);

		assert(SwatCharacterResource(IterAI.characterAI).CommonSensorAction.GetComplySensor() != None);
		SwatCharacterResource(IterAI.characterAI).CommonSensorAction.GetComplySensor().NotifyComply(Pawn);
	}
}

exec function AnimDrawDebugLines()
{
    local SwatPawn SwatPawn;
    foreach AllActors(class 'SwatPawn', SwatPawn)
    {
        SwatPawn.ToggleAnimDrawDebugLines();
    }
}

exec function DebugPathLines()
{
    local SwatAI SwatAI;
    foreach AllActors(class 'SwatAI', SwatAI)
    {
        SwatAI.ToggleDebugPathLines();
    }
}


exec function DebugAIs()
{
    local SwatAI SwatAI;
    foreach AllActors(class 'SwatAI', SwatAI)
    {
        SwatAI.bShowBlackboardDebugInfo = ! SwatAI.bShowBlackboardDebugInfo;
    }
}

exec function DebugTyrion()
{
	DebugTyrionCharacter();
	DebugTyrionMovement();
	DebugTyrionWeapon();
	DebugTyrionHead();
}

exec function DebugTyrionCharacter()
{
    local SwatAI SwatAI;
    foreach AllActors(class 'SwatAI', SwatAI)
    {
        SwatAI.bShowTyrionCharacterDebugInfo = ! SwatAI.bShowTyrionCharacterDebugInfo;
    }
}

exec function DebugTyrionMovement()
{
    local SwatAI SwatAI;
    foreach AllActors(class 'SwatAI', SwatAI)
    {
        SwatAI.bShowTyrionMovementDebugInfo = ! SwatAI.bShowTyrionMovementDebugInfo;
    }
}

exec function DebugTyrionWeapon()
{
    local SwatAI SwatAI;
    foreach AllActors(class 'SwatAI', SwatAI)
    {
        SwatAI.bShowTyrionWeaponDebugInfo = ! SwatAI.bShowTyrionWeaponDebugInfo;
    }
}

exec function DebugTyrionHead()
{
	local SwatAI SwatAI;
    foreach AllActors(class 'SwatAI', SwatAI)
    {
        SwatAI.bShowTyrionHeadDebugInfo = ! SwatAI.bShowTyrionHeadDebugInfo;
    }
}

exec function DebugAIAiming()
{
	local SwatAI SwatAI;
    foreach AllActors(class 'SwatAI', SwatAI)
    {
        SwatAI.bShowAimingDebugInfo = ! SwatAI.bShowAimingDebugInfo;
    }
}

exec function DisableAwareness(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).DisableAwareness();
	}

	ClientMessage("Awareness now disabled for all:"@AIClass.Name);
}

exec function EnableAwareness(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).EnableAwareness();
	}

	ClientMessage("Awareness now enabled for all:"@AIClass.Name);
}

exec function DisableCollisionAvoidance(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).DisableCollisionAvoidance();
	}

	ClientMessage("Collision Avoidance now disabled for all:"@AIClass.Name);
}

exec function EnableCollisionAvoidance(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).EnableCollisionAvoidance();
	}

	ClientMessage("Collision Avoidance now disabled for all:"@AIClass.Name);
}

exec function DisableVision(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).DisableVision(false);
	}

	ClientMessage("Vision now disabled for all:"@AIClass.Name);
}

exec function EnableVision(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).EnableVision();
	}

	ClientMessage("Vision now enabled for all:"@AIClass.Name);
}

exec function EnableHearing(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).EnableHearing();
	}

	ClientMessage("Hearing now enabled for all:"@AIClass.Name);
}

exec function DisableHearing(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).DisableHearing(false);
	}

	ClientMessage("Hearing now disabled for all:"@AIClass.Name);
}

// convenience because sometimes I type the wrong thing in [crombie]
exec function MakeAIsGod(optional class<SwatAI> OptionalAIClass)
{
	MakeAIGod(OptionalAIClass);
}

exec function MakeAIGod(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).Controller.bGodMode = ! SwatAI(AI).Controller.bGodMode;
	}

	ClientMessage("MakeAIGod called on all: "@AIClass.Name);
}

exec function LogTyrion(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).logTyrion = ! SwatAI(AI).logTyrion;
	}
}

exec function LogAI(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
		SwatAI(AI).LogAI = ! SwatAI(AI).LogAI;
	}
}

exec function AILowReady(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
        SwatAI(AI).SetUpperBodyAnimBehavior(kUBAB_LowReady);
        SwatAI(AI).SetLowReady(! SwatAI(AI).IsLowReady());
	}
}

exec function AIUpperBodyOn(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
        SwatAI(AI).SetUpperBodyAnimBehavior(kUBAB_AimWeapon);
	}
}

exec function AIUpperBodyOff(optional class<SwatAI> OptionalAIClass)
{
	local Actor AI;
	local class<SwatAI> AIClass;

	if (OptionalAIClass == None)
	{
		AIClass = class'SwatAI';
	}
	else
	{
		AIClass = OptionalAIClass;
	}

	foreach DynamicActors(AIClass, AI)
	{
        SwatAI(AI).SetUpperBodyAnimBehavior(kUBAB_FullBody);
	}
}

exec function OpenDoorsToLeft()
{
	local NavigationPoint Iter;
	local SwatDoor Door;

	for(Iter = Level.navigationPointList; Iter != None; Iter = Iter.nextNavigationPoint)
	{
		Door = SwatDoor(Iter);

		if (Door != None)
		{
			Door.SetPositionForMove( DoorPosition_OpenLeft, MR_Interacted );
			Door.Moved(true); //instantly to initial position
		}
	}
}

exec function OpenDoorsToRight()
{
	local NavigationPoint Iter;
	local SwatDoor Door;

	for(Iter = Level.navigationPointList; Iter != None; Iter = Iter.nextNavigationPoint)
	{
		Door = SwatDoor(Iter);

		if (Door != None)
		{
			Door.SetPositionForMove( DoorPosition_OpenRight, MR_Interacted );
			Door.Moved(true); //instantly to initial position
		}
	}
}

exec function LockAllDoors()
{
	local NavigationPoint Iter;
	local SwatDoor Door;

	for(Iter = Level.navigationPointList; Iter != None; Iter = Iter.nextNavigationPoint)
	{
		Door = SwatDoor(Iter);

		if ((Door != None) && Door.CanBeLocked())
		{
			Door.Lock();
		}
	}
}

// Morale
// output the morale history
exec function DebugMorale()
{
    local SwatAI SwatAI;
    foreach AllActors(class 'SwatAI', SwatAI)
    {
        SwatAI.bShowMoraleHistoryDebugInfo = ! SwatAI.bShowMoraleHistoryDebugInfo;
    }
}

exec function SummonArchetype(name ArchetypeKind, name ArchetypeName)
{
    local class<Archetype> ArchetypeClass;
    local Archetype Archetype;
    local Pawn PlayerPawn;
    local class<Actor> ClassToSpawn;
    local Actor Summoned;

    switch (ArchetypeKind)
    {
        case 'Enemy':
          ArchetypeClass = class'EnemyArchetype';
            break;
        case 'Hostage':
            ArchetypeClass = class'HostageArchetype';
            break;
        case 'Inanimate':
            ArchetypeClass = class'InanimateArchetype';
            break;
        default:
            ConsoleMessage("Unexpected ArchetypeKind "$ArchetypeKind$" specified.");
    }

    PlayerPawn = Level.GetLocalPlayerController().Pawn;

    //instantiate the archetype
    Archetype = new(None, string(ArchetypeName), 0) ArchetypeClass;
    if (Archetype == None)
    {
        ConsoleMessage("SummonArchetype: Couldn't instantiate a new Archetype of class "$ArchetypeClass);
        return;
    }
    Archetype.Initialize(Level);

    //pick a class to spawn
    ClassToSpawn = Archetype.PickClass();
    assert(ClassToSpawn != None);   //PickClass() should never return None

    //spawn it
    Summoned = Spawn(ClassToSpawn,,, PlayerPawn.Location + 70 * vector(PlayerPawn.Rotation) + vect(1,1,15));
    if (Summoned == None)
    {
        ConsoleMessage("SummonArchetype: Couldn't Spawn an instance of Class "$ClassToSpawn$".  (selected to spawn from Archetype "$Archetype$")");
        return;
    }

    //initialize it from the archetype
    Archetype.InitializeSpawned(IUseArchetype(Summoned), None);    //no Spawner
}

exec function DebugBallistics()
{
    Level.AnalyzeBallistics = !Level.AnalyzeBallistics;
}

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
exec function DebugGrenades()
{
    local class<SwatGrenadeProjectile> SGPClass;
	local SwatGrenadeProjectile ExistingProjectile;

    // Set the default for newly spawned grenades
    SGPClass = class'Engine.SwatGrenadeProjectile';
    SGPClass.Default.bRenderDebugInfo = !SGPClass.Default.bRenderDebugInfo;

    ConsoleMessage("Grenade debugging default changed to: "$SGPClass.Default.bRenderDebugInfo);

    // turn on/off debugging for existing grenades
	ForEach AllActors(class'SwatGrenadeProjectile',ExistingProjectile)
	{
		ExistingProjectile.bRenderDebugInfo = SGPClass.Default.bRenderDebugInfo;
        ConsoleMessage("  Grenade debugging changed to: "$ExistingProjectile.bRenderDebugInfo$" for pre-existing grenade "$ExistingProjectile);
	}
}
#endif

#if !IG_SWAT_DISABLE_VISUAL_DEBUGGING // ckline: prevent cheating in network games
exec function ToggleRecoil()
{
    local SwatGamePlayerController Player;
    Player = SwatGamePlayerController(Level.GetLocalPlayerController());

    Player.DebugShouldRecoil = !Player.DebugShouldRecoil;
}
#endif

exec function FlashlightLines(bool onState)
{
	local FiredWeapon TheWeapon;
	ForEach AllActors(class'FiredWeapon',TheWeapon)
	{
		ConsoleMessage("SwatCheatManager: Changing Flashlight debug line visibility for \""$TheWeapon$"\" to: "$onState);
		TheWeapon.DebugDrawFlashlightDir = onState;
	}
}

exec function FlashlightFancy(bool onState)
{
	local FiredWeapon TheWeapon;
	ForEach AllActors(class'FiredWeapon',TheWeapon)
	{
		ConsoleMessage("SwatCheatManager: Changing Flashlight point/spot type for \""$TheWeapon$"\" to: "$onState);
		if (onState)
			TheWeapon.FlashlightUseFancyLights = 1;
		else
			TheWeapon.FlashlightUseFancyLights = 0;
	}
}

// for debugging the Tased effect
exec function GetTased()
{
    SwatPlayer(Level.GetLocalPlayerController().Pawn).ReactToBeingTased(None, 10.0, 4);
}

// for debugging the PepperSpray effect.
exec function GetSprayed()
{
	local Bool  bTestingEffects;
	bTestingEffects = SwatPlayer(Level.GetLocalPlayerController().Pawn).bTestingCameraEffects;
	SwatPlayer(Level.GetLocalPlayerController().Pawn).bTestingCameraEffects = true;

    SwatPlayer(Level.GetLocalPlayerController().Pawn).ReactToBeingPepperSprayed(None, 10.0, 4, 0, 0);// player/AI react for 10/4 seconds regardless of protective equipment

	SwatPlayer(Level.GetLocalPlayerController().Pawn).bTestingCameraEffects = bTestingEffects;
}

// for debugging the CS Gas effect.
exec function GetGassed()
{
	local SwatGrenadeProjectile Gasser;
	local Class<SwatGrenadeProjectile> GrenadeClass;
	local Vector Offset;
	local Bool   bTestingEffects;

	Offset.X = 10;
	Offset.Y = 0;
	Offset.Z = 0;

	// This is needed to get around the face that the CSGasGrenadeProjectile
	// class is later in the compile order
	GrenadeClass = Class<SwatGrenadeProjectile>(DynamicLoadObject( "SwatEquipment.CSGasGrenadeProjectile", class'Class'));
	AssertWithDescription(GrenadeClass != None,
        "[henry] Could not find class CSGasGrenadeProjectile in GetGassed().");

    Gasser = Spawn(GrenadeClass,
				   Level.GetLocalPlayerController().Pawn, ,
				   Level.GetLocalPlayerController().Pawn.Location + Offset);
	AssertWithDescription(Gasser != None,
        "[henry] Could not create class CSGasGrenadeProjectile in GetGassed().");
    Gasser.bHidden = true;

	bTestingEffects = SwatPlayer(Level.GetLocalPlayerController().Pawn).bTestingCameraEffects;
	SwatPlayer(Level.GetLocalPlayerController().Pawn).bTestingCameraEffects = true;

    SwatPlayer(Level.GetLocalPlayerController().Pawn).ReactToCSGas(Gasser, 10.0, 0, 0); // react for 10 seconds regardless of protective equipment

	SwatPlayer(Level.GetLocalPlayerController().Pawn).bTestingCameraEffects = bTestingEffects;

    Gasser.Destroy();

}

// for debugging the Less Lethal Shotgun effect (which is a version of the StingGrenade effect).
exec function GetLLShotgun()
{
	local Range ImpulseRange;
	ImpulseRange.Min = 0;
	ImpulseRange.Max = 1;

    SwatPlayer(Level.GetLocalPlayerController().Pawn).
		ReactToStingGrenade(None,
							Level.GetLocalPlayerController().Pawn,
							0.0,
							10.0,
							ImpulseRange,
							10,
							10,
							10,					  // Duration
							6,					  // Armored Duration
							14,					  // No Armor Duration
							4,					  // AI Duration
							0);                   // morale
}

// for debugging the Sting grenade effect.
exec function GetStung()
{
	local SwatGrenadeProjectile Stinger;
	local Class<SwatGrenadeProjectile> GrenadeClass;
	local Range ImpulseRange;
	local Vector Offset;

	Offset.X = 10;
	Offset.Y = 0;
	Offset.Z = 0;

	// This is needed to get around the face that the StingGrenadeProjectile
	// class is later in the compile order
	GrenadeClass = Class<SwatGrenadeProjectile>(DynamicLoadObject( "SwatEquipment.StingGrenadeProjectile", class'Class'));
	AssertWithDescription(GrenadeClass != None,
        "[henry] Could not find class StingGrenadeProjectile in GetStung().");

    Stinger = Spawn(GrenadeClass,
					Level.GetLocalPlayerController().Pawn, ,
					Level.GetLocalPlayerController().Pawn.Location + Offset);
	AssertWithDescription(Stinger != None,
        "[henry] Could not create class StingGrenadeProjectile in GetStung().");
    Stinger.bHidden = true;
	ImpulseRange.Min = 0;
	ImpulseRange.Max = 1;

    SwatPlayer(Level.GetLocalPlayerController().Pawn).
		ReactToStingGrenade(Stinger,
							Level.GetLocalPlayerController().Pawn,
							0.0,
							10.0,
							ImpulseRange,
							10,
							10,
							10,					  // Duration
							6,					  // Armored Duration
							14,					  // No Armor Duration
							4,					  // AI Duration
							0);                   // morale
    Stinger.Destroy();

}


// for debugging the Flashbang effect.
exec function GetFlashBanged()
{
	local Range ImpulseRange;
	local Bool  bTestingEffects;
	ImpulseRange.Min = 0;
	ImpulseRange.Max = 1;

	bTestingEffects = SwatPlayer(Level.GetLocalPlayerController().Pawn).bTestingCameraEffects;
	SwatPlayer(Level.GetLocalPlayerController().Pawn).bTestingCameraEffects = true;

    SwatPlayer(Level.GetLocalPlayerController().Pawn).
		ReactToFlashbangGrenade(None,
								Level.GetLocalPlayerController().Pawn,
								0.0,
								10.0,
								ImpulseRange,
								10,
								100,                  // Stun Radius
								10,					  // Duration
								4,					  // AI Duration
								0);                   // morale

	SwatPlayer(Level.GetLocalPlayerController().Pawn).bTestingCameraEffects = bTestingEffects;
}

exec function DebugEffectEvent(name EffectEvent)
{
    EffectsSystem(Level.EffectsSystem).DebugEffectEvent[EffectsSystem(Level.EffectsSystem).DebugEffectEvent.length] = EffectEvent;
    ConsoleMessage("DebugEffectEvent() now debugging '"$EffectEvent$"'");
}

exec function TestSpawn(int Count)
{
    local SpawningManager SpawningManager;

    SpawningManager = SpawningManager(Level.SpawningManager);
    AssertWithDescription(SpawningManager != None,
        "[tcohen] This map has no SpawningManager in its LevelInfo.  Can't TestSpawn.");

    SpawningManager.TestSpawn(SwatGameInfo(Level.Game), Count);
}

exec function UsePrimaryEntry(bool UsePrimary)
{
	local SwatRepo TheRepo;

	TheRepo = SwatRepo(Level.GetRepo());
	if (UsePrimary)
	{
		TheRepo.SetDesiredEntryPoint(ET_Primary);
		ClientMessage("Set desired entry point to PRIMARY");
	}
	else
	{
		TheRepo.SetDesiredEntryPoint(ET_Secondary);
		ClientMessage("Set desired entry point to SECONDARY");
	}
}

//logs all actors that are bHidden=false and DrawType=DT_Sprite
exec function ListVisibleSprites()
{
    local Actor TheActor;

    foreach AllActors(class'Actor', TheActor)
    {
        if (TheActor.DrawType == DT_Sprite && TheActor.bHidden == false)
        {
            ConsoleMessage("FOUND VISIBLE SPRITE: "$TheActor$" at location "$TheActor.Location);
        }
    }
}

exec function ViewClass( class<actor> aClass, optional bool bQuiet, optional bool bCheat )
{
	// update the camera effects so that we can see current visual state correctly
	local SwatGamePlayerController GamePlayerController;

    Super.ViewClass(aClass, bQuiet, bCheat);

    GamePlayerController = SwatGamePlayerController( Level.GetLocalPlayerController() );
	GamePlayerController.RefreshCameraEffects( SwatPlayer(GamePlayerController.ViewTarget) );
}


exec function TaseMe()
{
	local SwatGamePlayerController GamePlayerController;
    GamePlayerController = SwatGamePlayerController( Level.GetLocalPlayerController() );
    GamePlayerController.GetCommandInterface().CurrentCommandTeam.DeployTaser(Pawn, Pawn.Location, Pawn);
}

exec function LogTimers()
{
    local Timer TheTimer;

    foreach AllActors(class'Timer', TheTimer)
    {
        if (TheTimer != None)
        {
            ConsoleMessage("  Timer: Name="$TheTimer.Name$" Owner="$TheTimer.Owner$" IsRunning="$TheTimer.IsRunning()$" LastStartTime="$TheTimer.GetLastStartTime());
        }
    }

}

exec function ThrowLS()
{
    local ISwatOfficer A;

    foreach AllActors(class'ISwatOfficer', A)
    {
		A.GetItemAtSlot(SLOT_Lightstick).Use();
    }
}

exec function SayEffectEvent(Name Event)
{
	TriggerEffectEvent(Event);
}

// dbeswick:
exec function runScript(Name label)
{
	local Script s;

	s = Script(findByLabel(class'Script', label));

	if (s == None)
	{
		ClientMessage("Script "$label$" not found");
	}
	else
	{
		if (!s.IsInState('ExecuteScript'))
			s.GotoState('ExecuteScript');
		ConsoleMessage("Ran script "$label);
		ClientMessage("Ran script "$label);
	}
}

defaultproperties
{
	bUserHidAIs = false;
}
