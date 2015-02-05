class Reaction_KillAllMySounds extends Reaction;

protected simulated function Execute(Actor Owner, Actor Other)
{
    SoundEffectsSubsystem(EffectsSystem(Owner.Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).StopMySchemas(Owner);
}
