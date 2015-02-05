// ====================================================================
//  Class:  GUI.GUIVertGripButton
//
//  Written by Joe Wilcox
//  (c) 2002, Epic Games, Inc.  All Rights Reserved
// ====================================================================

class GUIVertGripButton extends GUIGFXButton
		Native;

var(GUIVertGripButton) config  Material	GripButtonImage "Image to use for a grip button";

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	Graphic = GripButtonImage;
}


defaultproperties
{
	StyleName="STY_VertGrip"
	Position=ICP_Bound
	bNeverFocus=true
	bCaptureMouse=true	
	OnClickSound=CS_None
	GripButtonImage=Texture'gui_tex.White'
}
