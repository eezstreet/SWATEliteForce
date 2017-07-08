class FailedConnect extends LocalMessage
	abstract;

var localized string FailMessage[4];

static function int GetFailSwitch(string FailString)
{
	if ( FailString ~= "NEEDPW" )
		return 0;

	if ( FailString ~= "WRONGPW" )
		return 1;
	
	if ( FailString ~="GAMESTARTED" )
		return 2;
		
	return 3;
}
	
static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Core.Object OptionalObject 
	)
{
	return Default.FailMessage[Clamp(Switch,0,3)];
}
	
defaultproperties
{
	bBeep=false
	bFadeMessage=True
	bIsUnique=True

	DrawColor=(R=255,G=0,B=128,A=255)
	FontSize=1
	
	FailMessage(0)="FAILED TO JOIN GAME.  NEED PASSWORD."
	FailMessage(1)="FAILED TO JOIN GAME.  WRONG PASSWORD."
	FailMessage(2)="FAILED TO JOIN GAME.  GAME HAS STARTED."
	FailMessage(3)="FAILED TO JOIN GAME."
}