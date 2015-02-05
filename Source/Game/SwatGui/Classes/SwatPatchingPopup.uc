class SwatPatchingPopup extends SwatGuiPopup
	native;

import enum EGameSpyResult from Engine.GamespyManager;

var(SWATGui) private Editinline config GUIButton			Cancel;
var(SWATGui) private Editinline config GUIButton			Yes;
var(SWATGui) private Editinline config GUIButton			No;
var(SWATGui) private Editinline config GUIButton			Ok;
var(SWATGui) private Editinline config GUILabel				Info;

var private localized string PatchAvailableText;
var private localized string PatchAvailableText2;
var private localized string NoPatchAvailableText;
var private localized string LaunchFailedText;
var private localized string CheckingText;
var private string LaunchURL;
var SwatGamespyManager SGSM;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	Yes.OnClick = OnYes;
	No.OnClick = OnNo;
	Cancel.OnClick = OnCancel;
	Ok.OnClick = OnOk;
	
	Info.bAllowHTMLTextFormatting = true;

	SGSM = SwatGameSpyManager(PlayerOwner().Level.GetGameSpyManager());

	OnActivate = InternalOnActivate;
	OnDeactivate = InternalOnDeactivate;
}

native function OnYes(GUIComponent Sender);

function OnNo(GUIComponent Sender)
{
	Controller.CloseMenu();
}

function OnCancel(GUIComponent Sender)
{
	Controller.CloseMenu();
}

function OnOk(GUIComponent Sender)
{
	Controller.CloseMenu();
}

function InternalOnActivate()
{
	Check();
}

function InternalOnDeactivate()
{
	SGSM.OnQueryPatchResult = None;
}

function OnQueryPatchResult(bool bNeeded, bool bMandatory, string versionName, string URL)
{
	if (bNeeded)
	{
		HasPatch(URL, versionName);
	}
	else
	{
		UpToDate();
	}
}

function Check()
{
	Info.Caption = CheckingText;
	Cancel.Show();
	Ok.Hide();
	Yes.Hide();
	No.Hide();
	
	SGSM.OnQueryPatchResult = OnQueryPatchResult;
	SGSM.QueryPatch();
}

function HasPatch(string URL, string Version)
{
	Info.Caption = Repl(PatchAvailableText, "%v", Version);
	Info.Caption = Info.Caption $ "\n\n[b]" $ URL $ "[\\b]\n\n" $ PatchAvailableText2;
	Cancel.Hide();
	Ok.Hide();
	Yes.Show();
	Yes.EnableComponent();
	No.Show();

	LaunchURL = URL;
}

event OnURLFailed(string Error)
{
	log("URL launch failed:"@Error);

	Info.Caption = Repl(LaunchFailedText, "%u", LaunchURL);
	Cancel.Hide();
	Yes.Hide();
	No.Hide();
	Ok.Show();
}

function UpToDate()
{
	Info.Caption = NoPatchAvailableText;
	Cancel.Hide();
	Yes.Hide();
	No.Hide();
	Ok.Show();
}

defaultproperties
{
	PatchAvailableText="A new version of the game ([b]%v[\\b]) is available at the following URL:";
	PatchAvailableText2="You must upgrade to the latest version in order to play online. Would you like to exit the game and browse to the download location now?"
	NoPatchAvailableText="Your game is up-to-date.";
	LaunchFailedText="An error occurred while trying to launch your web browser. Please visit the website at the following address to download a patch for your software: [b]%u[\\b]";
	CheckingText="Checking for a new version...";
}