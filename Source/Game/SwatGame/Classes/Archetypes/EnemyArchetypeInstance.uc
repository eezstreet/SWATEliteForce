class EnemyArchetypeInstance extends CharacterArchetypeInstance
    dependson(SwatEnemy);

var ISwatEnemy.EnemySkill Skill;

var FiredWeapon PrimaryWeapon;
var FiredWeapon BackupWeapon;

var class<FiredWeapon> SelectedPrimaryWeaponClass;
var class<FiredWeapon> SelectedBackupWeaponClass;

var class<Ammunition> SelectedPrimaryWeaponAmmoClass;
var class<Ammunition> SelectedBackupWeaponAmmoClass;

var float InvestigateChance;
var float BarricadeChance;

//IArchetypeInstance implementation
function DestroyEquipment()
{
    Super.DestroyEquipment();

    if (PrimaryWeapon != None)
        PrimaryWeapon.Destroy();
    if (BackupWeapon != None)
        BackupWeapon.Destroy();
}
