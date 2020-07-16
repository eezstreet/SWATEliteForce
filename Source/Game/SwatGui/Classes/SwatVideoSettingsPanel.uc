// ====================================================================
//  Class:  SwatGui.SwatVideoSettingsPanel
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatVideoSettingsPanel extends SwatSettingsPanel
     ;

var(SWATGui) private EditInline Config GUIComboBox MyBMDBox;
var(SWATGui) private EditInline Config GUIComboBox MyDSDBox;
var(SWATGui) private EditInline Config GUIComboBox MyGlowDBox;
var(SWATGui) private EditInline Config GUIComboBox MyResBox;
var(SWATGui) private EditInline Config GUIComboBox MyTexDBox;
var(SWATGui) private EditInline Config GUIComboBox MyPixelShadersBox;
var(SWATGui) private EditInline Config GUIComboBox MyMirrorsBox;
var(SWATGui) private EditInline Config GUICheckBoxButton MyVSyncCheck;


var(SWATGui) private EditInline Config GUISlider MyBrightnessSlider;
var(SWATGui) private EditInline Config GUISlider MyContrastSlider;
var(SWATGui) private EditInline Config GUISlider MyGammaSlider;
var(SWATGui) private EditInline Config GUISlider MyFOVSlider;
var(SWATGui) private EditInline Config GUISlider MyFPFOVSlider;

var(SWATGui) private EditInline Config GUIComboBox MyWorldDetailBox;

var(SWATGui) private EditInline Config GUIComboBox MyRenderDetailBox ;

var() private float DefaultBrightness;
var() private float DefaultContrast;
var() private float DefaultGamma;
var() private float DefaultFOV;

var private string LastResolution;

var() private config localized string WarningTextVideoResolutionChange;


function InitComponent(GUIComponent MyOwner)
{
    local int i;
	Super.InitComponent(MyOwner);

    // settings that are off-low-med-high
	for( i = 0; i < GC.OtherDetailChoices.Length; i++ )
	{
    	MyBMDBox.AddItem(GC.OtherDetailChoices[i],,,i);
        MyDSDBox.AddItem(GC.OtherDetailChoices[i],,,i);
        MyGlowDBox.AddItem(GC.OtherDetailChoices[i],,,i);
    }

	for( i = 0; i < GC.ScreenResolutionChoices.Length; i++ )
	{
        MyResBox.AddItem(GC.ScreenResolutionChoices[i]);
    }

    // settings that are low-med-high
	for( i = 0; i < GC.TextureDetailChoices.Length; i++ )
	{
    	MyTexDBox.AddItem(GC.TextureDetailChoices[i],,,i);
    	MyWorldDetailBox.AddItem(GC.TextureDetailChoices[i],,,i);
    }

    // setting that is custom-low-med-high-veryhigh
	for( i = 0; i < GC.RenderDetailChoices.Length; i++ )
	{
        MyRenderDetailBox.AddItem(GC.RenderDetailChoices[i]);
    }

    // setting that is No/yes
	for( i = 0; i < GC.PixelShaderChoices.Length; i++ )
	{
        MyPixelShadersBox.AddItem(GC.PixelShaderChoices[i]);
    }

    // setting that is No/yes
	for( i = 0; i < GC.RealtimeMirrorChoices.Length; i++ )
	{
        MyMirrorsBox.AddItem(GC.RealtimeMirrorChoices[i]);
    }

    MyBMDBox.OnChange=ComboOnChange;
    MyDSDBox.OnChange=ComboOnChange;
    MyGlowDBox.OnChange=ComboOnChange;
    MyWorldDetailBox.OnChange=ComboOnChange;
    MyResBox.OnChange=ComboOnChange;
    MyTexDBox.OnChange=ComboOnChange;
    MyPixelShadersBox.OnChange=ComboOnChange;
    MyMirrorsBox.OnChange=ComboOnChange;

    MyBrightnessSlider.OnChange=ComboOnChange;
    MyContrastSlider.OnChange=ComboOnChange;
    MyGammaSlider.OnChange=ComboOnChange;
    MyFOVSlider.OnChange=ComboOnChange;
	MyFPFOVSlider.OnChange=ComboOnChange;
    MyRenderDetailBox.OnChange=RenderDetailOnChange;

	MyVSyncCheck.OnChange=ComboOnChange;
}

function SaveSettings()
{
log("[dkaplan] >>> SaveSettings");
    PlayerOwner().ConsoleCommand( "SAVERENDERCONFIG" );
    PlayerOwner().ConsoleCommand( "SAVECLIENTCONFIG" );

    //hack to re-trigger settingsmenu effect after long (audio-stopping) hitch
    SetTimer( 2.5 );
}

