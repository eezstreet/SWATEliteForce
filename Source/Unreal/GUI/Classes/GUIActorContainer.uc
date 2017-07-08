// ====================================================================
//  Class:  GUI.GUIActorContainer
//
//	GUIActorContainer - The container for actors in the gui
// ====================================================================
/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIActorContainer extends GUIActorContainerBase
		;


var(GUIActor) config Class<Actor> ActorClass "The actual class of the actor to spawn for this container"; 
var(GUIActor) config float ScaleFactor "The size offset for this Actor";

var(GUIActor) config StaticMesh StaticMesh "StaticMesh if DrawType=DT_StaticMesh";
var(GUIActor) config mesh		Mesh "Mesh if DrawType=DT_Mesh.";
var(GUIActor) config float	DrawScale "Scaling factor, 1.0=normal size.";
var(GUIActor) config vector	DrawScale3D "Scaling vector, (1.0,1.0,1.0)=normal size.";
var(GUIActor) config array<Material> Skins "Multiple skin support - not replicated.";
var(GUIActor) config bool bUnlit "Lights don't affect actor.";
var(GUIActor) config rotator RotationRate "Change in rotation per second.";
var(GUIActor) config bool    bHighDetail "Only show up in high or super high detail mode.";
var(GUIActor) config bool	bSuperHighDetail "Only show up in super high detail mode.";


function SpawnActor()
{
    if( Actor != None && Actor.Class == ActorClass && Actor.Tag == ActorName )
        return;
    Actor = PlayerOwner().Spawn(ActorClass,,ActorName);
    Actor.bHidden = false;
}

event OnModify()
{
    if( Actor == None )
        return;

    Actor.Skins=Skins;
    Actor.bUnlit=bUnlit;
    Actor.RotationRate=RotationRate;
    Actor.bHighDetail=bHighDetail;
    Actor.bSuperHighDetail=bSuperHighDetail;

    if( Actor.Mesh != Mesh && Mesh != None )
    	Actor.LinkMesh( Mesh );
	if( Actor.StaticMesh != StaticMesh && StaticMesh != None)
        Actor.SetStaticMesh( StaticMesh );

    Super.OnModify();
}

protected function PositionActor()	
{
    local float extraSize;
    
    extraSize = 1.0;
    Controller.SizeOfControl( self, extraSize ); 
    extraSize *= ScaleFactor;  
  	Actor.SetDrawScale( Actor.default.DrawScale*extraSize );    
	Actor.SetDrawScale3D( Actor.default.DrawScale3D*extraSize );

    Super.PositionActor();
}

defaultproperties
{
    ScaleFactor=3.5
	OnDraw=InternalOnDraw
}
