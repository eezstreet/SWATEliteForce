class IdleDefinition extends Core.Object
    within IdleActionsList
    perobjectconfig;

///////////////////////////////////////////////////////////////////////////////
//
// IdleDefinition Enumerations

import enum EIdleWeaponStatus from SwatWeapon;

enum EIdleCharacterType
{
    AllTypesIdle,
    OnlyWeaponUsersIdle,
    EnemyIdle,
    OfficerIdle,
    HostageIdle
};

enum EIdleTime
{
    IdleAnytimeExceptAiming,
    IdleAiming,
	IdleAnytime
};

enum EIdleCharacterAggression
{
	AggressionDoesNotMatter,
	PassiveCharactersOnly,
	AggressiveCharactersOnly
};

enum ECharacterIdlePosition
{
	IdlePositionDoesNotMatter,
    IdleStanding,
    IdleCrouching
};

///////////////////////////////////////////////////////////////////////////////
//
// IdleDefinition Configuration Variables
var config EIdleCharacterType		IdleCharacterType;
var config EIdleTime				IdleTime;
var config EIdleWeaponStatus		IdleWeaponStatus;
var config ECharacterIdlePosition	CharacterIdlePosition;
var config name						IdleCategory;
var config EIdleCharacterAggression IdleCharacterAggression;
var config float					Weight;
