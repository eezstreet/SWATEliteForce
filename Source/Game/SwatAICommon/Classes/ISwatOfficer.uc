///////////////////////////////////////////////////////////////////////////////
// ISwatOfficer.uc - ISwatOfficer interface
// we use this interface to be able to call functions on the SwatOfficer because we
// the definition of SwatOfficer has not been defined yet, but because SwatOfficer implements
// ISwatOfficer, we have a contract that says these functions will be implemented, and
// we can cast any Pawn pointer to an ISwatOfficer interface to call them

interface ISwatOfficer extends ISwatAI native;

///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////

function OfficerCommanderAction		GetOfficerCommanderAction();
function OfficerSpeechManagerAction	GetOfficerSpeechManagerAction();

function PlayTurnAwayAnimation();

///////////////////////////////////////////////////////////////////////////////
//
// Equipment

function ThrownWeapon		GetThrownWeapon(EquipmentSlot Slot);
function HandheldEquipment	GetItemAtSlot(EquipmentSlot Slot);
function FiredWeapon		GetPrimaryWeapon();
function FiredWeapon		GetBackupWeapon();
function bool PocketSlotContains(Pocket Slot, Name Equipment);

function ReEquipFiredWeapon();
function InstantReEquipFiredWeapon();

function bool HasTaser();

function SetDoorToBlowC2On(Door TargetDoor);

///////////////////////////////////////////////////////////////////////////////
//
// Formation

function Formation GetCurrentFormation();
function SetCurrentFormation(Formation Formation);
function ClearFormation();
