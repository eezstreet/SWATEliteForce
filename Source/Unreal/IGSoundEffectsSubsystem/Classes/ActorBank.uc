class ActorBank extends Engine.Actor
    native;

// =============================================================================
//  ActorBank
//   
//  An actor bank allows you to deposit and withdraw actors, allowing you to pool 
//  them to save on the costs of creating and deleting actors constantly.  Depositing
//  the actor will by default cause the actor to disappear, and stop ticking, making
//  it fairly low cost.  The only real cost of a deposited actor will be that it takes
//  up a spot in the actor list.  When an actor is withdrawn, it will reappear by 
//  default, and be removed from the banked actors list.  What happens to the actor
//  when deposited or withdrawn is handled by a delegate, so clients of this class 
//  can override the behaviour to do whatever was necessary.  The default behavior 
//  is simply to show and hide them respectively.
//
//  Note: Initialize MUST be called before being able to use this ActorBank
//
// ==============================================================================

var private array<Actor>        BankedActors;       // fifo list of banked actors
var private class<Actor>        ActorClassType;     // Class type for banked actors
var private bool                bInitialized;       // True if initialized

// carlos: set this to 1 to debug actor bank deposits/withdrawls
#define BANK_DEBUG 0

// Overridable delegate for withdrawn behavior 
delegate OnWithdrawn(Actor inActorWithdrawn)
{
    inActorWithdrawn.OptimizeIn();
}

// Overridable delegate for deposited behavior 
delegate OnDeposited(Actor inActorDeposited)
{
    inActorDeposited.OptimizeOut();
}

// Initialize this actor bank, Note: This MUST be called before using this actor bank.
simulated function Initialize(class<Actor> inClassType)
{
    ActorClassType = inClassType;
    bInitialized = true;
}

// Withdraw an actor from the bank.  If there are no actors in the banked list, it will create a 
// new one.  Wish real banks were that generous.
simulated event Actor Withdraw()
{
    local Actor WithdrawnActor; 

    assertWithDescription(bInitialized, "You MUST call Initialize before using an ActorBank.");

    if (BankedActors.Length > 0)
    {
        WithdrawnActor = BankedActors[0];
        BankedActors.Remove(0,1);
    }  
    else 
    {
        WithdrawnActor = Spawn(ActorClassType);
#if BANK_DEBUG
        log( "New actor "$WithdrawnActor$" created during soundeffects subsystem ActorBank withdrawl!" );
#endif
    }
    
#if BANK_DEBUG 
    log( "Actor "$WithdrawnActor$" withdrawn, Number of actors in Bank: "$BankedActors.Length );
#endif 
    OnWithdrawn(WithdrawnActor);
    return WithdrawnActor;
}

// Deposit and actor into the banked list.  
simulated event Deposit(Actor inActor)
{
    local int ct;

    assertWithDescription(bInitialized, "You MUST call Initialize before using an ActorBank.");
    assertWithDescription(inActor.IsA(ActorClassType.Name), "You can only deposit actors of class "$ActorClassType$", you're trying to deposit a "$inActor.Class);

    // Only deposit unique entries, script dynamic arrays don't have the AddUniqueItem exposed
    for ( ct = 0; ct < BankedActors.Length; ++ct )
    {
        if ( inActor == BankedActors[ct] )
        {
            return;
        }
    }

    // Add to the end 
    BankedActors[BankedActors.Length] = inActor;
#if BANK_DEBUG
    log( "Actor "$inActor$" deposited, Number of actors in Bank: "$BankedActors.Length );
#endif
    OnDeposited(inActor);
}

defaultproperties
{
    bHidden=true
    bStasis=true
    bCollideActors=false
    bCollideWorld=false
}
