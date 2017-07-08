class SwatGamespyProfilePopup extends SwatGuiPopup
	native;

import enum EGameSpyResult from Engine.GamespyManager;

var(SWATGui) private Editinline config GUIEditBox			Username;
var(SWATGui) private Editinline config GUIEditBox			Email;
var(SWATGui) private Editinline config GUIEditBox			Password;
var(SWATGui) private Editinline config GUICheckBoxButton	SavePassword;
var(SWATGui) private Editinline config GUIButton			LoginCreate;
var(SWATGui) private Editinline config GUIButton			Done;
var(SWATGui) private Editinline config GUILabel				Info;

var private config localized string DoneText;
var private config localized string CancelText;
var private localized string WaitText;
var private localized string ResultBadEmail;
var private localized string ResultBadLogin;
var private localized string ResultBadPassword;
var private localized string ResultCreateOk;
var private localized string ResultCreateBadPassword;
var private localized string ResultLoginOk;
var private localized string ResultLoginAfterCreateOk;
var private localized string ResultUnknown;
var private localized string LoggingInText;
var private localized string ProfileCreated;
var private localized string ProfileCreating;
var private localized string ProfileConnected;
var private localized string ProfileNotConnected;
var private localized string ProfileDetailsButNotConnected;
var private localized string ValidateBadUsername;
var private localized string ValidateBadUsernameFirstChar;
var private localized string ValidateBadPassword;
var private localized string ValidateBadEmail;
var SwatGamespyManager SGSM;

var bool bCreating;
var bool bOpen;
var string TimerOp;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	LoginCreate.OnClick = OnLoginCreate;
	Done.OnClick = OnDone;
	SavePassword.OnClick = OnSavePassword;
	
	Info.bAllowHTMLTextFormatting = true;

	SGSM = SwatGameSpyManager(PlayerOwner().Level.GetGameSpyManager());

	OnActivate = InternalOnActivate;
	OnDeactivate = InternalOnDeactivate;
}

function BeginGamespyOp()
{
	Done.Caption = CancelText;
	Info.Caption = WaitText;
	LoginCreate.DisableComponent();
	Email.DisableComponent();
	Username.DisableComponent();
	Password.DisableComponent();
}

function ConcludeGamespyOp(string Result)
{
	Info.Caption = Result;
	Done.Caption = DoneText;
	SGSM.OnProfileResult = None;
	LoginCreate.EnableComponent();
	Email.EnableComponent();
	Username.EnableComponent();
	Password.EnableComponent();
	TimerOp = "";
}

function OnLoginCreate(GUIComponent Sender)
{
	local string ValidationResult;

	bCreating = false;

	SGSM.default.SavedProfileEmail = Email.GetText();
	SGSM.default.SavedProfileNickname = Username.GetText();
	
	if (SavePassword.bChecked)
		SGSM.default.SavedProfilePassword = Password.GetText();
	else
		SGSM.default.SavedProfilePassword = "";

	SGSM.CurrentProfilePassword = Password.GetText();

	SGSM.class.static.StaticSaveConfig();

	SGSM.DisconnectUserAccount();

	// validate profile details
	ValidationResult = Validate();
	if (ValidationResult != "")
	{
		Info.Caption = ValidationResult;
		return;
	}

	// try login of profile details
	SGSM.OnProfileResult = OnConnectProfileResult;
	if (SGSM.ConnectUserAccount(Username.GetText(), Email.GetText(), Password.GetText()))
	{
		BeginGamespyOp();
	}
	else
	{
		ConcludeGamespyOp(ResultUnknown);
	}
}

native function string Validate();

function OnDone(GUIComponent Sender)
{
	if (Done.Caption == CancelText)
		SGSM.DisconnectUserAccount();
	Controller.CloseMenu();
}

function OnSavePassword(GUIComponent Sender)
{
	ShowConnectionInformation();
}

function ShowConnectionInformation()
{
	if (SGSM.bIsUserProfileConnected)
	{
		Info.Caption = ProfileConnected;
	}
	else
	{
		if (SGSM.default.SavedProfileEmail != ""
			&& SGSM.default.SavedProfileNickname != ""
			&& SGSM.default.SavedProfilePassword != "")
			Info.Caption = ProfileDetailsButNotConnected;
		else
			Info.Caption = ProfileNotConnected;
	}
}

function InternalOnActivate()
{
	bOpen = true;
	ConcludeGamespyOp("");

	Email.SetText(SGSM.default.SavedProfileEmail);
	Username.SetText(SGSM.default.SavedProfileNickname);
	Password.SetText(SGSM.GetGameSpyPassword());

	SavePassword.SetChecked(SGSM.default.SavedProfilePassword != "");
	ShowConnectionInformation();
}

function InternalOnDeactivate()
{
	bOpen = false;
	ConcludeGamespyOp("");
}

