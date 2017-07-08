/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUIProgressBar extends GUIComponent
        HideCategories(Menu,Object)
	Native;

cpptext
{
	void Draw(UCanvas* Canvas);
}


var(GUIProgressBar) config  Material	        BarMaterial "The material of the filled portion of the bar";
var(GUIProgressBar) config  Color		        BarColor "The Color of the filled portion of the bar";
var(GUIProgressBar) config  EMenuRenderStyle	BarRenderStyle "How should we display this image";
var(GUIProgressBar) config  float		        Value "The current percent filled value (clamped 0-1)";
var(GUIProgressBar) config  eProgressDirection  BarDirection "The direction to fill the bar";

defaultproperties
{
	BarColor=(R=255,G=255,B=255,A=255)
	BarRenderStyle=MSTY_Alpha
	Value=1.0
	BarDirection=DIRECTION_LeftToRight
	StyleName="STY_ProgressBar"
	BarMaterial=texture'gui_tex.white'
}