class Procedures extends Core.Object
    config(Leadership);
    //not perObjectConfig

var private config array< class<Procedure> > ProcedureClass;

var private config class<StatTrackerBase> StatTrackerClass;

//dkaplan: made public to allow SwatGameInfo to update the GameReplicationInfo
var array<Procedure> Procedures;

var StatTrackerBase CampaignStatTracking;

var private transient SwatGameInfo Game;

Overloaded function Construct()
{
    local Procedure CurrentProcedure;
    local int i;

    for (i=0; i<ProcedureClass.length; ++i)
    {
        AssertWithDescription(ProcedureClass[i] != None,
            "[tcohen] ProcedureClass index "$i
            $" in the "$class.name
            $" configuration file is not a valid Procedure class.");

        CurrentProcedure = new(None, string(ProcedureClass[i].name), 0) ProcedureClass[i]();

        assert(CurrentProcedure != None);
        assert(CurrentProcedure.IsA(ProcedureClass[i].name));  //TMC test Karl's bugfix for constructors from dynamic types

        Procedures[Procedures.length] = CurrentProcedure;
    }
}

final function Init(SwatGameInfo GameInfo)
{
    local int i;

    assert(GameInfo != None);
    Game = GameInfo;

    for (i=0; i<Procedures.length; ++i)
    {
        Procedures[i].Init(Game);
    }

    if(GameInfo.ShouldTrackCampaignStats()) {
      CampaignStatTracking = new(None, "SwatProcedures.StatTracker", 0) StatTrackerClass;
      CampaignStatTracking.Init(Game);
    }
}

function bool ProceduresMaxed()
{
    local int i;

    for( i = 0; i < Procedures.Length; i++ )
    {
        if( !Procedures[i].IsMaxed() )
            return false;
    }

    return true;
}
