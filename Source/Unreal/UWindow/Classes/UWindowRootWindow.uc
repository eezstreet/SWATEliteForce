//=============================================================================
// UWindowRootWindow - the root window.
//
// This Window should be subclassed for each different type of menuing system.
// In many cases, there should be at least 1 UWindowRootWindow that contains 
// at the very least the console.
//=============================================================================
class UWindowRootWindow extends UWindowWindow;

var UWindowWindow		MouseWindow;		// The window the mouse is over
var bool				bMouseCapture;
var float				OldMouseX, OldMouseY;
var UWindowWindow		FocusedWindow;
var UWindowWindow		KeyFocusWindow;		// window with keyboard focus
var MouseCursor			NormalCursor, MoveCursor, DiagCursor1, HandCursor, HSplitCursor, VSplitCursor, DiagCursor2, NSCursor, WECursor, WaitCursor;
var bool				bQuickKeyEnable;
var UWindowHotkeyWindowList	HotkeyWindows;
var config float		GUIScale;
var float				RealWidth, RealHeight;
var Font				Fonts[10];
var UWindowLookAndFeel	LooksAndFeels[20];
var config string		LookAndFeelClass;
var bool				bRequestQuit;
var float				QuitTime;
var bool				bAllowConsole;

var config float		MouseScale;
var float				MouseX;
var float				MouseY;

var float				OldClipX;
var float				OldClipY;

// Define the console that will be given to each local player

var class<UWindowConsoleWindow> ConsoleClass;
var UWindowConsoleWindow ConsoleWindow;				

// Define the Menubar that will be given to each local player

function BeginPlay() 
{
	Root = Self;
	MouseWindow = Self;
	KeyFocusWindow = Self;
}

function UWindowLookAndFeel GetLookAndFeel(String LFClassName)
{
	local int i;
	local class<UWindowLookAndFeel> LFClass;

	LFClass = class<UWindowLookAndFeel>(DynamicLoadObject(LFClassName, class'Class'));

	for(i=0;i<20;i++)
	{
		if(LooksAndFeels[i] == None)
		{
			LooksAndFeels[i] = new LFClass;
			LooksAndFeels[i].Setup();
			return LooksAndFeels[i];
		}

		if(LooksAndFeels[i].Class == LFClass)
			return LooksAndFeels[i];
	}
	Log("Out of LookAndFeel array space!!");
	return None;
}


