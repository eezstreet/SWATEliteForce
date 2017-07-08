/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUITimeline extends GUIMultiComponent
        HideCategories(Menu,Object)
	Native;

cpptext
{
	void Draw(UCanvas* Canvas);
}

var(GUITimeline) config  Material	        BarMaterial "The material of the filled portion of the bar";
var(GUITimeline) config  Color		        BarColor "The Color of the filled portion of the bar";
var(GUITimeline) config  EMenuRenderStyle	BarRenderStyle "How should we display this image";
var(GUITimeline) config  float              BarHeight "Height of the bar";

var(GUITimeline) config  Material	        SelectedPlotMaterial "The material for the selected plot point";
var(GUITimeline) config  Color		        SelectedPlotColor "The Color of the filled portion of the bar";
var(GUITimeline) config  EMenuRenderStyle	SelectedPlotRenderStyle "How should we display this image";
var(GUITimeline) config  float              SelectedPlotHeight "Height of the selected plot";
var(GUITimeline) config  float              SelectedPlotThickness "Thickness of the selected plot";

var(GUITimeline) config  Material	        UnSelectedPlotMaterial "The material for the un-selected plot points";
var(GUITimeline) config  Color		        UnSelectedPlotColor "The Color of the filled portion of the bar";
var(GUITimeline) config  EMenuRenderStyle	UnSelectedPlotRenderStyle "How should we display this image";
var(GUITimeline) config  float              UnSelectedPlotHeight "Height of the un-selected plot";
var(GUITimeline) config  float              UnSelectedPlotThickness "Thickness of the un-selected plot";

var(GUITimeline) config array<int> TimePlots;
var(GUITimeline) config int SelectedPlot;

function AddTimePlot( int i )
{
    TimePlots[TimePlots.Length] = i;
}

function ClearPlot()
{
    TimePlots.Remove( 0, TimePlots.Length );
}

function SelectPlot( int i )
{
    if( i >= TimePlots.Length )
        SelectedPlot = TimePlots.Length - 1;
    else if( i < 0 )
        SelectedPlot = 0;
    else
        SelectedPlot = i;
}

defaultproperties
{
	StyleName="STY_ProgressBar"
	
	BarMaterial=texture'gui_tex.white'
	BarColor=(R=255,G=255,B=255,A=255)
	BarRenderStyle=MSTY_Alpha
	BarHeight=0.2

	SelectedPlotMaterial=texture'gui_tex.white'
	SelectedPlotColor=(R=255,G=255,B=255,A=255)
	SelectedPlotRenderStyle=MSTY_Alpha
	SelectedPlotHeight=1.0
    SelectedPlotThickness=0.02
    
	UnSelectedPlotMaterial=texture'gui_tex.white'
	UnSelectedPlotColor=(R=150,G=150,B=150,A=255)
	UnSelectedPlotRenderStyle=MSTY_Alpha
	UnSelectedPlotHeight=0.8
    UnSelectedPlotThickness=0.01
}