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

class GUILightContainer extends GUIActorContainerBase
		;

import enum ELightType from Engine.Actor;
import enum ELightEffect from Engine.Actor;

var(GUIActor) config Class<Light> ActorClass "The actual class of the actor to spawn for this container"; 

var(GUIActor) config ELightType LightType;
var(GUIActor) config ELightEffect LightEffect;
var(GUIActor) config float LightBrightness;
var(GUIActor) config float LightRadius;
var(GUIActor) config byte  LightHue, LightSaturation;
var(GUIActor) config bool bDoNotApproximateBumpmap;
var(GUIActor) config bool bSpecialLit "Only affects special-lit surfaces.";
var(GUIActor) config bool bIsSpotlight "Will act as pointlight instead";


function SpawnActor()
{
    if( Actor != None && Actor.Class == ActorClass && Actor.Tag == ActorName )
        return;
    Actor = PlayerOwner().Spawn(ActorClass,,ActorName);
}

event OnModify()
{
    if( Actor == None )
        return;

    Actor.bSpecialLit=bSpecialLit;
    Actor.bDoNotApproximateBumpmap=bDoNotApproximateBumpmap;
    Actor.LightHue=LightHue;
    Actor.LightSaturation=LightSaturation;
    Actor.LightRadius=LightRadius;
    Actor.LightBrightness=LightBrightness;
    Actor.LightEffect=LightEffect;
    Actor.LightType=LightType;
    Actor.bDirectional=bIsSpotlight;

    Super.OnModify();
}

defaultproperties
{
	OnDraw=InternalOnDraw
}
