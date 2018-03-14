class CustomScenario extends Core.Object
    dependsOn(EnemyArchetype)
    perObjectConfig;

import enum EnemySkill from SwatAICommon.ISwatEnemy;

/*
 *	SWAT: Elite Force Custom Scenario Versions
 *
 *	Version 0: Base Game
 *	Version 1: Elite Force (base)
 */
var config int ScenarioVersion;

////////////////////////////////////////
// Added in Version 0
var String ScenarioName;
var String PackName;

var config name LevelLabel;
var config string Difficulty;

var config bool UseCampaignObjectives;
var config array<name> ScenarioObjectives;

var config bool SpecifyStartPoint;
var config bool UseSecondaryStartPoint;

var config float TimeLimit;

var config bool LoneWolf;
//'Any' means permit player to select
var config bool HasOfficerRedOne;
var config name RedOneLoadOut;
var config bool HasOfficerRedTwo;
var config name RedTwoLoadOut;
var config bool HasOfficerBlueOne;
var config name BlueOneLoadOut;
var config bool HasOfficerBlueTwo;
var config name BlueTwoLoadOut;

struct IntegerRangeCow
{
    var config int Max;
    var config int Min;
};

var config bool UseCampaignHostageSettings;

//only relevant if !UseCampaignHostageSettings
var config array<name> HostageArchetypes;
var config IntegerRangeCow HostageCountRangeCow; //compiler bug: this should be an IntegerRange
var config range HostageMorale;

var config bool UseCampaignEnemySettings;

//only relevant if !UseCampaignEnemySettings
var config array<name> EnemyArchetypes;
var config IntegerRangeCow EnemyCountRangeCow;   //compiler bug: this should be an IntegerRange
var config range EnemyMorale;

//the path name of the weapon class, ripe for DLO'ing
var config array<string>    EnemyPrimaryWeaponOptions;
var config string           EnemyPrimaryWeaponType;
var config string           EnemyPrimaryWeaponSpecific;
var config array<string>    EnemyBackupWeaponOptions;
var config string           EnemyBackupWeaponType;
var config string           EnemyBackupWeaponSpecific;

var config string           EnemySkill;

var config localized string Notes;    //localized for any shipping custom scenarios

////////////////////////////////////////
// Added in Version 1
var config bool UseCustomBriefing;
var config localized string CustomBriefing;
var config bool DisableBriefingAudio;
var config bool DisableEnemiesTab;
var config bool DisableHostagesTab;
var config bool DisableTimelineTab;
var config bool IsCustomMap;
var config string CustomMapURL;

var DoNot_LetTimerExpire TimedMissionObjective; // dbeswick:

