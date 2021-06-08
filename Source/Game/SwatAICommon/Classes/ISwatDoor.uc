///////////////////////////////////////////////////////////////////////////////
// ISwatDoor.uc - ISwatDoor interface
// this interface allows us to access functions in SwatDoor we are unable to
//  access in SwatAICommon because of package compilation order

interface ISwatDoor;
///////////////////////////////////////////////////////////////////////////////

import enum AIDoorUsageSide from ISwatAI;
import enum ESkeletalRegion from Engine.Actor;

///////////////////////////////////////////////////////////////////////////////

function bool IsOpen();
function bool IsOpenLeft();
function bool IsBroken();
function bool IsLocked();
function bool IsWedged();
function bool IsBoobyTrapped();
function bool IsBoobyTrapTriggered();
function bool IsChargePlacedOnLeft();
function bool IsChargePlacedOnRight();
function AIDoorUsageSide GetOpenPositions(Pawn Other, bool bPreferSides, out vector OpenPoint, out rotator PawnOpenRotation);
function bool IsOfficerAtSideOpenPoint(Pawn Officer, bool bOnLeftSide);
function vector GetCenterOpenPoint(Pawn Other, out AIDoorUsageSide DoorUsageSide);
function rotator GetSidesOpenRotation(vector OpenPoint);
function vector GetClosePoint(bool bCloseFromLeft);
function vector GetBreachFromPoint(Pawn Other);
function vector GetBreachAimPoint(Pawn Other);
function name GetOpenAnimation(Pawn Other, AIDoorUsageSide DoorUsageSide, optional bool bIsFranticOpen);
function name GetCloseAnimation(Pawn Other, bool bCloseFromBehind);
function name GetTryDoorAnimation(Pawn Other, AIDoorUsageSide DoorUsageSide);
function Pawn GetLastInteractor();
function Pawn GetPendingInteractor();
function SetPendingInteractor(Pawn Interactor);
function bool IsBlockedFor(Pawn Other);
function bool WasBlockedBy(name BlockedClassName);
function array<StackupPoint> GetStackupPoints(vector RequesterLocation);
function array<ClearPoint> GetClearPoints(vector RequesterLocation);
function bool PointIsToMyLeft(vector Point);
function bool ActorIsToMyLeft(Actor Other);
function vector GetSkeletalRegionCenter(ESkeletalRegion Region);
function name GetLeftRoomName();
function name GetRightRoomName();
function Breached(Pawn Instigator);
function Blasted(Pawn Instigator);
function OnUnlocked();
function OnWedged();
function OnUnwedged();
function Actor GetDeployedWedge();
function bool CanBeLocked();
function Lock();
function RegisterInterestedInDoorOpening(IInterestedInDoorOpening Registrant);
function UnRegisterInterestedInDoorOpening(IInterestedInDoorOpening Registrant);
function float GetMoveAndClearPauseThreshold();
function bool WasDoorInitiallyOpen();
function PlacedThrowPoint GetPlacedThrowPoint(vector Origin);
function float GetAdditionalGrenadeThrowDistance(vector Origin);
function array<Actor> GetDoorModels();
function bool IsActivelyTrapped();
function Actor GetTrapOnDoor();