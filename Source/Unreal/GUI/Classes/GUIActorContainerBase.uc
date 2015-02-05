// ====================================================================
//  Class:  GUI.GUIActorContainerBase
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

class GUIActorContainerBase extends GUIComponent
        HideCategories(Menu,Object)
        native
        abstract
		;

cpptext
{
    virtual void Modify() { eventOnModify(); Super::Modify(); } //callback from the object browser
}

import enum EDrawType from Engine.Actor;

var(GUIActor) config Name ActorName "The Name of the actor to spawn for this container (will load from the config section corresponding to this name && trigger any scripted sequences based off this name)"; 
var(GUIActor) EditConst EditInline Actor Actor "The actor that this container refers to"; 
var(GUIActor) config vector Offset "The positional offset for this Actor";

var(GUIActor) config rotator Rotation "Rotation.";
var(GUIActor) config EDrawType DrawType;
var(GUIActor) config Material		Texture "Sprite texture.if DrawType=DT_Sprite";


function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

function SpawnActor(); //must be implemented by subclasses

event Show()
{
//log("[dkaplan] Showing: "$self);
    SpawnActor();
    OnModify();
    
    Super.Show();
}

event Hide()
{
//log("[dkaplan] Hiding: "$self);
    if( Actor != None && !Actor.bDeleteMe )
    {
        Actor.destroy();
        Actor = None; // explicitly remove this reference to the actor
    }
    
    Super.Hide();
}

function bool InternalOnDraw(Canvas canvas)
{
    Canvas.DrawActor(Actor, false, true, PlayerOwner().FOVAngle );
	return true;
}


event OnChangeLayout()
{
    PositionActor();
    Super.OnChangeLayout();
}

protected function PositionActor()	
{
    local float extraOffY, extraOffZ;
    local float translatedX, translatedY, translatedZ;
    local vector CamPos, X, Y, Z;
	local rotator CamRot;
    
    if( Actor == None )
        return;
        
    translatedX = Offset.X;
    translatedY = Offset.Y;
    translatedZ = Offset.Z;

    Controller.CenterOfControl( self, extraOffY, extraOffZ );
    translatedY += extraOffY;
    translatedZ += extraOffZ;
    
    translatedY = ((translatedY-Controller.ResolutionX/2)/float(Controller.ResolutionX))*Controller.GUI_TO_WORLD_X;
    translatedZ = ((Controller.ResolutionY/2-translatedZ)/float(Controller.ResolutionY))*Controller.GUI_TO_WORLD_Y;

	CamRot = PlayerOwner().Rotation;
	CamPos = PlayerOwner().Location;	
	GetAxes(CamRot, X, Y, Z);

	Actor.SetLocation(CamPos + ((translatedX * X) + (translatedY * Y) + (translatedZ * Z)));
}

event OnModify()
{
    if( Actor == None )
        return;

    Actor.Texture=Texture;
    if( Actor.Rotation != Rotation )
        Actor.SetRotation(Rotation);
	if( Actor.DrawType != DrawType )
    	Actor.SetDrawType(DrawType);
    
    PositionActor();
}

function SaveLayout(bool FlushToDisk)
{
    //Actor.SaveConfig(string(Actor.tag));
        
    Super.SaveLayout( FlushToDisk );
}

defaultproperties
{
	bCaptureMouse=False
	bNeverFocus=true
    offset=(X=80.000000,Y=0.000000,Z=0.000000)
    bAcceptsInput=false
}
