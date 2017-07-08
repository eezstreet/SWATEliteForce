class ObjectPool extends Core.Object;

var Array<Core.Object>	Objects;

//
//	AllocateObject
//

simulated function Core.Object AllocateObject(class ObjectClass)
{
	local Core.Object	Result;
	local int		ObjectIndex;

	for(ObjectIndex = 0;ObjectIndex < Objects.Length;ObjectIndex++)
	{
		if(Objects[ObjectIndex].Class == ObjectClass)
		{
			Result = Objects[ObjectIndex];
			Objects.Remove(ObjectIndex,1);
			break;
		}
	}

	if(Result == None)
		Result = new(None) ObjectClass;

	return Result;
}

//
//	FreeObject
//

simulated function FreeObject(Core.Object Obj)
{
	Objects.Length = Objects.Length + 1;
	Objects[Objects.Length - 1] = Obj;
}

//
//	Shrink
//

simulated function Shrink()
{
	while(Objects.Length > 0)
	{
		//delete Objects[Objects.Length - 1];
		Objects.Remove(Objects.Length - 1,1);
	};
}