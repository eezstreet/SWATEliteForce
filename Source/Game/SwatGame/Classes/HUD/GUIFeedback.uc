class GUIFeedback extends GUI.GUIMultiComponent;

var(GUIFeedback) EditInline Config GUILabel         OtherLabel               "Text that displays the current rounds remaining in the magazine/clip.";
var(GUIFeedback) EditInline Config GUILabel         FireLabel               "Text that displays the current rounds remaining in the magazine/clip.";
var(GUIFeedback) EditInline Config GUILabel         UseLabel               "Text that displays the current rounds remaining in the magazine/clip.";

var() config localized string UseCaption;
var() config localized string FireCaption;

var string UseText;
var string FireText;
var string OtherText;

function OnConstruct(GUIController MyController)
{
    Super.OnConstruct(MyController);

    OtherLabel=GUILabel(AddComponent( "GUI.GUILabel", self.Name$"_OtherLabel" ));
    FireLabel=GUILabel(AddComponent( "GUI.GUILabel", self.Name$"_FireLabel" ));
    UseLabel=GUILabel(AddComponent( "GUI.GUILabel", self.Name$"_UseLabel" ));
}

function UpdateCaption()
{
    local bool bOther, bFire, bUse;

    bOther = Len(OtherText) > 0;
    bFire = Len(FireText) > 0;
    bUse = Len(UseText) > 0;

    OtherLabel.SetCaption(OtherText);
    FireLabel.SetCaption(FireCaption $ FireText);
    UseLabel.SetCaption(UseCaption $ UseText);
    
    OtherLabel.SetVisibility( bOther );
    FireLabel.SetVisibility( bFire );
    UseLabel.SetVisibility( bUse );

    if ( bOther || bFire || bUse )  //currently not blank
    {
        //going up...
        if( !(bRepositioning && TransitionSpec.NewPos.KeyName == 'up') && !IsAtPosition('up') )
        {
            RePosition('down', true);
            RePosition('up');
        }
    }
    else                    //currently blank
    {
        //going down...
        if( !(bRepositioning && TransitionSpec.NewPos.KeyName == 'down') && !IsAtPosition('down') )
            RePosition('down');
    }
}

defaultproperties
{
    bPersistent=True
}