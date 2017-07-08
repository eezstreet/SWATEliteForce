//=============================================================================
// BufferedTcpLink
//=============================================================================
class BufferedTcpLink extends TcpLink;

var string			InputBuffer;
var string 			OutputBuffer;

var string			CRLF;
var string			CR;
var string			LF;

var bool			bWaiting;
var float			WaitTimeoutTime;
var string			WaitingFor;
var int				WaitForCountChars;		// if we're waiting for X bytes
var string			WaitResult;
var int				WaitMatchData;

function ResetBuffer()
{
	InputBuffer = "";
	OutputBuffer = "";
	bWaiting = False;
	CRLF = Chr(10)$Chr(13);
	CR = Chr(13);
	LF = Chr(10);
}

function WaitFor(string What, float TimeOut, int MatchData)
{
	bWaiting = True;
	WaitingFor = What;
	WaitForCountChars = 0;
	WaitTimeoutTime = Level.TimeSeconds + TimeOut;
	WaitMatchData = MatchData;
	WaitResult = "";
}

function WaitForCount(int Count, float TimeOut, int MatchData)
{
	bWaiting = True;
	WaitingFor = "";
	WaitForCountChars = Count;
	WaitTimeoutTime = Level.TimeSeconds + TimeOut;
	WaitMatchData = MatchData;
	WaitResult = "";
}

function GotMatch(int MatchData)
{
	// called when a match happens	
}

function GotMatchTimeout(int MatchData)
{
	// when a match times out
}

function string ParseDelimited(string Text, string Delimiter, int Count, optional bool bToEndOfLine)
{
	local string Result;
	local int Found, i;
	local string s;

	Result = "";	
	Found = 1;
	
	for(i=0;i<Len(Text);i++)
	{
		s = Mid(Text, i, 1);
		if(InStr(Delimiter, s) != -1)
		{
			if(Found == Count)
			{
				if(bToEndOfLine)
					return Result$Mid(Text, i);
				else
					return Result;
			}

			Found++;			
		}
		else
		{
			if(Found >= Count)
				Result = Result $ s;
		}
	}
	
	return Result;
}

// Read an individual character, returns 0 if no characters waiting
function int ReadChar()
{
	local int c;
	
	if(InputBuffer == "")
		return 0;
	c = Asc(Left(InputBuffer, 1));
	InputBuffer = Mid(InputBuffer, 1);
	return c;
}

// Take a look at the next waiting character, return 0 if no characters waiting
function int PeekChar()
{
	//local int c;
	
	if(InputBuffer == "")
		return 0;
	return Asc(Left(InputBuffer, 1));
}

function bool ReadBufferedLine(out string Text)
{
	local int i;

	i = InStr(InputBuffer, Chr(13));
	if(i == -1)
		return False;

	Text = Left(InputBuffer, i);
	if(Mid(InputBuffer, i+1, 1) == Chr(10))
		i++;

	InputBuffer = Mid(InputBuffer, i+1);
	return True;
}

function SendBufferedData(string Text) 
{
	OutputBuffer = OutputBuffer $ Text;
}

event ReceivedText(string Text)
{
	InputBuffer = InputBuffer $ Text;
}

// DoQueueIO is intended to be called from Tick();
function DoBufferQueueIO() 
{
	local int i;

	while(bWaiting)
	{
		if(Level.TimeSeconds > WaitTimeoutTime)
		{
			bWaiting = False;
			GotMatchTimeout(WaitMatchData);
		}
		
		if(WaitForCountChars > 0)
		{
			if(Len(InputBuffer) < WaitForCountChars)
				break;

			WaitResult = Left(InputBuffer, WaitForCountChars);
			InputBuffer = Mid(InputBuffer, WaitForCountChars);
			bWaiting = False;
			GotMatch(WaitMatchData);
		}
		else
		{
			i = InStr(InputBuffer, WaitingFor);
			if(i == -1 && WaitingFor == CR)
				i = InStr(InputBuffer, LF);
			if(i != -1)
			{
				WaitResult = Left(InputBuffer, i + Len(WaitingFor));
				InputBuffer = Mid(InputBuffer, i + Len(WaitingFor));
				bWaiting = False;
				GotMatch(WaitMatchData);
			}
			else
				break;
		}
	}

	if(IsConnected())
	{
		if( OutputBuffer != "" )
		{
			i = SendText(OutputBuffer);
			OutputBuffer = Mid(OutputBuffer, i);
		}
	}
}

defaultproperties
{
	LinkMode=MODE_Text
	ReceiveMode=RMODE_Event
}