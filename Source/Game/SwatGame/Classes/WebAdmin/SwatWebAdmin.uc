// The SwatWebAdmin serves as a single connection.
// Ergo, there is one instance of SwatWebAdmin per active connection to the WebAdmin site.
class SwatWebAdmin extends IPDrv.TCPLink
	transient
	config(SwatGuiState)
	dependsOn(SwatAdmin);

import enum WebAdminMessageType from SwatAdmin;

struct PostData
{
	var string Key;
	var string Value;
};

struct HTTPMessage
{
	var string Version;
	var string Type; // On a request, this is either POST/HEAD/GET. On a response, this can be a 404 Not Found or 200 OK, for instance.
	var string URL; // This is always referring to the page that the admin is trying to go to.
	var string Body; // On a POST request, this is the query. On a GET response, this is the content sent back.
	var array<PostData> Params;	// Key/value pairs for the request

	// Everything past this point is considered an empty string if it does not exist
	var string UserAgent;	// not parsed, don't use
	var string ContentType;
	var string CacheControl;
	var string Pragma;
	var string Location;
	var string Cookie; // The incoming cookie. The user cookie is stored in SwatWebAdmin properties
	var int ContentLength;
};

var SwatWebAdminListener Listener;

var globalconfig string HTTPVersion;
var globalconfig string CacheControl;
var globalconfig string Pragma;

// propogated from the SwatWebAdminListener
var private bool DebugWebAdmin;
var private string PageHeader;
var private string PageStyle;
var private string PageFooter;
var private float ClientRefreshSeconds;

var private string Cookie;
var private string PreviousAlias;
var private string PreviousPassword;
var private bool PreviouslyGuest;

// Starts up the WebAdmin listener.
function BeginPlay()
{
	if(Listener == None)
	{
		// Something bad happened here...we got spawned without a listener...
		mplog("WebAdmin:did NOT spawn webadmin "$self$" because Listener was None");
		Destroy();
	}

	DebugWebAdmin = Listener.DebugWebAdmin;
	PageHeader = Listener.PageHeader;
	PageStyle = Listener.PageStyle;
	PageFooter = Listener.PageFooter;
	ClientRefreshSeconds = Listener.ClientRefreshSeconds;

	if(DebugWebAdmin)
	{
		mplog("WebAdmin:Spawned "$self);
	}
}

// Occurs when the TCP connection is closed.
event Closed()
{
	if(DebugWebAdmin)
	{
		mplog("WebAdmin:Closed()");
	}
	Destroy();
}

// Occurs when the TCP socket receives some data
event ReceivedText(string Text)
{
	local HTTPMessage HTTP;

	if(DebugWebAdmin)
	{
		mplog("WebAdmin: received text "$Text);
	}

	HTTP = ParseHTTP(Text);
	if(InStr(HTTP.Type, "POST") != -1)
	{
		// process POST requests here
		ProcessPostRequest(HTTP);
	}
	else if(InStr(HTTP.Type, "GET") != -1)
	{
		// process GET requests here
		ProcessGetRequest(HTTP);
	}
	else
	{
		// tell the client that we didn't understand what they wanted from us
		if(DebugWebAdmin)
		{
			mplog("didn't understand HTTP type: "$HTTP.Type);
		}
		SendClientError("405 Method Not Allowed");
	}
}

// Parses an HTTP request
function HTTPMessage ParseHTTP(string Text)
{
	local HTTPMessage HTTP;
	local int Index;
	local int LastIndex;
	local string ParseString;
	local string TagsString;
	local string OriginalText;
	local array<string> Lines;
	local array<string> KV;
	local array<string> KV2;
	local int i;

	if(DebugWebAdmin)
	{
		OriginalText = Text;
	}

	if(Text == "")
	{
		// if the text is blank, then the connection got closed
		return HTTP;
	}

	// Format of HTTP request:
	// <method> <url> <http version>\\r\\n
	// <tag>: <content>\\r\\n
	// <body>

	// parse method
	Index = InStr(Text, " ");
	ParseString = Left(Text, Index + 1);
	HTTP.Type = ParseString;

	// parse URL
	Text = Mid(Text, Index + 1);
	Index = InStr(Text, " ");
	ParseString = Left(Text, Index);
	HTTP.URL = ParseString;

	// parse HTTP version
	Text = Mid(Text, Index + 1);
	Index = InStr(Text, "\r\n");
	ParseString = Left(Text, Index + 1);
	HTTP.Version = ParseString;

	// parse tags
	Text = Mid(Text, Index + 2);
	LastIndex = InStr(Text, "\r\n\r\n");
	TagsString = Left(Text, LastIndex);

	Split(TagsString, "\n", Lines);
	for(i = 0; i < Lines.Length; i++)
	{
		TagsString = Lines[i];
		Split(TagsString, ": ", KV);

		if(KV[0] ~= "Cookie")
		{
			HTTP.Cookie = KV[1];
			Split(HTTP.Cookie, "=", KV2);
			if(KV2[1] ~= "__invalid")
			{
				HTTP.Cookie = "";
			}
			else
			{
				HTTP.Cookie = Left(KV2[1], 16);
			}
		}
		else if(KV[0] ~= "User-Agent")
		{
			HTTP.UserAgent = KV[1];
		}
	}

	// parse body
	Text = Mid(Text, LastIndex + 4);
	HTTP.Body = Text;

	if(DebugWebAdmin)
	{
		//mplog("Got HTTP request: " $ OriginalText);
		mplog("Parsed as:");
		mplog("Method: " $ HTTP.Type);
		mplog("URL: " $ HTTP.URL);
		mplog("Version: " $ HTTP.Version);
		mplog("Body: "$HTTP.Body);
		//mplog("User-Agent: " $ HTTP.UserAgent);
	}

	return HTTP;
}