function Created() 
{
	LookAndFeel = GetLookAndFeel(LookAndFeelClass);
	SetupFonts();

	NormalCursor.tex = Texture'UWindow_res.MouseCursor';
	NormalCursor.HotX = 0;
	NormalCursor.HotY = 0;
	NormalCursor.WindowsCursor = ViewportOwner.IDC_ARROW;

	MoveCursor.tex = Texture'UWindow_res.MouseMove';
	MoveCursor.HotX = 8;
	MoveCursor.HotY = 8;
	MoveCursor.WindowsCursor = ViewportOwner.IDC_SIZEALL;
	
	DiagCursor1.tex = Texture'UWindow_res.MouseDiag1';
	DiagCursor1.HotX = 8;
	DiagCursor1.HotY = 8;
	DiagCursor1.WindowsCursor = ViewportOwner.IDC_SIZENWSE;
	
	HandCursor.tex = Texture'UWindow_res.MouseHand';
	HandCursor.HotX = 11;
	HandCursor.HotY = 1;
	HandCursor.WindowsCursor = ViewportOwner.IDC_ARROW;

	HSplitCursor.tex = Texture'UWindow_res.MouseHSplit';
	HSplitCursor.HotX = 9;
	HSplitCursor.HotY = 9;
	HSplitCursor.WindowsCursor = ViewportOwner.IDC_SIZEWE;

	VSplitCursor.tex = Texture'UWindow_res.MouseVSplit';
	VSplitCursor.HotX = 9;
	VSplitCursor.HotY = 9;
	VSplitCursor.WindowsCursor = ViewportOwner.IDC_SIZENS;

	DiagCursor2.tex = Texture'UWindow_res.MouseDiag2';
	DiagCursor2.HotX = 7;
	DiagCursor2.HotY = 7;
	DiagCursor2.WindowsCursor = ViewportOwner.IDC_SIZENESW;

	NSCursor.tex = Texture'UWindow_res.MouseNS';
	NSCursor.HotX = 3;
	NSCursor.HotY = 7;
	NSCursor.WindowsCursor = ViewportOwner.IDC_SIZENS;

	WECursor.tex = Texture'UWindow_res.MouseWE';
	WECursor.HotX = 7;
	WECursor.HotY = 3;
	WECursor.WindowsCursor = ViewportOwner.IDC_SIZEWE;

	WaitCursor.tex = Texture'UWindow_res.MouseWait';
	WECursor.HotX = 6;
	WECursor.HotY = 9;
	WECursor.WindowsCursor = ViewportOwner.IDC_WAIT;


	HotkeyWindows = New class'UWindowHotkeyWindowList';
	HotkeyWindows.Last = HotkeyWindows;
	HotkeyWindows.Next = None;
	HotkeyWindows.Sentinel = HotkeyWindows;

	Cursor = NormalCursor;
	
	if (ConsoleClass != None)
	{
		ConsoleWindow = UWindowConsoleWindow(CreateWindow(ConsoleClass, 100, 100, 200, 200));
		ConsoleWindow.HideWindow();
	}	
	
}

function MoveMouse(float X, float Y)
{
	local UWindowWindow NewMouseWindow;
	local float tx, ty;

	MouseX = X;
	MouseY = Y;

	if(!bMouseCapture)
		NewMouseWindow = FindWindowUnder(X, Y);
	else
		NewMouseWindow = MouseWindow;

	if(NewMouseWindow != MouseWindow)
	{
		MouseWindow.MouseLeave();
		NewMouseWindow.MouseEnter();
		MouseWindow = NewMouseWindow;
	}

	if(MouseX != OldMouseX || MouseY != OldMouseY)
	{
		OldMouseX = MouseX;
		OldMouseY = MouseY;

		MouseWindow.GetMouseXY(tx, ty);
		MouseWindow.MouseMove(tx, ty);
	}
}

function DrawMouse(Canvas C) 
{
	if(ViewportOwner.bWindowsMouseAvailable)
	{
		// Set the windows cursor...
		ViewportOwner.SelectedCursor = MouseWindow.Cursor.WindowsCursor;
	}
	else
	{
		C.DrawColor.R = 255;
		C.DrawColor.G = 255;
		C.DrawColor.B = 255;
		C.bNoSmooth = True;
		C.Style=2;
		C.SetPos(MouseX * GUIScale - MouseWindow.Cursor.HotX, MouseY * GUIScale - MouseWindow.Cursor.HotY);
		C.DrawIcon(MouseWindow.Cursor.tex, 1.0);
		C.Style=1;
	}

	/* DEBUG - show which window mouse is over

	MouseWindow.GetMouseXY(X, Y);
	C.Font = Fonts[F_Normal];

	C.DrawColor.R = 0;
	C.DrawColor.G = 0;
	C.DrawColor.B = 0;
	C.SetPos(MouseX * GUIScale - MouseWindow.Cursor.HotX, MouseY * GUIScale - MouseWindow.Cursor.HotY);
	C.DrawText( GetPlayerOwner().GetItemName(string(MouseWindow))$" "$int(MouseX * GUIScale)$", "$int(MouseY * GUIScale)$" ("$int(X)$", "$int(Y)$")");

	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 0;
	C.SetPos(-1 + MouseX * GUIScale - MouseWindow.Cursor.HotX, -1 + MouseY * GUIScale - MouseWindow.Cursor.HotY);
	C.DrawText( GetPlayerOwner().GetItemName(string(MouseWindow))$" "$int(MouseX * GUIScale)$", "$int(MouseY * GUIScale)$" ("$int(X)$", "$int(Y)$")");

	*/
}

