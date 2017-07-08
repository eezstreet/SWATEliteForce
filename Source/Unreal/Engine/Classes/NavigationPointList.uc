class NavigationPointList extends Core.Object
	native;

var private array<NavigationPoint> NavPointList;

native final function Add(NavigationPoint NavPoint);

native final function Remove(NavigationPoint NavPoint);

native final function Empty();

// Returns -1 if can't find the navpoint
native final function int GetIndexOf(NavigationPoint NavPoint);

native final function int GetSize();

native final function NavigationPoint GetEntryAt(int Index);

native final function bool Contains(NavigationPoint Point);

event NavigationPoint GetRandomEntry()
{
    return NavPointList[Rand(NavPointList.Length)];
}
