// ====================================================================
//  Class:  GUI.GUILinkButton
//
//	GUILinkButton - A button that leads someone to a web URL, optionally quitting the game
//
//  Written by eezstreet
//  (c) 2017, SWAT: Elite Force, Inc.  All Rights Reserved
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

class GUILinkButton extends GUIButton
    HideCategories(Menu, Object);

var(GUILinkButton) config string URL "The URL to go to";
var(GUILinkButton) config bool bQuitGame "Quit the game after this button has been clicked";

function InitComponent(GUIComponent MyOwner)
{
  Super.InitComponent(MyOwner);
  OnClick=InternalOnClick;
}

function InternalOnClick(GUIComponent Sender)
{
  PlayerOwner().ConsoleCommand("start "$URL);
  if(bQuitGame)
  {
    PlayerOwner().ConsoleCommand("quit");
  }
  else
  {
    PlayerOwner().ConsoleCommand("disconnect");
  }
}
