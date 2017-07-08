class SwatEntryPlayerController extends SwatPlayerController;

event PostBeginPlay()
{
    log("[dkaplan]: In PostBeginPlay of SwatEntryPlayerController");
	Super.PostBeginPlay();
}

#if !IG_THIS_IS_SHIPPING_VERSION //we dont want this debug code in the shipping version
exec function DebugServerList(int num)
{
    SwatGUIControllerBase(Player.GUIController).DebugServerList(num);
}
#endif