// Send the client a non-successful HTTP response, like a 404
function SendClientError(string ErrorMessage)
{
	local string S;

	S = HTTPVersion $ " " $ ErrorMessage $ "\\r\\n";

	SendText(S);
}

function array<PostData> ParseData(string Data)
{
	local PostData CurrentData;
	local array<PostData> PostData;
	local array<string> Pairs;
	local array<string> Pair;
	local int i;

	Split(Data, "&", Pairs);
	for(i = 0; i < Pairs.Length; i++)
	{
		Split(Pairs[i], "=", Pair);
		CurrentData.Key = Pair[0];
		if(Pair.Length == 1)
		{
			CurrentData.Value = Pair[0];
		}
		else
		{
			CurrentData.Value = Pair[1];
		}
		PostData[PostData.Length] = CurrentData;
	}

	return PostData;
}

function ParseGetData(out HTTPMessage InMessage)
{
	local string PairString;
	local int StringIndex;

	StringIndex = InStr(InMessage.URL, "?");
	if(StringIndex == -1)
	{
		// go about on our merry way, there's nothing to parse
		return;
	}

	PairString = Mid(InMessage.URL, StringIndex + 1);
	InMessage.URL = Left(InMessage.URL, StringIndex);
	InMessage.Params = ParseData(PairString);
}

function ParsePostData(out HTTPMessage InMessage)
{
	InMessage.Params = ParseData(InMessage.Body);
}

function string GetPostDataKey(array<PostData> PostData, string Key)
{
	local int i;

	for(i = 0; i < PostData.length; i++)
	{
		if(PostData[i].key ~= key)
		{
			return PostData[i].value;
		}
	}

	return "";
}

// Processes a POST request
function ProcessPostRequest(HTTPMessage InMessage)
{
	local string HTML;

	ParsePostData(InMessage);

	HTML = FormatTextString(PageHeader, PageStyle);
	if(InMessage.URL ~= "/login_action")
	{
		if(!WebAdminPage_LoginAction(InMessage, HTML))
		{
			return;
		}
	}
	else if(InMessage.URL ~= "/meta-send")
	{
		if(!WebAdminMeta_Send(InMessage))
		{
			Redirect("/index");
		}
		return;
	}
	HTML = HTML $ PageFooter;
	SendHTML(HTML);
}

// Processes a GET request
function ProcessGetRequest(HTTPMessage InMessage)
{
	local string HTML;

	ParseGetData(InMessage);

	HTML = FormatTextString(PageHeader, PageStyle);
	if(InMessage.URL ~= "/testconnect")
	{
		HTML = HTML $ WebAdminPage_TestConnect(InMessage);
	}
	else if(InMessage.URL ~= "/index" || InMessage.URL ~= "/")
	{
		HTML = HTML $ WebAdminPage_Index(InMessage);
	}
	else if(InMessage.URL ~= "/info")
	{
		HTML = HTML $ WebAdminPage_Info(InMessage);
	}
	else if(InMessage.URL ~= "/login")
	{
		if(!WebAdminPage_Login(InMessage, HTML))
		{
			Redirect("/webadmin");
			return;
		}
	}
	else if(InMessage.URL ~= "/logout")
	{
		if(!WebAdminPage_LogoutAction(InMessage, HTML))
		{
			Redirect("/index");
			return;
		}
	}
	else if(InMessage.URL ~= "/webadmin")
	{
		if(!WebAdminPage_WebAdmin(InMessage, HTML))
		{
			Redirect("/index");
			return;
		}
	}
	else if(InMessage.URL ~= "/meta-poll")
	{
		// /meta-poll is a unique URL that shouldn't be accessible to the client.
		if(!WebAdminMeta_Poll(InMessage))
		{
			Redirect("/index");
		}
		return;
	}
	else if(InMessage.URL ~= "/commandhelp")
	{
		HTML = HTML $ WebAdminPage_CommandHelp(InMessage);
	}
	else
	{
		HTML = HTML $ WebAdminPage_404(InMessage);
	}
	HTML = HTML $ PageFooter;
	SendHTML(HTML);
}

