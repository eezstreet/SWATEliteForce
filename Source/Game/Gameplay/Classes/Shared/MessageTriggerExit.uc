class MessageTriggerExit extends MessageTrigger
	editinlinenew;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "Trigger "$triggeredBy$" is exited";
}