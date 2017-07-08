class GUIFireMode extends GUI.GUILabel;

import enum FireMode from Engine.FiredWeapon;

var() private config localized string FireModeSingleText;
var() private config localized string FireModeSingleTaserText;
var() private config localized string FireModeDoubleTaserText;
var() private config localized string FireModeBurstText;
var() private config localized string FireModeAutoText;

function SelectFireMode( FireMode mode )
{
    SetCaption(FireModeText(mode));
}

private function string FireModeText( FireMode mode )
{
    switch(mode)
    {
        case FireMode_Single:
            return FireModeSingleText;
            break;
        case FireMode_SingleTaser:
            return FireModeSingleTaserText;
            break;
	    case FireMode_DoubleTaser:
            return FireModeDoubleTaserText;
            break;
        case FireMode_Burst:
            return FireModeBurstText;
            break;
        case FireMode_Auto:
            return FireModeAutoText;
            break;
    }
}

defaultproperties
{
    FireModeSingleText="SEMI"
	FireModeSingleTaserText="SINGLE"
	FireModeDoubleTaserText="DOUBLE"
    FireModeBurstText="BURST"
    FireModeAutoText="AUTO"
    bPersistent=True
}