class GUIExternalViewport extends GUI.GUIImage
    ;

function InitComponent(GUIComponent Owner)
{
    Super.InitComponent(Owner);
}

event Hide()
{
    Super.Hide();
    OnClientDraw=InternalRender;
}

function InternalRender(Canvas inCanvas)
{
    //do nothing, this serves as a stub for reassigning the onClientDraw delegate
}


defaultproperties
{
}