function LoadSettings()
{
    local float FOV;
	local float FPFOV;

    FOV = float(PlayerOwner().ConsoleCommand("Get PlayerController BaseFOV"));
	FPFOV = float(PlayerOwner().ConsoleCommand("Get FOVSettings FPFOV"));
    log("[dkaplan] >>> LoadSettings");

    PlayerOwner().ConsoleCommand( "RESETCLIENTCONFIG" );
    // reset render config after client config because it modifies some
    // client config settings
    PlayerOwner().ConsoleCommand( "RESETRENDERCONFIG" );

    MyBrightnessSlider.SetValue( float(PlayerOwner().ConsoleCommand( "GETBRIGHTNESS" ) ));
    MyContrastSlider.SetValue( float(PlayerOwner().ConsoleCommand( "GETCONTRAST" ) ));
    MyGammaSlider.SetValue( float(PlayerOwner().ConsoleCommand( "GETGAMMA" ) ));
    MyFOVSlider.SetValue( FOV );
	MyFPFOVSlider.SetValue( FPFOV );
    MyResBox.Find( PlayerOwner().ConsoleCommand( "GETCURRENTRES" ) );

    MyResBox.SetEnabled( true );
    MyBrightnessSlider.SetEnabled( true );
    MyContrastSlider.SetEnabled( true );
    MyGammaSlider.SetEnabled( true );
    MyFOVSlider.SetEnabled(true);

    // Set render detail, which will cause RenderDetailOnChange() to be
    // called, which will in turn load the renderconfig-based sub-settings
    //
    // convert RenderDetail value range (-1,0...3 == custom,0...3) to
    // combobox value range (0,1...4 == custom,low...superhigh)
    MyRenderDetailBox.SetIndex(1 + int(PlayerOwner().ConsoleCommand( "RENDERDETAIL GET" )));

    //hack to re-trigger settingsmenu effect after long (audio-stopping) hitch
    SetTimer( 2.5 );
}

event Timer()
{
    //retrigger the settings menu effect (because previous hitch may have stopped it)
    if( GC.SwatGameState == GAMESTATE_None ||
        ( GC.SwatGameRole != GAMEROLE_MP_Host &&
          GC.SwatGameRole != GAMEROLE_MP_Client ) )
    {
        PlayerOwner().UnTriggerEffectEvent('UIMenuLoop','SettingsMenu');
        PlayerOwner().TriggerEffectEvent('UIMenuLoop',,,,,,,,'SettingsMenu');
    }
}

function LoadRenderConfigBasedSettings()
{
    local bool bRenderDetailSetToCustom;

log("[dkaplan] >>> LoadRenderConfigBasedSettings");

    bRenderDetailSetToCustom = MyRenderDetailBox.GetIndex() == 0;

    if (DynamicCheckOptionBumpMapDetail())
        MyBMDBox.SetIndex(int(PlayerOwner().ConsoleCommand( "BUMPMAPDETAIL GET" ) ));
    else
        MyBMDBox.SetIndex(0);
    MyBMDBox.SetEnabled( bRenderDetailSetToCustom );
    if( !DynamicCheckOptionBumpMapDetail() )
        MyBMDBox.DisableComponent();

    MyDSDBox.SetIndex(int(PlayerOwner().ConsoleCommand( "SHADOWDETAIL GET" ) ));
    MyDSDBox.SetEnabled( bRenderDetailSetToCustom );
    if( !DynamicCheckOptionShadowDetail() )
        MyDSDBox.DisableComponent();

    if (DynamicCheckOptionGlowDetail())
        MyGlowDBox.SetIndex(int(PlayerOwner().ConsoleCommand( "GLOWDETAIL GET" ) ));
    else
        MyGlowDBox.SetIndex(0);
    MyGlowDBox.SetEnabled( bRenderDetailSetToCustom );
    if( !DynamicCheckOptionGlowDetail() )
        MyGlowDBox.DisableComponent();

    // convert RenderDetail value range (0...3 == off,1...3) to
    // WorldDetail combobox value range (0...2 == low...high)
    MyWorldDetailBox.SetIndex(-1 + int(PlayerOwner().ConsoleCommand( "WORLDDETAIL GET" ) ));
    MyWorldDetailBox.SetEnabled( bRenderDetailSetToCustom );
    if( !DynamicCheckOptionWorldDetail() )
        MyWorldDetailBox.DisableComponent();

    // convert TextureDetail value range (1-3 == low-high) to
    // combobox value range (0-2 == low-high)
    // (ignore TextureDetail value of 0, which we don't use for our defaults)
    MyTexDBox.SetIndex(-1 + int(PlayerOwner().ConsoleCommand( "TEXTUREDETAIL GET" ) ));
    MyTexDBox.SetEnabled( bRenderDetailSetToCustom );
    if( !DynamicCheckOptionTextureDetail() )
        MyTexDBox.DisableComponent();

	// Enable/disable ps2.0 shaders as appropriate
    if (! bRenderDetailSetToCustom)
    {
		if (DynamicCheckOptionSupportsPS20())
			MyPixelShadersBox.SetIndex(1);
		else
			MyPixelShadersBox.SetIndex(0); // "no"
    }
    MyPixelShadersBox.SetEnabled( bRenderDetailSetToCustom );
    if( ! DynamicCheckOptionSupportsPS20() )
        MyPixelShadersBox.DisableComponent();

	// Enable/disable realtime mirrors as appropriate
    MyMirrorsBox.SetIndex(int(PlayerOwner().ConsoleCommand( "USEREALTIMEMIRRORS GET" ) ));
    MyMirrorsBox.SetEnabled( bRenderDetailSetToCustom );

	MyVSyncCheck.bChecked = bool(PlayerOwner().ConsoleCommand( "GET D3DDrv.D3DRenderDevice UseVSync" ));
}


