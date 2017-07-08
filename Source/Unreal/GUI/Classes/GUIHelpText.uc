// ====================================================================
//  Class:  GUI.GUIHelpText
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

class GUIHelpText extends GUILabel
    HideCategories(Menu,Object)
	Native;

cpptext
{
		void PreDraw(UCanvas* Canvas);
	void UpdateComponent(UCanvas* Canvas);
}

var(GUIHelpText) config		float	XOverlapPercent "The percentage of the ActiveControl to overlap by this label";
var(GUIHelpText) config		float	YOverlapPercent "The percentage of the ActiveControl to overlap by this label";
var(GUIHelpText) config		float	XBorderPercent "The percentage of border around the text (typically in the range 1.0 - 1.5)";
var(GUIHelpText) config		float	YBorderPercent "The percentage of border around the text (typically in the range 1.0 - 1.5)";
var(GUIHelpText) config		float	MaxWidth "The maximum width of the label, if exceded, will word wrap";

function InitComponent(GUIComponent Owner)
{
    Super.InitComponent(Owner);
}

defaultproperties
{
	TextAlign=TXTA_Center
    RenderWeight=0.8
    XOverlapPercent=0.2
    YOverlapPercent=0.2
    XBorderPercent=1.1
    YBorderPercent=1.2
    MaxWidth=160.0
}