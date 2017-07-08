//=============================================================================
// UWindowClientWindow - a blanked client-area window.
//=============================================================================
class UWindowClientWindow extends UWindowWindow;

function Close(optional bool bByParent)
{
	if(!bByParent)
		ParentWindow.Close(bByParent);

	Super.Close(bByParent);
}