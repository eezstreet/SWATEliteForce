// ====================================================================
//  Class:  SwatGui.SwatConnectionFailureMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatConnectionFailureMenu extends SwatGUIPage
     ;

var(SWATGui) private EditInline Config GUILabel   MyErrorLabel;
var(SWATGui) private EditInline Config GUIButton  MyOKButton;

var() private config localized string ConnectionFailed;
var() private config localized string NetworkingFailed;
var() private config localized string UrlFailed;
var() private config localized string ConnectionTimeOut;
var() private config localized string RejectedByServer;
var() private config localized string CDKeyFailed;
var() private config localized string DemoLoadFailed;
var() private config localized string ConfigMD5ChecksumFailure;
var() private config localized string ConfigMD5ChecksumCountFailure;
var() private config localized string PackageMD5ChecksumFailure;
var() private config localized string GenericFailure;

var() private config localized string IPBanned;
var() private config localized string WrongPassword;
var() private config localized string NeedPassword;
var() private config localized string InvalidOptions;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyOKButton.OnClick=InternalOnClick;
}

event HandleParameters(string Param1, string Param2, optional int param3)
{
    if( Left(Param2, 6) == "CUSTOM" )
    {
        MyErrorLabel.SetCaption(Right(Param2, Len(Param2)-7));
    }
    else if( Param1 == "ConnectionFailed" )
    {
        // First check for specific failure reasons.
        if( Param2 == "CDKeyFailed" )
            MyErrorLabel.SetCaption( CDKeyFailed );
        // If no specific failure reason matches, use a generic "connection failed" message
        else
            MyErrorLabel.SetCaption( ConnectionFailed );
    }
    else if( Param1 == "DemoLoadFailed" )
        MyErrorLabel.SetCaption( FormatTextString( DemoLoadFailed, Param2 ) );
    else if( Param1 == "Networking Failed" )
        MyErrorLabel.SetCaption( NetworkingFailed );
    else if( Param1 == "UrlFailed" )
    {
        if( InStr( Param2, "Index.s4m" ) != -1 )
            MyErrorLabel.SetCaption( ConnectionFailed );
        else
            MyErrorLabel.SetCaption( FormatTextString( UrlFailed, Param2 ) );
    }
    else if( Param1 == "ConnectingText" )
        MyErrorLabel.SetCaption( ConnectionTimeOut );
    else if( Param1 == "Rejected By Server" )
    {
        if( Param2 == "The password you entered is incorrect." )
            MyErrorLabel.SetCaption( WrongPassword );
        else if( Param2 == "You need to enter a password to join this game." )
            MyErrorLabel.SetCaption( NeedPassword );
        else if( Param2 == "You have been banned from this server." )
            MyErrorLabel.SetCaption( IPBanned );
        else if( Param2 == "The options you specified are invalid" )
            MyErrorLabel.SetCaption( InvalidOptions );
	}
	else if( Param1 == "ConfigMD5ChecksumFailed" )
		MyErrorLabel.SetCaption( FormatTextString( ConfigMD5ChecksumFailure, Param2 ) );
	else if( Param1 == "ConfigMD5ChecksumCountFailed" )
		MyErrorLabel.SetCaption(ConfigMD5ChecksumCountFailure);
	else if( Param1 == "PackageMD5ChecksumFailed" )
	    MyErrorLabel.SetCaption(PackageMD5ChecksumFailure);
	else if( Param1 == "GenericFailure" )
	    MyErrorLabel.SetCaption(GenericFailure);
	else
	    MyErrorLabel.SetCaption(GenericFailure);
}

function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyOKButton:
			PerformClose();
			break;
	}
}

function PerformClose() 
{
    SwatGUIController(Controller).FailedConnectionAccepted();
}

defaultproperties
{
    ConnectionFailed="The connection to the server has failed."
    NetworkingFailed="The network connection has failed."
    UrlFailed="Error: %1"
    ConnectionTimeOut="The connection to the server has timed out."
    RejectedByServer="The connection to the server was rejected."
    CDKeyFailed="CD Key authentication has failed."
    DemoLoadFailed="Invalid demo map: '%1'"
	ConfigMD5ChecksumFailure="File is incompatible with the version on the server: '%1'"
	ConfigMD5ChecksumCountFailure="Connection to server rejected (unexpected number of configuration files)."
	PackageMD5ChecksumFailure="Connection to server rejected (invalid content)."
	GenericFailure="The connection to the server has failed."
	
	WrongPassword="The password you entered is incorrect."
	NeedPassword="You need to enter a password to join this game."
	IPBanned="You have been banned from this server."
	InvalidOptions="The options you specified are invalid."
}
