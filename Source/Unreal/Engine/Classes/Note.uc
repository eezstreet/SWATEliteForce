//=============================================================================
// A sticky note.  Level designers can place these in the level and then
// view them as a batch in the error/warnings window.
//=============================================================================
class Note extends Actor
	placeable
	native;

var() string Text;

defaultproperties
{
     bStatic=True
     bHidden=True
     bNoDelete=True
     Texture=Texture'Engine_res.S_Note'
	 bMovable=False
}
