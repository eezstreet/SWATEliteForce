interface ICanBeSelectedInTheGUI;

static function string GetFriendlyName();
static function string GetDescription();
static function Material GetGUIImage();
static function class<Actor> GetRenderableActorClass();
