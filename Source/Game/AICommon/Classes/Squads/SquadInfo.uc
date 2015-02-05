//=====================================================================
// SquadInfo
//=====================================================================

class SquadInfo extends Engine.Actor
#if !IG_TRIBES3
	placeable
#endif
	native;

//=====================================================================
// Constants

#if IG_TRIBES3
const MAX_TICKS_TO_PROCESS_PAIN = 5;	// upper bound on the number of AI ticks it will take to react to pain
#endif

//=====================================================================
// Variables

#if IG_TRIBES3	// place for designers to put goals/abilities
var(AI) editinline array< class<Tyrion_GoalBase> > goals		"Goals the resource is trying to achieve";
var(AI)	editinline array< class<Tyrion_ActionBase> > abilities	"The actions this resource is capable of performing";
#endif

// AI resources - must be created by designers for AI characters
var Tyrion_ResourceBase SquadAI;

var array<Pawn> pawns;	// the pawns that make up this squad (not rooks in case SquadInfo gets moved into Engine for Boston)

var(AI) Tyrion_ResourceBase.AI_LOD_Levels AI_LOD_Level;	// AI Level of detail (LOD)

var float tickTime;				// when tickTime < 0, we tick the AI
var float tickTimeOrg;			// last generated tickTime value
var Range tickTimeUpdateRange;  // min and max time that will be used to make a random tickTime

var bool logTyrion;		// for debug: switch on Tyrion logs

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Called at start of gameplay
 
function PostBeginPlay()
{
#if IG_TRIBES3  //tcohen: added to stop warning about unreferenced local variable
	local int i;
#endif

 	squadAI = new class<Tyrion_ResourceBase>( DynamicLoadObject( "Tyrion.AI_SquadResource", class'Class'));
	squadAI.setResourceOwner( self );

#if IG_TRIBES3	// process designer-specified goals/abilities
	// Move designer-assigned goals and abilities (actions) to the resource
	for ( i = 0; i < goals.length; i++ )
	{
		squadAI.assignGoal( goals[i] );
	}

	for ( i = 0; i < abilities.length; i++ )
	{
		squadAI.assignAbility( abilities[i] );
	}
#endif
}

//---------------------------------------------------------------------
// a squad member was destroyed

function memberDestroyed( Pawn member )
{
	if ( class'Pawn'.static.checkAlive( member ))
		memberDied( member );	// so memberDied is called only once on pawns that die and are subsequently destroyed
}

//---------------------------------------------------------------------
// a squad member died

function memberDied( Pawn member, optional Pawn InstigatedBy, optional class<DamageType> damageType, optional vector HitLocation )
{
#if IG_TRIBES3
	local int i;
#endif

	// notify actions
	squadAI.pawnDied( member );

#if IG_TRIBES3
	for( i = 0; i < pawns.length; ++i )
	{
		if ( pawns[i] != member && class'Pawn'.static.checkAlive( pawns[i] ) )
		{
			pawns[i].setLimitedTimeLODActivation( MAX_TICKS_TO_PROCESS_PAIN );

			Level.AI_Setup.sendAllyDiedMessage( pawns[i], member, InstigatedBy, damageType, HitLocation );
		}
	}
#endif

	if ( !squadAI.isActive() )
	{
#if IG_TRIBES3
		dispatchMessage(new class'MessageSquadDeath'(label));
#endif
		cleanupAI();
	}
}

//---------------------------------------------------------------------
// cleanup AI when squad dead

function cleanupAI()
{
#if IG_TRIBES3
	local int i;

	// make sure the outer of any classes is no longer pointing to this (soon to be destroyed) actor
	for ( i = 0; i < goals.length; ++i )
	{
		level.AI_Setup.makeSafeOuter( self, goals[i] );
	}
#endif

	squadAI.cleanup();
	squadAI.deleteSensors();
	squadAI.deleteRemovedActions();
}

//---------------------------------------------------------------------
// Cause all resources attached to this pawn to re-check their goals

function rematchGoals()
{
	squadAI.bMatchGoals = true;
}

//---------------------------------------------------------------------
// number of living members in the squad
// (returns the first living pawn in the pawn list if there is one)

function int nActiveMembers( out Pawn livingPawn )
{
	local int i;
	local int n;

	// loop over all pawns p in the squad
	for ( i = pawns.length-1; i >= 0 ; --i )
		if ( class'Pawn'.static.checkAlive( pawns[i] ) )
		{
			livingPawn = pawns[i];
			n++;
		}

	return n;
}

//---------------------------------------------------------------------
// Add a pawn to this squad

function addToSquad( Pawn p )
{
	local int i;

	for ( i = 0; i < pawns.length; i++ )
		if ( pawns[i] == p )
			return;					// p already in the list

	pawns[pawns.length] = p;		// pawns.push(p)
}

//---------------------------------------------------------------------
// Remove a pawn from this squad

function removeFromSquad( Pawn p )
{
	local int i;

	for ( i = 0; i < pawns.length; i++ )
		if ( pawns[i] == p )
		{
			pawns.remove( i, 1 );	// removes element - shifts the rest
			break;
		}
}

//=====================================================================

defaultproperties
{
	logTyrion					= false
	bHidden						= true
	AI_LOD_Level				= AILOD_ALWAYS_ON
	tickTimeUpdateRange			= (Min=0.095,Max=0.105)
}