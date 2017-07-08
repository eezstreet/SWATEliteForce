//
//  TMC
//
//  Please Note: This class is now defunct.
//
//  While there may still be some references to it, the Equipment class
//  replaces Inventory in the SWAT codebase.
//

//=============================================================================
// Inventory
//
// Inventory is the parent class of all actors that can be carried by other actors.  
// Inventory items are placed in the holding actor's inventory chain, a linked list 
// of inventory actors.  Each inventory class knows what pickup can spawn it (its 
// PickupClass).  When tossed out (using the DropFrom() function), inventory items 
// replace themselves with an actor of their Pickup class.
//
//=============================================================================
class Inventory extends Actor
	abstract
	native
	nativereplication;

//-----------------------------------------------------------------------------

var	 byte			InventoryGroup;     // The weapon/inventory set, 0-9.
var	 byte			GroupOffset;		// position within inventory group. (used by prevweapon and nextweapon) 				
var	 bool	 		bDisplayableInv;	// Item displayed in HUD.
#if !IG_SWAT // ckline: we don't support this
var	 bool			bTossedOut;			// true if weapon/inventory was tossed out (so players can't cheat w/ weaponstay)
var	 class<Pickup>  PickupClass;		// what class of pickup is associated with this inventory item
var() travel int	Charge;				// Charge (for example, armor remaining if an armor)
#endif

//-----------------------------------------------------------------------------
// Rendering information.

// Player view rendering info.
var(FirstPerson)	 vector      PlayerViewOffset;   // Offset from view center.
var(FirstPerson)    rotator     PlayerViewPivot;    // additive rotation offset for tweaks
var() bool bDrawingFirstPerson;
var	 float		 BobDamping;		 // how much to damp view bob

#if !IG_SWAT // ckline: we don't support this
// 3rd person mesh.
var actor 	ThirdPersonActor;
var class<InventoryAttachment> AttachmentClass;
#endif

//-----------------------------------------------------------------------------
// HUD graphics.

#if !IG_SWAT // ckline: we don't support this
var	 Material Icon;
var	 Material StatusIcon;         // Icon used with ammo/charge/power count on HUD.
#endif
var	 localized string	 ItemName;

// Network replication.
replication
{
	// Things the server should send to the client.
#if !IG_SWAT // ckline: we don't support this
	reliable if( bNetOwner && bNetDirty && (Role==ROLE_Authority) )
		Charge,ThirdPersonActor;
#endif
}

#if !IG_SWAT // ckline: we don't support this
simulated function AttachToPawn(Pawn P)
{
	local name BoneName;

	if ( ThirdPersonActor == None )
	{
		ThirdPersonActor = Spawn(AttachmentClass,Owner);
		InventoryAttachment(ThirdPersonActor).InitFor(self);
	}
    //TMC removed
	//BoneName = P.GetWeaponBoneFor(self);
	if ( BoneName == '' )
	{
		ThirdPersonActor.SetLocation(P.Location);
		ThirdPersonActor.SetBase(P);
	}
	else
		P.AttachToBone(ThirdPersonActor,BoneName);
}
#endif

/* UpdateRelative()
For tweaking weapon positioning.  Pass in a new relativerotation, and use the weapon editactor
properties sheet to modify the relativelocation
*/
exec function updaterelative(int pitch, int yaw, int roll)
{
	local rotator NewRot;

	NewRot.Pitch = pitch;
	NewRot.Yaw = yaw;
	NewRot.Roll = roll;
#if !IG_SWAT // ckline: we don't support this
	ThirdPersonActor.SetRelativeLocation(ThirdPersonActor.Default.RelativeLocation);
	ThirdPersonActor.SetRelativeRotation(NewRot);
#endif
}

#if !IG_SWAT // ckline: we don't support this
simulated function DetachFromPawn(Pawn P)
{
	if ( ThirdPersonActor != None )
	{
		ThirdPersonActor.Destroy();
		ThirdPersonActor = None;
	}
}
#endif

simulated function String GetHumanReadableName()
{
	if ( ItemName == "" )
		ItemName = GetItemName(string(Class));

	return ItemName;
}

#if !IG_SWAT // ckline: we don't support this
function PickupFunction(Pawn Other);
#endif

//=============================================================================
// AI inventory functions.
simulated function Weapon RecommendWeapon( out float rating )
{
	if ( inventory != None )
		return inventory.RecommendWeapon(rating);
	else
	{
		rating = -1;
		return None;
	}
}

//=============================================================================
// Inventory travelling across servers.

//
// Called after a travelling inventory item has been accepted into a level.
//
event TravelPreAccept()
{
	Super.TravelPreAccept();
	GiveTo( Pawn(Owner) );
}