function bool CheckCaptureMouseUp()
{
	local float X, Y;

	if(bMouseCapture) {
		MouseWindow.GetMouseXY(X, Y);
		MouseWindow.LMouseUp(X, Y);
		bMouseCapture = False;
		return True;
	}
	return False;
}

function bool CheckCaptureMouseDown()
{
	local float X, Y;

	if(bMouseCapture) {
		MouseWindow.GetMouseXY(X, Y);
		MouseWindow.LMouseDown(X, Y);
		bMouseCapture = False;
		return True;
	}
	return False;
}


function CancelCapture()
{
	bMouseCapture = False;
}


function CaptureMouse(optional UWindowWindow W)
{
	bMouseCapture = True;
	if(W != None)
		MouseWindow = W;
	//Log(MouseWindow.Class$": Captured Mouse");
}

function Texture GetLookAndFeelTexture()
{
	Return LookAndFeel.Active;
}

function bool IsActive()
{
	Return True;
}

function AddHotkeyWindow(UWindowWindow W)
{
//	Log("Adding hotkeys for "$W);
	UWindowHotkeyWindowList(HotkeyWindows.Insert(class'UWindowHotkeyWindowList')).Window = W;
}

function RemoveHotkeyWindow(UWindowWindow W)
{
	local UWindowHotkeyWindowList L;

//	Log("Removing hotkeys for "$W);

	L = HotkeyWindows.FindWindow(W);
	if(L != None)
		L.Remove();
}


function WindowEvent(WinMessage Msg, Canvas C, float X, float Y, int Key) 
{
	switch(Msg) {
	case WM_KeyDown:
		if(HotKeyDown(Key, X, Y))
			return;
		break;
	case WM_KeyUp:
		if(HotKeyUp(Key, X, Y))
			return;
		break;
	}
	
	Super.WindowEvent(Msg, C, X, Y, Key);
}


function bool HotKeyDown(int Key, float X, float Y)
{
	local UWindowHotkeyWindowList l;

	l = UWindowHotkeyWindowList(HotkeyWindows.Next);
	while(l != None) 
	{
		if(l.Window != Self && l.Window.HotKeyDown(Key, X, Y)) return True;
		l = UWindowHotkeyWindowList(l.Next);
	}

	return False;
}

function bool HotKeyUp(int Key, float X, float Y)
{
	local UWindowHotkeyWindowList l;

	l = UWindowHotkeyWindowList(HotkeyWindows.Next);
	while(l != None) 
	{
		if(l.Window != Self && l.Window.HotKeyUp(Key, X, Y)) return True;
		l = UWindowHotkeyWindowList(l.Next);
	}

	return False;
}

function CloseActiveWindow()
{
	if(ActiveWindow != None)
		ActiveWindow.EscClose();
}

function Resized()
{
	ResolutionChanged(WinWidth, WinHeight);
}

function SetScale(float NewScale)
{
	WinWidth = RealWidth / NewScale;
	WinHeight = RealHeight / NewScale;

	GUIScale = NewScale;

	ClippingRegion.X = 0;
	ClippingRegion.Y = 0;
	ClippingRegion.W = WinWidth;
	ClippingRegion.H = WinHeight;

	SetupFonts();

	Resized();
}

