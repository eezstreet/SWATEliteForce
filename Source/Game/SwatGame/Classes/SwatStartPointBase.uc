class SwatStartPointBase extends Engine.PlayerStart
    abstract
	native;

// The entry location, for single-player games 
enum EEntryType
{
	ET_Primary,
	ET_Secondary
};

var() EEntryType EntryType "The entry point type designation for single player games"; 


///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	bSinglePlayerStart=false
}
