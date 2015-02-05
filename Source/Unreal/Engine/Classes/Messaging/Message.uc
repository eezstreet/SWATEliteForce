// IGA class
class Message extends Core.Object
	abstract
	native;

var class<Actor>	specificTo;		// can be None, used by UnrealEd to filter the message dropdown list

native static function Object Allocate( optional Object Context, optional Object Outer, optional string n, optional INT flags, optional Object Template );

// editorDisplay
// Override this function to specify the text shown within the editor
// "filter" is the script's filter object and can be "none"
static function string editorDisplay(Name instigator, Message filter)
{
	return "All messages from "$instigator;
}

// Called by a script when it receives a message.
// Designers can create an optional "filter" message object within a script that incoming messages are compared against.
// "filterMsg" is the calling script's filter message object, and this function is called on the incoming message.
// The base class implementation only accepts the message if string comparisons on all non-empty fields are identical.
// Returns false if the calling script should not be executed (ie message does not pass filter)
function bool passesFilter(Message filterMsg)
{
	local Name propName;
	local String filterProp;
	local bool passed;

	passed = true;

	ForEach AllEditableProperties(class, class'Message', propName)
	{
		filterProp = filterMsg.GetPropertyText(string(propName));

		// If the property's not "empty"
		if (!(filterProp == "" || filterProp == "None" || filterProp == "0" || filterProp == "0.00"))
		{
			if (filterProp != GetPropertyText(string(propName)))
			{
				passed = false; // filter this message out
			}
		}
	}

	return passed;
}

defaultproperties
{
	specificTo	= class'Actor'
}