function MutateLevelRosters(SpawningManager SpawningManager, out array<Roster> Rosters)
{
    local EnemyRoster EnemyRoster;
    local HostageRoster HostageRoster;
    local Archetype.ChanceArchetypePair ChanceArchetypePair;
    local CustomScenarioCreatorMissionSpecificData MissionData;
    local int CampaignEnemies, CampaignHostages;
    local bool DeleteRoster;
    local int i;

    //delete any rosters that shouldn't spawn in this CustomScenario
    //iterate backward because removing items changes array indices
    for (i = Rosters.length - 1; i >= 0; --i)
    {
        DeleteRoster = true;    //unless preserved below ...

        if  (
                SpawningManager.IsMissionObjective(Rosters[i].SpawnerGroup)
            &&  UseCampaignObjectives
            )
        {
            log("[CUSTOM SCENARIO] Keeping Roster index "$i
                    $" with SpawnerGroup="$Rosters[i].SpawnerGroup
                    $" because IsMissionObjective && UseCampaignObjectives.");
            DeleteRoster = false;
        }
        else
        if  (Rosters[i].IsA('EnemyRoster') && UseCampaignEnemySettings)
        {
            log("[CUSTOM SCENARIO] Keeping Roster index "$i
                    $" with SpawnerGroup="$Rosters[i].SpawnerGroup
                    $" because IsA('EnemyRoster') && UseCampaignEnemySettings.");
            DeleteRoster = false;
        }
        else
        if  (Rosters[i].IsA('HostageRoster') && UseCampaignHostageSettings)
        {
            log("[CUSTOM SCENARIO] Keeping Roster index "$i
                    $" with SpawnerGroup="$Rosters[i].SpawnerGroup
                    $" because IsA('HostageRoster') && UseCampaignHostageSettings.");
            DeleteRoster = false;
        }

        if (DeleteRoster)
        {
            log("[CUSTOM SCENARIO] Deleting Roster index "$i
                    $" with SpawnerGroup="$Rosters[i].SpawnerGroup
                    $".  No reason to justify keeping it: UseCampaignObjectives="$UseCampaignObjectives
                    $", Rosters[i].SpawnerGroup="$Rosters[i].SpawnerGroup
                    $", IsMissionObjective()="$SpawningManager.IsMissionObjective(Rosters[i].SpawnerGroup));
            Rosters.Remove(i, 1);
        }
    }

    if (UseCampaignObjectives)
    {
        //determine how many CampaignEnemies and CampaignHostages will be spawned
        MissionData = new (None, string(LevelLabel)) class'CustomScenarioCreatorMissionSpecificData';
        assert(MissionData != None);
        CampaignEnemies = MissionData.CampaignObjectiveEnemySpawn.length;
        CampaignHostages = MissionData.CampaignObjectiveHostageSpawn.length;

        log("[CUSTOM SCENARIO] Specifies "$EnemyCountRangeCow.Min
                $" to "$EnemyCountRangeCow.Max
                $" Enemies and "$HostageCountRangeCow.Min
                $" to "$HostageCountRangeCow.Max
                $" Hostages, including "$CampaignEnemies
                $" Campaign Enemies and "$CampaignHostages
                $" Campaign Hostages.");
    }
    else
    {
        CampaignEnemies = 0;
        CampaignHostages = 0;

        log("[CUSTOM SCENARIO] Specifies "$EnemyCountRangeCow.Min
                $" to "$EnemyCountRangeCow.Max
                $" Enemies and "$HostageCountRangeCow.Min
                $" to "$HostageCountRangeCow.Max
                $" Hostages.");
    }

    assertWithDescription(CampaignEnemies >= 0 && CampaignHostages >= 0,
        "[tcohen] CustomScenario::MutateLevelRosters() CampaignEnemies="$CampaignEnemies
        $", CampaignHostages="$CampaignHostages);

    if (!UseCampaignEnemySettings)
    {
        // add enemy roster

        EnemyRoster = new(None, "CustomScenarioEnemyRoster") class'EnemyRoster';
        for (i=0; i<EnemyArchetypes.length; ++i)
        {
            ChanceArchetypePair.Archetype = EnemyArchetypes[i];
            ChanceArchetypePair.Chance = 100 / EnemyArchetypes.length;
            EnemyRoster.Archetypes[i] = ChanceArchetypePair;
        }
        EnemyRoster.Count.Min = EnemyCountRangeCow.Min - CampaignEnemies;
        EnemyRoster.Count.Max = EnemyCountRangeCow.Max - CampaignEnemies;
        EnemyRoster.SpawnerGroup = 'CustomRosterSpawnerGroup';
        //add the enemy roster to the list of rosters
        log("[CUSTOM SCENARIO] Adding Custom Enemy Roster, Count.Min="$EnemyRoster.Count.Min$", Count.Max="$EnemyRoster.Count.Max);
        Rosters[Rosters.length] = EnemyRoster;
    }

    if (!UseCampaignHostageSettings)
    {
        // add hostage roster

        HostageRoster = new(None, "CustomScenarioHostageRoster") class'HostageRoster';
        for (i=0; i<HostageArchetypes.length; ++i)
        {
            ChanceArchetypePair.Archetype = HostageArchetypes[i];
            ChanceArchetypePair.Chance = 100 / HostageArchetypes.length;
            HostageRoster.Archetypes[i] = ChanceArchetypePair;
        }
        HostageRoster.Count.Min = HostageCountRangeCow.Min - CampaignHostages;
        HostageRoster.Count.Max = HostageCountRangeCow.Max - CampaignHostages;
        HostageRoster.SpawnerGroup = 'CustomRosterSpawnerGroup';
        //add the Hostage roster to the list of rosters
        log("[CUSTOM SCENARIO] Adding Custom Hostage Roster, Count.Min="$HostageRoster.Count.Min$", Count.Max="$HostageRoster.Count.Max);
        Rosters[Rosters.length] = HostageRoster;
    }
}

