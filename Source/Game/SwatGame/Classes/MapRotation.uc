class MapRotation extends Core.Object
    config(SwatGuiState)
    perObjectConfig;

//copied from ServerSettings
const MAX_MAPS = 40;
var() config String Maps[MAX_MAPS];
var() config int NumMaps;

function AddMap( string MapName )
{
    if( NumMaps >= MAX_MAPS )
        return;
        
    Maps[NumMaps] = MapName;
    
    NumMaps++;
}

function ClearMaps()
{
    local int i;
    
    for( i = 0; i < MAX_MAPS; i++ )
    {
        Maps[i] = "";
    }

    NumMaps=0;
}

