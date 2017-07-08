class ActionLog extends Action;

var() actionnoresolve string text;


// execute
latent function Variable execute()
{
    local string Result;

    local int Current, Left, Right, NextInterval; //positions in Text

    local string VariableName;
    local Variable Variable;
    local string VariableValue;

	Super.execute();

    Left = InStr(Mid(Text, Current, Len(Text) - Current), "[");

    if (Left < 0)
        Result = Text;
    else
    {
        //parse Text and substitute variables with their values
        while (NextInterval >= 0)
        {
            //concatenate text up to this substitution
            Result = Result $ Mid(Text, Current, Left - Current);

            //find the right bracket
            Right = Left + InStr(Mid(Text, Left + 1, Len(Text) - Left), "]");
            
            if (Right <= Left)
			{
				logError("Syntax error in log string: unterminated square bracket");
                break;
			}

            //lookup the variable value
            VariableName = Mid(Text, Left + 1, Right - Left);

            Variable = tryFindVariable(VariableName);

            if (Variable == None)
                VariableValue = "(variable "$VariableName$" not found)";
            else
                VariableValue = Variable.GetPropertyText("value");

            //concatenate variable value
            Result = Result $ VariableValue;
            
            Current = Right + 2;    //skip to the character after the ]

            NextInterval = InStr(Mid(Text, Current, Len(Text) - Current), "[");
            Left = Current + NextInterval;
        }

        Result = Result $ Mid(Text, Current, Len(Text) - Current);
    }

	SLog(Result);
	
	if (CanSLog())
		parentScript.Level.Game.Broadcast(parentScript, "GUI SCRIPT LOG: "$Result);

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Log '" $ text $ "'";
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Log"
	actionHelp			= "Outputs to the Unreal log file. Use [<varname>] to output variables, i.e. 'The value of MyCounter is [MyCounter]'"
	category			= "Other"
}