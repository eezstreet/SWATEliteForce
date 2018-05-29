// Discord Webhook class.
// This functionality currently does not work. Originally the intention was to have the game send Discord messages
// through Discord's built-in Webhook system. However, since Discord uses HTTPS and refuses to allow the option of
// HTTP messages, there's no way to implement this at the moment.
// A final implementation may be to pipe messages over an HTTP connection to an intermediary server.
// However, I don't like this because it allows us to sniff messages sent from servers.
class DiscordWebhookListener extends IPDrv.TCPLink
	config(SwatGuiState);

var config string WebhookIP;
var config string WebhookID;
var config string WebhookToken;

var IpAddr DiscordAddress;

///////////////////////////////////////////////////
//
//	Connecting

// Initial function that gets run when the game starts
function BeginPlay()
{
	log("Establishing Discord link... to "$WebhookIP);
	Resolve(WebhookIP);
}

// Gets called after the webhook URL is resolved
// The IpAddr struct Addr contains the valid address.
event Resolved( IpAddr Addr )
{
	log("Discord link established!");
	DiscordAddress = Addr;
}

// Called when domain resolution fails.
event ResolveFailed()
{
	log("Failed to resolve Discord link - webhook will not function properly");
	Destroy();
}

///////////////////////////////////////////////////
//
//	Sending stuff

// Send a message
function SendMessage(coerce string Message, optional bool IsTTS, optional string SendAsUsername)
{
	local string PostRequest;

	PostRequest = "POST /webhooks/"$WebhookID$"/"$WebhookToken$" HTTP/1.1\r\n";
	PostRequest = PostRequest $ "Host: discordapp.com\r\n";
	PostRequest = PostRequest $ "Content-Type: application/json\r\n";
	PostRequest = PostRequest $ "{";
	PostRequest = PostRequest $ "\"content\": \"" $ Message $ "\",";
	PostRequest = PostRequest $ "\"tts\": \"" $ IsTTS $"\"";
	if(!(SendAsUsername ~= ""))
	{
		PostRequest = PostRequest $ ", \"username\": \"" $ SendAsUsername $ "\"";
	}
	PostRequest = PostRequest $ "}\r\n";

	log("Discord -- Sent message: ");
	log(PostRequest);

	SendText(PostRequest);
}

// Test - get webhook
function TestGetWebhook()
{
	local string GetRequest;

	GetRequest = "GET /webhooks/"$WebhookID$"/"$WebhookToken$" HTTP/1.1\r\n";
	GetRequest = GetRequest $ "Host: discordapp.com\r\n";

	SendText(GetRequest);
}

///////////////////////////////////////////////////
//
//	Receiving stuff
//	Only really done with TestGetWebhook

event ReceivedText( string Text )
{
	log("Discord -- Received text");
	log(Text);
}

defaultproperties
{
}
