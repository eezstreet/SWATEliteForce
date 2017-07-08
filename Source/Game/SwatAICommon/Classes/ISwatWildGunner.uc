///////////////////////////////////////////////////////////////////////////////
// ISwatWildGunner.uc - ISwatWildGunner interface
// we use this interface to be able to call functions on the SwatWildGunner because we
// the definition of SwatWildGunner has not been defined yet, but because SwatWildGunner implements
// ISwatWildGunner, we have a contract that says these functions will be implemented, and 
// we can cast any Pawn pointer to an ISwatWildGunnerinterface to call them

interface ISwatWildGunner extends ISwatEnemy;

function bool isFiring();

