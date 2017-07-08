class UWindowConsoleClientWindow extends UWindowDialogClientWindow;

var UWindowConsoleTextAreaControl TextArea;
var UWindowEditControl	EditControl;

#exec LOAD FILE=UWindow_res.pkg

function Created()
{
	TextArea = UWindowConsoleTextAreaControl(CreateWindow(class'UWindowConsoleTextAreaControl', 0, 0, WinWidth, WinHeight));
	EditControl = UWindowEditControl(CreateControl(class'UWindowEditControl', 0, WinHeight-16, WinWidth, 16));
	EditControl.SetFont(F_Normal);
	EditControl.SetValue("Test");
	EditControl.SetNumericOnly(False);
	EditControl.SetMaxLength(400);
	EditControl.SetHistory(True);
	Cursor = Root.NormalCursor;
} 

function Notify(UWindowDialogControl C, byte E)
{
	local string s;
	Super.Notify(C, E);

	switch(E)
	{
	case DE_EnterPressed:
		switch(C)
		{
		case EditControl:
			if(EditControl.GetValue() != "")
			{
				s = EditControl.GetValue();
		
				Message( "> "$s, 6.0 );
				EditControl.Clear();
				if( !Root.ConsoleCommand( s ) )
					Message( Localize("Errors","Exec","Core"), 6.0 );
			}
			break;
		}
		break;
	case DE_WheelUpPressed:
		switch(C)
		{
		case EditControl:
			TextArea.VertSB.Scroll(-1);
			break;
		}
		break;
	case DE_WheelDownPressed:
		switch(C)
		{
		case EditControl:
			TextArea.VertSB.Scroll(1);
			break;
		}
		break;
	}
}

function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);

	EditControl.SetSize(WinWidth, 17);
	EditControl.WinLeft = 0;
	EditControl.WinTop = WinHeight - EditControl.WinHeight;
	EditControl.EditBoxWidth = WinWidth;

	TextArea.SetSize(WinWidth, WinHeight - EditControl.WinHeight);
}

function Paint(Canvas C, float X, float Y)
{
	DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, Texture'UWindow_res.BlackTexture');
}

function Message( coerce string Msg, float MsgLife )
{
	Super.Message( Msg, MsgLife );

	if ( Msg!="" )  
		TextArea.AddText(Msg);
}