function TravelPostAccept()
{
	Super.TravelPostAccept();
#if !IG_SWAT // ckline: we don't support this
	PickupFunction(Pawn(Owner));
#endif
}

//=============================================================================
// General inventory functions.

//
// Called by engine when destroyed.
//
function Destroyed()
{
	// Remove from owner's inventory.
    //TMC removed
//	if( Pawn(Owner)!=None )
//		Pawn(Owner).DeleteInventory( Self );
#if !IG_SWAT // ckline: we don't support this
	if ( ThirdPersonActor != None )
		ThirdPersonActor.Destroy();
#endif
}

//
// Give this inventory item to a pawn.
//
function GiveTo( pawn Other )
{
    //TMC removed Epic's Weapon or Inventory code here - removed function body.
    assert(false);
}

#if !IG_SWAT // ckline: we don't support this
//
// Function which lets existing items in a pawn's inventory
// prevent the pawn from picking something up. Return true to abort pickup
// or if item handles pickup, otherwise keep going through inventory list.
//
function bool HandlePickupQuery( pickup Item )
{
	if ( Item.InventoryType == Class )
		return true;
	if ( Inventory == None )
		return false;

	return Inventory.HandlePickupQuery(Item);
}
#endif

#if !IG_SWAT // ckline: we don't support this
//
// Select first activatable powerup.
//
function Powerups SelectNext()
{
	if ( Inventory != None )
		return Inventory.SelectNext();
	else
		return None;
}
#endif

#if !IG_SWAT // ckline: we don't support this
//
// Toss this item out.
//
function DropFrom(vector StartLocation)
{
	local Pickup P;

	if ( Instigator != None )
	{
		DetachFromPawn(Instigator);	
        //TMC removed
		//Instigator.DeleteInventory(self);
	}	
	SetDefaultDisplayProperties();
	Instigator = None;
	StopAnimating();
	GotoState('');

	P = spawn(PickupClass,,,StartLocation);
	if ( P == None )
	{
		destroy();
		return;
	}
	P.InitDroppedPickupFor(self);
	P.Velocity = Velocity;
	Velocity = vect(0,0,0);
}
#endif

//=============================================================================
// Using.

function Use( float Value );

//=============================================================================
// Weapon functions.

// Find a weapon in inventory that has an Inventory Group matching F.

simulated function Weapon WeaponChange( byte F, bool bSilent )
{
	if( Inventory == None)
		return None;
	else
		return Inventory.WeaponChange( F, bSilent );
}

// Find the previous weapon (using the Inventory group)
simulated function Weapon PrevWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
	if ( Inventory == None )
		return CurrentChoice;
	else
		return Inventory.PrevWeapon(CurrentChoice,CurrentWeapon);
}

// Find the next weapon (using the Inventory group)
simulated function Weapon NextWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
	if ( Inventory == None )
		return CurrentChoice;
	else
		return Inventory.NextWeapon(CurrentChoice,CurrentWeapon);
}

//=============================================================================
// Armor functions.

#if !IG_SWAT // ckline: we don't support this
//
// Return the best armor to use.
//
function armor PrioritizeArmor( int Damage, class<DamageType> DamageType, vector HitLocation )
{
	local Armor FirstArmor;

	if ( Inventory != None )
		FirstArmor = Inventory.PrioritizeArmor(Damage, DamageType, HitLocation);
	else
		FirstArmor = None;

	return FirstArmor;
}
#endif

//
// Used to inform inventory when owner event occurs (for example jumping or weapon change)
//
function OwnerEvent(name EventName)
{
	if( Inventory != None )
		Inventory.OwnerEvent(EventName);
}

// used to ask inventory if it needs to affect its owners display properties
function SetOwnerDisplay()
{
	if( Inventory != None )
		Inventory.SetOwnerDisplay();
}

static function string StaticItemName()
{
	return Default.ItemName;
}


defaultproperties
{
	bOnlyDirtyReplication=true
	bOnlyRelevantToOwner=true
//#if !IG_SWAT // ckline: we don't support this
//	AttachmentClass=class'InventoryAttachment'
//#endif
     BobDamping=0.960000
     bTravel=True
     DrawType=DT_None
     AmbientGlow=0
     RemoteRole=ROLE_SimulatedProxy
	 NetPriority=1.4
	 bOnlyOwnerSee=true
	 bHidden=true
	 bClientAnim=true
	 Physics=PHYS_None
	 bReplicateMovement=false
	 bAcceptsProjectors=True
     bDrawingFirstPerson=false
}

