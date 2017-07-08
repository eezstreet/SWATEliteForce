//=============================================================================
// LevelSummary contains the summary properties from the LevelInfo actor.
// Designed for fast loading.
//=============================================================================
class LevelSummary extends Core.Object
    dependsOn(Repo)
	native;

#if IG_SWAT //dkaplan: some additional info we want to use in SWAT
import enum EMPMode from Repo;
#endif

//-----------------------------------------------------------------------------
// Properties.

// From LevelInfo.
var() localized string Title;
var()           string Author;
#if !IG_SWAT //dkaplan: some info we DONT want to use in SWAT
var() int	IdealPlayerCount;
#endif
var() localized string LevelEnterText;

#if IG_SWAT //dkaplan: some additional info we want to use in SWAT
var()         Material Screenshot "Screenshot of the level to be displayed on the server setup menu";
var() Localized string Description "Description of the level to be displayed on the server setup menu";
var() array<EMPMode>   SupportedModes "Multiplayer game modes supported by this map. If none are specified this map will not be available for multiplayer games.";
var()			int		IdealPlayerCountMin		"Recommended minimum number of players for this level.";
var()			int		IdealPlayerCountMax		"Recommended maximum number of players for this level.";
#endif

defaultproperties
{
}
