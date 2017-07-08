///////////////////////////////////////////////////////////////////////////////

class ActionTrainerPlayAnim extends TrainerScriptActionBase;

///////////////////////////////////////////////////////////////////////////////

var() Name animationName;
var() bool looping          "If true, the specified animation will loop until a Stop Anim script action is run";
var() bool waitToFinish     "If true, the script will wait for the animation to finish before continuing. Only works if non-looping.";

///////////////////////////////////////////////////////////////////////////////

latent function Variable execute()
{
    local SwatTrainer swatTrainer;
    swatTrainer = GetSwatTrainer();

    if (swatTrainer != None)
    {
        if (looping)
        {
            swatTrainer.AnimLoopSpecial(animationName);
        }
        else
        {
            swatTrainer.AnimPlaySpecial(animationName);
            if (waitToFinish)
            {
                swatTrainer.AnimFinishSpecial();
            }
        }
    }

    return None;
}

///////////////////////////////////////

function editorDisplayString(out string s)
{
    local string playStyleString;
    if (looping)
    {
        playStyleString = "loop";
    }
    else
    {
        if (waitToFinish)
        {
            playStyleString = "play and wait for";
        }
        else
        {
            playStyleString = "play";
        }
    }

    s = "Trainer AI - "$playStyleString$" animation "$animationName;
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    returnType        = None
    actionDisplayName = "Trainer - Play Animation"
    actionHelp        = "Plays an animation on the Trainer AI."
    category          = "AI"

    looping           = false
    waitToFinish      = true
}

///////////////////////////////////////////////////////////////////////////////
