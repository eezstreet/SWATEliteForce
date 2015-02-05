//=====================================================================
// Tyrion_Setup
// Performs one-time initializations/setup for Tyrion AI
//=====================================================================

class Tyrion_Setup extends Actor
	native;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------

native function makeSafeOuter( Object objOwner, Object obj );

//---------------------------------------------------------------------
// Shallow copy function
// Returns None if copy failed
// Note: shouldn't this be in Object.uc?

static function Object shallowCopy( Object source )
{
	local Object dest;

	dest = new(source.outer) source.class;

	if ( static.copyParameters( source, dest ) )
		return dest;
	else
		return None;
}

//---------------------------------------------------------------------
// Copy parameters from source to dest
// Note: shouldn't this be in Object.uc?

native static function bool copyParameters( Object source, Object dest);

//=====================================================================
// defaults

defaultproperties
{
	bHidden	= true
	DrawType = DT_None
}