// Send an HTTP Response
function SendHTTPResponse(HTTPMessage OutMessage)
{
	local string S;

	S = OutMessage.Version $ " " $ OutMessage.Type $ "\r\n";
	S = S $ "Content-Type: " $ OutMessage.ContentType $ "\r\n";
	S = S $ "Cache-Control: " $ OutMessage.CacheControl $ "\r\n";
	S = S $ "Content-Length: " $ OutMessage.ContentLength $ "\r\n";
	if(OutMessage.Location != "")
	{	// send redirect if needed
		S = S $ "Location: " $ OutMessage.Location $ "\r\n";
	}
	if(Cookie != "")
	{
		S = S $ "Set-Cookie: token=" $ Cookie $ "\r\n";
	}
	S = S $ "Pragma: " $ OutMessage.Pragma $ "\r\n\r\n";
	S = S $ OutMessage.Body;

	SendText(S);
	if(DebugWebAdmin)
	{
		mplog("Sent "$S);
	}
}

// Send some HTML to the client
function SendHTML(string HTML)
{
	local HTTPMessage OutMessage;

	OutMessage.Version = HTTPVersion;
	OutMessage.Type = "200 OK";
	OutMessage.ContentType = "text/html";
	OutMessage.ContentLength = Len(HTML);
	OutMessage.CacheControl = CacheControl;
	OutMessage.Pragma = Pragma;
	OutMessage.Body = HTML;

	SendHTTPResponse(OutMessage);
}

// Send some XML to the client
function SendXML(string XML)
{
	local HTTPMessage OutMessage;

	OutMessage.Version = HTTPVersion;
	OutMessage.Type = "200 OK";
	OutMessage.ContentType = "text/xml";
	OutMessage.ContentLength = Len(XML);
	OutMessage.CacheControl = CacheControl;
	OutMessage.Pragma = Pragma;
	OutMessage.Body = XML;

	SendHTTPResponse(OutMessage);
}

// Redirect the client to some location
function Redirect(string Location)
{
	local HTTPMessage OutMessage;

	OutMessage.Version = HTTPVersion;
	OutMessage.Type = "303 See Other";
	OutMessage.CacheControl = CacheControl;
	OutMessage.Pragma = Pragma;
	OutMessage.Location = Location;

	SendHTTPResponse(OutMessage);
}

///////////////////////////////////////////////////////////////////////////////
//
//	Metadata - AJAX requests

// Polling sends awaiting messages to the client and updates the userlist
function bool WebAdminMeta_Poll(HTTPMessage InMessage)
{
	local string Alias;
	local string Password;
	local bool WasGuest;

	Alias = GetPostDataKey(InMessage.Params, "u");
	Password = GetPostDataKey(InMessage.Params, "p");
	WasGuest = GetPostDataKey(InMessage.Params, "g") ~= "true";
	return Listener.Polled(self, Cookie, Alias, Password, WasGuest, RemoteAddr);
}

// Sending sends some console command to the server
function bool WebAdminMeta_Send(HTTPMessage InMessage)
{
	return Listener.SentData(self, Cookie, InMessage.Body);
}

///////////////////////////////////////////////////////////////////////////////
//
//	POST responses - content

function bool WebAdminPage_LoginAction(HTTPMessage InMessage, out string HTML)
{
	local string Alias;
	local string Password;
	local string LoginType;
	local SwatAdminPermissions Perms;

	Alias = GetPostDataKey(InMessage.Params, "alias");
	Password = GetPostDataKey(InMessage.Params, "password");
	LoginType = GetPostDataKey(InMessage.Params, "logintype");

	// check to see if no alias entered
	if(Alias ~= "")
	{
		Redirect("/login?e=noalias");
		return false;
	}

	// check to see if the alias is already used
	if(Listener.AliasInUse(Alias))
	{
		Redirect("/login?e=aliasinuse");
		return false;
	}

	// if we're using the login page, we need to check the password
	if(LoginType ~= "Login")
	{
		if(Password ~= "")
		{
			Redirect("/login?e=nopass");
			return false;
		}

		Perms = SwatGameInfo(Level.Game).Admin.FindRole(Password);

		if(Perms == None)
		{
			Redirect("/login?e=invalidpass");
			return false;
		}

		PreviouslyGuest = false;
	}
	else
	{
		Perms = SwatGameInfo(Level.Game).Admin.GuestPermissions;
		PreviouslyGuest = true;
	}

	//{
	//	Redirect("/login?e=invalidrole");
	//	return false;
	//}

	// add user to logged in admin list and set cookie
	Cookie = Listener.LoginUser(Alias, Perms, RemoteAddr);

	// tell the other webadmins that we logged in
	if(Perms.PermissionSetName == "")
	{
		Listener.SendWebAdminMessage(WebAdminMessageType.MessageType_AdminJoin, "" $ Alias $ " joined WebAdmin as a guest.");
	}
	else
	{
		Listener.SendWebAdminMessage(WebAdminMessageType.MessageType_AdminJoin, "" $ Alias $ " joined WebAdmin with role: " $ Perms.PermissionSetName);
	}

	PreviousAlias = Alias;
	PreviousPassword = Password;

	// redirect
	HTML = HTML $ "<span class=\"sty_statictext\">You have logged in successfully and will enter the WebAdmin panel in 5 seconds.</span><br>";
	HTML = HTML $ "<span class=\"sty_statictext\">Click <a href=\"/webadmin\">here</a> if your browser does not redirect you.</span>";
	HTML = HTML $ "<meta http-equiv=\"refresh\" content=\"5; url=/webadmin\">";
	return true;
}