function Timer()
{
	if (!bOpen)
		return;

	if (TimerOp == "create")
	{
		SGSM.OnProfileResult = OnCreateProfileResult;
		log("Creating account"@Username.GetText()@Email.GetText()@Password.GetText());
		if (!SGSM.CreateUserAccount(Username.GetText(), Email.GetText(), Password.GetText()))
		{
			ConcludeGamespyOp(ResultUnknown);
		}
	}
	else if (TimerOp == "connectaftercreate")
	{
		SGSM.OnProfileResult = OnConnectProfileResult;
		if (!SGSM.ConnectUserAccount(Username.GetText(), Email.GetText(), Password.GetText()))
		{
			ConcludeGamespyOp(ResultUnknown);
		}
	}
}

function OnCreateProfileResult(EGameSpyResult result, int profileId)
{
	local string StrResult;
	local bool bSuccess;

	switch (result)
	{
	case GSR_BAD_EMAIL:
		StrResult = ResultBadEmail;
		break;
	case GSR_BAD_PASSWORD:
		StrResult = ResultBadPassword;
		break;
	case GSR_BAD_NICK:
		StrResult = ResultBadLogin;
		break;
	case GSR_VALID_PROFILE:
		StrResult = ResultLoginOk;
		bSuccess = true;
		break;
	default:
		StrResult = ResultUnknown;
	}

	if (!bSuccess)
	{
		ConcludeGamespyOp(StrResult);
	}
	else
	{
		Info.Caption = ProfileCreated;

		// account created -- connect it
		TimerOp = "connectaftercreate";
		SetTimer(0.5, false); // hack, gamespy doesn't like ops during callback
	}
}

function OnConnectProfileResult(EGameSpyResult result, int profileId)
{
	local string StrResult;
	local bool bSuccess;
	local bool bShouldTryCreate;

	switch (result)
	{
	case GSR_BAD_EMAIL:
		StrResult = ResultBadEmail;
		bShouldTryCreate = true;
		break;
	case GSR_BAD_NICK:
		StrResult = ResultBadLogin;
		bShouldTryCreate = true;
		break;
	case GSR_BAD_PASSWORD:
		StrResult = ResultBadPassword;
		break;
	case GSR_USER_CONNECTED:
		if (TimerOp == "connectaftercreate")
			StrResult = ResultLoginAfterCreateOk;
		else
			StrResult = ResultLoginOk;
		bSuccess = true;
		break;
	default:
		StrResult = ResultUnknown;
	}

	// if we failed a login, try create
	if (!bSuccess && !bCreating && bShouldTryCreate)
	{
		Info.Caption = ProfileCreating;

		bCreating = true;
		TimerOp = "create";
		SetTimer(0.5, false); // hack, gamespy doesn't like ops during callback
		return;
	}

	ConcludeGamespyOp(StrResult);

	// tell server to retry stats auth if necessary
	if (SwatGamePlayerController(PlayerOwner()) != None)
		SwatGamePlayerController(PlayerOwner()).ServerRetryStatsAuth();

	SGSM.SavedProfileID = profileID;
}

defaultproperties
{
	ResultBadEmail = "[c=ff0000]The email you supplied is invalid. Try again with a valid email."
	ResultBadLogin = "[c=ff0000]The user name or password you provided is invalid."
	ResultBadPassword = "[c=ff0000]The email address you supplied is already in use, and the password you provided is invalid. Use a different email address or enter the correct password."
	ResultCreateOk = "[c=ffffff]Profile successfully created."
	ResultLoginOk = "[c=ffffff]Login successful. You will be connected automatically on starting each game."
	ResultLoginAfterCreateOk = "[c=00ff00]A new profile has been created for you and login was successful. You will be connected automatically on starting each game."
	ResultUnknown = "[c=ff0000]An error occurred while transmitting data to GameSpy. Please try again later."
	WaitText = "Please wait..."
	DoneText = "DONE"
	CancelText = "CANCEL"
	ProfileCreated = "Profile created, connecting..."
	ProfileCreating = "Account not found, creating...";
	ProfileConnected = "You are currently connected to the GameSpy stat-tracking service. Visit [b]www.gamespyid.com[\\b] for account help."
	ProfileNotConnected = "You are not currently connected to the GameSpy stat-tracking service. Please enter your login details and connect to enable stat-tracking.  Visit [b]www.gamespyid.com[\\b] for account help."
	ProfileDetailsButNotConnected = "You are not currently connected to the GameSpy stat-tracking service. You will be connected automatically each time you join a stats-enabled server."
	ValidateBadUsername = "[c=ff0000]Usernames must have between 3 and 20 characters. Only alphanumeric characters and the characters #$%&'()*+-./:;<=>?@^_`{|}~ are allowed."
	ValidateBadUsernameFirstChar = "[c=ff0000]Usernames may not begin with the following characters: @, +, :, #"
	ValidateBadPassword = "[c=ff0000]You must specify a password.";
	ValidateBadEmail = "[c=ff0000]The email address you specified is not a valid email address.";
}