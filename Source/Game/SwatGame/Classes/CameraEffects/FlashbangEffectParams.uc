class FlashbangEffectParams  extends Core.Object
   notplaceable
   hidecategories(Object)
   abstract;

var () float RetinaImageDuration "The freeze frame will last this many seconds";
var () float FlashWhiteDuration  "Sets how long the white flash lasts in seconds";
var () float FlashFadeDuration   "How long it takes for the white to fade out (this has to be less than the FlashWhiteDuration)";
var () float FlashInsetAmount    "The white flash texture is zoomed in by this fraction (0-1) at the beginning of the effect and then zooms out to 100% as it fades out";
var () float RetinaEaseIn        "The Ease In paramter for the retina image (rage: .2 - 10) - (1 means linear, more than 1 means a slow ease in, less than 1 means a sharp accelleration)";
var () float RetinaEaseOut       "The Ease Out paramter for the retina image (rage: .2 - 10) - (1 means linear, more than 1 means a slow ease ease out, less than 1 means a sharp accelleration)";
var () float FlashEaseIn         "The Ease In parameter for the white flash (the equation is (1 - Time^EaseIn)^EaseOut, for Time going between 0 and 1";
var () float FlashEaseOut        "The Ease Out parameter for the white flash" ;
var () float FlashInsetEaseIn    "The Ease In parameter for the white flash inset motion";
var () float FlashInsetEaseOut   "The Ease Out parameter for the white flash inset motion";

var () Shader RetinaImage        "The Shader material for rendering the Retina Image";
var () Texture Flash             "The Texture for the white flash";

defaultproperties
{
    RetinaImage=Shader'CameraEffectsTex.RetinaImage'
	Flash=Texture'CameraEffectsTex.Flash'
		// NOTE: The effect duration (either RetinaImageDuration or FlashWhiteDuration+FlashFadeDuration SHOULD NOT EXCEED
		// the PlayerStunDuration set a few lines above for the FlashbangGrenadeProjectile or else you will still see the
		// camera effect but you won't be logically 'stunned'
	RetinaImageDuration=6.0
	FlashWhiteDuration=.2
	FlashFadeDuration=4.0
		// fractional amount to inset the white oval image to start before it zooms out as it fades
		// 0 means no inset, 1 means zoom completely into the central pixel to start with.
    FlashInsetAmount=0.2
		// For help with these parameters, see the Wiki page:
		// http://minuteman/IrrationalWiki/moin.cgi/SwatGame_2fHUDEffects
    RetinaEaseIn=3.0
    RetinaEaseOut=1.0
    FlashEaseIn=1.8
    FlashEaseOut=1.0
    FlashInsetEaseIn=1.7
    FlashInsetEaseOut=1.5
}
