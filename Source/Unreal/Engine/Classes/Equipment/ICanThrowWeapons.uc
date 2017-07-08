interface ICanThrowWeapons;

//Return the location & rotation for a thrown projectile
//  results are passed thru 'out' parameters
simulated function GetThrownProjectileParams(out vector outLocation, out rotator outRotation);

//Returns the ICanThrowWeapons' chosen animation for throwing
simulated function name GetPreThrowAnimation();
simulated function name GetThrowAnimation(float ThrowSpeed);

//Returns the root bone used for a Pawn's throw animation
simulated function name GetPawnThrowRootBone();

//Returns the tween time used for a Pawn's throw animation
simulated function float GetPawnThrowTweenTime();
