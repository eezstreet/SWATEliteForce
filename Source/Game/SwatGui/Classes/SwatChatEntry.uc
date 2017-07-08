// ====================================================================
//  Class:  SwatGui.SwatChatEntry
//  Parent: GUIEditBox
//
//  Chat entry box.
// ====================================================================

class SwatChatEntry extends GUI.GUIEditBox
     ;

var() array<string> ChatEntryHistory;
var() int ChatEntryIndex;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    if( State == EInputAction.IST_Press )
    {
        if( KeyMatchesBinding( Key, "ScrollChatUp" ) )
        {
            ScrollChatEntryUp();
            return true;
        }
        if( KeyMatchesBinding( Key, "ScrollChatDown" ) )
        {
            ScrollChatEntryDown();
            return true;
        }
    }

    if( Super.InternalOnKeyEvent(Key,State,delta) )
        return true;
    
    if( KeyMatchesBinding( Key, "Fire" ) )
        return true;
    
    if( State == EInputAction.IST_Release )
        return false;

    return true;
}

function AddEntryToHistory( string newEntry )
{
    ChatEntryHistory[ChatEntryHistory.Length] = newEntry;
    
    SetChatEntryIndex( ChatEntryHistory.Length );
}

function ScrollChatEntryUp()
{
    SetChatEntryIndex( Clamp( ChatEntryIndex-1, 0, ChatEntryHistory.Length ) );
}

function ScrollChatEntryDown()
{
    SetChatEntryIndex( Clamp( ChatEntryIndex+1, 0, ChatEntryHistory.Length ) );
}

private function SetChatEntryIndex( int newIndex )
{
    ChatEntryIndex = newIndex;
    
    if( ChatEntryIndex >= ChatEntryHistory.Length )
        SetText( "" );
    else
        SetText( ChatEntryHistory[ChatEntryIndex] );
}