function RenderDetailOnChange( GUIComponent Sender )
{
log("[dkaplan] >>> RenderDetailOnChange. bActiveInput="$bActiveInput$" bLoadingSettings="$bLoadingSettings);

    if( !bActiveInput )
        return;

    ApplySetting("RenderDetail");
    SaveSettings(); // save to config so LoadSettings can load from config
    LoadRenderConfigBasedSettings(); // set GUI components from config
}

function ComboOnChange( GUIComponent Sender )
{
log("[dkaplan] >>> ComboOnChange. Sender="$Sender.Name$" bActiveInput="$bActiveInput$" bLoadingSettings="$bLoadingSettings);

    if( !bActiveInput || bLoadingSettings )
        return;
    switch (Sender)
    {
        case MyResBox:
            // hack: prevent a hitch due to flushing viewport when switching
            // to the same resolution as current resolution
            if (MyResBox.Get() == PlayerOwner().ConsoleCommand( "GETCURRENTRES" ))
            {
                log("Resolution change is no-op, skipping application to prevent flush");
                break;
            }

            ApplyDangerousSetting("Resolution", WarningTextVideoResolutionChange);
            break;
        case MyBMDBox:
            ApplySetting("BumpMapDetail");
            break;
        case MyDSDBox:
            ApplySetting("ShadowDetail");
            break;
        case MyGlowDBox:
            ApplySetting("GlowDetail");
            break;
        case MyWorldDetailBox:
            ApplySetting("WorldDetail");
            break;
        case MyTexDBox:
            ApplySetting("TextureDetail");
            break;
        case MyPixelShadersBox:
            ApplySetting("AllowShaders20");
            break;
        case MyMirrorsBox:
            ApplySetting("Mirrors");
            break;
        case MyBrightnessSlider:
            ApplySetting("Brightness");
            break;
        case MyContrastSlider:
            ApplySetting("Contrast");
            break;
        case MyGammaSlider:
            ApplySetting("Gamma");
            break;
        case MyFOVSlider:
            ApplySetting("FOV");
            break;
		case MyFPFOVSlider:
			ApplySetting("FPFOV");
			break;
		case MyVSyncCheck:
			ApplySetting("VSync");
			break;
    }
}

