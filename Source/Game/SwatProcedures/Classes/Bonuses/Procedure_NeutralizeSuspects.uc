class Procedure_NeutralizeSuspects extends SwatGame.Procedure
    implements  IInterested_GameEvent_GameStarted
    abstract;

var config int TotalBonus;
var config float PerEnemyBonusFraction;     //this is the fraction of the per-enemy bonus received when an incapacitated enemy is arrested

var int TotalEnemies;
var float BonusPerEnemy;

var array<SwatEnemy> NeutralizedEnemies;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.GameStarted.Register(self);
}

//interface IInterested_GameEvent_GameStarted implementation
function OnGameStarted()
{
    local SwatGame.SwatEnemy Enemy;

    foreach GetGame().DynamicActors(class'SwatGame.SwatEnemy', Enemy)    //can't use collision hash because we want infinite radius
        TotalEnemies++;

    BonusPerEnemy = ( float(TotalBonus) / float(TotalEnemies) ) * PerEnemyBonusFraction;

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" calculated BonusPerEnemy = ( float(TotalBonus) / float(TotalEnemies) ) * PerEnemyBonusFraction\n"
            $"                          = ( "$TotalBonus$" / "$TotalEnemies$" ) * "$PerEnemyBonusFraction$"\n"
            $"                          = "$BonusPerEnemy);
}

function string Status()
{
    return NeutralizedEnemies.length $ "/" $ TotalEnemies;
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = BonusPerEnemy * NeutralizedEnemies.length\n"
            $"                           = "$BonusPerEnemy$" * "$NeutralizedEnemies.length$"\n"
            $"                           = "$BonusPerEnemy * NeutralizedEnemies.length$"\n"
            $"         AdditionalBonus() = "$AdditionalBonus());

    return  (BonusPerEnemy * NeutralizedEnemies.length) + AdditionalBonus();
}

function int AdditionalBonus()
{
    return 0;
}
