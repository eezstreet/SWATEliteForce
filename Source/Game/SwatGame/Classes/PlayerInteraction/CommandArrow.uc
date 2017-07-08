class CommandArrow extends Engine.Actor
    config(SwatGame)
    native;

var config float PointOffset;
var config float OverheadOffset;

var private Vector NativeOffset;
var private bool bNativeUpdatePosition;
var private Actor Source;
var private Actor Target;

function ShowArrow( float LifeSpan, Actor inSource, Actor inTarget, optional Vector SourceLocation, optional Vector TargetLocation, optional bool PointAtSource )
{
	local Vector diff;

//log( self$"::ShowArrow( LifeSpan = "$LifeSpan$", inSource = "$inSource$", inTarget = "$inTarget$", SourceLocation = "$SourceLocation$", TargetLocation = "$TargetLocation$", PointAtSource = "$PointAtSource$" )" );

    Source = inSource;
    Target = inTarget;

    if( Source != None )
        SourceLocation = Source.Location;
    if( Target != None )
        TargetLocation = Target.Location;

    //setup the arrow
    if( PointAtSource )
    {
        //attach the arrow to the source
        Source.AttachToBone( self, 'bip01' );

        diff = vect(0.0, 0.0, 0.0);
        diff.z = OverheadOffset;

        //set initial position
        SetRelativeLocation( diff );

        SetRelativeRotation( Rotator( vect(0.0, 0.0, -1.0) ) );
    }
    else
    {
        if( Target != None && Target.IsA('SwatPawn') )
        {
            //do location updates natively
            bNativeUpdatePosition = true;
        }

        //arrow from source to target
	    diff = TargetLocation - SourceLocation;

        //set rotation
        SetRotation(Rotator(diff));

        //set initial position
        NativeOffset = PointOffset * Normal(diff);
        SetLocation( TargetLocation + NativeOffset );
    }

    
    //set timer to hide at the end of this lifespan
    SetTimer( LifeSpan, false );


    //display the arrow
    Show();
    LoopAnim('Point');
} 

event Timer()
{
    //lifespan is up, hide the arrow
    Hide();
    StopAnimating();
    
    if( Source != None )
        Source.DetachFromBone( self );

    //stop special tick handling
    bNativeUpdatePosition = false;
}

defaultproperties
{
    Mesh=Mesh'CoopArrow.CoopArrow'
    Physics=PHYS_None
    DrawType=DT_Mesh
    RemoteRole=ROLE_None
    PointOffset=-60.0
    OverheadOffset=120.0
    bOwnerNoSee=true
}
