class OfficerPersonality extends SwatOfficer;

function ReportToTOC(name EffectEventName, name ReplyEventName, Actor other, SwatPlayer player)
{
	player.CurrentReportableCharacter = IAmReportableCharacter(other);
    TriggerEffectEvent( EffectEventName, self, , , , , , player, Label );
}