function SetupFonts()
{
	if(GUIScale == 2)
	{
		Fonts[F_Normal] = Font(DynamicLoadObject("UWindowFonts.Tahoma20", class'Font'));
		Fonts[F_Bold] = Font(DynamicLoadObject("UWindowFonts.TahomaB20", class'Font'));
		Fonts[F_Large] = Font(DynamicLoadObject("UWindowFonts.Tahoma30", class'Font'));
		Fonts[F_LargeBold] = Font(DynamicLoadObject("UWindowFonts.TahomaB30", class'Font'));
	}
	else
	{
		Fonts[F_Normal] = Font(DynamicLoadObject("UWindowFonts.Tahoma10", class'Font'));
		Fonts[F_Bold] = Font(DynamicLoadObject("UWindowFonts.TahomaB10", class'Font'));
		Fonts[F_Large] = Font(DynamicLoadObject("UWindowFonts.Tahoma20", class'Font'));
		Fonts[F_LargeBold] = Font(DynamicLoadObject("UWindowFonts.TahomaB20", class'Font'));
	}	
}

function ChangeLookAndFeel(string NewLookAndFeel)
{
	LookAndFeelClass = NewLookAndFeel;
	SaveConfig();

//	// Completely restart UWindow system on the next paint
//	Console.ResetUWindow();
}

function HideWindow()
{
}

function SetMousePos(float X, float Y)
{
	MouseX = X;
	MouseY = Y;
}

function QuitGame()
{
	bRequestQuit = True;
	QuitTime = 0;
	NotifyQuitUnreal();
}

function DoQuitGame()
{
	SaveConfig();
//	Console.SaveConfig();
//	Console.ViewPort.Actor.SaveConfig();
//	Close();
	ViewportOwner.Actor.ConsoleCommand("exit");
}

function Tick(float Delta)
{
	if(bRequestQuit)
	{
		// Give everything time to close itself down (ie sockets).
		if(QuitTime > 0.25)
			DoQuitGame();
		QuitTime += Delta;
	}

	Super.Tick(Delta);
}

// ====================================================================
// Glue Code to hold the UWindows together
// ====================================================================

event Initialized()		// Replaces the BeginPlay 
{
	Root = Self;
	MouseWindow = Self;
	KeyFocusWindow = Self;
	
	Created();		// Glue Logic Replace it later
}


function bool KeyEvent( out EInputKey Key, out EInputAction Action, FLOAT Delta )
{

	if ( (Action == IST_Press) && (Key == IK_Tilde) )
	{
		bAllowConsole = true;
		GotoState('UWindows');
		return true;
	}
		
	return Super.KeyEvent(Key,Action,Delta);
}


state UWindows
{
	function BeginState()
	{
		// Add code to initialize the uwindows system
	
		bVisible 		= true;
		bRequiresTick 	= true;
		
		bWindowVisible = True;
		bUWindowActive = true;

		ViewportOwner.bShowWindowsMouse = True;
		ViewportOwner.bSuspendPrecaching = True;

		if (ViewportOwner.Actor.Level.NetMode == NM_Standalone)
			ViewportOwner.Actor.SetPause( True );

		if (bAllowConsole)
			ConsoleWindow.ShowWindow();
		
	}
	
	function EndState()
	{
		// Add code to hide the window

		bVisible		 = false;
		bRequiresTick	 = false;

		bUWindowActive = False;
		bWindowVisible = False;

		ViewportOwner.bShowWindowsMouse = False;
		ViewportOwner.bSuspendPrecaching = False;

		if (ViewportOwner.Actor.Level.NetMode == NM_Standalone)
			ViewportOwner.Actor.SetPause( False );

		ConsoleWindow.HideWindow();			
			
	}

	function bool KeyType(out EInputKey Key, optional string Unicode )
	{
		WindowEvent(WM_KeyType, None, MouseX, MouseY, Key);
		return true;
	}
	
	function bool KeyEvent( EInputKey Key, EInputAction Action, FLOAT Delta )
	{
		local byte k;
		k = Key;
	
		switch (Action)
		{
			case IST_Release:
				switch (k)
				{
				
					case EInputKey.IK_Escape:
						CloseActiveWindow();
						break;
					case EInputKey.IK_LeftMouse:
						WindowEvent(WM_LMouseUp, None, MouseX, MouseY, k);
						break;
					case EInputKey.IK_RightMouse:
						WindowEvent(WM_RMouseUp, None, MouseX, MouseY, k);
						break;
					case EInputKey.IK_MiddleMouse:
						WindowEvent(WM_MMouseUp, None, MouseX, MouseY, k);
						break;
					default:
						WindowEvent(WM_KeyUp, None, MouseX, MouseY, k);
						break;
				}
				break;

			case IST_Press:
			
				switch (k)
				{
					case EInputKey.IK_LeftMouse:
						WindowEvent(WM_LMouseDown, None, MouseX, MouseY, k);
						break;
					case EInputKey.IK_RightMouse:
						WindowEvent(WM_RMouseDown, None, MouseX, MouseY, k);
						break;
					case EInputKey.IK_MiddleMouse:
						WindowEvent(WM_MMouseDown, None, MouseX, MouseY, k);
						break;
					default:
						WindowEvent(WM_KeyDown, None, MouseX, MouseY, k);
						break;
				}
				break;
			case IST_Axis:
				switch (Key)
				{
					case IK_MouseX:
						MouseX = MouseX + (MouseScale * Delta);
						break;
					case IK_MouseY:
						MouseY = MouseY - (MouseScale * Delta);
						break;					
				}
			default:
				break;
		}
		return true;
	}

}	

