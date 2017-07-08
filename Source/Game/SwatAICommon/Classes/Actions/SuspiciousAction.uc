///////////////////////////////////////////////////////////////////////////////
// SuspiciousAction.uc - SuspiciousAction class
// The base action for Investigating and Barricading

class SuspiciousAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

// if our current weapon needs a reload, reload it
protected latent function CheckWeaponStatus()
{
	local FiredWeapon CurrentWeapon, BackupWeapon;

	// check if our current weapon needs a reload, and if we can reload it.
	// if it's empty and we can't reload, equip our backup weapon if we have one
	if (m_Pawn.GetActiveItem() != None)
	{
		CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());
		BackupWeapon = ISwatEnemy(m_Pawn).GetBackupWeapon();

		if (CurrentWeapon != None)
		{
			if (CurrentWeapon.NeedsReload() && CurrentWeapon.CanReload())
			{
				CurrentWeapon.LatentReload();
			}
			else if (CurrentWeapon.IsEmpty() && (BackupWeapon != None))
			{
				BackupWeapon.LatentEquip();
			}
		}
	}
}