function bool WebAdminPage_LogoutAction(HTTPMessage InMessage, out string HTML)
{
	local bool LoggedOut;

	LoggedOut = Listener.LogoutUser(Cookie);
	Cookie = "__invalid";

	if(!LoggedOut)
	{
		Redirect("/index");
		return false;
	}
	HTML = HTML $ "<span class=\"sty_statictext\">You have logged out successfully and will return to the main page in 5 seconds.</span><br>";
	HTML = HTML $ "<span class=\"sty_statictext\">Click <a href=\"/index\">here</a> if your browser does not redirect you.</span>";
	HTML = HTML $ "<meta http-equiv=\"refresh\" content=\"5; url=/index\">";
	return true;
}

///////////////////////////////////////////////////////////////////////////////
//
//	GET responses - content

// 404 page
function string WebAdminPage_404(HTTPMessage InMessage)
{
	return "<h1>404 Page Not Found</h1><hr><i>Couldn't find page \"" $ InMessage.URL $ "\"</i><br><i>SWAT: Elite Force WebAdmin</i>";
}

// Test connection page - just prints out "Connection Successful" if the webadmin works
function string WebAdminPage_TestConnect(HTTPMessage InMessage)
{
	return "Connection successful!";
}

// Index page - shows some basic data as well as the login/info links
function string WebAdminPage_Index(HTTPMessage InMessage)
{
	local string S;
	local ServerSettings Settings;
	local string ServerName;
	local string MapName;
	local string PlayersString;

	Settings = ServerSettings(Level.CurrentServerSettings);
	ServerName = Settings.ServerName;
	MapName = Settings.Maps[Settings.MapIndex];
	PlayersString = "(" $ Level.Game.NumPlayers $ "/" $ Settings.MaxPlayers $")";

	S = "<span class=\"sty_title\">SWAT: Elite Force WebAdmin</span>";
	S = S $ "<br><div id=\"webadmin-content-box\">";
	S = S $ "<span class=\"sty_subtitle\">" $ ServerName $ "</span>";
	S = S $ "<br><span class=\"sty_statictext\">" $ MapName $ " " $ PlayersString $ " </span>";
	S = S $ "<br><form action=\"/login\" method=\"get\" style=\"display:inline;\"><input class=\"sty_button\" type=\"submit\" value=\"Login\"></form>";
	S = S $ "<form action=\"/info\" method=\"get\" style=\"display:inline;\"><input type=\"submit\" class=\"sty_button\" value=\"Server Info\"></form>";

	S = S $ "</div>";

	return S;
}

// Info page - shows all of the info that is in the index page, as well as the names of each player, next map, and the round state
function string WebAdminPage_Info(HTTPMessage InMessage)
{
	local string S;
	local ServerSettings Settings;
	local string ServerName;
	local string MapName;
	local string PlayersString;
	local string NextMapName;
	local string RoundState;
	local SwatGameReplicationInfo SGRI;
	local SwatPlayerReplicationInfo PRI;
	local int i;
	local string TeamString;
	local string StatusString;
	local SwatRepo Repo;

	SGRI = SwatGameReplicationInfo(Level.Game.GameReplicationInfo);
	Repo = SwatRepo(Level.GetRepo());

	Settings = ServerSettings(Level.CurrentServerSettings);
	ServerName = Settings.ServerName;
	MapName = Settings.Maps[Settings.MapIndex];
	PlayersString = "" $ Level.Game.NumPlayers $ "/" $ Settings.MaxPlayers;
	NextMapName = SGRI.NextMap;
	if(NextMapName == "")
	{
		NextMapName = "Undecided";	// in campaign coop most likely
	}

	switch(Repo.GuiConfig.SwatGameState)
	{
		case GAMESTATE_EntryLoading:
			RoundState = "Server starting";
			break;
		case GAMESTATE_LevelLoading:
			RoundState = "Loading mission";
			break;
		case GAMESTATE_PreGame:
			RoundState = "Waiting to start";
			break;
		case GAMESTATE_MidGame:
			RoundState = "In progress";
			break;
		case GAMESTATE_PostGame:
			RoundState = "Waiting for next map";
			break;
		default:
			RoundState = "Unknown";
			break;
	}

	S = "<span class=\"sty_title\">SWAT: Elite Force WebAdmin</span>";
	S = S $ "<br><div id=\"webadmin-content-box\">";

	S = S $ "<span class=\"sty_subtitle\">Server Info</span>";
	S = S $ "<p><br><span class=\"sty_statictext\">Server Name: "$ServerName$"</span>";
	S = S $ "<br><span class=\"sty_statictext\">Players: "$PlayersString$"</span>";
	S = S $ "<br><span class=\"sty_statictext\">Current Map: "$MapName$"</span>";
	S = S $ "<br><span class=\"sty_statictext\">Next Map: "$NextMapName$"</span>";
	S = S $ "<br><span class=\"sty_statictext\">Round State: "$RoundState$"</span><br></p>";

	S = S $ "<span class=\"sty_subtitle\">Player Info</span>";
	S = S $ "<p><table><tr><th>Ping</th><th>Name</th><th>Team</th><th>Status</th></tr>";
	for(i = 0; i < ArrayCount(SGRI.PRIStaticArray); i++)
	{
		PRI = SGRI.PRIStaticArray[i];
		if(PRI == None)
		{
			continue;
		}

		TeamString = PRI.Team.TeamName;
		if(PRI.IsLeader)
		{
			TeamString = TeamString $ " (Leader)";
		}

		if(Repo.GuiConfig.SwatGameState == GAMESTATE_MidGame)
		{
			switch(PRI.COOPPlayerStatus)
			{
				case STATUS_Healthy:
					StatusString = "Healthy";
					break;
				case STATUS_Injured:
					StatusString = "Injured";
					break;
				case STATUS_Incapacitated:
					StatusString = "Incapacitated";
					break;
			}
		}
		else if(PRI.COOPPlayerStatus == STATUS_Ready)
		{
			StatusString = "Ready";
		}
		else
		{
			StatusString = "Not Ready";
		}

		S = S $ "<tr>";
		S = S $ "<td>" $ PRI.Ping $ "</td><td>" $ PRI.PlayerName $ "</td><td>" $ TeamString $ "</td><td>" $ StatusString $ "</td>";
		S = S $ "</tr>";
	}
	S = S $ "</table></p>";
	S = S $ "<form action=\"/index\" method=\"get\" style=\"display-inline;\"><input type=\"submit\" class=\"sty_button\" value=\"Back\"></form>";
	S = S $ "</div>";
	return S;
}

