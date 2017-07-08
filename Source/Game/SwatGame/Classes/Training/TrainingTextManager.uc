class TrainingTextManager extends Engine.Actor
    Config(TrainingText);

var private config localized string OpenKeybindingCode;
var private config localized string CloseKeybindingCode;

function SetTrainingText(name TrainingText)
{
    local SwatGamePlayerController SGPC;
    local Controller current;

    for ( current = Level.ControllerList; current != None; current = current.NextController )
    {
        SGPC = SwatGamePlayerController( current );
        if ( SGPC != None )
        {
            SGPC.ClientSetTrainingText( TrainingText );
        }
    }
}

function ClientSetTrainingText(name TrainingText)
{
    local GUIScrollText Control;
    local TrainingText Text;
log( self$"::ClientSetTrainingText( "$TrainingText$" )" );
    Control = SwatGamePlayerController(Level.GetLocalPlayerController()).GetHUDPage().GetTrainingTextControl();

    if (TrainingText == '')
        Control.SetContent("");
    else
    {
        Text = new (None, string(TrainingText)) class'TrainingText';
        assert(Text != None);

        assertWithDescription(Text.Text != "",
            "[tcohen] The TrainingTextManager was called to SetTrainingText() with the TrainingText named "$TrainingText
            $".  But there doesn't seem to be any Training Text by that name in TrainingText.ini.  Please check the name and the config file.");

        Control.WinTop = Text.WinTop;
        Control.WinLeft = Text.WinLeft;
        Control.WinWidth = Text.WinWidth;
        Control.WinHeight = Text.WinHeight;

        if( Text.Text == "" )
            Control.Clear();
        else
            Control.SetContent( Control.ReplaceKeybindingCodes( Text.Text, OpenKeybindingCode, CloseKeybindingCode ) );
    }
}

defaultproperties
{
    label=TrainingTextManager

    DrawType=DT_Sprite
    bHidden=true
    Texture=Texture'EditorSprites.Sprite_TrainingTextManager'
  
    bStatic=false
    Physics=PHYS_None
    bStasis=true
    
    bCollideActors=false
    bCollideWorld=false
    
    OpenKeybindingCode="[k="
    CloseKeybindingCode="]"
}
