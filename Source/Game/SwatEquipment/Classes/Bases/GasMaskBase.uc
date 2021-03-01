class GasMaskBase extends Engine.Headgear
    implements IProtectFromCSGas, IProtectFromPepperSpray;

var globalconfig Sound TestSound;

function QualifyProtectedRegion()
{
    assertWithDescription(ProtectedRegion < REGION_Body_Max,
        "[Carlos] The GaskMaskBase class "$class.name
        $" specifies ProtectedRegion="$GetEnum(ESkeletalRegion, ProtectedRegion)
        $".  ProtectiveEquipment may only protect body regions or Region_None.");
}

/////////////////////////////////////////////////////////////////////////////////////////////
//
//         Below this is the testing round for a barebone attempt on a looping sound effect
//     I'm trying it with a timer rn , let's home it works as expected...  -Scape
//
/////////////////////////////////////////////////////////////////////////////////////////////


function PostBeginPlay()
{
    Super.PostBeginPlay();

    SetTimer(1, True);
}


simulated event PostNetBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(1, True);
}


event Timer()
{
    ActivateSound();
}


function ActivateSound()
{
    local SwatPawn A;
    local Controller Player;
    local PlayerController PC;


    A = SwatPawn(Owner);
    Player = SwatGamePlayerController(A.Controller);
    PC = PlayerController(Player);


    if (Player.bIsPlayer == True && Player == Level.GetLocalPlayerController())
    {
        PC.ClientPlaySound(TestSound);
		//PC.ConsoleMessage("Gas mask breath");
    }
	
	//setting the timer about long the loop sound is
	SetTimer(15.75, True);
}

DefaultProperties
{
    TestSound=Sound'SW_FR.gas_mask_noise'
}