// Login page - allows the user to log in, or takes them immediately to the webadmin panel if they are logged in with a cookie already
// If the guest role on the server allows for logging in as a guest, we can use an alias to log in as a guest.
function bool WebAdminPage_Login(HTTPMessage InMessage, out string S)
{
	local string Error;

	if(Listener.LoggedIn(InMessage.Cookie))
	{
		Cookie = InMessage.Cookie;
		return false;
	}

	Cookie = "";
	mplog("Cookie got blanked because login");
	Error = GetPostDataKey(InMessage.Params, "e");

	S = S $ "<span class=\"sty_title\">SWAT: Elite Force WebAdmin</span>";
	S = S $ "<br><div id=\"webadmin-content-box\">";
	if(Error ~= "noalias")
	{
		S = S $ "<span class=\"sty_error\">Please enter an alias.</span><br>";
	}
	else if(Error ~= "aliasinuse")
	{
		S = S $ "<span class=\"sty_error\">That alias is already in use. Please enter another.</span><br>";
	}
	else if(Error ~= "nopass")
	{
		S = S $ "<span class=\"sty_error\">Please enter a password.</span><br>";
	}
	else if(Error ~= "invalidpass")
	{
		S = S $ "<span class=\"sty_error\">Invalid role password.</span><br>";
	}
	else if(Error ~= "invalidrole")
	{
		S = S $ "<span class=\"sty_error\">That role doesn't have WebAdmin access.</span><br>";
	}
	S = S $ "<span class=\"sty_subtitle\">Login</span>";
	S = S $ "<form action=\"/login_action\" method=\"post\">";
	S = S $ "<span class=\"sty_statictext\">Alias</span><input type=\"text\" name=\"alias\" class=\"sty_inputtext\">";
	S = S $ "<br><span class=\"sty_statictext\">Role Password</span><input type=\"password\" class=\"sty_inputtext\" name=\"password\">";
	S = S $ "<br><input type=\"submit\" class=\"sty_button\" name=\"logintype\" value=\"Login\">";
	S = S $ "<input type=\"submit\" class=\"sty_button\" name=\"logintype\" value=\"Login as Guest\">";
	S = S $ "</form>";
	S = S $ "<form action=\"/index\" method=\"get\" style=\"display-inline;\"><input type=\"submit\" class=\"sty_button\" value=\"Back\"></form>";
	S = S $ "</div>";
	return true;
}

