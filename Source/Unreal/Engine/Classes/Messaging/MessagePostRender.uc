// IGA class
class MessagePostRender extends Message
	native;

var Canvas canvas;

// construct
overloaded function construct(Canvas _canvas)
{
	canvas = _canvas;
}

// no editor display
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "";
}


defaultproperties
{
	specificTo	= None
}