function MutateMissionObjectives(MissionObjectives MissionObjectives)
{
    local int i, j;
    local bool dupe, found;
    local MissionObjectives CustomMissionObjectives;  //the set of available objectives for custom missions
    local Automatic_DoNot_Die DoNotDieObjective;;

    //the Outer of the CustomMissionObjectives is the Outer of the Campaign MissionObjectives.
    //this is so that when Objective::Initialize() stores Game=SwatMission(Outer).Game, it gets a valid GameInfo reference.
    CustomMissionObjectives = new (MissionObjectives.Outer, "CustomScenario") class'SwatGame.MissionObjectives';
    assert(CustomMissionObjectives != None);

    if (!UseCampaignObjectives)
    {
        MissionObjectives.Objectives.Remove(0, MissionObjectives.Objectives.length);

        //we always want a DoNot_Die objective, even if no Campaign objectives
        DoNotDieObjective = Automatic_DoNot_Die(MissionObjectives.AddObjective(
                class'SwatGame.Automatic_DoNot_Die',
                'Automatic_DoNot_Die'));
        assert(DoNotDieObjective != None);
    }

    for (i=0; i<ScenarioObjectives.length; ++i)
    {
        //check if ScenarioObjectives[i] is already in MissionObjectives.Objectives
        dupe = false;
        for (j=0; j<MissionObjectives.Objectives.length; ++j)
        {
            if (ScenarioObjectives[i] == MissionObjectives.Objectives[j].name)
            {
                dupe = true;
                break;
            }
        }
        if (dupe) break;    //ScenarioObjectives[i] is already in MissionObjectives

        //find ScenarioObjectives[i] in CustomMissionObjectives and add it to MissionObjectives
        found = false;
        for (j=0; j<CustomMissionObjectives.Objectives.length; ++j)
        {
            if (ScenarioObjectives[i] == CustomMissionObjectives.Objectives[j].name)
            {
                found = true;
                MissionObjectives.AddObjective(
                        CustomMissionObjectives.Objectives[j].Class,
                        CustomMissionObjectives.Objectives[j].name);
                break;
            }
        }
        assertWithDescription(found,
            "[tcohen] CustomScenario::MutateMissionObjectives() Tried to add the ScenarioObjectives named "$ScenarioObjectives[i]
            $" to the list of MissionObjectives.  But an Objective by that name was not found in the list of "
            $"CustomMissionObjectives (the Objectives available for Custom Scenarios).  "
            $"** IMPORTANT ** Custom Scenarios made with older builds may _not_ be compatible with newer builds.  "
            $"Please DO NOT file a bug about this unless you created this Custom Scenario with this build.");
    }

    //add TimedMissionObjective if a TimeLimit was specified
    if (TimeLimit > 0)
    {
        TimedMissionObjective = DoNot_LetTimerExpire(MissionObjectives.AddObjective(
                class'SwatGame.DoNot_LetTimerExpire',
                'Custom_Timed'));
        assert(TimedMissionObjective != None);

        TimedMissionObjective.Time = TimeLimit;
		TimedMissionObjective.StopTimer();
    }

    //if 'Automatic_DoNot_Die' is the only objective, then unhide it
    if  (
            MissionObjectives.Objectives.length == 1
        &&  MissionObjectives.Objectives[0].name == 'Automatic_DoNot_Die'
        )
        MissionObjectives.Objectives[0].IsHidden = false;
}

function MutateArchetype(Archetype Archetype)
{
    local EnemyArchetype EnemyArchetype;
    local EnemyArchetype.EnemySkillChancePair CurrentSkill;

    if (Archetype.IsA('EnemyArchetype') && !UseCampaignEnemySettings)
    {
        EnemyArchetype = EnemyArchetype(Archetype);
        EnemyArchetype.Morale = EnemyMorale;

        EnemyArchetype.Skill.Remove(0, EnemyArchetype.Skill.length);

        CurrentSkill.Chance = 10;   //this value is arbitrary

        if (EnemySkill == "Low" || EnemySkill == "Any")
        {
            CurrentSkill.Skill = EnemySkill_Low;
            EnemyArchetype.Skill[EnemyArchetype.Skill.length] = CurrentSkill;
        }
        if (EnemySkill == "Medium" || EnemySkill == "Any")
        {
            CurrentSkill.Skill = EnemySkill_Medium;
            EnemyArchetype.Skill[EnemyArchetype.Skill.length] = CurrentSkill;
        }
        if (EnemySkill == "High" || EnemySkill == "Any")
        {
            CurrentSkill.Skill = EnemySkill_High;
            EnemyArchetype.Skill[EnemyArchetype.Skill.length] = CurrentSkill;
        }
    }
    else
    if (Archetype.IsA('HostageArchetype') && !UseCampaignHostageSettings)
        HostageArchetype(Archetype).Morale = HostageMorale;
    //else, the Archetype may be an InanimateArchetype or maybe something else
    //anyway, it doesn't have morale.
}

function MutateEnemyWeapons(out array<EnemyArchetype.WeaponClipcountChanceSet> ArchetypeWeapons, array<String> ScenarioWeapons)
{
    local EnemyArchetype.WeaponClipcountChanceSet ArchetypeWeapon;
    local int i;

    ArchetypeWeapons.Remove(0, ArchetypeWeapons.length);

    for (i=0; i<ScenarioWeapons.length; ++i)
    {
        ArchetypeWeapon.Weapon = ScenarioWeapons[i];
        ArchetypeWeapon.Chance = 10;  //this value doesn't matter, as long as its the same for each set, so that each weapon has an equal chance

        ArchetypeWeapons[i] = ArchetypeWeapon;
    }
}