// Webadmin page - redirects the user to the index if they do not have a login token, otherwise shows the full webadmin panel.
// The WebAdmin panel is very reminiscent of the ingame panel, but also has an AJAX-enabled event/chat window and a list of players and webadmins.
// The logged in user can type chat through here, and will show up as <Alias>(WebAdmin): <Message> to connected clients and other webadmins.
function bool WebAdminPage_WebAdmin(HTTPMessage InMessage, out string HTML)
{
	local string Alias;
	local SwatAdminPermissions Permissions;

	if(InMessage.Cookie != Cookie)
	{
		Cookie = InMessage.Cookie;
	}

	if(!Listener.GetUserData(Cookie, Alias, Permissions))
	{
		// person is not logged in - abort!
		return false;
	}

	HTML = HTML $ "<span class=\"sty_title\">SWAT: Elite Force WebAdmin</span><br>";
	HTML = HTML $ "<table class=\"sty_layouttable\">";
	HTML = HTML $ "<tr><td class=\"sty_statictext\" colspan=\"2\">Logged in as "$Alias;

	if(Permissions.PermissionSetName != "")
	{
		HTML = HTML $ " ("$Permissions.PermissionSetName$") ";
	}

	HTML = HTML $ " - <a href=\"/logout\">Log Out</a> - ";
	HTML = HTML $ "<a href=\"javascript:void(window.open('/commandhelp', 'WebAdmin Command Help', 'width=700,height=600'));\">Command Help</a>";

	HTML = HTML $ "</td></tr>";

	// draw the userlist
	HTML = HTML $ "<tr><td><div id=\"buffer\" class=\"sty_textarea\"></div></td><td id=\"userlist\" class=\"sty_userlist\"></td></tr>";


	HTML = HTML $ "<tr>";

	// draw the actions comboboxes and buttons
	HTML = HTML $ "<td colspan=\"2\" class=\"sty_statictext\"><form style=\"display-inline;\" onkeypress=\"return keyPressed(event.keyCode);\">";
	HTML = HTML $ "<div style=\"float:left;\">";
	HTML = HTML $ "<select id=\"mapaction\" name=\"mapaction\">";
	HTML = HTML $ " <option value=\"abortgame\">Abort Round</option>";
	HTML = HTML $ " <option value=\"nextmap\">Go to Next Map</option>";
	HTML = HTML $ " <option value=\"lockteams\">Lock/Unlock Teams</option>";
	HTML = HTML $ " <option value=\"alltoblue\">Send all to Blue</option>";
	HTML = HTML $ " <option value=\"alltored\">Send all to Red</option>";
	HTML = HTML $ " <option value=\"startgame\">Start Round</option>";
	HTML = HTML $ "</select> ";
	HTML = HTML $ "<input class=\"sty_smolbutton\" type=\"button\" id=\"currentmapbutton\" onclick=\"mapButton()\" value=\"execute\"/>";
	HTML = HTML $ "</div><div style=\"float:right;\">";
	HTML = HTML $ "<select id=\"playerselection\" name=\"playerselection\"></select>";
	HTML = HTML $ "<select id=\"playeraction\" name=\"playeraction\">";
	HTML = HTML $ " <option value=\"forcell \">Force Less Lethal</option>";
	HTML = HTML $ " <option value=\"forceblue \">Force to Blue Team</option>";
	HTML = HTML $ " <option value=\"forcered \">Force to Red Team</option>";
	HTML = HTML $ " <option value=\"forcespec \">Force to Spectate</option>";
	HTML = HTML $ " <option value=\"kick \">Kick</option>";
	HTML = HTML $ " <option value=\"kickban \">Kick-Ban</option>";
	HTML = HTML $ " <option value=\"kill \">Kill</option>";
	HTML = HTML $ " <option value=\"lockplayerteam \">Lock/Unlock Player Team</option>";
	HTML = HTML $ " <option value=\"mute \">Mute/Unmute</option>";
	HTML = HTML $ " <option value=\"promote \">Promote to Leader</option>";
	HTML = HTML $ "</select> ";
	HTML = HTML $ "<input class=\"sty_smolbutton\" type=\"button\" id=\"currentplayerbutton\" onclick=\"playerButton()\" value=\"execute\"/></div></form></td>";

	HTML = HTML $ "</tr>";

	// draw the text entry
	HTML = HTML $ "<tr><td colspan=\"2\"><div id=\"bottominput\">";
	HTML = HTML $ "<form onkeypress=\"return keyPressed(event.keyCode);\" style=\"display:flex; width:100%; margin-bottom:0px;\">";
	HTML = HTML $ "<input type=\"text\" id=\"inputarea\" autocomplete=\"off\" style=\"display-inline;\" />";
	HTML = HTML $ "<input type=\"button\" class=\"sty_smolbutton\" value=\"send\" id=\"sendbutton\" onclick=\"sendButton()\" />";
	HTML = HTML $ "</form>";
	HTML = HTML $ "</td></div></tr>";
	HTML = HTML $ "</table>";
	HTML = HTML $ "</form>";

	// nasty javascript here...
	HTML = HTML $ "<script type=\"text/javascript\">";

	// Some global junk here
	HTML = HTML $ "var previousAlias = '"$PreviousAlias$"';";
	HTML = HTML $ "var previousPassword = '"$PreviousPassword$"';";
	if(PreviouslyGuest)
	{
		// This is moronic but required. The string representation for boolean in UnrealScript is "True" but JavaScript only understands "true"
		// Adding to this, UnrealScript doesn't have a ternary operator so this just makes for a sad situation all around
		HTML = HTML $ "var previousGuest = true;";
	}
	else
	{
		HTML = HTML $ "var previousGuest = false;";
	}

	// The sendButton() function gets called when we click on the "send" button
	HTML = HTML $ "function sendButton() {";
	HTML = HTML $ "		var xhttp = new XMLHttpRequest();";
	HTML = HTML $ "		xhttp.open(\"POST\", \"/meta-send\", true);";
	HTML = HTML $ "		xhttp.send(document.getElementById(\"inputarea\").value);";
	HTML = HTML $ "		document.getElementById(\"inputarea\").value = \"\";";
	HTML = HTML $ "}";

	// The mapButton() function gets called when we click on the "execute" button for the map selection
	HTML = HTML $ "function mapButton() {";
	HTML = HTML $ "		var sendString = '/' + document.getElementById(\"mapaction\").value;";
	HTML = HTML $ "		var xhttp = new XMLHttpRequest();";
	HTML = HTML $ "		xhttp.open(\"POST\", \"/meta-send\", true);";
	HTML = HTML $ "		xhttp.send(sendString);";
	HTML = HTML $ "}";

	// The playerButton() function gets called when we click on the "execute" button for the player selection
	HTML = HTML $ "function playerButton() {";
	HTML = HTML $ "		var sendString = '/' + document.getElementById(\"playeraction\").value + document.getElementById(\"playerselection\").value;";
	HTML = HTML $ "		var xhttp = new XMLHttpRequest();";
	HTML = HTML $ "		xhttp.open(\"POST\", \"/meta-send\", true);";
	HTML = HTML $ "		xhttp.send(sendString);";
	HTML = HTML $ "}";

	// The keypress() function gets called every time we press a button on the keyboard
	HTML = HTML $ "function keyPressed(key) {";
	HTML = HTML $ "		if(key == 13) {";
	HTML = HTML $ "			sendButton();";
	HTML = HTML $ "			return false;";
	HTML = HTML $ "		} return true;";
	HTML = HTML $ "}";

	// The parse polled data function uses the polled data in a meaningful way
	HTML = HTML $ "function parsePolledData(textdata) {";
	HTML = HTML $ "		var parser = new DOMParser();";
	HTML = HTML $ "		var xmldoc = parser.parseFromString(textdata, \"text/xml\");";
	HTML = HTML $ "		var users = xmldoc.getElementsByTagName(\"USER\");";
	HTML = HTML $ "		var admins = xmldoc.getElementsByTagName(\"ADMIN\");";
	HTML = HTML $ "		var msgs = xmldoc.getElementsByTagName(\"MSG\");";
	HTML = HTML $ "		var buffer = document.getElementById(\"buffer\");";
	HTML = HTML $ "		var userlist = document.getElementById(\"userlist\");";
	HTML = HTML $ "		var ministring = '';";
	HTML = HTML $ "		var playerSelect = document.getElementById(\"playerselection\");";
	HTML = HTML $ "		var previousPlayer = playerSelect.value;";
	HTML = HTML $ "		var i;";
	// Iterate through admin list
	HTML = HTML $ "		userlist.innerHTML = \"<span class='sty_userlisttitle'>WebAdmin Users</span>\";";
	HTML = HTML $ "		ministring = '<p>';";
	HTML = HTML $ "		for(i = 0; i < admins.length; i++) {";
	HTML = HTML $ "			var admin = admins[i];";
	HTML = HTML $ "			var adminname = admin.childNodes[0].childNodes[0].nodeValue;";
	HTML = HTML $ "			var adminrole;";
	HTML = HTML $ "			if(admin.childNodes[1] == null || admin.childNodes[1].childNodes[0] == null) {";
	HTML = HTML $ "				adminrole = \"Guest\";";
	HTML = HTML $ "			} else {";
	HTML = HTML $ "				adminrole = admin.childNodes[1].childNodes[0].nodeValue;";
	HTML = HTML $ "			}";
	HTML = HTML $ "			ministring += adminname + '('+adminrole+')' + '<br>';";
	HTML = HTML $ "		}";
	HTML = HTML $ "		ministring += '</p>';";
	HTML = HTML $ "		userlist.innerHTML += ministring;";
	HTML = HTML $ "		ministring = '<p>';";
	// Clear the previous user list
	HTML = HTML $ "		for(i = playerSelect.options.length - 1; i >= 0; i--) {";
	HTML = HTML $ "			playerSelect.remove(i);";
	HTML = HTML $ "		}";
	// Iterate through user list
	HTML = HTML $ "		if(users.length > 0) {";
	HTML = HTML $ "			userlist.innerHTML += \"<span class='sty_userlisttitle'>Players</span>\";";
	HTML = HTML $ "		}";
	HTML = HTML $ "		for(i = 0; i < users.length; i++) {";
	HTML = HTML $ "			var user = users[i];";
	HTML = HTML $ "			var username = user.childNodes[0].nodeValue;";
	HTML = HTML $ "			var option = document.createElement(\"option\");";
	HTML = HTML $ "			var minidiv = document.createElement(\"div\");";
	HTML = HTML $ "			minidiv.innerHTML = username;";
	HTML = HTML $ "			ministring += username + '<br>';";
	HTML = HTML $ "			username = minidiv.textContent || minidiv.innerText || '';";
	HTML = HTML $ "			option.text = username;";
	HTML = HTML $ "			option.value = username;";
	HTML = HTML $ "			playerSelect.add(option);";
	HTML = HTML $ "		}";
	HTML = HTML $ "		playerSelect.value = previousPlayer;";
	HTML = HTML $ "		ministring += '</p>';";
	HTML = HTML $ "		userlist.innerHTML += ministring;";
	// Iterate through the list of new messages
	HTML = HTML $ "		for(i = 0; i < msgs.length; i++) {";
	HTML = HTML $ "			var msg = msgs[i];";
	HTML = HTML $ "			var msgtype = msg.childNodes[0].childNodes[0].nodeValue;";
	HTML = HTML $ "			var msgtext = msg.childNodes[1].childNodes[0].nodeValue;";
	HTML = HTML $ "			buffer.innerHTML = buffer.innerHTML + msgtext + '</br>';";
	HTML = HTML $ "		}";
	// Scroll the buffer to the bottom
	HTML = HTML $ "		if(msgs.length > 0) {";
	HTML = HTML $ "			buffer.scrollTop = buffer.scrollHeight;";
	HTML = HTML $ "		}";
	HTML = HTML $ "}";

	// The polled data function gets called in response to a successful polling
	HTML = HTML $ "function polledData() {";
	HTML = HTML $ "		if(this.readyState == 4 && this.status == 200) {";
	HTML = HTML $ "			parsePolledData(this.responseText);";
	HTML = HTML $ "		}";
	HTML = HTML $ "}";

	// The frame function gets executed every three seconds. It polls for meta information.
	// On the server end, we will want this to run very fast!!
	HTML = HTML $ "function runFrame() {";
	HTML = HTML $ "		var xhttpf = new XMLHttpRequest();";
	HTML = HTML $ "		xhttpf.onreadystatechange = polledData;";
	HTML = HTML $ "		xhttpf.open(\"GET\", \"/meta-poll?u=\"+previousAlias+\"&p=\"+previousPassword+\"&g=\"+previousGuest, true);";
	HTML = HTML $ "		xhttpf.send();";
	HTML = HTML $ "		setTimeout(runFrame, "$int(ClientRefreshSeconds * 1000)$");";
	HTML = HTML $ "}";

	// run the frame function - it'll rerun itself every 5 seconds as needed
	HTML = HTML $ "runFrame();";

	HTML = HTML $ "</script>";

	return true;
}