function PostRender(canvas Canvas)
{
	local UWindowWindow NewFocusWindow;
	
	Canvas.bNoSmooth = True;
	Canvas.Z = 1;
	Canvas.Style = 1;
	Canvas.DrawColor.r = 255;
	Canvas.DrawColor.g = 255;
	Canvas.DrawColor.b = 255;

	if(ViewportOwner.bWindowsMouseAvailable && Root != None)
	{
		MouseX = ViewportOwner.WindowsMouseX/Root.GUIScale;
		MouseY = ViewportOwner.WindowsMouseY/Root.GUIScale;
	}
	
	if(Canvas.ClipX != OldClipX || Canvas.ClipY != OldClipY)
	{
		OldClipX = Canvas.ClipX;
		OldClipY = Canvas.ClipY;
		
		WinTop = 0;
		WinLeft = 0;
		WinWidth = Canvas.ClipX / Root.GUIScale;
		WinHeight = Canvas.ClipY / Root.GUIScale;

		RealWidth = Canvas.ClipX;
		RealHeight = Canvas.ClipY;

		ClippingRegion.X = 0;
		ClippingRegion.Y = 0;
		ClippingRegion.W = Root.WinWidth;
		ClippingRegion.H = Root.WinHeight;
		Resized();
	}

	if(MouseX > WinWidth) MouseX = WinWidth;
	if(MouseY > WinHeight) MouseY = WinHeight;
	if(MouseX < 0) MouseX = 0;
	if(MouseY < 0) MouseY = 0;


	// Check for keyboard focus
	NewFocusWindow = CheckKeyFocusWindow();

	if(NewFocusWindow != KeyFocusWindow)
	{
		KeyFocusWindow.KeyFocusExit();		
		KeyFocusWindow = NewFocusWindow;
		KeyFocusWindow.KeyFocusEnter();
	}

	MoveMouse(MouseX, MouseY);

	WindowEvent(WM_Paint, Canvas, MouseX, MouseY, 0);

	DrawMouse(Canvas);

}		

function Message( coerce string Msg, float MsgLife)
{
	PropagateMessage(Msg,MsgLife);

	// @@Hack - Pass along to the console
	
	if (ConsoleWindow!=None)
  		ConsoleWindow.PropagateMessage(Msg,MsgLife);
} 


defaultproperties
{
	GUIScale=1
	LookAndFeelClass=""
	bAllowConsole=True
	ConsoleClass=class'UWindowConsoleWindow'
	MouseScale=0.60

}