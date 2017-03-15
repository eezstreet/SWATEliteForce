// SwatAIData is a hack to allow modmakers to implement more variables in SwatHostage and SwatEnemy without breaking native.

class SwatAIData extends Core.Object;

var public Spawner SpawnedFrom;
var public Timer DOATimer;
var public bool TreatAsDOA; // Treat this as a DOA and not as a killed character

simulated function Destroyed()
{
  // Put anything that needs to be garbage-collected here
  SpawnedFrom = None;
  DOATimer = None;
}

defaultproperties
{
  // Put any default properties here
  TreatAsDOA = false
}