function InternalApplySetting( String Setting, optional bool bRevertSetting )
{
    local String SettingValue;
    local String ConsoleCommand;
    local bool OnlyUpdateGUI;

log("dkaplan >>> InternalApplySetting( "$Setting$" )");

    SettingValue = "";
    ConsoleCommand = "";

    // by default, don't apply settings if we're loading the GUI page, because
    // the settings are already (internally) applied
    OnlyUpdateGUI = bLoadingSettings;

    switch (Setting)
    {
		case "VSync":
			SettingValue = string(MyVSyncCheck.bChecked);
			ConsoleCommand = "SET D3DDrv.D3DRenderDevice UseVSync";
			break;

        case "RenderDetail":
            // convert combobox value range (0,1...4 == custom,low...superhigh)
            // to RenderDetail value range (-1,0...3 == custom,0...3)
            SettingValue = string(MyRenderDetailBox.GetIndex()-1);
            ConsoleCommand = "RENDERDETAIL";

            // hack: prevent a hitch due to flushing viewport when switching
            // to custom renderdetail, or switching to the same renderdetail
            if (SettingValue ~= PlayerOwner().ConsoleCommand( "RENDERDETAIL GET" ))
            {
                log("RenderDetail change is no-op, skipping application to prevent flush");
                OnlyUpdateGUI = true;
            }
            break;
        case "Resolution":
            if( bRevertSetting )
            {
                PlayerOwner().ConsoleCommand( "SETRES"@LastResolution );
                bLoadingSettings=true;
                MyResBox.Find( PlayerOwner().ConsoleCommand( "GETCURRENTRES" ) );
                bLoadingSettings=false;

                // opt-out of the normal console command execution path
                return;
            }
            else
            {
                LastResolution = PlayerOwner().ConsoleCommand( "GETCURRENTRES" );

                SettingValue = MyResBox.Get();
                ConsoleCommand = "SETRES";
            }
            break;
        case "BumpMapDetail":
            SettingValue = string(MyBMDBox.GetInt());
            ConsoleCommand = "BUMPMAPDETAIL";
            break;
        case "ShadowDetail":
            SettingValue = string(MyDSDBox.GetInt());
            ConsoleCommand = "SHADOWDETAIL";
            break;
        case "GlowDetail":
            SettingValue = string(MyGlowDBox.GetInt());
            ConsoleCommand = "GLOWDETAIL";
            break;
        case "WorldDetail":
            // convert WorldDetail combobox value range (0...2 == low...high)
            // to RenderDetail value range (0...3 == off,1...3)
            SettingValue = string(1 + MyWorldDetailBox.GetInt());
            ConsoleCommand = "WORLDDETAIL";
            break;
        case "TextureDetail":
            // convert combobox value range (0-2 == low-high)
            // to TextureDetail value range (1-3 == low-high)
            // (ignore TextureDetail value of 0, which we don't
            // use for our defaults
            SettingValue = string(MyTexDBox.GetInt() + 1);
            ConsoleCommand = "TEXTUREDETAIL";

            // hack: prevent a hitch due to flushing viewport when switching
            // to the same texture detail as current setting
            if (SettingValue ~= PlayerOwner().ConsoleCommand( "TEXTUREDETAIL GET" ))
            {
                log("TextureDetail change is no-op, skipping application to prevent flush");
                OnlyUpdateGUI = true;
            }
            break;
        case "AllowShaders20":
            SettingValue = "0";
            if (MyPixelShadersBox.GetIndex() != 0)
				SettingValue = "1"; // use 2.0 shaders
            ConsoleCommand = "SHADERS20";
            break;
        case "Mirrors":
            SettingValue = "0";
            if (MyMirrorsBox.GetIndex() != 0)
				SettingValue = "1"; // use realtime mirrors
            ConsoleCommand = "USEREALTIMEMIRRORS";
            break;
        case "Brightness":
            SettingValue = string(MyBrightnessSlider.Value);
            ConsoleCommand = "BRIGHTNESS";
            break;
        case "Contrast":
            SettingValue = string(MyContrastSlider.Value);
            ConsoleCommand = "CONTRAST";
            break;
        case "Gamma":
            SettingValue = string(MyGammaSlider.Value);
            ConsoleCommand = "GAMMA";
            break;
        case "FOV":
            SettingValue = string(MyFOVSlider.Value);
            ConsoleCommand = "FOV";
            break;
		case "FPFOV":
			SettingValue = string(MyFPFOVSlider.Value);
			ConsoleCommand = "FPFOV";
			break;
    }

    if (SettingValue != "" && ConsoleCommand != "")
    {
        if (OnlyUpdateGUI) // don't actually apply the settings, just set the GUI components
        {
            Log("SwatVideoSettingsPanel only needs to set GUI, so NOT Applying Setting: \""$ConsoleCommand@SettingValue$"\"");
        }
        else
        {
            Log("SwatVideoSettingsPanel Applying Setting: \""$ConsoleCommand@SettingValue$"\"");
            PlayerOwner().ConsoleCommand( ConsoleCommand@SettingValue );
			PostApplySetting( Setting );
        }
    }
    else
    {
        assertWithDescription(false, "Invalid option application attempt for setting "$Setting$" (bRevertSetting="$bRevertSetting$").\nCommand = \""$ConsoleCommand$"\" Setting = "$SettingValue);
    }
}

function PostApplySetting( String Setting )
{
	local string LastResolution;

    switch (Setting)
    {
		case "VSync":
			// re-set res to recreate viewport with vsync settings
		    LastResolution = PlayerOwner().ConsoleCommand( "GETCURRENTRES" );
		    PlayerOwner().ConsoleCommand( "SETRES"@LastResolution );
			break;
	}
}