function string WebAdminPage_CommandHelp(HTTPMessage InMessage)
{
	local string HTML;

	HTML = "<p class=\"sty_statictext\">The following commands can be used in WebAdmin. To use them, type in the message box and send.</p>";
	HTML = HTML $ "<table class=\"sty_statictext\"><tr><th>Command</th><th>Description</th></tr>";
	HTML = HTML $ "<tr><th>/kick -player name-</th><td>Kicks the specified player.</td></tr>";
	HTML = HTML $ "<tr><th>/kickban -player name-<br>/ban -player name-</th><td>Kicks the specified player from the server and bans them.</td></tr>";
	HTML = HTML $ "<tr><th>/lockteams</th><td>Locks/Unlocks the teams.</td></tr>";
	HTML = HTML $ "<tr><th>/lockplayerteam -player name-</th><td>Locks/Unlocks the player's team.</td></tr>";
	HTML = HTML $ "<tr><th>/alltored</th><td>Forces all players to the red team.</td></tr>";
	HTML = HTML $ "<tr><th>/alltoblue</th><td>Forces all players to the blue team.</td></tr>";
	HTML = HTML $ "<tr><th>/forcered -playername-</th><td>Forces a player to the red team.</td></tr>";
	HTML = HTML $ "<tr><th>/forceblue -playername-</th><td>Forces a player to the blue team.</td></tr>";
	HTML = HTML $ "<tr><th>/mute -playername-</th><td>Toggle mute on a player.</td></tr>";
	HTML = HTML $ "<tr><th>/kill -playername-</th><td>Kills a player.</td></tr>";
	HTML = HTML $ "<tr><th>/promote -playername-</th><td>Promotes a player to leader.</td></tr>";
	HTML = HTML $ "<tr><th>/forcespec -playername-</th><td>Forces a player to spectate.</td></tr>";
	HTML = HTML $ "<tr><th>/switch -map name, including .s4m-</th><td>Go to the specified map.</td></tr>";
	HTML = HTML $ "<tr><th>/nextmap</th><td>Go to the next map.</td></tr>";
	HTML = HTML $ "<tr><th>/startgame</th><td>Starts the current round.</td></tr>";
	HTML = HTML $ "<tr><th>/abortgame</th><td>Aborts the current round.</td></tr>";
	HTML = HTML $ "<tr><th>/forcell -playername-</th><td>Forces a player to use the less lethal loadout.</td></tr>";
	HTML = HTML $ "</table>";

	return HTML;
}

function SetCookie(string NewCookie)
{
	Cookie = NewCookie;
}

defaultproperties
{
	HTTPVersion="HTTP/1.1"
	CacheControl="no-store, no-cache, must-revalidate, post-check=0, pre-check=0"
	Pragma="no-cache"
}
