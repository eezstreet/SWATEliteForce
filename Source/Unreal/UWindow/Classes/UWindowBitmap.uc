class UWindowBitmap extends UWindowWindow;

var Texture T;
var Region	R;
var bool	bStretch;
var bool	bCenter;


function Paint(Canvas C, float X, float Y)
{
	if(bStretch)
	{
		DrawStretchedTextureSegment(C, 0, 0, WinWidth, WinHeight, R.X, R.Y, R.W, R.H, T);
	}
	else
	{
		if(bCenter)
		{
			DrawStretchedTextureSegment(C, (WinWidth - R.W)/2, (WinHeight - R.H)/2, R.W, R.H, R.X, R.Y, R.W, R.H, T);
		}
		else
		{
			DrawStretchedTextureSegment(C, 0, 0, R.W, R.H, R.X, R.Y, R.W, R.H, T);
		}
	}
}