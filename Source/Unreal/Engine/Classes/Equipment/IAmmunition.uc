interface IAmmunition;

//returns true iff there is no ammo loaded (ie. weapon cannot currently be fired).  does not check IsEmpty or CanReload
function bool NeedsReload();

//returns true iff there is ammo remaining that is not loaded
function bool CanReload();

//returns true iff there is no ammo loaded and none remaining to load
function bool IsEmpty();

function OnRoundUsed(Pawn User, Equipment Launcher);
function OnReloaded();