/////////////////////////////////////////////////////////////////////////
// Dynamic Option Checks
//   Returns true if the option should be presented to the
//   user, based on hardware available combined with the
//   current settings of the other options.
//
//   For example, if the user has a Geforce3 card, "High Detail"
//   bump mapping might be a "potential" option, but
//   it might be currently rejected if the user
//   has their screen resolution set too high.
/////////////////////////////////////////////////////////////////////////

function bool DynamicCheckOptionBumpMapDetail()
{
    local bool SupportsBumpmapping;
    SupportsBumpmapping = bool(PlayerOwner().ConsoleCommand( "SUPPORTS BUMPMAP" ) );
    return SupportsBumpmapping;
}

function bool DynamicCheckOptionShadowDetail()
{
    return true;
}

function bool DynamicCheckOptionGlowDetail()
{
    local bool SupportsGlow;
    SupportsGlow = bool(PlayerOwner().ConsoleCommand( "SUPPORTS GLOW" ) );
    return SupportsGlow;
}

function bool DynamicCheckOptionWorldDetail()
{
    return true;
}


function bool DynamicCheckOptionTextureDetail()
{
    return true;
}

function bool DynamicCheckOptionSupportsPS20()
{
    local int MaxPSVer;

	// if we don't support bumpmapping, we don't support any PS version
	if (!DynamicCheckOptionBumpMapDetail())
		return false;

    MaxPSVer = int(PlayerOwner().ConsoleCommand( "MAXPSVER GET" ) );
    return MaxPSVer >= 20 ;
}

protected function ResetToDefaults()
{
	local string DefaultRes;
	local string CurrentRes;

log("dkaplan >>> ResetToDefaults()");

    //set the video defaults here
    MyBrightnessSlider.SetValue( DefaultBrightness );
    MyContrastSlider.SetValue( DefaultContrast );
    MyGammaSlider.SetValue( DefaultGamma );
    MyFOVSlider.SetValue(DefaultFOV);
	MyFPFOVSlider.SetValue(DefaultFOV);

	// set resolution, if the default is different from current setting
	CurrentRes = PlayerOwner().ConsoleCommand( "GETCURRENTRES" );
	DefaultRes = PlayerOwner().ConsoleCommand("GETBESTGUESSDEFAULTRESOLUTION");
	log("CurrentRes = "$CurrentRes$" DefaultRes = "$DefaultRes);
	if ( !(CurrentRes ~= DefaultRes))
	{
		log("Changing resolution to "$DefaultRes);
		PlayerOwner().ConsoleCommand( "SETRES"@DefaultRes );
		MyResBox.Find( PlayerOwner().ConsoleCommand( "GETCURRENTRES" ) );
	}

    // Reset the render detail to the default that was set at the time
    // that the game first started up (i.e., the "best guess" setting
    // that was made in SetInitialConfiguration() in Launch.cpp
    //
    // convert RenderDetail value range (-1,0...3 == custom,0...3) to
    // combobox value range (0,1...4 == custom,low...superhigh)
    MyRenderDetailBox.SetIndex(1 + int(PlayerOwner().ConsoleCommand( "RENDERDETAIL GET BESTGUESSDEFAULT" )));

    // Reset to the default best-guess as to whether to use 2.0 shaders or not
    if (DynamicCheckOptionSupportsPS20())
        MyPixelShadersBox.SetIndex( int(PlayerOwner().ConsoleCommand( "SHADERS20 GET BESTGUESSDEFAULT")) );
    else
        MyPixelShadersBox.SetIndex(0);

	MyVSyncCheck.bChecked = false;
}

function InternalOnDeActivate()
{
  Controller.OpenWaitDialog();
  Super.InternalOnDeActivate();
  PlayerOwner().ConsoleCommand("SaveFOVSettings");
  Controller.CloseWaitDialog();
}


defaultproperties
{
    WarningTextVideoResolutionChange="The game will now attempt to change video resolution. If this fails, the game will revert to the current setting after 10 seconds. Are you sure you want to change video resolution?"

    // When changing video resolution or texture resolution, it might take a
    // long time to re-load all the textures. Make sure we don't revert before
    // the user has a chance to see the confirm dialog.
    ConfirmationDialogDelayBeforeRevert=30

    ConfirmResetString="Are you sure that you wish to reset all video settings to their defaults? This may take a few moments."

    DefaultBrightness=0.6
    DefaultContrast=0.6
    DefaultGamma=1.2
    DefaultFOV=85.0
}
