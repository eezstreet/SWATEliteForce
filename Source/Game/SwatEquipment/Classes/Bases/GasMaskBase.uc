class GasMaskBase extends Engine.Headgear
    implements IProtectFromCSGas, IProtectFromPepperSpray;

function QualifyProtectedRegion()
{
    assertWithDescription(ProtectedRegion < REGION_Body_Max,
        "[Carlos] The GaskMaskBase class "$class.name
        $" specifies ProtectedRegion="$GetEnum(ESkeletalRegion, ProtectedRegion)
        $".  ProtectiveEquipment may only protect body regions or Region_None.");
}

//FUNCTIONS TO ACTIVATE GAS MASKS LOOPING BREATH SOUND
simulated function PostBeginPlay()
{
	local SwatGamePlayerController PC;

	PC = SwatGamePlayerController(Pawn(Owner).Controller);
	if( PC == Level.GetLocalPlayerController() )
	{
		//log( "Gas mask breathing" );
		TriggerEffectEvent('ActivatedLoop');
	}	
}


simulated function PostNetBeginPlay()
{
	local SwatGamePlayerController PC;

	PC = SwatGamePlayerController(Pawn(Owner).Controller);
	if( PC == Level.GetLocalPlayerController() )
	{
		//log( "MP Gas mask breathing" );
		TriggerEffectEvent('ActivatedLoop');
	}	
}
