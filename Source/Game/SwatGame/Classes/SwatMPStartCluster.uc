// A start cluster is a sort of container for a collection of SwatPlayerStart
// points, and is associated with a particular team. It is used so that the MP
// spawn code can easily locate a start cluster that meets certain criteria
// (e.g., closest cluster to team XYZ) and then spawn members of team XYZ at
// the spawn points associated with the cluster.
//
// When one of these is spawned (e.g. placed in the editor) it will automatically
// spawn 16 SwatMPStartPoints and place them in the StartPoints array.

class SwatMPStartCluster extends Engine.Actor
    placeable
	native;

import enum EMPTeam from SwatGame.SwatGameInfo;
import enum EMPMode from Engine.Repo;

var(StartCluster) EMPTeam ClusterTeam "In multiplayer games, defines the team that may spawn at this cluster";

var(StartCluster) bool UseInBarricadedSuspects "Set to true if this start cluster can be used in the Barricaded Suspects game mode";
var(StartCluster) bool UseInVIPEscort "Set to true if this start cluster can be used in the VIP Escort game mode";
var(StartCluster) bool UseInRapidDeployment "Set to true if this start cluster can be used in the Rapid Deploymentgame mode";
var(StartCluster) bool UseInSmashAndGrab "Set to true if this start cluster can be used in the Smash And Grab game mode";

var(StartCluster) bool NeverFirstSpawnInBSRound "If true, this cluster should not be used for the first spawn of a Barricaded Suspects round.";
var(StartCluster) bool NeverFirstSpawnInVIPRound "If true, this cluster should not be used for the first spawn of a VIP Escort round.";
var(StartCluster) bool NeverFirstSpawnInRDRound "If true, this cluster should not be used for the first spawn of a Rapid Deployment round.";
var(StartCluster) bool NeverFirstSpawnInSAGRound "If true, this cluster should not be used for the first spawn of a Smash And Grab round.";

var(StartCluster) bool IsPrimaryEntryPoint "If true, this cluster can be used for primary spawns in COOP mode.";
var(StartCluster) bool IsSecondaryEntryPoint "If true, this cluster can be used for secondary spawns in COOP mode.";

var bool IsEnabled "If true, this spawn cluster is currently enabled.";

var int NumberOfStartPoints;

// These are const so they cannot be changed from script. The start points are 
// spawned (in native code) when the cluster is placed in the editor.
var const SwatMPStartPoint StartPoints[16];

// Defines the static prefix of the name of the texture assigned to each start
// point and cluser. For start points, the full name of the texture loaded will be 
// MPStartPointIconNamePrefix<INDEX>_<TEAM> where <INDEX> is e.g. "12" for the 
// 12th start point in the cluster, and <TEAM> is "Swat" if EMPTeam == MPT_Swat
// or "Suspects" if EMPTeam == MPT_Suspects.
// For start clusters, the texture used will be MPStartClusterIconNamePrefix_<TEAM>.
var private String MPStartPointIconNamePrefix; 
var private String MPStartClusterIconNamePrefix;

///////////////////////////////////////////////////////////////////////////////

cpptext 
{
	virtual void CheckForErrors();
    virtual void PostEditAdd(GroupFactory& Grouper);
	virtual void UpdateIcons();
	virtual void PostEditChange();
	virtual void PostEditLoad();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	ClusterTeam=MPT_Swat
	DrawType=DT_Sprite
    Texture=Texture'EditorSprites.SwatMPStartCluster'
    UseInBarricadedSuspects=true
    UseInVIPEscort=true
    UseInRapidDeployment=true
	UseInSmashAndGrab=true
    NeverFirstSpawnInBSRound=false
    NeverFirstSpawnInVIPRound=false
    NeverFirstSpawnInRDRound=false
	NeverFirstSpawnInSAGRound=false
	bDirectional=false
    NumberOfStartPoints=16

//	bNotBased=false
    bStatic=true
    bNoDelete=true
    bHidden=true
    bCollideWhenPlacing=true
    CollisionRadius=+00030.000000
    CollisionHeight=+00080.000000
    bCollideActors=true

	MPStartPointIconNamePrefix="EditorSprites.MPSpawnCluster_Start"
    MPStartClusterIconNamePrefix="EditorSprites.SwatMPStartCluster";

    IsEnabled=true
}
