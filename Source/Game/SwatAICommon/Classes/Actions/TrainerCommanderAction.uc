///////////////////////////////////////////////////////////////////////////////

class TrainerCommanderAction extends CommanderAction;

///////////////////////////////////////////////////////////////////////////////

function float GetFlashbangedMoraleModification()			{ return 0.0; }
function float GetGassedMoraleModification()				{ return 0.0; }
function float GetPepperSprayedMoraleModification()			{ return 0.0; }
function float GetStungMoraleModification()					{ return 0.0; }
function float GetTasedMoraleModification()					{ return 0.0; }
function float GetStunnedByC2DetonationMoraleModification()	{ return 0.0; }

function bool ShouldRunWhenFlashBanged()        { return false; }
function bool ShouldRunWhenGassed()             { return false; }
function bool ShouldRunWhenPepperSprayed()      { return false; }
function bool ShouldRunWhenStung()              { return false; }
function bool ShouldRunWhenTased()              { return false; }
function bool ShouldRunWhenStunnedByC2()        { return false; }

protected function bool WillReactToGrenadeBeingThrown()   { return false; }

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    bListeningForCompliance = false
}

///////////////////////////////////////////////////////////////////////////////
